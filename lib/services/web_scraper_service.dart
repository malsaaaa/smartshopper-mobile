import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/scrapers/base_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/mydin_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/myaeon2go_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/lotus_scraper.dart';

/// Web scraper service that manages all retailer scrapers
/// Coordinates scraping across multiple retailers and stores data in Firestore
class WebScraperService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Scrapers for each retailer.
  // Keys are the *normalized* retailer name (lowercase, alphanumeric only).
  // e.g. "Lotus's" → "lotuss", "myAEON2go" → "myaeon2go"
  late final Map<String, BaseScraper> _scrapers = {
    'mydin': MyDinScraper(),
    'myaeon2go': MyAeon2GoScraper(),
    'lotuss': LotusScraper(),
  };

  /// Get all available scrapers
  Map<String, BaseScraper> getScrapers() => _scrapers;

  /// Get scraper by retailer name.
  /// The name is normalized (lowercase, non-alphanumeric stripped) before lookup
  /// so display names like "Lotus's" and "myAEON2go" map correctly.
  BaseScraper? getScraper(String retailerName) {
    return _scrapers[_normalizeKey(retailerName)];
  }

  /// Normalize a retailer display name to a map key:
  /// lowercase + strip any character that is not a-z or 0-9.
  String _normalizeKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Scrape all retailers and store results in Firestore
  /// Returns count of scraped and stored products
  Future<Map<String, int>> scrapeAllRetailers({
    bool storeInFirestore = true,
    int? pageNumber,
    String? category,
  }) async {
    final results = <String, int>{};

    print('🔍 Starting scrape of all retailers...');

    for (final entry in _scrapers.entries) {
      final retailerName = entry.key;
      final scraper = entry.value;

      try {
        final count = await _scrapeRetailer(
          retailerName,
          scraper,
          storeInFirestore: storeInFirestore,
          pageNumber: pageNumber,
          category: category,
        );
        results[retailerName] = count;
      } catch (e) {
        print('❌ Error scraping $retailerName: $e');
        results[retailerName] = 0;
      }
    }

    print('✅ Scraping complete: $results');
    return results;
  }

  /// Scrape a single retailer
  Future<int> scrapeRetailer(
    String retailerName, {
    bool storeInFirestore = true,
    int? pageNumber,
    String? category,
  }) async {
    final scraper = _scrapers[_normalizeKey(retailerName)];
    if (scraper == null) {
      print('❌ Scraper not found for: $retailerName (normalized: "${_normalizeKey(retailerName)}", available: ${_scrapers.keys.toList()})');
      return 0;
    }

    return await _scrapeRetailer(
      retailerName,
      scraper,
      storeInFirestore: storeInFirestore,
      pageNumber: pageNumber,
      category: category,
    );
  }

  Future<void> _log(String level, String retailer, String message) async {
    try {
      await _db.collection('scraper_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'level': level,
        'retailer': retailer,
        'message': message,
      });
    } catch (e) {
      print('Error writing scraper log: $e');
    }
  }

  /// Internal scrape logic for a single retailer
  Future<int> _scrapeRetailer(
    String retailerName,
    BaseScraper scraper, {
    required bool storeInFirestore,
    int? pageNumber,
    String? category,
  }) async {
    print('🔄 Scraping $retailerName...');
    
    // Normalize casing for logs/display
    final displayRetailer = scraper.getRetailerInfo().name;

    try {
      // Get retailer info
      final retailerInfo = scraper.getRetailerInfo();
      
      await _log('INFO', displayRetailer, 'Scraping job started — target: ${retailerInfo.website}');
      await _log('INFO', displayRetailer, 'Sending HTTP request to retailer website…');

      if (storeInFirestore) {
        await _storeRetailer(retailerInfo);
      }

      await _log('INFO', displayRetailer, 'Connected. Parsing document structure and extracting product listings…');

      // Scrape products
      final products = await scraper.scrapeProducts(
        pageNumber: pageNumber,
        category: category,
      );

      if (products.isEmpty) {
        print('⚠️ No products found for $retailerName');
        await _log('WARN', displayRetailer, 'Connected, but no products were found. Scraping completed with 0 items.');
        return 0;
      }

      await _log('INFO', displayRetailer, 'Scraped ${products.length} product prices. Writing updated prices to Firestore…');

      // Store products and prices
      if (storeInFirestore) {
        await _storeProducts(products);
      }

      await _log('SUCCESS', displayRetailer, 'Scraping job completed. ${products.length} prices updated in database.');
      return products.length;
    } catch (e) {
      print('❌ Error scraping $displayRetailer: $e');
      await _log('ERROR', displayRetailer, 'Scraping job failed with error: $e');
      return 0;
    }
  }

  /// Store or update retailer info in Firestore
  Future<void> _storeRetailer(Retailer retailer) async {
    try {
      await _db.collection('retailers').doc(retailer.id.toString()).set({
        'id': retailer.id,
        'name': retailer.name,
        'logoUrl': retailer.logoUrl,
        'website': retailer.website,
        'latitude': retailer.latitude,
        'longitude': retailer.longitude,
        'createdAt': retailer.createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Stored retailer: ${retailer.name}');
    } catch (e) {
      print('❌ Error storing retailer ${retailer.name}: $e');
    }
  }

  /// Store products and their prices in Firestore.
  ///
  /// Firestore batches are limited to 500 writes. Since each product needs
  /// 2 writes (product doc + price doc), we chunk at 200 pairs per batch.
  Future<void> _storeProducts(List<(Product, Price)> products) async {
    const int chunkSize = 200; // 200 pairs × 2 writes = 400 writes per batch
    int totalStored = 0;

    for (int start = 0; start < products.length; start += chunkSize) {
      final end =
          (start + chunkSize < products.length) ? start + chunkSize : products.length;
      final chunk = products.sublist(start, end);

      try {
        final batch = _db.batch();

        for (final (product, price) in chunk) {
          // Use a stable document ID so re-runs update rather than duplicate.
          // Format: <retailerId>_<normalized-name-hash>
          final stableProductId = '${price.retailerId}_${_stableKey(product.name)}';

          final productDoc = _db.collection('products').doc(stableProductId);
          batch.set(
            productDoc,
            {
              'id': stableProductId,
              'name': product.name,
              'description': product.description,
              'category': product.category,
              'productType': product.productType,
              'imageUrl': product.imageUrl,
              'createdAt': product.createdAt,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Price doc ID: retailerId_stableProductId
          final priceId = '${price.retailerId}_$stableProductId';
          final priceDoc = _db.collection('prices').doc(priceId);
          batch.set(
            priceDoc,
            {
              'id': priceId,
              'productId': stableProductId,
              'retailerId': price.retailerId.toString(),
              'price': price.price,
              'productUrl': price.productUrl,
              'scrapedAt': price.scrapedAt,
              'createdAt': price.createdAt,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();
        totalStored += chunk.length;
        print('✅ Stored chunk ${start ~/ chunkSize + 1}: ${chunk.length} products (total: $totalStored)');
      } catch (e) {
        print('❌ Error storing products chunk [$start-$end]: $e');
      }
    }

    print('✅ Stored $totalStored / ${products.length} products in total');
  }

  /// Create a short, stable key from a product name for use as a Firestore
  /// document ID. Strips non-alphanumeric characters and lowercases.
  String _stableKey(String name) {
    // Keep alphanumerics + spaces, collapse whitespace, lowercase, replace spaces
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    // Truncate to 80 chars to stay well within Firestore ID limits
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  /// Get products from a specific retailer
  Future<List<Product>> getProductsByRetailer(String retailerName) async {
    try {
      // Get retailer ID from scraper
      final scraper = _scrapers[retailerName.toLowerCase()];
      if (scraper == null) return [];

      final retailerInfo = scraper.getRetailerInfo();

      // Get prices for this retailer
      final pricesSnapshot = await _db
          .collection('prices')
          .where('retailerId', isEqualTo: retailerInfo.id.toString())
          .get();

      if (pricesSnapshot.docs.isEmpty) return [];

      // Get unique product IDs and fetch products
      final productIds = <String>{};
      for (final doc in pricesSnapshot.docs) {
        final productId = doc['productId']?.toString();
        if (productId != null) {
          productIds.add(productId);
        }
      }

      final products = <Product>[];
      for (final productId in productIds) {
        final productDoc = await _db.collection('products').doc(productId).get();
        if (productDoc.exists) {
          products.add(Product.fromFirestore(productDoc.data()!, productDoc.id));
        }
      }

      return products;
    } catch (e) {
      print('❌ Error getting products for $retailerName: $e');
      return [];
    }
  }

  /// Get scraping statistics
  Future<Map<String, dynamic>> getScrapingStats() async {
    try {
      final retailersSnapshot = await _db.collection('retailers').get();
      final productsSnapshot = await _db.collection('products').get();
      final pricesSnapshot = await _db.collection('prices').get();

      return {
        'retailers': retailersSnapshot.size,
        'products': productsSnapshot.size,
        'prices': pricesSnapshot.size,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting scraping stats: $e');
      return {};
    }
  }

  /// Clear all scraped data from Firestore (for testing)
  Future<void> clearScrapedData() async {
    try {
      print('⚠️ Clearing all scraped data...');
      
      final batch = _db.batch();
      
      // Delete all products
      final products = await _db.collection('products').get();
      for (final doc in products.docs) {
        batch.delete(doc.reference);
      }

      // Delete all prices
      final prices = await _db.collection('prices').get();
      for (final doc in prices.docs) {
        batch.delete(doc.reference);
      }

      // Delete all retailers
      final retailers = await _db.collection('retailers').get();
      for (final doc in retailers.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All scraped data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}
