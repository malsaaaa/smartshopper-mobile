import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/firestore_auth_service.dart';
import 'package:smartshopper_mobile/services/firestore_user_service.dart';
import 'package:smartshopper_mobile/services/fcm_service.dart';
import 'package:smartshopper_mobile/data/models/index.dart';

/// Firebase Auth Service Provider
final firestoreAuthServiceProvider = Provider<FirestoreAuthService>((ref) {
  return FirestoreAuthService();
});

/// Authentication state provider
final firestoreAuthStateProvider =
    StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(firestoreAuthServiceProvider);
  return authService.authStateChanges;
});

/// Check if user is logged in
final isUserLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(firestoreAuthStateProvider);
  return authState.whenData((user) => user != null).value ?? false;
});

/// Get current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(firestoreAuthStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

/// Get current user profile from Firestore
final currentUserProfileProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final userService = FirestoreUserService();
  return userService.getUserById(userId);
});

/// Sign up notifier
class SignUpNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SignUpNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(firestoreAuthServiceProvider);
      await authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      // Ask for notification permissions upon successful registration
      await FCMService().requestNotificationPermission();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Sign up provider
final signUpProvider = StateNotifierProvider<SignUpNotifier, AsyncValue<void>>(
  (ref) => SignUpNotifier(ref),
);

/// Sign in notifier
class SignInNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SignInNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(firestoreAuthServiceProvider);
      await authService.signIn(
        email: email,
        password: password,
      );
      // Ask for notification permissions upon successful login
      await FCMService().requestNotificationPermission();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Sign in provider
final signInProvider = StateNotifierProvider<SignInNotifier, AsyncValue<void>>(
  (ref) => SignInNotifier(ref),
);

/// Google Sign-In notifier
class GoogleSignInNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  GoogleSignInNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(firestoreAuthServiceProvider);
      await authService.signInWithGoogle();
      // Ask for notification permissions upon successful Google login
      await FCMService().requestNotificationPermission();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Google Sign-In provider
final googleSignInProvider = StateNotifierProvider<GoogleSignInNotifier, AsyncValue<void>>(
  (ref) => GoogleSignInNotifier(ref),
);

/// Sign out function
final signOutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(firestoreAuthServiceProvider);
  await authService.signOut();
});
