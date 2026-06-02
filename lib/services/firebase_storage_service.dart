import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage Service
/// Handles file uploads and downloads
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      debugPrint('📤 [STORAGE] Starting upload for user: $userId');
      debugPrint('📄 [STORAGE] File path: ${imageFile.path}');
      
      final storageRef = _storage.ref();
      final profilePicRef = storageRef.child('profile_pictures/$userId.jpg');
      
      debugPrint('📍 [STORAGE] Destination: ${profilePicRef.fullPath}');
      
      // Upload file
      final uploadTask = profilePicRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Monitor progress for debugging
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = 100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint('⏳ [STORAGE] Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for the task to complete
      final snapshot = await uploadTask;
      debugPrint('✅ [STORAGE] Upload completed. Status: ${snapshot.state}');
      
      // Give Firebase a small window to index
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Get download URL
      final downloadUrl = await profilePicRef.getDownloadURL();
      
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
