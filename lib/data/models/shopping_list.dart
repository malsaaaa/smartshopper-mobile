/// ShoppingItem model representing an item in a shopping list
class ShoppingItem {
  final String? documentId; // Firestore document ID
  final int? id; // Legacy ID (optional)
  final String? shoppingListId;
  final int? productId;
  final String name;
  final int quantity;
  final double estimatedPrice;
  final bool isPurchased;
  final int? retailerId;
  final String? retailerName;
  final String? retailerLogoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItem({
    this.documentId,
    this.id,
    this.shoppingListId,
    this.productId,
    required this.name,
    required this.quantity,
    required this.estimatedPrice,
    this.isPurchased = false,
    this.retailerId,
    this.retailerName,
    this.retailerLogoUrl,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating from JSON
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      documentId: json['documentId'] as String?,
      id: json['id'] as int?,
      shoppingListId: json['shoppingListId'] as String?,
      productId: json['productId'] as int?,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      isPurchased: json['isPurchased'] as bool? ?? false,
      retailerId: json['retailerId'] as int?,
      retailerName: json['retailerName'] as String?,
      retailerLogoUrl: json['retailerLogoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] as DateTime 
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt'] as DateTime
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Factory constructor for creating from Firestore document
  factory ShoppingItem.fromFirestore(String documentId, Map<String, dynamic> json) {
    return ShoppingItem(
      documentId: documentId,
      productId: json['productId'] as int?,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      isPurchased: json['isPurchased'] as bool? ?? false,
      retailerId: json['retailerId'] is int ? json['retailerId'] as int : int.tryParse(json['retailerId']?.toString() ?? ''),
      retailerName: json['retailerName'] as String?,
      retailerLogoUrl: json['retailerLogoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'id': id,
      'shoppingListId': shoppingListId,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'estimatedPrice': estimatedPrice,
      'isPurchased': isPurchased,
      'retailerId': retailerId,
      'retailerName': retailerName,
      'retailerLogoUrl': retailerLogoUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'estimatedPrice': estimatedPrice,
      'isPurchased': isPurchased,
      'retailerId': retailerId,
      'retailerName': retailerName,
      'retailerLogoUrl': retailerLogoUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copy with modifications
  ShoppingItem copyWith({
    String? documentId,
    int? id,
    String? shoppingListId,
    int? productId,
    String? name,
    int? quantity,
    double? estimatedPrice,
    bool? isPurchased,
    int? retailerId,
    String? retailerName,
    String? retailerLogoUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isPurchased: isPurchased ?? this.isPurchased,
      retailerId: retailerId ?? this.retailerId,
      retailerName: retailerName ?? this.retailerName,
      retailerLogoUrl: retailerLogoUrl ?? this.retailerLogoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Safe string ID for Firestore operations.
  /// Prefers documentId (Firestore); falls back to legacy int id as string.
  /// Never returns the literal string "null".
  String get effectiveId => documentId ?? id?.toString() ?? '';

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, quantity: $quantity, retailer: $retailerName, purchased: $isPurchased)';
}

/// ShoppingList model representing a user's shopping list
class ShoppingList {
  final String? documentId; // Firestore document ID
  final int? id; // Legacy ID (optional)
  final String userId;
  final String name;
  final String? description;
  final double? budget;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShoppingItem> items;

  ShoppingList({
    this.documentId,
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.budget,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  /// Calculate total estimated cost
  double get totalEstimatedCost {
    return items.fold(0.0, (sum, item) => sum + (item.estimatedPrice * item.quantity));
  }

  /// Calculate budget remaining
  double? get budgetRemaining {
    if (budget == null) return null;
    return budget! - totalEstimatedCost;
  }

  /// Get count of purchased items
  int get purchasedItemsCount {
    return items.where((item) => item.isPurchased).length;
  }

  /// Get count of pending items
  int get pendingItemsCount {
    return items.where((item) => !item.isPurchased).length;
  }

  /// Factory constructor for creating from JSON
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as int?,
      documentId: json['documentId'] as String?,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] as DateTime 
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is DateTime
          ? json['updatedAt'] as DateTime
          : DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Factory constructor for creating from Firestore document
  factory ShoppingList.fromFirestore(String documentId, Map<String, dynamic> json) {
    return ShoppingList(
      documentId: documentId,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      items: [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'budget': budget,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'budget': budget,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copy with modifications
  ShoppingList copyWith({
    String? documentId,
    int? id,
    String? userId,
    String? name,
    String? description,
    double? budget,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShoppingItem>? items,
  }) {
    return ShoppingList(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  /// Safe string ID for Firestore operations.
  /// Prefers documentId (Firestore); falls back to legacy int id as string.
  /// Never returns the literal string "null".
  String get effectiveId => documentId ?? id?.toString() ?? '';

  @override
  String toString() =>
      'ShoppingList(id: $id, name: $name, items: ${items.length}, total: RM${totalEstimatedCost.toStringAsFixed(2)})';
}
