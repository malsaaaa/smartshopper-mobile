/// Product State Management with Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/firestore_product_service.dart';
import 'package:smartshopper_mobile/utils/product_utils.dart';

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

/// Helper function to create a precise, collision-resistant match key for
/// deduplication and cross-retailer grouping.
///
/// Key design rules:
///   - Brand + product type + **exact** size must all match for grouping.
///   - Size is extracted with a strict word-boundary regex (avoids "1" matching "18").
///   - Milo sub-variants (soft pack, fuze, 3-in-1, UHT, etc.) are distinguished.
///   - Falls back to full-name normalization (no size stripping) so unrecognized
///     products with different names are never merged.
String _getProductMatchKey(String name) {
  final lower = name.toLowerCase().trim();

  // ── Size extraction (strict – no false positives) ────────────────────────
  // Returns a canonical size token like "1kg", "200ml", "5pack", "18s".
  String extractSize(String text) {
    // Pack multiplier formats: "6x200ml", "200ml x 6", "6 x 200ml"
    final packRx1 = RegExp(
        r'\b([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\s*[x×*]\s*([0-9]+)\b',
        caseSensitive: false);
    final m1 = packRx1.firstMatch(text);
    if (m1 != null) {
      return '${m1.group(1)}${m1.group(2)!.toLowerCase()}x${m1.group(3)}';
    }
    final packRx2 = RegExp(
        r'\b([0-9]+)\s*[x×*]\s*([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\b',
        caseSensitive: false);
    final m2 = packRx2.firstMatch(text);
    if (m2 != null) {
      return '${m2.group(2)}${m2.group(3)!.toLowerCase()}x${m2.group(1)}';
    }

    // Count/serving formats: "18s", "30s", "100s", "25pcs", "5pack"
    final countRx =
        RegExp(r'\b([0-9]+)\s*(s|pcs|pack|sachets?|teabags?)\b', caseSensitive: false);
    final mc = countRx.firstMatch(text);
    if (mc != null) {
      return '${mc.group(1)}${mc.group(2)!.toLowerCase().replaceAll(RegExp(r's$'), 's')}';
    }

    // Standard weight/volume: strictly word-boundary anchored
    final singleRx =
        RegExp(r'\b([0-9]+(?:\.[0-9]+)?)\s*(kg|g|l|ml)\b', caseSensitive: false);
    final ms = singleRx.firstMatch(text);
    if (ms != null) {
      return '${ms.group(1)}${ms.group(2)!.toLowerCase()}';
    }

    return '';
  }

  // ── 1. Milo ───────────────────────────────────────────────────────────────
  if (lower.contains('milo')) {
    final size = extractSize(lower);

    // Determine sub-variant with strict precedence
    String variant;
    if (lower.contains('3in1') || lower.contains('3 in 1') ||
        lower.contains('three in one')) {
      variant = '3in1';
    } else if (lower.contains('fuze') || lower.contains('fuse')) {
      variant = 'fuze';
    } else if (lower.contains('nugget')) {
      variant = 'nuggets';
    } else if (lower.contains('cereal bar') || lower.contains('cereal_bar')) {
      variant = 'cerealbar';
    } else if (lower.contains('cereal')) {
      variant = 'cereal';
    } else if (lower.contains('biscuit')) {
      variant = 'biscuit';
    } else if (lower.contains('chocobar') || lower.contains('choco bar')) {
      variant = 'chocobar';
    } else if (lower.contains('ice cream') || lower.contains('ice_cream') ||
        lower.contains('kaw')) {
      variant = 'icecream';
    } else if (lower.contains('uht') ||
        lower.contains('rtd') ||
        lower.contains('ready to drink') ||
        lower.contains('drink') && !lower.contains('powder')) {
      variant = 'uht';
    } else if (lower.contains('soft pack') || lower.contains('softpack') ||
        lower.contains('refill')) {
      // Soft-pack / refill pouches are a distinct SKU (not regular powder tin)
      variant = 'softpack';
    } else {
      // Default: regular powder (tins / cans)
      variant = 'powder';
    }
    return 'milo_${variant}_$size';
  }

  // ── 2. Cooking Oils (branded) ─────────────────────────────────────────────
  final oilBrands = [
    'buruh', 'knife', 'red eagle', 'vesawit', 'alif',
    'naturel', 'saji', 'tropical', 'rasaku', 'topvalu',
  ];
  for (final brand in oilBrands) {
    if (lower.contains(brand) && lower.contains('oil')) {
      final size = extractSize(lower);
      final brandKey = brand.replaceAll(' ', '');
      return '${brandKey}_oil_$size';
    }
  }
  // Generic cooking oil (no recognised brand)
  if (lower.contains('cooking oil')) {
    final size = extractSize(lower);
    return 'cookingoil_$size';
  }

  // ── 3. Maggi ──────────────────────────────────────────────────────────────
  if (lower.contains('maggi')) {
    final size = extractSize(lower);
    String flavour;
    if (lower.contains('asam laksa') || lower.contains('laksa')) {
      flavour = 'laksa';
    } else if (lower.contains('tomyam') || lower.contains('tom yam')) {
      flavour = 'tomyam';
    } else if (lower.contains('chicken') || lower.contains('ayam')) {
      flavour = 'chicken';
    } else if (lower.contains('kari') || lower.contains('curry')) {
      flavour = 'curry';
    } else if (lower.contains('anchovies') || lower.contains('ikan bilis')) {
      flavour = 'anchovies';
    } else if (lower.contains('sambal')) {
      flavour = 'sambal';
    } else if (lower.contains('cube') || lower.contains('stock')) {
      flavour = 'stock';
    } else {
      flavour = 'other';
    }
    return 'maggi_${flavour}_$size';
  }

  // ── 4. Boh Tea ────────────────────────────────────────────────────────────
  if (lower.contains('boh')) {
    final size = extractSize(lower);
    String type = 'regular';
    if (lower.contains('green')) type = 'green';
    else if (lower.contains('earl grey')) type = 'earlgrey';
    else if (lower.contains('chamomile')) type = 'chamomile';
    return 'boh_${type}_$size';
  }

  // ── 5. Rice (branded) ─────────────────────────────────────────────────────
  final riceBrands = ['jati', 'sunflower', 'seri murni', 'faiza', 'royal gold'];
  for (final brand in riceBrands) {
    if (lower.contains(brand) && lower.contains('rice')) {
      final size = extractSize(lower);
      return '${brand.replaceAll(' ', '')}_rice_$size';
    }
  }

  // ── 6. Aik Cheong / Nescafé / generic coffee-tea ─────────────────────────
  if (lower.contains('aik cheong') || lower.contains('aik_cheong')) {
    final size = extractSize(lower);
    return 'aikcheong_${size}';
  }
  if (lower.contains('nescafe') || lower.contains('nescafé')) {
    final size = extractSize(lower);
    return 'nescafe_${size}';
  }

  // ── Fallback: preserve full normalized name (size included) ───────────────
  // Strip punctuation but keep spaces so different-size products stay separate.
  final normalized = lower
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
  return normalized;
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
