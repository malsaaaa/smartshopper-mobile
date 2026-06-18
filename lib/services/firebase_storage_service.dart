import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage Service
/// Handles file uploads and downloads
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
    String fileName = 'profile.jpg',
  }) async {
    try {
      debugPrint('📤 [STORAGE] Starting upload for user: $userId');
      debugPrint('📄 [STORAGE] File name: $fileName');

      final inferredContentType = _inferContentType(fileName, contentType);
      
      final storageRef = _storage.ref();
      final profilePicRef = storageRef.child('profile_pictures/$userId.jpg');
      
      debugPrint('📍 [STORAGE] Destination: ${profilePicRef.fullPath}');
      
      // Upload bytes so the same code works on web and mobile.
      final uploadTask = profilePicRef.putData(
        imageBytes,
        SettableMetadata(contentType: inferredContentType),
      );
      
      // Monitor progress for debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = 100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint('⏳ [STORAGE] Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for the task to complete, but don't allow it to hang forever.
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException('Profile picture upload timed out.');
        },
      );
      debugPrint('✅ [STORAGE] Upload completed. Status: ${snapshot.state}');
      
      // Give Firebase a small window to index
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Get download URL
      final downloadUrl = await profilePicRef.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Getting the download URL timed out.');
        },
      );
      
      debugPrint('🔗 [STORAGE] Download URL obtained: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [STORAGE] CRITICAL FAILURE: $e');
      if (e is FirebaseException) {
        debugPrint('🏷️ [STORAGE] Error Code: ${e.code}');
        debugPrint('📝 [STORAGE] Error Message: ${e.message}');
      }
      return null;
    }
  }

  String _inferContentType(String fileName, String fallback) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return fallback;
  }

  /// Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$userId.jpg');
      await ref.delete();
    } catch (e) {
      debugPrint('❌ Failed to delete profile picture: $e');
    }
  }
}
