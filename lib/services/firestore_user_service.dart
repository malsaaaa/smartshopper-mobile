import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:smartshopper_mobile/data/models/index.dart' as models;

/// Firestore User Service
/// Handles user profile operations with Firestore backend
class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create or update user profile
  Future<void> createOrUpdateUser({
    required String userId,
    required String name,
    required String email,
    String? profilePicture,
  }) async {
    try {
      print('📝 Creating/updating user in Firestore: userId=$userId, email=$email');
      await _usersCollection.doc(userId).set(
        {
          'id': userId,
          'name': name,
          'email': email,
          'profilePicture': profilePicture,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('✅ User profile saved to Firestore');
    } catch (e) {
      print('❌ Failed to create/update user in Firestore: $e');
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// Get user by ID
  Future<models.User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return models.User(
        id: userId.hashCode,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        profilePicture: data['profilePicture'],
        isAdmin: data['isAdmin'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user name
  Future<void> updateUserName(String userId, String name) async {
    try {
      await _usersCollection.doc(userId).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user name: $e');
    }
  }

  /// Update user email
  Future<void> updateUserEmail(String userId, String email) async {
    try {
      await _usersCollection.doc(userId).update({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user email: $e');
    }
  }

  /// Update user profile picture
  Future<void> updateProfilePicture(String userId, String pictureUrl) async {
    try {
      await _usersCollection.doc(userId).update({
        'profilePicture': pictureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
