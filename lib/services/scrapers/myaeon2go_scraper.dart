import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/utils/product_utils.dart';

import 'base_scraper.dart';

/// myAEON2go retailer scraper.
///
/// myAEON2go uses a React storefront with JSON route payloads, so the scraper
/// targets the same product and soft-category endpoints that the browser uses.
class MyAeon2GoScraper extends BaseScraper {
  static const String baseUrl = 'https://myaeon2go.com';
  static const String retailerName = 'myAEON2go';
  static const int retailerId = 2;
  static const String defaultCsrfToken = 'zAZtwxfWJSl3C72w6Kq9UAGQ6BkM4yD6lTXBx7-m38q';

  final String? sessionCookieHeader;
  final String csrfToken;

  MyAeon2GoScraper({
    this.sessionCookieHeader,
    String? csrfToken,
  }) : csrfToken = csrfToken ?? defaultCsrfToken;

  static const List<String> searchTerms = [
    'cooking oil 5kg',
    'milo 1kg',
    'maggi curry 5 pack',
    'tea bags',
    'rice 10kg',
  ];

  @override
  Retailer getRetailerInfo() {
    return Retailer(
      id: retailerId,
      name: retailerName,
      logoUrl: 'assets/images/retailers/aeon.png',
      website: baseUrl,
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
      // If a specific category/query is passed (e.g., from manual search)
      if (category != null && category.isNotEmpty) {
        final products = await _fetchProductsForQuery(category);
        print('✅ myAEON2go: Scraped ${products.length} products for search category "$category"');
        return products;
      }

      // Default background run: scrape the 5 target search keywords
      final allProducts = <(Product, Price)>[];

      for (final term in searchTerms) {
        print('🔄 myAEON2go: Scraping search results for "$term"...');
        final products = await _fetchProductsForQuery(term);

        if (products.isNotEmpty) {
          allProducts.addAll(products);
          print('✅ myAEON2go: Scraped ${products.length} products for "$term"');
        } else {
          print('⚠️ myAEON2go: No products found for "$term"');
        }

        // Polite delay of 500ms between search requests
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ myAEON2go: Scraped a total of ${allProducts.length} products across all search terms');
      return allProducts;
    } catch (e) {
      print('❌ myAEON2go scraping error: $e');
      return [];
    }
  }

  @override
  Future<(Product, Price)?> scrapeProductByUrl(String url) async {
    try {
      final response = await _getJson(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final item = _extractProductVariant(jsonDecode(response.body));
      if (item == null) return null;

      final product = _mapProduct(item);
      final price = _mapPrice(item, product.id, productUrl: url);
      return (product, price);
    } catch (e) {
      print('❌ myAEON2go product URL scraping error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    return searchTerms;
  }

  Future<http.Response> _getJson(Uri uri) {
    final headers = <String, String>{
      'accept': 'application/json, text/plain, */*',
      'content-type': 'application/json',
      'api-json': 'true',
      'isfromspa': 'false',
      'x-csrf-token': csrfToken,
      'referer': '$baseUrl/',
      'origin': baseUrl,
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    };

    if (sessionCookieHeader != null && sessionCookieHeader!.trim().isNotEmpty) {
      headers['cookie'] = sessionCookieHeader!;
    }

    return http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
  }

  Future<List<(Product, Price)>> _fetchProductsForQuery(String query) async {
    final url = '$baseUrl/products/search/${Uri.encodeComponent(query)}';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'user-agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'referer': '$baseUrl/',
          'accept-language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('❌ myAEON2go search page failed: ${response.statusCode}');
        return [];
      }

      final html = response.body;
      
      // Extract PhoenixAppState
      const startKeyword = "let PhoenixAppState = '";
      final startIndex = html.indexOf(startKeyword);
      if (startIndex == -1) {
        print('❌ myAEON2go: let PhoenixAppState not found in HTML for query "$query"');
        return [];
      }

      final valueStart = startIndex + startKeyword.length;
      final valueEnd = html.indexOf("';", valueStart);
      if (valueEnd == -1) {
        print('❌ myAEON2go: End of PhoenixAppState string not found for query "$query"');
        return [];
      }

      final base64Str = html.substring(valueStart, valueEnd);
      final decodedBytes = base64.decode(base64Str);
      final decodedStr = utf8.decode(decodedBytes);
      final decoded = jsonDecode(decodedStr);

      return _parseStateResponse(decoded);
    } catch (e) {
      print('❌ myAEON2go: Error fetching/parsing search for "$query": $e');
      return [];
    }
  }

  List<(Product, Price)> _parseStateResponse(dynamic decoded) {
    final items = _extractVariantList(decoded);
    return items.map((item) {
      final product = _mapProduct(item);
      final price = _mapPrice(item, product.id);
      return (product, price);
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _extractVariantList(dynamic decoded) {
    final items = <Map<String, dynamic>>[];

    void walk(dynamic value) {
      if (value is Map) {
        final map = value.cast<String, dynamic>();
        final productListEntities = map['productListEntities'];
        if (productListEntities is List) {
          for (final entry in productListEntities) {
            if (entry is Map) {
              items.add(entry.cast<String, dynamic>());
            }
          }
          return;
        }

        final variant = map['variant'];
        if (variant is Map && variant.containsKey('nameText')) {
          items.add(variant.cast<String, dynamic>());
          return;
        }

        for (final nested in map.values) {
          walk(nested);
        }
      } else if (value is List) {
        for (final nested in value) {
          walk(nested);
        }
      }
    }

    walk(decoded);
    return items;
  }

  Map<String, dynamic>? _extractProductVariant(dynamic decoded) {
    Map<String, dynamic>? found;

    void walk(dynamic value) {
      if (found != null) return;
      if (value is Map) {
        final map = value.cast<String, dynamic>();
        final variant = map['variant'];
        if (variant is Map && variant.containsKey('nameText')) {
          found = variant.cast<String, dynamic>();
          return;
        }
        if (map.containsKey('nameText') && map.containsKey('price')) {
          found = map;
          return;
        }
        for (final nested in map.values) {
          walk(nested);
        }
      } else if (value is List) {
        for (final nested in value) {
          walk(nested);
        }
      }
    }

    walk(decoded);
    return found;
  }

  Product _mapProduct(Map<String, dynamic> item) {
    final productId = _extractInt(item['_id']) ?? _extractInt(item['gid']) ?? DateTime.now().millisecondsSinceEpoch;
    
    // Extract base name
    String baseName = _firstNonEmptyString([
      item['nameText'],
      item['name'],
      item['extendedName'],
    ]).trim();

    if (baseName.isEmpty) {
      baseName = 'myAEON2go Product $productId';
    }

    // Extract brand
    final brand = _firstNonEmptyString([item['brandingText']]).trim();
    
    // Extract size/weight details (e.g. "3 kg")
    final size = _firstNonEmptyString([item['extendedInfoText']]).trim();

    // Construct descriptive name
    String fullName = baseName;
    
    // 1. Prepend brand if not already in the name
    if (brand.isNotEmpty) {
      final lowerName = fullName.toLowerCase();
      final lowerBrand = brand.toLowerCase();
      if (!lowerName.contains(lowerBrand)) {
        fullName = '$brand $fullName';
      }
    }
    
    // 2. Append size/weight if not already in the name
    if (size.isNotEmpty) {
      final lowerName = fullName.toLowerCase();
      final lowerSize = size.toLowerCase();
      if (!lowerName.contains(lowerSize)) {
        fullName = '$fullName $size';
      }
    }

    // Apply rule-based naming standardization
    final standardizedName = standardizeProductName(fullName);

    final description = _stripHtml(_firstNonEmptyString([
      item['longDescription'],
      item['extendedInfoText'],
      item['extendedInfo2Text'],
    ]));
    final imageUrl = _extractImageUrl(item);

    return Product(
      id: productId,
      name: standardizedName,
      description: description,
      category: extractBrand(standardizedName),
      productType: extractCategory(standardizedName),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Price _mapPrice(Map<String, dynamic> item, int productId, {String? productUrl}) {
    final price = _extractDouble(item['salePrice'])
        .clamp(0, double.infinity)
        .toDouble();
    final url = productUrl ?? _buildProductUrl(item);

    return Price(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: productId,
      retailerId: retailerId,
      price: price > 0 ? price : _extractDouble(item['price']),
      productUrl: url,
      scrapedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _buildProductUrl(Map<String, dynamic> item) {
    final gid = _extractInt(item['gid']) ?? 0;
    final slug = _firstNonEmptyString([item['slug']]);
    if (gid == 0 || slug.isEmpty) return baseUrl;
    return '$baseUrl/product/$gid/$slug';
  }

  String _extractImageUrl(Map<String, dynamic> item) {
    final images = item['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        final url = first['original'] ?? first['url'];
        if (url != null) return url.toString();
      }
    }

    final nested = item['image'];
    if (nested is String && nested.isNotEmpty) return nested;

    return '';
  }

  String _extractProductType(Map<String, dynamic> item) {
    final categories = item['product'] is Map ? (item['product']['categories'] as List?) : null;
    if (categories != null && categories.isNotEmpty) {
      final names = categories
          .whereType<Map>()
          .map((entry) => entry['name']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        return names.last.replaceAll('_', ' ');
      }
    }

    final text = _firstNonEmptyString([item['nameText'], item['extendedName']]);
    final lower = text.toLowerCase();
    if (lower.contains('chicken') || lower.contains('meat')) return 'Fresh Food';
    if (lower.contains('fish') || lower.contains('salmon')) return 'Seafood';
    if (lower.contains('drink') || lower.contains('coffee') || lower.contains('tea')) return 'Beverages';
    if (lower.contains('bread') || lower.contains('bakery')) return 'Bakery';
    if (lower.contains('snack')) return 'Snacks';
    return 'General';
  }

  int? _extractInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  double _extractDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final text = value?.toString() ?? '';
    final match = RegExp(r'([\d.]+)').firstMatch(text);
    return double.tryParse(match?.group(1) ?? '') ?? 0.0;
  }

  String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeCategory(String category) {
    return category
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}