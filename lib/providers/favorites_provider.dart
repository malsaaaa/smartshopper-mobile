import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_auth_provider.dart';

/// Favorites notifier storing a list of favorite product IDs for the current user.
class FavoritesNotifier extends StateNotifier<List<int>> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FavoritesNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      final snapshot = await _firestore.collection('users').doc(uid).collection('favorites').get();
      final ids = snapshot.docs.map((d) => int.tryParse(d.id) ?? 0).where((i) => i > 0).toList();
      state = ids;
    } catch (_) {
      // ignore errors and keep empty state
    }
  }

  Future<void> toggleFavorite(int productId) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == null) return;

    final exists = state.contains(productId);
    if (exists) {
      state = state.where((i) => i != productId).toList();
      try {
        await _firestore.collection('users').doc(uid).collection('favorites').doc(productId.toString()).delete();
      } catch (_) {}
    } else {
      state = [productId, ...state];
      try {
        await _firestore.collection('users').doc(uid).collection('favorites').doc(productId.toString()).set({
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  bool isFavorite(int productId) => state.contains(productId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<int>>((ref) {
  return FavoritesNotifier(ref);
});
