import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/scrapers/base_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/mydin_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/myaeon2go_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/lotus_scraper.dart';

/// Web scraper service that manages all retailer scrapers
/// Coordinates scraping across multiple retailers and stores data in Firestore
class WebScraperService {
  // Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Registry of active scrapers by normalized key
  late final Map<String, BaseScraper> _scrapers = {
    'mydin': MyDinScraper(),
    'myaeon2go': MyAeon2GoScraper(),
    'lotuss': LotusScraper(),
  };

  /// Get list of scrapers
  Map<String, BaseScraper> getScrapers() => _scrapers;

  /// Get scraper by name (normalizes input key)
  BaseScraper? getScraper(String retailerName) {
    return _scrapers[_normalizeKey(retailerName)];
  }

  /// Convert retailer name to standard map key (lowercase, alphanumeric only)
  String _normalizeKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Scrape all registered retailers
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

  /// Trigger scrape for a single retailer
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

  /// Log job progress/state to Firestore
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

  /// Internal job run logic for a single retailer
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

      // Store products and prices in database
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

  /// Save retailer info to database
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

  /// Save products and prices using Firestore batch writes
  Future<void> _storeProducts(List<(Product, Price)> products) async {
    // Batch operations chunk size (max 500 writes limit, using 200 pairs = 400 writes)
    const int chunkSize = 200;
    int totalStored = 0;

    for (int start = 0; start < products.length; start += chunkSize) {
      final end =
          (start + chunkSize < products.length) ? start + chunkSize : products.length;
      final chunk = products.sublist(start, end);

      try {
        final batch = _db.batch();

        for (final (product, price) in chunk) {
          // Generate a unique, stable doc ID for product
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

          // Save associated price entry
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

  /// Generate clean product key from name
  String _stableKey(String name) {
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  /// Fetch product list for specific retailer
  Future<List<Product>> getProductsByRetailer(String retailerName) async {
    try {
      final scraper = _scrapers[retailerName.toLowerCase()];
      if (scraper == null) return [];

      final retailerInfo = scraper.getRetailerInfo();

      // Query price records by retailer ID
      final pricesSnapshot = await _db
          .collection('prices')
          .where('retailerId', isEqualTo: retailerInfo.id.toString())
          .get();

      if (pricesSnapshot.docs.isEmpty) return [];

      // Collect product document references
      final productIds = <String>{};
      for (final doc in pricesSnapshot.docs) {
        final productId = doc['productId']?.toString();
        if (productId != null) {
          productIds.add(productId);
        }
      }

      // Fetch product models from database
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

  /// Retrieve database metrics (counts)
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

  /// Purge all scraped collections from Firestore
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
