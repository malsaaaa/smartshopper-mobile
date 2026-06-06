/// Notification model with support for discount notifications
class Notification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type; // 'price_drop', 'new_discount', 'price_target', 'budget_alert', 'deal', 'system'
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  
  // Discount notification specific fields
  final String? productId;
  final String? productName;
  final String? productImage;
  final double? oldPrice;
  final double? newPrice;
  final int? discountPercentage;
  final String? retailer;
  final DateTime? discountExpiresAt;
  final String? actionUrl;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.productId,
    this.productName,
    this.productImage,
    this.oldPrice,
    this.newPrice,
    this.discountPercentage,
    this.retailer,
    this.discountExpiresAt,
    this.actionUrl,
  });

  /// Calculate discount percentage if not provided
  int? get calculatedDiscount {
    if (discountPercentage != null) return discountPercentage;
    if (oldPrice != null && newPrice != null && oldPrice! > 0) {
      return ((oldPrice! - newPrice!) / oldPrice! * 100).round();
    }
    return null;
  }

  /// Check if discount is still valid
  bool get isDiscountValid {
    if (discountExpiresAt == null) return true;
    return DateTime.now().isBefore(discountExpiresAt!);
  }

  /// Factory constructor for creating from JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      productImage: json['productImage'] as String?,
      oldPrice: json['oldPrice'] as double?,
      newPrice: json['newPrice'] as double?,
      discountPercentage: json['discountPercentage'] as int?,
      retailer: json['retailer'] as String?,
      discountExpiresAt: json['discountExpiresAt'] != null 
          ? DateTime.parse(json['discountExpiresAt'] as String) 
          : null,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'discountPercentage': discountPercentage,
      'retailer': retailer,
      'discountExpiresAt': discountExpiresAt?.toIso8601String(),
      'actionUrl': actionUrl,
    };
  }

  /// Copy with modifications
  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? productId,
    String? productName,
    String? productImage,
    double? oldPrice,
    double? newPrice,
    int? discountPercentage,
    String? retailer,
    DateTime? discountExpiresAt,
    String? actionUrl,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      oldPrice: oldPrice ?? this.oldPrice,
      newPrice: newPrice ?? this.newPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      retailer: retailer ?? this.retailer,
      discountExpiresAt: discountExpiresAt ?? this.discountExpiresAt,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  @override
  String toString() =>
      'Notification(id: $id, title: $title, type: $type, productName: $productName, discount: ${calculatedDiscount}%)';
}
