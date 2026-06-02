import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/services/firestore_user_service.dart';

/// Get current user from Firestore
final firestoreCurrentUserProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    return null;
  }

  final userService = FirestoreUserService();
  try {
    return await userService.getUserById(userId);
  } catch (e) {
    throw Exception('Failed to fetch user: $e');
  }
});

/// User state notifier for Firestore updates
class FirestoreUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final FirestoreUserService _userService = FirestoreUserService();

  FirestoreUserNotifier(this._ref) : super(const AsyncValue.data(null)) {
    // Load user data on initialization
    _loadUser();
  }

  /// Load user data from Firestore
  Future<void> _loadUser() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      state = const AsyncValue.loading();
      final user = await _userService.getUserById(userId);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _userService.getUserById(userId);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update user name
  Future<void> updateName(String newName) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not authenticated');

      await _userService.updateUserName(userId, newName);

      // Update local state
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(
            user.copyWith(name: newName),
          );
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not authenticated');

      await _userService.updateUserEmail(userId, newEmail);

      // Update local state
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(
            user.copyWith(email: newEmail),
          );
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update profile picture
  Future<void> updateProfilePicture(String pictureUrl) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not authenticated');

      await _userService.updateProfilePicture(userId, pictureUrl);

      // Update local state
      state.whenData((user) {
        if (user != null) {
          state = AsyncValue.data(
            user.copyWith(profilePicture: pictureUrl),
          );
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// User state notifier provider
final firestoreUserNotifierProvider =
    StateNotifierProvider<FirestoreUserNotifier, AsyncValue<User?>>((ref) {
  final notifier = FirestoreUserNotifier(ref);
  // Watch for auth state changes and refresh user when it changes
  ref.listen(currentUserIdProvider, (previous, next) {
    if (next != null && next != previous) {
      notifier.refreshUser();
    }
  });
  return notifier;
});

/// Convenience provider to get user name
final firestoreUserNameProvider = Provider<String?>((ref) {
  final user = ref.watch(firestoreUserNotifierProvider);
  return user.whenData((u) => u?.name).value;
});

/// Convenience provider to get user email
final firestoreUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(firestoreUserNotifierProvider);
  return user.whenData((u) => u?.email).value;
});
