import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/utils/product_utils.dart';
import 'base_scraper.dart';

/// MyDin retailer scraper
/// Scrapes product information from MyDin's Magento API.
class MyDinScraper extends BaseScraper {
  static const String baseUrl = 'https://mydin.my';
  static const String apiBaseUrl = 'https://myapi.mydin.my/magento';
  static const String retailerName = 'MyDin';
  static const int retailerId = 1;
  static const int defaultCategoryId = 1222;
  static const int defaultPageSize = 48;
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
      logoUrl: 'assets/images/retailers/mydin.png',
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
      // If a specific category or query is passed (e.g. from manual search/filter)
      if (category != null && category.isNotEmpty) {
        final products = await _fetchProducts(
          search: category,
          pageSize: defaultPageSize,
          currentPage: pageNumber ?? 1,
        );
        print('✅ MyDin: Scraped ${products.length} products for search category "$category"');
        return products;
      }

      // Default background run: scrape the 5 target search keywords
      final allProducts = <(Product, Price)>[];

      for (final term in searchTerms) {
        print('🔄 MyDin: Scraping search results for "$term"...');
        final products = await _fetchProducts(
          search: term,
          pageSize: defaultPageSize,
          currentPage: 1,
        );

        if (products.isNotEmpty) {
          allProducts.addAll(products);
          print('✅ MyDin: Scraped ${products.length} products for "$term"');
        } else {
          print('⚠️ MyDin: No products found for "$term"');
        }

        // Polite delay of 500ms between search requests
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ MyDin: Scraped a total of ${allProducts.length} products across all search terms');
      return allProducts;
    } catch (e) {
      print('❌ MyDin scraping error: $e');
      return [];
    }
  }

  @override
  Future<(Product, Price)?> scrapeProductByUrl(String url) async {
    try {
      final slug = _extractProductSlug(url);
      if (slug.isEmpty) return null;

      final products = await _fetchProducts(
        filter: {
          'url_key': {
            'eq': slug,
          },
        },
        pageSize: 1,
        currentPage: 1,
      );

      if (products.isEmpty) return null;
      return products.first;
    } catch (e) {
      print('❌ MyDin product URL scraping error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    return searchTerms;
  }

  Future<List<(Product, Price)>> _fetchProducts({
    Map<String, dynamic>? filter,
    String? search,
    required int pageSize,
    required int currentPage,
  }) async {
    final payload = [
      {
        if (filter != null) 'filter': filter,
        if (search != null) 'search': search,
        'pageSize': pageSize,
        'currentPage': currentPage,
        if (filter != null) 'sort': {
          'position': 'ASC',
        },
      },
      {
        'products': 'products-custom-query',
        'metadata': {
          'fields': _productFields,
        },
      },
    ];

    final response = await http
        .get(
          Uri.parse('$apiBaseUrl/products?body=${Uri.encodeComponent(jsonEncode(payload))}'),
          headers: const {
            'accept': 'application/json',
            'user-agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      print('❌ MyDin API failed: ${response.statusCode}');
      return [];
    }

    return _parseProductsResponse(response.body);
  }

  List<(Product, Price)> _parseProductsResponse(String body) {
    final decoded = jsonDecode(body);
    final items = _extractItems(decoded);
    final results = <(Product, Price)>[];

    for (final item in items) {
      try {
        final product = _mapProduct(item);
        final price = _mapPrice(item, product.id);
        results.add((product, price));
      } catch (e) {
        print('⚠️ Error parsing MyDin API product: $e');
      }
    }

    return results;
  }

  List<Map<String, dynamic>> _extractItems(dynamic decoded) {
    final items = <Map<String, dynamic>>[];

    void walk(dynamic value) {
      if (value is Map) {
        final map = value.cast<String, dynamic>();
        final maybeItems = map['items'];
        if (maybeItems is List) {
          for (final entry in maybeItems) {
            if (entry is Map) {
              items.add(entry.cast<String, dynamic>());
            }
          }
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

  Product _mapProduct(Map<String, dynamic> item) {
    final id = _extractInt(item['id']) ?? DateTime.now().millisecondsSinceEpoch;
    final name = _firstNonEmptyString([
      item['custom_productname'],
      item['name'],
      _mapString(item['description'], 'html'),
    ]);
    final standardizedName = standardizeProductName(name.isEmpty ? 'Mydin Product $id' : name);
    
    final description = _stripHtml(
      _firstNonEmptyString([
        _mapString(item['description'], 'html'),
        item['custom_productdescription'],
      ]),
    );
    final imageUrl = _mapString(item['thumbnail'], 'url');

    return Product(
      id: id,
      name: standardizedName,
      description: description,
      category: extractBrand(standardizedName),
      productType: extractCategory(standardizedName),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Price _mapPrice(Map<String, dynamic> item, int productId) {
    final id = DateTime.now().millisecondsSinceEpoch;
    final price = _extractPrice(item['price_range']);
    final urlKey = _firstNonEmptyString([item['url_key']]);

    return Price(
      id: id,
      productId: productId,
      retailerId: retailerId,
      price: price,
      productUrl: urlKey.isEmpty ? baseUrl : '$baseUrl/product/$urlKey',
      scrapedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Extract numeric price from nested API response objects.
  double _extractPrice(dynamic value) {
    try {
      if (value == null) {
        return 0.0;
      }

      if (value is num) {
        return value.toDouble();
      }

      if (value is Map) {
        final map = value.cast<String, dynamic>();
        final candidates = [
          map['value'],
          map['final_price'],
          map['regular_price'],
          map['minimum_price'],
          map['maximum_price'],
        ];

        for (final candidate in candidates) {
          final extracted = _extractPrice(candidate);
          if (extracted > 0) {
            return extracted;
          }
        }
      }

      final text = value.toString();
      final match = RegExp(r'value\s*=\s*([\d.]+)').firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 0.0;
      }

      final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  int? _extractInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _mapString(dynamic value, String key) {
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final nested = map[key];
      if (nested != null) {
        return nested.toString();
      }
    }
    return '';
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

  String _extractProductSlug(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return '';

    return segments.last;
  }

  /// Extract product type from name.
  String _extractProductType(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('drink') || lower.contains('beverage')) return 'Beverages';
    if (lower.contains('meat') || lower.contains('chicken')) return 'Meat & Seafood';
    if (lower.contains('vegetable') || lower.contains('fruit')) return 'Produce';
    if (lower.contains('dairy') || lower.contains('milk')) return 'Dairy';
    if (lower.contains('snack') || lower.contains('chip')) return 'Snacks';
    return 'General';
  }

  static const String _productFields = '''
items {
  id
  name
  sku
  url_key
  custom_productname
  description {
    html
  }
  thumbnail {
    url
    label
  }
  price_range {
    minimum_price {
      final_price {
        currency
        value
      }
      regular_price {
        currency
        value
      }
    }
  }
  salable_quantity
  quantity
  categories {
    name
  }
}
page_info {
  current_page
  page_size
  total_pages
}
total_count
''';
}
