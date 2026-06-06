import 'package:html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:smartshopper_mobile/data/models/index.dart';
import 'base_scraper.dart';

/// Giant retailer scraper
/// Scrapes product information from Giant website
class GiantScraper extends BaseScraper {
  static const String baseUrl = 'https://www.giant.com.my';
  static const String retailerName = 'Giant';
  static const int retailerId = 2;

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
      
      // Giant search page URL
      final url = _buildSearchUrl(category: category, page: pageNumber);
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        print('❌ Giant scraping failed: ${response.statusCode}');
        return [];
      }

      final document = html.parse(response.body);
      
      // Extract products - adjust selectors based on actual Giant HTML structure
      final productElements = document.querySelectorAll('.product-card, [data-product-id], .item-card');
      
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
          print('⚠️ Error parsing Giant product: $e');
          continue;
        }
      }

      print('✅ Giant: Scraped ${results.length} products');
      return results;
    } catch (e) {
      print('❌ Giant scraping error: $e');
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
      final productName = document.querySelector('h1, .product-name, [data-product-name]')?.text ?? '';
      final productPrice = _extractPrice(
        document.querySelector('.product-price, [data-price], .price')?.text ?? '0'
      );
      final imageUrl = document.querySelector('img.product-image, img[alt*=product]')?.attributes['src'] ?? '';
      final description = document.querySelector('.product-description, .desc, [data-description]')?.text ?? '';

      if (productName.isEmpty) return null;

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch,
        name: productName,
        description: description,
        category: 'Giant',
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
      print('❌ Giant product URL scraping error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    // Return common Giant categories
    return [
      'Groceries',
      'Fresh Produce',
      'Meat & Poultry',
      'Seafood',
      'Dairy & Eggs',
      'Bakery',
      'Beverages',
      'Snacks & Confectionery',
      'Health & Beauty',
      'Home & Lifestyle',
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
      final name = element.querySelector('.product-name, .title, h2')?.text?.trim() ?? '';
      final imageUrl = element.querySelector('img')?.attributes['src'] ?? '';
      final description = element.querySelector('.product-description, .desc')?.text?.trim() ?? '';

      if (name.isEmpty) return null;

      return Product(
        id: productId,
        name: name,
        description: description,
        category: 'Giant',
        productType: _extractProductType(name),
        imageUrl: imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ Error parsing Giant product: $e');
      return null;
    }
  }

  /// Parse price from product element
  Price? _parsePrice(html.Element element, int productId) {
    try {
      final priceText = element.querySelector('.product-price, [data-price], .price')?.text ?? '0';
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
      print('⚠️ Error parsing Giant price: $e');
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
    if (lower.contains('meat') || lower.contains('poultry')) return 'Meat & Poultry';
    if (lower.contains('seafood') || lower.contains('fish')) return 'Seafood';
    if (lower.contains('vegetable') || lower.contains('fruit')) return 'Produce';
    if (lower.contains('dairy') || lower.contains('milk')) return 'Dairy';
    if (lower.contains('snack') || lower.contains('chip')) return 'Snacks';
    return 'General';
  }
}
