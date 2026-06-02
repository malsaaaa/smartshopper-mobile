/// Product model representing an item to be price-compared
class Product {
  final int id;
  final String name;
  final String description;
  final String category;     // Brand name (e.g., Nestlé, Faiza)
  final String productType;  // Product type (e.g., Drinks, Instant Noodles)
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.productType = '',
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] as int? ?? 0),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt']) 
          : (json['createdAt'] as dynamic),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.parse(json['updatedAt']) 
          : (json['updatedAt'] as dynamic),
    );
  }

  /// Factory constructor for creating from Firestore
  factory Product.fromFirestore(Map<String, dynamic> json, String docId) {
    return Product(
      id: int.tryParse(docId) ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'productType': productType,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Product(id: $id, name: $name, category: $category, productType: $productType)';
}
