import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartshopper_mobile/services/firestore_user_service.dart';

/// Firebase Authentication Service
/// Handles user registration, login, and authentication state
class FirestoreAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirestoreUserService _userService = FirestoreUserService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Get current authenticated user
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Sign up with email and password
  Future<firebase_auth.UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('📝 Starting sign up for email: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Firebase Auth user created: ${userCredential.user?.uid}');

      // Create user profile in Firestore
      await _userService.createOrUpdateUser(
        userId: userCredential.user!.uid,
        name: name,
        email: email,
      );
      debugPrint('✅ Firestore user profile created');

      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error: ${e.code} - ${e.message}');
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email is already registered.');
      }
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error during sign up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('User not found.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password.');
      }
      throw Exception('Sign in failed: ${e.message}');
    }
  }

  /// Sign in with Google
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled.');
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔑 Got Firebase credential from Google');

      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ Firebase Auth user created: ${userCredential.user?.uid}');

      // Create or update user profile in Firestore
      await _userService.createOrUpdateUser(
        userId: userCredential.user!.uid,
        name: googleUser.displayName ?? 'User',
        email: googleUser.email,
        profilePicture: googleUser.photoUrl,
      );

      debugPrint('✅ Firestore user profile created from Google');

      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error during Google sign-in: ${e.code} - ${e.message}');
      throw Exception('Google sign-in failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error during Google sign-in: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        await _userService.deleteUser(userId);
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Delete account failed: $e');
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        await currentUser!.verifyBeforeUpdateEmail(newEmail);
        await _userService.updateUserEmail(userId, newEmail);
      }
    } catch (e) {
      throw Exception('Update email failed: $e');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Update password failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Send password reset email failed: $e');
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() => currentUser != null;

  /// Get current user ID
  String? getCurrentUserId() => currentUser?.uid;

  /// Get current user email
  String? getCurrentUserEmail() => currentUser?.email;
}
