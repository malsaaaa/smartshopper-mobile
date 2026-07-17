import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/scrapers/base_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/mydin_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/myaeon2go_scraper.dart';
import 'package:smartshopper_mobile/services/scrapers/lotus_scraper.dart';
import 'package:smartshopper_mobile/utils/product_utils.dart';

/// Web scraper service that manages all retailer scrapers
/// Coordinates scraping across multiple retailers and stores data in Firestore
class WebScraperService {
  // Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory catalog cache to reduce Firestore reads
  static List<Product>? _cachedCatalog;
  
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

    print('🔍 Starting parallel scrape of all retailers...');

    final tasks = _scrapers.entries.map((entry) async {
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
        return MapEntry(retailerName, count);
      } catch (e) {
        print('❌ Error scraping $retailerName: $e');
        return MapEntry(retailerName, 0);
      }
    });

    final list = await Future.wait(tasks);
    results.addEntries(list);

    print('✅ Scraping complete: $results');
    return results;
  }

  /// Resolve in-memory scraped items against each other and the current catalog
  List<(Product, Price)> resolveInMemoryProducts(List<(Product, Price)> items, List<Product> existingProducts) {
    final List<(Product, Price)> resolved = [];
    final List<Product> tempProducts = List.from(existingProducts);

    for (final (product, price) in items) {
      // Resolve stable unified product ID (either reuse a match or build a global hash)
      final stableProductId = _resolveProductEntity(product.name, product.productType, tempProducts);

      // Create a unified product copy with the resolved ID
      final unifiedProduct = Product(
        id: stableProductId,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        category: product.category,
        productType: product.productType,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );

      // Cache it locally so subsequent items in this same search match it
      if (!tempProducts.any((p) => p.id == stableProductId)) {
        tempProducts.add(unifiedProduct);
      }

      // Create a price copy linked to the resolved product ID
      final unifiedPrice = Price(
        id: price.id,
        productId: stableProductId,
        retailerId: price.retailerId,
        price: price.price,
        productUrl: price.productUrl,
        scrapedAt: price.scrapedAt,
        createdAt: price.createdAt,
        updatedAt: price.updatedAt,
      );

      resolved.add((unifiedProduct, unifiedPrice));
    }

    return resolved;
  }

  /// Scrape all registered retailers concurrently in parallel (for in-memory cache)
  Future<List<(Product, Price)>> scrapeAllProducts({
    String? category,
  }) async {
    // 1. Fetch current catalog for live in-memory entity resolution
    List<Product> existingProducts = [];
    try {
      if (_cachedCatalog != null) {
        existingProducts = List.from(_cachedCatalog!);
      } else {
        final snapshot = await _db.collection('products').get();
        existingProducts = snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList();
        _cachedCatalog = List.from(existingProducts);
      }
    } catch (_) {}

    final tasks = _scrapers.entries.map((entry) async {
      try {
        final products = await entry.value.scrapeProducts(category: category);
        return products;
      } catch (e) {
        print('❌ Error scraping ${entry.key}: $e');
        return <(Product, Price)>[];
      }
    });

    final results = await Future.wait(tasks);
    final List<(Product, Price)> all = [];
    for (final list in results) {
      all.addAll(list);
    }
    
    // 2. Perform live in-memory AI entity resolution before returning to the search screens
    return resolveInMemoryProducts(all, existingProducts);
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



  /// Sørensen-Dice coefficient bigram character similarity (robust to typos and word variations)
  double _diceSimilarity(String s1, String s2) {
    s1 = s1.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    s2 = s2.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (s1 == s2) return 1.0;
    if (s1.length < 2 || s2.length < 2) return 0.0;

    final pairs1 = <String>{};
    for (int i = 0; i < s1.length - 1; i++) {
      pairs1.add(s1.substring(i, i + 2));
    }

    final pairs2 = <String>{};
    for (int i = 0; i < s2.length - 1; i++) {
      pairs2.add(s2.substring(i, i + 2));
    }

    final intersection = pairs1.intersection(pairs2).length;
    return (2.0 * intersection) / (pairs1.length + pairs2.length);
  }

  /// Model representation of parsed weight/volume quantities for precise resolution
  ScraperParsedQty? _parseQuantity(String name) {
    final lower = name.toLowerCase();
    
    // 1. Check for multipack formats: e.g., "4 x 80g", "4x23.5g", "12 x 1l", "26 x 33g", "12 x 1L"
    final multipackRegex = RegExp(
      r'(\d+)\s*(?:x|pcs|packets|teabags|bags|sticks|s|packets\s*x)\s*(\d+(?:\.\d+)?)\s*(kg|g|l|ml|kg|s)\b', 
      caseSensitive: false
    );
    final multiMatch = multipackRegex.firstMatch(lower);
    if (multiMatch != null) {
      final int mult = int.tryParse(multiMatch.group(1)!) ?? 1;
      final double value = double.tryParse(multiMatch.group(2)!) ?? 0.0;
      final String rawUnit = multiMatch.group(3)!;
      
      String normUnit = 'g';
      double multiplierValue = 1.0;
      if (rawUnit == 'kg') { normUnit = 'g'; multiplierValue = 1000.0; }
      else if (rawUnit == 'g') { normUnit = 'g'; multiplierValue = 1.0; }
      else if (rawUnit == 'l') { normUnit = 'ml'; multiplierValue = 1000.0; }
      else if (rawUnit == 'ml') { normUnit = 'ml'; multiplierValue = 1.0; }
      else if (rawUnit == 's') { normUnit = 's'; multiplierValue = 1.0; }
      
      return ScraperParsedQty(
        totalValue: value * multiplierValue * mult,
        unit: normUnit,
        multiplier: mult,
        singleValue: value * multiplierValue,
      );
    }
    
    // 2. Check for single weight/volume values: e.g. "5kg", "500g", "1l", "1.5l", "250ml", "100s"
    final singleRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(kg|g|l|ml|s)\b', caseSensitive: false);
    final singleMatch = singleRegex.firstMatch(lower);
    if (singleMatch != null) {
      final double value = double.tryParse(singleMatch.group(1)!) ?? 0.0;
      final String rawUnit = singleMatch.group(2)!;
      
      String normUnit = 'g';
      double multiplierValue = 1.0;
      if (rawUnit == 'kg') { normUnit = 'g'; multiplierValue = 1000.0; }
      else if (rawUnit == 'g') { normUnit = 'g'; multiplierValue = 1.0; }
      else if (rawUnit == 'l') { normUnit = 'ml'; multiplierValue = 1000.0; }
      else if (rawUnit == 'ml') { normUnit = 'ml'; multiplierValue = 1.0; }
      else if (rawUnit == 's') { normUnit = 's'; multiplierValue = 1.0; }
      
      return ScraperParsedQty(
        totalValue: value * multiplierValue,
        unit: normUnit,
        multiplier: 1,
        singleValue: value * multiplierValue,
      );
    }
    
    return null;
  }

  /// Resolves the product ID using NLP token-matching, brand matching, and volume comparison
  int _resolveProductEntity(String name, String category, List<Product> existingProducts) {
    final brand = extractBrand(name);
    final scraperQty = _parseQuantity(name);

    // List of packaging/filler terms to exclude during Jaccard token calculations
    final stopWords = {
      'pack', 'packets', 'pouch', 'bag', 'bags', 'sticks', 'pcs', 'rtd', 
      'ready', 'to', 'drink', 'in', 'original', 'value', 'super', 'mega', 'mp'
    };

    double bestScore = 0.0;
    Product? bestMatch;
    double bestThreshold = 0.52;

    for (final existing in existingProducts) {
      // 1. Product Type (Category) must match (e.g. Cooking Ingredients vs Beverages)
      if (existing.productType != category) continue;
      
      // 2. Brand must match
      final existingBrand = extractBrand(existing.name);
      if (existingBrand != brand) continue;

      // 3. Mathematical Quantity/Multipack safety check
      final existingQty = _parseQuantity(existing.name);
      
      bool qtyMatch = true;
      double threshold = 0.52; // Default required matching confidence (52%)
      
      if (scraperQty != null && existingQty != null) {
        // Strict matching: both sizes defined
        if (scraperQty.unit != existingQty.unit ||
            scraperQty.multiplier != existingQty.multiplier ||
            (scraperQty.singleValue - existingQty.singleValue).abs() > 0.01) {
          qtyMatch = false;
        }
      } else if ((scraperQty == null && existingQty != null) || (scraperQty != null && existingQty == null)) {
        // Pragmatic matching: only one has size. Allow merge if similarity is extremely high (>= 75%)
        threshold = 0.75;
      }
      
      if (!qtyMatch) continue; // Size mismatch -> reject merge!

      // 4. Jaccard token similarity with stopword filtering
      final tokens1 = name.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
          .split(' ')
          .where((w) => w.length > 1 && !stopWords.contains(w))
          .toSet();
          
      final tokens2 = existing.name.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
          .split(' ')
          .where((w) => w.length > 1 && !stopWords.contains(w))
          .toSet();
      
      if (tokens1.isEmpty || tokens2.isEmpty) continue;
      final jaccardScore = tokens1.intersection(tokens2).length / tokens1.union(tokens2).length;

      // 5. Sørensen-Dice bigram similarity
      final diceScore = _diceSimilarity(name, existing.name);

      // 6. Compute hybrid confidence score (average of bigram Dice and Jaccard)
      final hybridScore = (jaccardScore + diceScore) / 2.0;

      if (hybridScore >= threshold && hybridScore > bestScore) {
        bestScore = hybridScore;
        bestMatch = existing;
        bestThreshold = threshold;
      }
    }

    // Reuse ID if matches meet the required similarity threshold
    if (bestMatch != null) {
        print('🤖 Entity Resolution: Merged "$name" with existing "${bestMatch.name}" (Similarity: ${(bestScore*100).toStringAsFixed(0)}%)');
      return bestMatch.id;
    }

    // Default clean global product ID
    return parseStableId(_stableKey(name));
  }

  /// Save products and prices using Firestore batch writes with Entity Matching
  Future<void> _storeProducts(List<(Product, Price)> products) async {
    // 1. Fetch current catalog for entity matching
    List<Product> existingProducts = [];
    try {
      if (_cachedCatalog != null) {
        existingProducts = List.from(_cachedCatalog!);
      } else {
        final snapshot = await _db.collection('products').get();
        existingProducts = snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList();
        _cachedCatalog = List.from(existingProducts);
      }
      print('🤖 Loaded ${existingProducts.length} existing products for similarity deduplication (cached: ${_cachedCatalog != null}).');
    } catch (e) {
      print('⚠️ Failed to pre-load catalog. Scraping will default to exact string hashes: $e');
    }

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
          // Resolve stable unified product ID (either reuse a match or build a global hash)
          final stableProductId = _resolveProductEntity(product.name, product.productType, existingProducts);

          // Add this to our local listing for batch matching (so items in the same scraping job merge)
          if (!existingProducts.any((p) => p.id == stableProductId)) {
            final newProd = Product(
              id: stableProductId,
              name: product.name,
              description: product.description,
              imageUrl: product.imageUrl,
              category: product.category,
              productType: product.productType,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            existingProducts.add(newProd);
            if (_cachedCatalog != null && !_cachedCatalog!.any((p) => p.id == stableProductId)) {
              _cachedCatalog!.add(newProd);
            }
          }

          final productDoc = _db.collection('products').doc(stableProductId.toString());
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
        Product? cached;
        if (_cachedCatalog != null) {
          cached = _cachedCatalog!.cast<Product?>().firstWhere(
                (p) => p?.id.toString() == productId.toString(),
                orElse: () => null,
              );
        }
        if (cached != null) {
          products.add(cached);
        } else {
          final productDoc = await _db.collection('products').doc(productId).get();
          if (productDoc.exists) {
            final p = Product.fromFirestore(productDoc.data()!, productDoc.id);
            products.add(p);
            if (_cachedCatalog != null) {
              _cachedCatalog!.add(p);
            }
          }
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
      _cachedCatalog = null;
      
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

/// Helper model class representing parsed quantity configurations for entity resolution
class ScraperParsedQty {
  final double totalValue;
  final String unit;
  final int multiplier;
  final double singleValue;

  ScraperParsedQty({
    required this.totalValue,
    required this.unit,
    required this.multiplier,
    required this.singleValue,
  });
}
