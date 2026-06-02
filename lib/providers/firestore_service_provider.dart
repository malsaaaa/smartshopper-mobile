import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/firestore_shopping_list_service.dart';
import 'package:smartshopper_mobile/services/firestore_user_service.dart';

/// Firestore User Service Provider
final firestoreUserServiceProvider = Provider<FirestoreUserService>((ref) {
  return FirestoreUserService();
});

/// Firestore Shopping List Service Provider
final firestoreShoppingListServiceProvider =
    Provider<FirestoreShoppingListService>((ref) {
  return FirestoreShoppingListService();
});
