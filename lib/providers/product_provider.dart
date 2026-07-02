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
  final localPrices = ref.watch(localPricesProvider);
  final localProducts = ref.watch(localProductsProvider);

  return pricesAsync.when(
    data: (prices) => productsAsync.when(
      data: (products) => retailersAsync.when(
        data: (retailers) {
          // Combine firestore and in-memory scraped prices / products
          final allPrices = [...prices, ...localPrices];
          final allProducts = [...products, ...localProducts];

          final joined = allPrices.map((price) {
            final product = allProducts.cast<Product?>().firstWhere(
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

/// Helper function to create a tokenized match key for deduplication and grouping
String _getProductMatchKey(String name) {
  final lower = name.toLowerCase();

  // Helper to extract numeric size/weight (e.g. 1kg, 200ml, 5-pack, 18s) and pack sizes (e.g. 200mlx6)
  String _extractSize(String text) {
    // 1. Check for pack multiplier format: e.g. "200mlx6", "200ml x 6", "6x200ml", "6 x 200ml"
    final packRx1 = RegExp(r'\b([0-9.]+)\s*(kg|g|l|ml)\s*[x*]\s*([0-9]+)\b', caseSensitive: false);
    final match1 = packRx1.firstMatch(text);
    if (match1 != null) {
      return '${match1.group(1)}${match1.group(2)}x${match1.group(3)}'.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    }
    
    final packRx2 = RegExp(r'\b([0-9]+)\s*[x*]\s*([0-9.]+)\s*(kg|g|l|ml)\b', caseSensitive: false);
    final match2 = packRx2.firstMatch(text);
    if (match2 != null) {
      return '${match2.group(2)}${match2.group(3)}x${match2.group(1)}'.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    }

    // 2. Standard single size format
    final rx = RegExp(r'\b([0-9.]+)\s*(kg|g|l|ml|s|pack|pcs|tgs)\b', caseSensitive: false);
    final match = rx.firstMatch(text);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}'.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    }
    return '';
  }

  // 1. Milo
  if (lower.contains('milo')) {
    final size = _extractSize(lower);
    String variant = 'powder';
    if (lower.contains('3in1') || lower.contains('3 in 1')) {
      variant = '3in1';
    } else if (lower.contains('uht') || lower.contains('rtd') || lower.contains('ready') || lower.contains('carton') || lower.contains('box') || lower.contains('drink')) {
      variant = 'uht';
    } else if (lower.contains('can')) {
      variant = 'can';
    } else if (lower.contains('nugget')) {
      variant = 'nuggets';
    } else if (lower.contains('cereal') || lower.contains('bar')) {
      variant = 'cereal';
    } else if (lower.contains('biscuit')) {
      variant = 'biscuit';
    }
    return 'milo_${variant}_$size';
  }

  // 2. Cooking Oils (Buruh, Knife, Red Eagle, Vesawit, Alif)
  for (final brand in ['buruh', 'knife', 'red eagle', 'vesawit', 'alif']) {
    if (lower.contains(brand)) {
      final size = _extractSize(lower);
      return '${brand.replaceAll(" ", "")}_oil_$size';
    }
  }

  // 3. Maggi
  if (lower.contains('maggi')) {
    final size = _extractSize(lower);
    String flavour = 'curry';
    if (lower.contains('asam laksa') || lower.contains('laksa')) {
      flavour = 'laksa';
    } else if (lower.contains('chicken') || lower.contains('ayam')) {
      flavour = 'chicken';
    } else if (lower.contains('tomyam') || lower.contains('tom yam')) {
      flavour = 'tomyam';
    }
    return 'maggi_${flavour}_$size';
  }

  // 4. Boh Tea
  if (lower.contains('boh')) {
    final size = _extractSize(lower);
    return 'boh_tea_$size';
  }

  // 5. Rice (Jati, Sunflower, Seri Murni)
  for (final brand in ['jati', 'sunflower', 'seri murni']) {
    if (lower.contains(brand)) {
      final size = _extractSize(lower);
      return '${brand.replaceAll(" ", "")}_rice_$size';
    }
  }

  // Fallback: lowercase and strip punctuation/spaces
  return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
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
  final localProducts = ref.watch(localProductsProvider);
  
  return productsAsync.when(
    data: (products) {
      final allProducts = [...products, ...localProducts];
      return allProducts.cast<Product?>().firstWhere(
        (p) => p?.id == productId, 
        orElse: () => null
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Prices for specific product (computed with joined data from all matching products by name)
final pricesForProductProvider = Provider.family<List<Price>, int>((ref, productId) {
  final enhancedPricesAsync = ref.watch(enhancedPricesProvider);
  final productsAsync = ref.watch(productsStreamProvider);
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
        data: (enhancedPrices) {
          final filtered = enhancedPrices
              .where((price) => sameNameProductIds.contains(price.productId))
              .toList();
          
          // Deduplicate by retailerId, keeping only the newest scrape timestamp
          final Map<int, Price> uniquePrices = {};
          for (final price in filtered) {
            final existing = uniquePrices[price.retailerId];
            if (existing == null) {
              uniquePrices[price.retailerId] = price;
            } else {
              final existingTime = existing.scrapedAt ?? existing.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final newTime = price.scrapedAt ?? price.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              if (newTime.isAfter(existingTime)) {
                uniquePrices[price.retailerId] = price;
              }
            }
          }
          
          final result = uniquePrices.values.toList();
          return result..sort((a, b) => a.price.compareTo(b.price));
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
