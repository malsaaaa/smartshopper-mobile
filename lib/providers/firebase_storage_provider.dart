import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/firebase_storage_service.dart';

/// Provider for Firebase Storage Service
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});
