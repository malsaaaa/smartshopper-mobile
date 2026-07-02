import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/utils/product_utils.dart';
import 'base_scraper.dart';

/// Lotus (Lotus's Superstore Malaysia) retailer scraper.
/// Scrapes products from Lotus's backend API directly.
class LotusScraper extends BaseScraper {
  // Base URL and target endpoints
  static const String _storeFront = 'https://www.lotuss.com.my/en';
  static const String _apiBase = 'https://api-o2o.lotuss.com.my';
  static const String _websiteCode = 'malaysia_hy';
  static const int _pageSize = 30;

  static const String retailerName = 'Lotus';
  static const int retailerId = 3;

  // Fixed headers required by Lotus's API (captured from live web session)
  static const Map<String, String> _apiHeaders = {
    'accept': 'application/json, text/plain, */*',
    'accept-language': 'en',
    'channel': 'web',
    'version': '2.3.9',
    'key':
        'SeiRQmEDnaZXOlpfKhCjV4Bo2y6vAcW99QKmzifsgP2uCMN7wF3ahRXex84kH6qUVIWoY5Dp0GEljdAvS1JytOZcLbnBTr',
    'origin': 'https://www.lotuss.com.my',
    'referer': 'https://www.lotuss.com.my/',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  // Default background search keywords
  static const List<String> searchTerms = [
    'cooking oil',
    'milo',
  ];

  @override
  Retailer getRetailerInfo() {
    // Return metadata for Lotus
    return Retailer(
      id: retailerId,
      name: retailerName,
      logoUrl: 'assets/images/retailers/lotuss.png',
      website: _storeFront,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<(Product, Price)>> scrapeProducts({
    int? pageNumber,
    String? category,
  }) async {
    try {
      // Handle manual search if category is provided
      if (category != null && category.isNotEmpty) {
        final products = await _fetchProductsForQuery(category);
        print(
            '✅ Lotus: Scraped ${products.length} products for query "$category"');
        return products;
      }

      // Loop through keywords to build search results
      final List<(Product, Price)> all = [];
      for (final term in searchTerms) {
        final products = await _fetchProductsForQuery(term);
        all.addAll(products);
        print('✅ Lotus: Scraped ${products.length} products for "$term"');
      }
      print('✅ Lotus: Total scraped ${all.length} products');
      return all;
    } catch (e) {
      print('❌ Lotus scraping error: $e');
      return [];
    }
  }

  @override
  Future<(Product, Price)?> scrapeProductByUrl(String url) async {
    // URL scraping not supported for React SPA
    print('⚠️ Lotus: scrapeProductByUrl is not supported for SPA pages.');
    return null;
  }

  @override
  Future<List<String>> getCategories() async => const [
        'Beverages',
        'Cooking Ingredients',
        'Food',
      ];

  /// Loop through all pages of results
  Future<List<(Product, Price)>> _fetchProductsForQuery(String query) async {
    final List<(Product, Price)> results = [];
    int offset = 0;
    int total = _pageSize;

    while (offset < total) {
      final page = await _fetchPage(query: query, offset: offset);
      if (page == null) break;

      total = page['meta']?['total'] as int? ?? 0;
      final products =
          (page['data']?['products'] as List<dynamic>?) ?? [];

      // Parse page items into product-price list
      for (final raw in products) {
        final pair = _parsePair(raw as Map<String, dynamic>);
        if (pair != null) results.add(pair);
      }

      offset += _pageSize;
    }

    return results;
  }

  /// Call one page of the Lotus product search API
  Future<Map<String, dynamic>?> _fetchPage({
    required String query,
    required int offset,
  }) async {
    // Encode query parameters to JSON
    final q = jsonEncode({
      'offset': offset,
      'limit': _pageSize,
      'search': query,
      'sort': 'relevance:DESC',
      'filter': <String, dynamic>{},
      'websiteCode': _websiteCode,
    });

    final uri = Uri.parse(
        '$_apiBase/lotuss-mobile-bff/product/v2/products?q=${Uri.encodeComponent(q)}');

    try {
      // Make HTTPS GET call with API headers
      final response = await http
          .get(uri, headers: _apiHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('❌ Lotus API error ${response.statusCode}: ${response.body.substring(0, 200)}');
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Lotus API request failed: $e');
      return null;
    }
  }

  /// Convert raw product JSON to Product/Price models
  (Product, Price)? _parsePair(Map<String, dynamic> raw) {
    try {
      final name = (raw['name'] as String? ?? '').trim();
      if (name.isEmpty) return null;

      // Extract final price, fallback to regular price
      final minimumPrice =
          (raw['priceRange']?['minimumPrice'] as Map<String, dynamic>?) ?? {};
      final finalPrice =
          (minimumPrice['finalPrice']?['value'] as num?)?.toDouble() ?? 0.0;
      final regularPrice =
          (minimumPrice['regularPrice']?['value'] as num?)?.toDouble() ??
              finalPrice;
      final price = finalPrice > 0 ? finalPrice : regularPrice;

      // Extract product image URL
      final imageUrl = (raw['thumbnail']?['url'] as String?) ??
          (raw['smallImage']?['url'] as String?) ??
          (raw['image']?['url'] as String?) ??
          '';

      // Build store web link
      // Using the verified '/en/p/<sku>' format which works and redirects correctly
      final sku = (raw['sku'] as String?) ?? '';
      final productUrl = sku.isNotEmpty
          ? 'https://www.lotuss.com.my/en/p/$sku'
          : 'https://www.lotuss.com.my/en';

      final standardizedName = standardizeProductName(name);
      final brand = extractBrand(standardizedName);
      final category = extractCategory(standardizedName);

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch,
        name: standardizedName,
        description: '',
        category: brand,
        productType: category,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final priceObj = Price(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id,
        retailerId: retailerId,
        price: price,
        productUrl: productUrl,
        scrapedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return (product, priceObj);
    } catch (e) {
      print('⚠️ Lotus: error parsing product: $e');
      return null;
    }
  }
}
