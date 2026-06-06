import 'models/index.dart';

/// MockData provides realistic test data for the SmartShopper app
/// Contains Malaysian retailers, products, and pricing data
class MockData {
  // Private constructor to prevent instantiation
  MockData._();

  // ============== USER ==============
  static final mockUser = User(
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    profilePicture: null,
    isAdmin: false,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  // ============== RETAILERS ==============
  /// 5 major Malaysian retailers with varying products and prices
  static final retailers = [
    Retailer(
      id: 1,
      name: 'Mydin',
      logoUrl: 'assets/images/retailers/mydin.png',
      website: 'https://mydin.com.my',
      latitude: 3.0558,
      longitude: 101.5925,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    Retailer(
      id: 2,
      name: 'Giant',
      logoUrl: 'assets/images/retailers/giant.png',
      website: 'https://giant.com.my',
      latitude: 3.1042,
      longitude: 101.5975,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    Retailer(
      id: 5,
      name: "Lotus's",
      logoUrl: 'assets/images/retailers/lotuss.png',
      website: 'https://lotuss.com.my',
      latitude: 3.1114,
      longitude: 101.5833,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
  ];

  // ============== PRODUCTS ==============
  /// Malaysian grocery products organised by brand
  static final products = [
    Product(
      id: 1,
      name: 'Milo Activ-Go',
      description: 'Chocolate malt drink powder - 400g',
      category: 'Nestlé',
      productType: 'Drinks',
      imageUrl: 'assets/images/products/milo.png',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 2,
      name: 'Maggi Noodles',
      description: 'Instant noodles - 5 packs',
      category: 'Nestlé',
      productType: 'Instant Noodles',
      imageUrl: 'assets/images/products/maggi.png',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 3,
      name: 'Teh Tarik Mix',
      description: 'Instant tea mix - 300g',
      category: 'Aik Cheong',
      productType: 'Drinks',
      imageUrl: 'assets/images/products/tehtarik.png',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 4,
      name: 'Beras Wangi',
      description: 'Jasmine rice - 5kg',
      category: 'Faiza',
      productType: 'Rice & Grains',
      imageUrl: 'assets/images/products/rice.png',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 6,
      name: 'Nescafé Gold',
      description: 'Premium instant coffee - 200g',
      category: 'Nestlé',
      productType: 'Drinks',
      imageUrl: 'assets/images/products/nescafe.png',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 7,
      name: 'Sunlight Dishwashing Liquid',
      description: 'Dishwashing liquid - 800ml',
      category: 'Unilever',
      productType: 'Household Cleaning',
      imageUrl: 'assets/images/products/sunlight.png',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ),
  ];

  // ============== PRICES ==============
  /// Realistic prices for products across different retailers
  /// Shows price variations (e.g., best prices at different stores)
  static List<Price> get prices {
    final now = DateTime.now();

    return [
      // Milo Activ-Go prices
      Price(
        id: 1,
        productId: 1,
        retailerId: 1,
        price: 12.50,
        productUrl: 'https://mydin.com.my/milo-activ-go',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[0],
      ),
      Price(
        id: 2,
        productId: 1,
        retailerId: 2,
        price: 11.99,
        productUrl: 'https://giant.com.my/milo-activ-go',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[0],
      ),
      Price(
        id: 5,
        productId: 1,
        retailerId: 5,
        price: 12.30,
        productUrl: 'https://lotuss.com.my/milo-activ-go',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[2],
        product: products[0],
      ),

      // Maggi Noodles prices
      Price(
        id: 6,
        productId: 2,
        retailerId: 1,
        price: 4.50,
        productUrl: 'https://mydin.com.my/maggi-noodles',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[1],
      ),
      Price(
        id: 7,
        productId: 2,
        retailerId: 2,
        price: 4.20,
        productUrl: 'https://giant.com.my/maggi-noodles',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[1],
      ),
      Price(
        id: 10,
        productId: 2,
        retailerId: 5,
        price: 4.60,
        productUrl: 'https://lotuss.com.my/maggi-noodles',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[2],
        product: products[1],
      ),

      // Teh Tarik Mix prices
      Price(
        id: 11,
        productId: 3,
        retailerId: 1,
        price: 8.90,
        productUrl: 'https://mydin.com.my/teh-tarik-mix',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[2],
      ),
      Price(
        id: 12,
        productId: 3,
        retailerId: 2,
        price: 8.50,
        productUrl: 'https://giant.com.my/teh-tarik-mix',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[2],
      ),
      Price(
        id: 15,
        productId: 3,
        retailerId: 5,
        price: 8.60,
        productUrl: 'https://lotuss.com.my/teh-tarik-mix',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[2],
        product: products[2],
      ),

      // Beras Wangi prices
      Price(
        id: 16,
        productId: 4,
        retailerId: 1,
        price: 22.80,
        productUrl: 'https://mydin.com.my/beras-wangi',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[3],
      ),
      Price(
        id: 17,
        productId: 4,
        retailerId: 2,
        price: 21.50,
        productUrl: 'https://giant.com.my/beras-wangi',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[3],
      ),
      Price(
        id: 20,
        productId: 4,
        retailerId: 5,
        price: 23.20,
        productUrl: 'https://lotuss.com.my/beras-wangi',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[2],
        product: products[3],
      ),

      // Nescafé Gold prices
      Price(
        id: 24,
        productId: 6,
        retailerId: 1,
        price: 18.50,
        productUrl: 'https://mydin.com.my/nescafe-gold',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[4],
      ),
      Price(
        id: 25,
        productId: 6,
        retailerId: 2,
        price: 17.90,
        productUrl: 'https://giant.com.my/nescafe-gold',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[4],
      ),

      // Sunlight Dishwashing Liquid prices
      Price(
        id: 27,
        productId: 7,
        retailerId: 1,
        price: 6.80,
        productUrl: 'https://mydin.com.my/sunlight-dishwashing',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[0],
        product: products[5],
      ),
      Price(
        id: 28,
        productId: 7,
        retailerId: 2,
        price: 6.50,
        productUrl: 'https://giant.com.my/sunlight-dishwashing',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[1],
        product: products[5],
      ),
      Price(
        id: 29,
        productId: 7,
        retailerId: 5,
        price: 6.90,
        productUrl: 'https://lotuss.com.my/sunlight-dishwashing',
        scrapedAt: now,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        retailer: retailers[2],
        product: products[5],
      ),
    ];
  }

  // ============== SHOPPING ITEMS ==============
  /// Shopping items for the sample shopping list
  static final shoppingItems = [
    ShoppingItem(
      id: 1,
      shoppingListId: '1',
      productId: 1,
      name: 'Milo Activ-Go',
      quantity: 2,
      estimatedPrice: 11.99,
      isPurchased: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    ShoppingItem(
      id: 2,
      shoppingListId: '1',
      productId: 2,
      name: 'Maggi Noodles',
      quantity: 5,
      estimatedPrice: 4.20,
      isPurchased: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    ShoppingItem(
      id: 3,
      shoppingListId: '1',
      productId: 3,
      name: 'Teh Tarik Mix',
      quantity: 1,
      estimatedPrice: 8.50,
      isPurchased: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    ShoppingItem(
      id: 4,
      shoppingListId: '1',
      productId: 4,
      name: 'Beras Wangi',
      quantity: 1,
      estimatedPrice: 21.50,
      isPurchased: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    ShoppingItem(
      id: 5,
      shoppingListId: '1',
      productId: 6,
      name: 'Nescafé Gold',
      quantity: 2,
      estimatedPrice: 17.90,
      isPurchased: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ];

  // ============== SHOPPING LISTS ==============
  static final shoppingLists = [
    ShoppingList(
      id: 1,
      userId: 'user_1',
      name: 'Weekly Groceries',
      description: 'Weekly shopping list for home supplies',
      budget: 150.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
      items: shoppingItems,
    ),
    ShoppingList(
      id: 2,
      userId: 'user_1',
      name: 'Monthly Essentials',
      description: 'Monthly household essentials',
      budget: 300.0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      items: [
        ShoppingItem(
          id: 6,
          shoppingListId: '2',
          productId: 7,
          name: 'Sunlight Dishwashing Liquid',
          quantity: 3,
          estimatedPrice: 6.50,
          isPurchased: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
      ],
    ),
  ];

  // ============== BUDGET ==============
  static late Budget budget = _createBudget();

  /// Factory for creating budget with current dates
  static Budget _createBudget() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = now.month == 12
        ? DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1))
        : DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

    return Budget(
      id: 1,
      userId: 1,
      limit: 500.0,
      spent: 234.50,
      period: 'monthly',
      startDate: startDate,
      endDate: endDate,
      createdAt: startDate,
      updatedAt: now,
      history: [
        BudgetHistory(
          id: 1,
          budgetId: 1,
          amount: 89.90,
          type: 'expense',
          description: 'Weekly grocery shopping',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        BudgetHistory(
          id: 2,
          budgetId: 1,
          amount: 144.60,
          type: 'expense',
          description: 'Monthly household supplies',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  // ============== NOTIFICATIONS ==============
  static final notifications = <Notification>[];

  // ============== CONVENIENCE GETTERS ==============

  /// Get prices for a specific product
  static List<Price> getPricesForProduct(int productId) {
    return prices.where((price) => price.productId == productId).toList();
  }

  /// Get best (lowest) price for a product
  static Price? getBestPriceForProduct(int productId) {
    final productPrices = getPricesForProduct(productId);
    if (productPrices.isEmpty) return null;
    return productPrices.reduce((a, b) => a.price < b.price ? a : b);
  }

  /// Get product by ID
  static Product? getProductById(int id) {
    return products.cast<Product?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  /// Get retailer by ID
  static Retailer? getRetailerById(int id) {
    return retailers.cast<Retailer?>().firstWhere(
          (r) => r?.id == id,
          orElse: () => null,
        );
  }

  /// Get all products in a category (brand)
  static List<Product> getProductsByCategory(String category) {
    return products.where((p) => p.category == category).toList();
  }

  /// Get distinct brand categories
  static List<String> getCategories() {
    final categories = <String>{};
    for (final product in products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  /// Get all products of a specific product type
  static List<Product> getProductsByType(String productType) {
    return products.where((p) => p.productType == productType).toList();
  }

  /// Get distinct product types
  static List<String> getProductTypes() {
    final types = <String>{};
    for (final product in products) {
      if (product.productType.isNotEmpty) {
        types.add(product.productType);
      }
    }
    return types.toList();
  }

  /// Calculate total cost for a shopping list at a specific retailer
  static double calculateTotalAtRetailer(
      List<ShoppingItem> items, int retailerId) {
    double total = 0;
    for (final item in items) {
      final itemPrices = getPricesForProduct(item.productId ?? 0);
      final priceAtRetailer = itemPrices.firstWhere(
        (p) => p.retailerId == retailerId,
        orElse: () => itemPrices.isNotEmpty
            ? itemPrices.first
            : Price(
                id: 0,
                productId: item.productId ?? 0,
                retailerId: retailerId,
                price: item.estimatedPrice,
                productUrl: '',
                scrapedAt: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );
      total += priceAtRetailer.price * item.quantity;
    }
    return total;
  }

  /// Get all retailer totals for a shopping list with pricing info
  static Map<int, double> getAllRetailerTotals(List<ShoppingItem> items) {
    final totals = <int, double>{};
    for (final retailer in retailers) {
      totals[retailer.id] = calculateTotalAtRetailer(items, retailer.id);
    }
    return totals;
  }

  /// Get the best (cheapest) retailer for a shopping list
  static Retailer? getBestRetailerForList(List<ShoppingItem> items) {
    if (items.isEmpty || retailers.isEmpty) return null;

    final totals = getAllRetailerTotals(items);
    int? bestRetailerId;
    double? minTotal;

    totals.forEach((retailerId, total) {
      if (minTotal == null || total < minTotal!) {
        minTotal = total;
        bestRetailerId = retailerId;
      }
    });

    return bestRetailerId != null ? getRetailerById(bestRetailerId!) : null;
  }
}
