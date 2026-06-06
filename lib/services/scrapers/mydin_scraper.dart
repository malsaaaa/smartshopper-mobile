import 'package:html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';
import 'base_scraper.dart';

/// MyDin retailer scraper
/// Scrapes product information from MyDin website
class MyDinScraper extends BaseScraper {
  static const String baseUrl = 'https://www.mydin.com.my';
  static const String retailerName = 'MyDin';
  static const int retailerId = 1;

  @override
  Retailer getRetailerInfo() {
    return Retailer(
      id: retailerId,
      name: retailerName,
      logoUrl: '$baseUrl/assets/images/logo.png',
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
      final List<(Product, Price)> results = [];
      
      // MyDin search page URL
      final url = _buildSearchUrl(category: category, page: pageNumber);
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        print('❌ MyDin scraping failed: ${response.statusCode}');
        return [];
      }

      final document = html.parse(response.body);
      
      // Extract products - adjust selectors based on actual MyDin HTML structure
      final productElements = document.querySelectorAll('.product-item, [data-product]');
      
      int productId = 1;
      for (final element in productElements) {
        try {
          final product = _parseProduct(element, productId);
          final price = _parsePrice(element, productId);
          
          if (product != null && price != null) {
            results.add((product, price));
            productId++;
          }
        } catch (e) {
          print('⚠️ Error parsing MyDin product: $e');
          continue;
        }
      }

      print('✅ MyDin: Scraped ${results.length} products');
      return results;
    } catch (e) {
      print('❌ MyDin scraping error: $e');
      return [];
    }
  }

  @override
  Future<(Product, Price)?> scrapeProductByUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) return null;

      final document = html.parse(response.body);
      
      // Extract single product details
      final productName = document.querySelector('h1, .product-name')?.text ?? '';
      final productPrice = _extractPrice(
        document.querySelector('.price, [data-price]')?.text ?? '0'
      );
      final imageUrl = document.querySelector('img[data-src], img[src*=product]')?.attributes['src'] ?? '';
      final description = document.querySelector('.description, .product-desc')?.text ?? '';

      if (productName.isEmpty) return null;

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch,
        name: productName,
        description: description,
        category: 'MyDin',
        productType: 'General',
        imageUrl: imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final price = Price(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id,
        retailerId: retailerId,
        price: productPrice,
        productUrl: url,
        scrapedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return (product, price);
    } catch (e) {
      print('❌ MyDin product URL scraping error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    // Return common MyDin categories
    return [
      'Groceries',
      'Dairy & Eggs',
      'Meat & Seafood',
      'Bakery',
      'Snacks',
      'Beverages',
      'Health & Beauty',
      'Household',
    ];
  }

  /// Build search URL based on filters
  String _buildSearchUrl({String? category, int? page}) {
    final pageStr = page != null ? '?page=$page' : '';
    final categoryStr = category != null ? '&category=$category' : '';
    return '$baseUrl/products$pageStr$categoryStr';
  }

  /// Parse individual product element
  Product? _parseProduct(html.Element element, int productId) {
    try {
      final name = element.querySelector('.product-name, .title')?.text?.trim() ?? '';
      final imageUrl = element.querySelector('img')?.attributes['src'] ?? '';
      final description = element.querySelector('.product-desc, .description')?.text?.trim() ?? '';

      if (name.isEmpty) return null;

      return Product(
        id: productId,
        name: name,
        description: description,
        category: 'MyDin',
        productType: _extractProductType(name),
        imageUrl: imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ Error parsing MyDin product: $e');
      return null;
    }
  }

  /// Parse price from product element
  Price? _parsePrice(html.Element element, int productId) {
    try {
      final priceText = element.querySelector('.price, [data-price]')?.text ?? '0';
      final price = _extractPrice(priceText);
      final url = element.querySelector('a')?.attributes['href'] ?? '';

      return Price(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: productId,
        retailerId: retailerId,
        price: price,
        productUrl: url.startsWith('http') ? url : '$baseUrl$url',
        scrapedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ Error parsing MyDin price: $e');
      return null;
    }
  }

  /// Extract numeric price from text
  double _extractPrice(String text) {
    try {
      // Remove currency symbols and extra text, keep only numbers and decimal point
      final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Extract product type from name
  String _extractProductType(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('drink') || lower.contains('beverage')) return 'Beverages';
    if (lower.contains('meat') || lower.contains('chicken')) return 'Meat & Seafood';
    if (lower.contains('vegetable') || lower.contains('fruit')) return 'Produce';
    if (lower.contains('dairy') || lower.contains('milk')) return 'Dairy';
    if (lower.contains('snack') || lower.contains('chip')) return 'Snacks';
    return 'General';
  }
}
