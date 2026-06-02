import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/providers/firestore_service_provider.dart';

/// Get all shopping lists from Firestore for current user
final firestoreAllShoppingListsProvider =
    FutureProvider<List<ShoppingList>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  
  // If no user is logged in, return empty list
  if (userId == null) {
    return [];
  }

  final service = ref.watch(firestoreShoppingListServiceProvider);
  try {
    return await service.getAllLists();
  } catch (e) {
    throw Exception('Failed to fetch shopping lists: $e');
  }
});

/// Shopping list notifier for CRUD operations
class FirestoreShoppingListsNotifier
    extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  final Ref _ref;

  FirestoreShoppingListsNotifier(this._ref)
      : super(const AsyncValue.loading());

  // ─── Helpers ────────────────────────────────────────────────────────────

  List<ShoppingList> get _current => state.valueOrNull ?? [];

  /// Load all lists from Firestore.
  /// Keeps the previous data visible while reloading (no blank flash).
  Future<void> loadLists() async {
    // Don't blank the UI — keep previous data while refreshing
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final service = _ref.read(firestoreShoppingListServiceProvider);
      final lists = await service.getAllLists();
      state = AsyncValue.data(lists);
    } catch (e, st) {
      // Preserve existing data alongside the error so the UI can show
      // a Retry without wiping the list.
      state = AsyncValue.error(e, st);
    }
  }

  // ─── Create ─────────────────────────────────────────────────────────────

  /// Create new shopping list — optimistically adds to state, then syncs.
  Future<ShoppingList> createList({
    required String name,
    String? description,
    double? budget,
  }) async {
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      final newList = await service.createList(
        name: name,
        description: description,
        budget: budget,
      );

      // Optimistic: append immediately so the sheet can pick it up
      state = AsyncValue.data([..._current, newList]);

      return newList;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Update list ─────────────────────────────────────────────────────────

  Future<void> updateList(
    String listId, {
    String? name,
    String? description,
    double? budget,
  }) async {
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.updateList(
        listId,
        name: name,
        description: description,
        budget: budget,
      );

      // Optimistic: update matching list in state
      state = AsyncValue.data(
        _current.map((list) {
          final id = list.effectiveId;
          if (id != listId) return list;
          return list.copyWith(
            name: name ?? list.name,
            description: description ?? list.description,
            budget: budget ?? list.budget,
          );
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Delete list ─────────────────────────────────────────────────────────

  /// Delete shopping list — optimistically removes from state.
  Future<void> deleteList(String listId) async {
    // Snapshot current state in case we need to roll back
    final previous = _current;

    // Optimistic remove
    state = AsyncValue.data(
      _current.where((list) {
        final id = list.effectiveId;
        return id != listId;
      }).toList(),
    );

    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.deleteList(listId);
    } catch (e, st) {
      // Roll back on failure
      state = AsyncValue.data(previous);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Add item ────────────────────────────────────────────────────────────

  /// Add item to a shopping list — optimistically updates state immediately,
  /// no Firestore round-trip reload needed.
  Future<void> addItem(
    String listId, {
    required int productId,
    required String name,
    required int quantity,
    required double estimatedPrice,
    int? retailerId,
    String? retailerName,
  }) async {
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      final newItem = await service.addItem(
        listId,
        productId: productId,
        name: name,
        quantity: quantity,
        estimatedPrice: estimatedPrice,
        retailerId: retailerId,
        retailerName: retailerName,
      );

      // Optimistic: splice the new item into the matching list in state —
      // no loadLists() call, so the UI never blanks.
      state = AsyncValue.data(
        _current.map((list) {
          final id = list.effectiveId;
          if (id != listId) return list;
          return list.copyWith(items: [...list.items, newItem]);
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Delete item ─────────────────────────────────────────────────────────

  /// Delete item — optimistically removes from state.
  Future<void> deleteItem(String listId, String itemId) async {
    final previous = _current;

    // Optimistic remove
    state = AsyncValue.data(
      _current.map((list) {
        final id = list.effectiveId;
        if (id != listId) return list;
        return list.copyWith(
          items: list.items
              .where((item) =>
                  (item.documentId ?? item.id.toString()) != itemId)
              .toList(),
        );
      }).toList(),
    );

    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.deleteItem(listId, itemId);
    } catch (e, st) {
      // Roll back on failure
      state = AsyncValue.data(previous);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ─── Update item ─────────────────────────────────────────────────────────

  /// Update item — optimistically patches the item in state.
  Future<void> updateItem(
    String listId,
    String itemId, {
    int? quantity,
    bool? isPurchased,
    double? estimatedPrice,
  }) async {
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.updateItem(
        listId,
        itemId,
        quantity: quantity,
        isPurchased: isPurchased,
        estimatedPrice: estimatedPrice,
      );

      // Optimistic patch
      state = AsyncValue.data(
        _current.map((list) {
          final id = list.effectiveId;
          if (id != listId) return list;
          return list.copyWith(
            items: list.items.map((item) {
              final iid = item.documentId ?? item.id.toString();
              if (iid != itemId) return item;
              return item.copyWith(
                quantity: quantity ?? item.quantity,
                isPurchased: isPurchased ?? item.isPurchased,
                estimatedPrice: estimatedPrice ?? item.estimatedPrice,
              );
            }).toList(),
          );
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Shopping lists state notifier provider
final firestoreShoppingListsNotifierProvider = StateNotifierProvider<
    FirestoreShoppingListsNotifier,
    AsyncValue<List<ShoppingList>>>((ref) {
  final notifier = FirestoreShoppingListsNotifier(ref);
  // Automatically load lists when provider is initialized
  notifier.loadLists();
  return notifier;
});

/// Convenience provider to watch shopping lists
final firestoreShoppingListsWatch = Provider<AsyncValue<List<ShoppingList>>>((ref) {
  return ref.watch(firestoreShoppingListsNotifierProvider);
});

/// Get specific shopping list by ID
final firestoreShoppingListByIdProvider =
    FutureProvider.family<ShoppingList?, String>((ref, listId) async {
  final lists = await ref.watch(firestoreAllShoppingListsProvider.future);
  return lists.cast<ShoppingList?>().firstWhere(
        (list) => list?.id.toString() == listId,
        orElse: () => null,
      );
});
