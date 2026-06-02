import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/providers/firestore_service_provider.dart';
import 'package:smartshopper_mobile/services/location_service.dart';
import 'package:smartshopper_mobile/providers/product_provider.dart';
import 'package:smartshopper_mobile/providers/location_provider.dart';

/// Manages the single cart (shopping list) per user.
/// Uses the Firestore "active" shopping list as the cart.
class CartNotifier extends StateNotifier<AsyncValue<ShoppingList?>> {
  final Ref _ref;
  String? _cartId;

  CartNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  List<ShoppingItem> get _items => state.valueOrNull?.items ?? [];

  // ── Load cart from Firestore ────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final service = _ref.read(firestoreShoppingListServiceProvider);
      // getActiveShoppingList already loads items & creates cart if missing
      final cart = await service.getActiveShoppingList();
      _cartId = cart?.documentId;
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  // ── Ensure cart exists (create if first use) ────────────────────────────

  Future<void> _ensureCart() async {
    if (_cartId != null && state.valueOrNull != null) return;
    await _load();
    if (_cartId == null) throw Exception('Could not create cart');
  }

  // ── Add to cart ─────────────────────────────────────────────────────────

  Future<void> addToCart(
    Product product, {
    Price? selectedPrice,
    int quantity = 1,
  }) async {
    await _ensureCart();
    if (_cartId == null) return;

    // Merge: same product + same retailer → just increase qty
    final existing = _items.cast<ShoppingItem?>().firstWhere(
      (item) =>
          item!.productId == product.id &&
          item.retailerId == selectedPrice?.retailerId,
      orElse: () => null,
    );
    if (existing != null) {
      await updateQuantity(existing.effectiveId, existing.quantity + quantity);
      return;
    }

    final service = _ref.read(firestoreShoppingListServiceProvider);
    final newItem = await service.addItem(
      _cartId!,
      productId: product.id,
      name: product.name,
      quantity: quantity,
      estimatedPrice: selectedPrice?.price ?? 0.0,
      retailerId: selectedPrice?.retailerId,
      retailerName: selectedPrice?.retailer?.name,
      retailerLogoUrl: selectedPrice?.retailer?.logoUrl,
      imageUrl: product.imageUrl,
    );

    // Optimistic splice into state
    state.whenData((cart) {
      if (cart == null) return;
      state = AsyncValue.data(cart.copyWith(items: [...cart.items, newItem]));
    });
  }

  // ── Remove from cart ────────────────────────────────────────────────────

  Future<void> removeFromCart(String itemId) async {
    final cart = state.valueOrNull;
    if (cart == null || _cartId == null) return;

    final previous = cart;
    state = AsyncValue.data(
      cart.copyWith(
        items: cart.items.where((i) => i.effectiveId != itemId).toList(),
      ),
    );
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.deleteItem(_cartId!, itemId);
    } catch (_) {
      state = AsyncValue.data(previous); // rollback
    }
  }

  // ── Update quantity ─────────────────────────────────────────────────────

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_cartId == null) return;
    if (quantity <= 0) {
      await removeFromCart(itemId);
      return;
    }

    state.whenData((cart) {
      if (cart == null) return;
      state = AsyncValue.data(
        cart.copyWith(
          items: cart.items
              .map((i) =>
                  i.effectiveId == itemId ? i.copyWith(quantity: quantity) : i)
              .toList(),
        ),
      );
    });
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.updateItem(_cartId!, itemId, quantity: quantity);
    } catch (_) {
      await _load();
    }
  }

  // ── Toggle selected (checkbox) ──────────────────────────────────────────

  Future<void> toggleSelected(String itemId) async {
    if (_cartId == null) return;
    final cart = state.valueOrNull;
    if (cart == null) return;

    final item = cart.items.firstWhere((i) => i.effectiveId == itemId);
    final newVal = !item.isPurchased;

    state = AsyncValue.data(
      cart.copyWith(
        items: cart.items
            .map((i) =>
                i.effectiveId == itemId ? i.copyWith(isPurchased: newVal) : i)
            .toList(),
      ),
    );
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      await service.updateItem(_cartId!, itemId, isPurchased: newVal);
    } catch (_) {
      await _load();
    }
  }

  // ── Select / deselect all ───────────────────────────────────────────────

  Future<void> setAllSelected(bool selected) async {
    if (_cartId == null) return;
    final cart = state.valueOrNull;
    if (cart == null) return;

    state = AsyncValue.data(
      cart.copyWith(
        items: cart.items.map((i) => i.copyWith(isPurchased: selected)).toList(),
      ),
    );
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      for (final item in cart.items) {
        await service.updateItem(_cartId!, item.effectiveId,
            isPurchased: selected);
      }
    } catch (_) {
      await _load();
    }
  }

  // ── Clear cart ──────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    final cart = state.valueOrNull;
    if (cart == null || _cartId == null || cart.items.isEmpty) return;

    final toDelete = List<ShoppingItem>.from(cart.items);
    state = AsyncValue.data(cart.copyWith(items: []));
    try {
      final service = _ref.read(firestoreShoppingListServiceProvider);
      for (final item in toDelete) {
        await service.deleteItem(_cartId!, item.effectiveId);
      }
    } catch (_) {
      await _load();
    }
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<ShoppingList?>>((ref) {
  ref.watch(isUserLoggedInProvider); // re-init on login/logout
  return CartNotifier(ref);
});

/// Total number of distinct items (qty-summed) in the cart.
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null) return 0;
  return cart.items.fold(0, (sum, i) => sum + i.quantity);
});

/// Total price of ALL items.
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null) return 0.0;
  return cart.items
      .fold(0.0, (sum, i) => sum + i.estimatedPrice * i.quantity);
});

/// Total price of SELECTED items only.
final cartSelectedTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null) return 0.0;
  return cart.items
      .where((i) => i.isPurchased)
      .fold(0.0, (sum, i) => sum + i.estimatedPrice * i.quantity);
});

/// Count of selected items.
final cartSelectedCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null) return 0;
  return cart.items.where((i) => i.isPurchased).fold(0, (s, i) => s + i.quantity);
});

/// Breakdown of cart total by category.
final cartCategoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null) return {};

  final breakdown = <String, double>{};
  for (final item in cart.items) {
    // Look up product to get product type (Actual Category)
    final product = MockData.getProductById(item.productId ?? 0);
    final category = product?.productType ?? 'Other';
    final itemTotal = item.estimatedPrice * item.quantity;
    breakdown[category] = (breakdown[category] ?? 0.0) + itemTotal;
  }
  return breakdown;
});

/// Total estimated fuel cost to visit all retailers in the cart.
final cartTravelCostProvider = Provider<double>((ref) {
  final cart = ref.watch(cartNotifierProvider).valueOrNull;
  if (cart == null || cart.items.isEmpty) return 0.0;

  // Watch the user's live position
  final userPos = ref.watch(userLocationProvider);

  final retailersAsync = ref.watch(retailersStreamProvider);
  return retailersAsync.when(
    data: (retailers) {
      // Get unique retailer IDs from items in cart
      final retailerIds = cart.items
          .map((i) => i.retailerId)
          .where((id) => id != null)
          .toSet();

      double totalFuelCost = 0.0;

      for (final id in retailerIds) {
        final retailer = retailers.cast<Retailer?>().firstWhere(
              (r) => r?.id == id,
              orElse: () => null,
            );
        
        if (retailer != null) {
          final distance = LocationService.calculateDistanceTo(retailer, currentPos: userPos);
          if (distance != null) {
            totalFuelCost += LocationService.calculateGasCost(distance);
          }
        }
      }
      return totalFuelCost;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
