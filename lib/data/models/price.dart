import 'product.dart';
import 'retailer.dart';

/// Price model representing a product's price at a specific retailer
class Price {
  final int id;
  final int productId;
  final int retailerId;
  final double price;
  final String productUrl;
  final DateTime scrapedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Retailer? retailer;
  final Product? product;

  Price({
    required this.id,
    required this.productId,
    required this.retailerId,
    required this.price,
    required this.productUrl,
    required this.scrapedAt,
    required this.createdAt,
    required this.updatedAt,
    this.retailer,
    this.product,
  });

  /// Factory constructor for creating from JSON
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] as int? ?? 0),
      productId: json['productId'] is String ? int.tryParse(json['productId']) ?? 0 : (json['productId'] as int? ?? 0),
      retailerId: json['retailerId'] is String ? int.tryParse(json['retailerId']) ?? 0 : (json['retailerId'] as int? ?? 0),
      price: (json['price'] as num? ?? 0).toDouble(),
      productUrl: json['productUrl'] as String? ?? '',
      scrapedAt: json['scrapedAt'] is String ? DateTime.parse(json['scrapedAt']) : (json['scrapedAt'] as dynamic),
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : (json['createdAt'] as dynamic),
      updatedAt: json['updatedAt'] is String ? DateTime.parse(json['updatedAt']) : (json['updatedAt'] as dynamic),
      retailer: json['retailer'] != null
          ? Retailer.fromJson(json['retailer'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Factory constructor for creating from Firestore
  factory Price.fromFirestore(Map<String, dynamic> json, String docId) {
    return Price(
      id: 0, // Not strictly used for display
      productId: int.tryParse(json['productId']?.toString() ?? '') ?? 0,
      retailerId: int.tryParse(json['retailerId']?.toString() ?? '') ?? 0,
      price: (json['price'] as num? ?? 0).toDouble(),
      productUrl: json['productUrl'] as String? ?? '',
      scrapedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(), // Fallback
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'retailerId': retailerId,
      'price': price,
      'productUrl': productUrl,
      'scrapedAt': scrapedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retailer': retailer?.toJson(),
      'product': product?.toJson(),
    };
  }

  @override
  String toString() =>
      'Price(id: $id, price: RM${price.toStringAsFixed(2)}, retailer: ${retailer?.name})';

  Price copyWith({
    int? id,
    int? productId,
    int? retailerId,
    double? price,
    String? productUrl,
    DateTime? scrapedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Retailer? retailer,
    Product? product,
  }) {
    return Price(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      retailerId: retailerId ?? this.retailerId,
      price: price ?? this.price,
      productUrl: productUrl ?? this.productUrl,
      scrapedAt: scrapedAt ?? this.scrapedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retailer: retailer ?? this.retailer,
      product: product ?? this.product,
    );
  }
}
