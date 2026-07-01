/// Product State Management with Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/firestore_product_service.dart';

// ============== LOCAL SCAN / SCRAPE STORAGE (IN-MEMORY CACHE) ==============

/// In-memory scraped products for session query fallback (bypass Firestore rules)
final localProductsProvider = StateProvider<List<Product>>((ref) => []);

/// In-memory scraped prices
final localPricesProvider = StateProvider<List<Price>>((ref) => []);

// ============== SERVICE PROVIDER ==============

/// Single instance of FirestoreProductService
final firestoreProductServiceProvider = Provider<FirestoreProductService>((ref) {
  return FirestoreProductService();
});

// ============== STREAM PROVIDERS (LIVE DATA) ==============

/// Stream of all products
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final service = ref.watch(firestoreProductServiceProvider);
  return service.getProductsStream();
});

/// Stream of all retailers
final retailersStreamProvider = StreamProvider<List<Retailer>>((ref) {
  final service = ref.watch(firestoreProductServiceProvider);
  return service.getRetailersStream();
});

/// Stream of all prices
final pricesStreamProvider = StreamProvider<List<Price>>((ref) {
  final service = ref.watch(firestoreProductServiceProvider);
  return service.getPricesStream();
});

/// Enhanced list of prices with joined product and retailer data
final enhancedPricesProvider = Provider<AsyncValue<List<Price>>>((ref) {
  final pricesAsync = ref.watch(pricesStreamProvider);
  final productsAsync = ref.watch(productsStreamProvider);
  final retailersAsync = ref.watch(retailersStreamProvider);

  return pricesAsync.when(
    data: (prices) => productsAsync.when(
      data: (products) => retailersAsync.when(
        data: (retailers) {
          final joined = prices.map((price) {
            final product = products.cast<Product?>().firstWhere(
                  (p) => p?.id == price.productId,
                  orElse: () => null,
                );
            final retailer = retailers.cast<Retailer?>().firstWhere(
                  (r) => r?.id == price.retailerId,
                  orElse: () => null,
                );
            return price.copyWith(product: product, retailer: retailer);
          }).toList();
          return AsyncValue.data(joined);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============== COMPUTED PROVIDERS ==============

/// Search products by query (computed from stream)
/// Deduplicated list of products by name (computed)
String _getProductMatchKey(String name) {
  // Normalize name: lowercase and strip out all non-alphanumeric characters (spaces, hyphens, parentheses, etc.)
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Deduplicated list of products by name (computed)
final groupedProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final localProducts = ref.watch(localProductsProvider);
  
  return productsAsync.whenData((products) {
    final allProducts = [...products, ...localProducts];
    final Map<String, Product> uniqueProducts = {};
    for (final product in allProducts) {
      final matchKey = _getProductMatchKey(product.name);
      if (!uniqueProducts.containsKey(matchKey)) {
        uniqueProducts[matchKey] = product;
      }
    }
    return uniqueProducts.values.toList();
  });
});

/// Search products by query (computed from deduplicated list)
final productSearchProvider = Provider.family<List<Product>, String>((ref, query) {
  final groupedProductsAsync = ref.watch(groupedProductsProvider);
  return groupedProductsAsync.when(
    data: (products) {
      if (query.isEmpty) return products;
      final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      return products.where((p) {
        final name = p.name.toLowerCase();
        final desc = p.description.toLowerCase();
        return queryWords.every((word) => name.contains(word) || desc.contains(word));
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Product by ID (computed)
final productByIdProvider = Provider.family<Product?, int>((ref, productId) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) => products.cast<Product?>().firstWhere(
      (p) => p?.id == productId, 
      orElse: () => null
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Prices for specific product (computed with joined data from all matching products by name)
final pricesForProductProvider = Provider.family<List<Price>, int>((ref, productId) {
  final enhancedPricesAsync = ref.watch(enhancedPricesProvider);
  final productsAsync = ref.watch(productsStreamProvider);
  final localPrices = ref.watch(localPricesProvider);
  final localProducts = ref.watch(localProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final allProducts = [...products, ...localProducts];
      final targetProduct = allProducts.cast<Product?>().firstWhere(
        (p) => p?.id == productId,
        orElse: () => null,
      );
      if (targetProduct == null) return [];
      
      final targetKey = _getProductMatchKey(targetProduct.name);
      final sameNameProductIds = allProducts
          .where((p) => _getProductMatchKey(p.name) == targetKey)
          .map((p) => p.id)
          .toSet();
          
      return enhancedPricesAsync.when(
        data: (livePrices) {
          final allPrices = [...livePrices, ...localPrices];
          final filteredLive = allPrices
              .where((price) => sameNameProductIds.contains(price.productId))
              .toList();
          return filteredLive..sort((a, b) => a.price.compareTo(b.price));
        },
        loading: () => [],
        error: (_, __) => [],
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Best price for specific product (computed)
final bestPriceForProductProvider = Provider.family<Price?, int>((ref, productId) {
  final prices = ref.watch(pricesForProductProvider(productId));
  if (prices.isEmpty) return null;
  return prices.reduce((a, b) => a.price < b.price ? a : b);
});

/// All categories (computed)
final categoriesProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) => products.map((p) => p.category).toSet().toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
