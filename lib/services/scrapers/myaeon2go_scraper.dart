import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';

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

  static const Map<String, int> _categoryGids = {
    'all': 8412982,
    'aeon_fresh': 545234,
    'ready_to_eat': 8630656,
    'delica': 10000022,
    'best_sellers': 1066,
  };

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
      final gid = _resolveCategoryGid(category);
      final url = Uri.parse(
        '$baseUrl/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&gid=$gid&pleType=softCategory',
      );

      final response = await _getJson(url);
      if (response.statusCode != 200) {
        print('❌ myAEON2go scraping failed: ${response.statusCode}');
        return [];
      }

      final results = _parseListResponse(response.body);
      print('✅ myAEON2go: Scraped ${results.length} products');
      return results;
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
    return _categoryGids.keys.toList(growable: false);
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

  int _resolveCategoryGid(String? category) {
    if (category == null || category.trim().isEmpty) {
      return _categoryGids['best_sellers']!;
    }

    final parsed = int.tryParse(category.trim());
    if (parsed != null) return parsed;

    final normalized = _normalizeCategory(category);
    return _categoryGids[normalized] ?? _categoryGids['best_sellers']!;
  }

  List<(Product, Price)> _parseListResponse(String body) {
    final decoded = jsonDecode(body);
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
    final name = _firstNonEmptyString([
      item['nameText'],
      item['name'],
      item['extendedName'],
    ]);
    final description = _stripHtml(_firstNonEmptyString([
      item['longDescription'],
      item['extendedInfoText'],
      item['extendedInfo2Text'],
    ]));
    final imageUrl = _extractImageUrl(item);

    return Product(
      id: productId,
      name: name.isEmpty ? 'myAEON2go Product $productId' : name,
      description: description,
      category: retailerName,
      productType: _extractProductType(item),
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