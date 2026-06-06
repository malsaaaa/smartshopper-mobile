import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/services/fcm_service.dart';

/// FCM Service provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM Token provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return await fcmService.getToken();
});

/// Push notifications enabled provider
final pushNotificationsEnabledProvider = StateProvider<bool>((ref) => true);

/// Subscribed topics provider
final subscribedTopicsProvider = StateProvider<List<String>>((ref) => [
  'discounts',
  'deals',
  'price_alerts',
]);
