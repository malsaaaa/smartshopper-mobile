/// Product CRUD service
/// Manages all product catalog operations with in-memory storage
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';

class ProductService {
  // In-memory database (replace with API later)
  late List<Product> _products;
  late List<Price> _prices;

  ProductService() {
    _products = List.from(MockData.products);
    _prices = List.from(MockData.prices);
  }

  // ============== READ ==============

  /// Get all products
  List<Product> getAllProducts() {
    return List.from(_products);
  }

  /// Get product by ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search products by name or description
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return getAllProducts();

    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  /// Get all categories
  List<String> getCategories() {
    final categories = <String>{};
    for (var product in _products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  /// Get prices for product
  List<Price> getPricesForProduct(int productId) {
    return _prices.where((price) => price.productId == productId).toList();
  }

  /// Get best price for product
  Price? getBestPriceForProduct(int productId) {
    final prices = getPricesForProduct(productId);
    if (prices.isEmpty) return null;

    return prices.reduce((a, b) => a.price < b.price ? a : b);
  }

  // ============== CREATE ==============

  /// Add new product
  Product createProduct({
    required String name,
    required String description,
    required String category,
    String? imageUrl,
  }) {
    final newId = _products.isNotEmpty
        ? _products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    final newProduct = Product(
      id: newId,
      name: name,
      description: description,
      category: category,
      imageUrl: imageUrl ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _products.add(newProduct);
    return newProduct;
  }

  /// Add price for product
  Price addPriceForProduct({
    required int productId,
    required int retailerId,
    required double price,
    required String productUrl,
  }) {
    final newId = _prices.isNotEmpty
        ? _prices.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    final newPrice = Price(
      id: newId,
      productId: productId,
      retailerId: retailerId,
      price: price,
      productUrl: productUrl,
      scrapedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _prices.add(newPrice);
    return newPrice;
  }

  // ============== UPDATE ==============

  /// Update product
  Product? updateProduct(int id, {
    String? name,
    String? description,
    String? category,
    String? imageUrl,
  }) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) return null;

    final product = _products[index];
    final updatedProduct = Product(
      id: product.id,
      name: name ?? product.name,
      description: description ?? product.description,
      category: category ?? product.category,
      imageUrl: imageUrl ?? product.imageUrl,
      createdAt: product.createdAt,
      updatedAt: DateTime.now(),
    );

    _products[index] = updatedProduct;
    return updatedProduct;
  }

  /// Update price
  Price? updatePrice(int priceId, {
    double? price,
    String? productUrl,
  }) {
    final index = _prices.indexWhere((p) => p.id == priceId);
    if (index == -1) return null;

    final priceEntry = _prices[index];
    final updatedPrice = Price(
      id: priceEntry.id,
      productId: priceEntry.productId,
      retailerId: priceEntry.retailerId,
      price: price ?? priceEntry.price,
      productUrl: productUrl ?? priceEntry.productUrl,
      scrapedAt: priceEntry.scrapedAt,
      createdAt: priceEntry.createdAt,
      updatedAt: DateTime.now(),
    );

    _prices[index] = updatedPrice;
    return updatedPrice;
  }

  // ============== DELETE ==============

  /// Delete product
  bool deleteProduct(int id) {
    final initialLength = _products.length;
    _products.removeWhere((product) => product.id == id);
    // Also remove related prices
    _prices.removeWhere((price) => price.productId == id);
    return _products.length < initialLength;
  }

  /// Remove price entry
  bool deletePrice(int priceId) {
    final initialLength = _prices.length;
    _prices.removeWhere((price) => price.id == priceId);
    return _prices.length < initialLength;
  }

  /// Remove prices for specific retailer
  bool deletePricesForRetailer(int productId, int retailerId) {
    final initialLength = _prices.length;
    _prices.removeWhere((price) =>
        price.productId == productId && price.retailerId == retailerId);
    return _prices.length < initialLength;
  }
}
