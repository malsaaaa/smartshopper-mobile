/// Product State Management with Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';
import 'package:smartshopper_mobile/services/firestore_product_service.dart';

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
final productSearchProvider = Provider.family<List<Product>, String>((ref, query) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) {
      if (query.isEmpty) return products;
      final lowercaseQuery = query.toLowerCase();
      return products.where((p) => 
        p.name.toLowerCase().contains(lowercaseQuery) || 
        p.description.toLowerCase().contains(lowercaseQuery)
      ).toList();
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

/// Prices for specific product (computed with joined data)
final pricesForProductProvider = Provider.family<List<Price>, int>((ref, productId) {
  final enhancedPricesAsync = ref.watch(enhancedPricesProvider);
  return enhancedPricesAsync.when(
    data: (livePrices) {
      final filteredLive = livePrices.where((p) => p.productId == productId).toList();
      
      // Merge with MockData to ensure variety for demo
      final mockPrices = MockData.getPricesForProduct(productId);
      
      final Map<int, Price> merged = {};
      
      // Add mock prices first as fallback
      for (final p in mockPrices) {
        if (p.retailerId != null) merged[p.retailerId!] = p;
      }
      
      // Overwrite with live prices if they exist for the same retailer
      for (final p in filteredLive) {
        if (p.retailerId != null) merged[p.retailerId!] = p;
      }
      
      return merged.values.toList()..sort((a, b) => a.price.compareTo(b.price));
    },
    loading: () => MockData.getPricesForProduct(productId),
    error: (_, __) => MockData.getPricesForProduct(productId),
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
