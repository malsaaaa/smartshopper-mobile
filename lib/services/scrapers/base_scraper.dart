import 'package:smartshopper_mobile/data/models/index.dart';

/// Base class for all retailer scrapers
abstract class BaseScraper {
  /// Get retailer info
  Retailer getRetailerInfo();

  /// Scrape products from retailer website
  /// Returns list of (product, price) pairs
  Future<List<(Product, Price)>> scrapeProducts({
    int? pageNumber,
    String? category,
  });

  /// Scrape a single product by URL
  Future<(Product, Price)?> scrapeProductByUrl(String url);

  /// Get available categories for this retailer
  Future<List<String>> getCategories();
}

/// Scraping result model
class ScrapingResult {
  final Product product;
  final Price price;

  ScrapingResult({
    required this.product,
    required this.price,
  });
}
