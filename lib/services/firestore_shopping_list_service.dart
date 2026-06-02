import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:smartshopper_mobile/data/models/index.dart';

/// Firestore Shopping List Service
/// Handles shopping list operations with Firestore backend
class FirestoreShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Get shopping lists collection reference for current user
  CollectionReference<Map<String, dynamic>> _getListsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('shoppingLists');
  }

  /// Get items subcollection for a shopping list
  CollectionReference<Map<String, dynamic>> _getItemsCollection(
    String userId,
    String listId,
  ) {
    return _getListsCollection(userId).doc(listId).collection('items');
  }

  /// Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get the active shopping list for the current user
  /// Creates a default active list if none exists
  Future<ShoppingList?> getActiveShoppingList() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) return null;

      final snapshot = await _getListsCollection(userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Create a default active shopping list
        return await createList(name: 'My Shopping List', isActive: true);
      }

      final doc = snapshot.docs.first;
      final shoppingList = ShoppingList.fromFirestore(doc.id, doc.data());

      // Load items
      final itemsSnapshot = await _getItemsCollection(userId, doc.id).get();
      final items = itemsSnapshot.docs
          .map((itemDoc) => ShoppingItem.fromFirestore(itemDoc.id, itemDoc.data()))
          .toList();

      return shoppingList.copyWith(items: items);
    } catch (e) {
      debugPrint('Error getting active shopping list: $e');
      return null;
    }
  }

  /// Get all shopping lists for current user
  Future<List<ShoppingList>> getAllLists() async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    try {
      final snapshot = await _getListsCollection(userId).get();
      final lists = <ShoppingList>[];

      for (final doc in snapshot.docs) {
        try {
          final list = ShoppingList.fromFirestore(doc.id, doc.data());
          lists.add(list);
        } catch (e) {
          // Skip malformed documents instead of failing the entire load
          debugPrint('⚠️ Skipping malformed list doc ${doc.id}: $e');
        }
      }

      return lists;
    } catch (e) {
      debugPrint('❌ Error getting shopping lists: $e');
      rethrow; // Propagate so provider can show error UI
    }
  }

  /// Get shopping list by ID
  Future<ShoppingList?> getListById(String listId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) return null;

      final doc = await _getListsCollection(userId).doc(listId).get();
      if (!doc.exists) return null;

      final shoppingList = ShoppingList.fromFirestore(doc.id, doc.data()!);

      // Load items
      final itemsSnapshot = await _getItemsCollection(userId, listId).get();
      final items = itemsSnapshot.docs
          .map((itemDoc) => ShoppingItem.fromFirestore(itemDoc.id, itemDoc.data()))
          .toList();

      return shoppingList.copyWith(items: items);
    } catch (e) {
      debugPrint('Error getting shopping list: $e');
      return null;
    }
  }

  /// Create new shopping list
  Future<ShoppingList> createList({
    required String name,
    String? description,
    double? budget,
    bool isActive = false,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final newList = ShoppingList(
        userId: userId,
        name: name,
        description: description,
        budget: budget,
        isActive: isActive,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _getListsCollection(userId).add(newList.toFirestore());
      return newList.copyWith(documentId: docRef.id);
    } catch (e) {
      debugPrint('Error creating shopping list: $e');
      rethrow;
    }
  }

  /// Update shopping list
  Future<void> updateList(
    String listId, {
    String? name,
    String? description,
    double? budget,
    bool? isActive,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (budget != null) updateData['budget'] = budget;
      if (isActive != null) updateData['isActive'] = isActive;

      await _getListsCollection(userId).doc(listId).update(updateData);
    } catch (e) {
      debugPrint('Error updating shopping list: $e');
      rethrow;
    }
  }

  /// Add item to shopping list
  Future<ShoppingItem> addItem(
    String listId, {
    required String name,
    required int quantity,
    required double estimatedPrice,
    int? productId,
    int? retailerId,
    String? retailerName,
    String? retailerLogoUrl,
    String? imageUrl,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final newItem = ShoppingItem(
        name: name,
        quantity: quantity,
        estimatedPrice: estimatedPrice,
        productId: productId,
        retailerId: retailerId,
        retailerName: retailerName,
        retailerLogoUrl: retailerLogoUrl,
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _getItemsCollection(userId, listId).add(newItem.toFirestore());
      return newItem.copyWith(documentId: docRef.id);
    } catch (e) {
      debugPrint('Error adding item: $e');
      rethrow;
    }
  }

  /// Update item in shopping list
  Future<void> updateItem(
    String listId,
    String itemId, {
    String? name,
    int? quantity,
    double? estimatedPrice,
    bool? isPurchased,
    String? retailerName,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (name != null) updateData['name'] = name;
      if (quantity != null) updateData['quantity'] = quantity;
      if (estimatedPrice != null) updateData['estimatedPrice'] = estimatedPrice;
      if (isPurchased != null) updateData['isPurchased'] = isPurchased;
      if (retailerName != null) updateData['retailerName'] = retailerName;

      await _getItemsCollection(userId, listId).doc(itemId).update(updateData);
    } catch (e) {
      debugPrint('Error updating item: $e');
      rethrow;
    }
  }

  /// Toggle purchase status of an item
  Future<void> toggleItemPurchased(String listId, String itemId, bool isPurchased) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      await _getItemsCollection(userId, listId).doc(itemId).update({
        'isPurchased': isPurchased,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error toggling item purchased: $e');
      rethrow;
    }
  }

  /// Delete item from shopping list
  Future<void> deleteItem(String listId, String itemId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      await _getItemsCollection(userId, listId).doc(itemId).delete();
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  /// Clear all purchased items from a shopping list
  Future<void> clearPurchasedItems(String listId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _getItemsCollection(userId, listId)
          .where('isPurchased', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing purchased items: $e');
      rethrow;
    }
  }

  /// Delete entire shopping list
  Future<void> deleteList(String listId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      // Delete all items first
      final itemsSnapshot = await _getItemsCollection(userId, listId).get();
      for (final doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the list
      await _getListsCollection(userId).doc(listId).delete();
    } catch (e) {
      debugPrint('Error deleting shopping list: $e');
      rethrow;
    }
  }
}
