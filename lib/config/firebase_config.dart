import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:smartshopper_mobile/data/models/notification.dart' as notif;
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
import 'package:smartshopper_mobile/services/fcm_service.dart';
import 'firebase_options.dart';

/// Initialize Firebase with platform-specific options
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Initialize Firebase Cloud Messaging
/// Note: FCM only works on Android/iOS, skipped on web platforms
Future<void> initializeFCM({
  required Function(String? route, Map<String, dynamic>? data)? onNotificationTap,
  required Function(notif.Notification)? onNotificationReceived,
  required NotificationPreferences preferences,
}) async {
  // Skip FCM initialization on web platforms
  if (kIsWeb) {
    print('⚠️  FCM skipped on web. Push notifications only work on Android/iOS.');
    return;
  }
  
  final fcmService = FCMService();
  await fcmService.initialize(
    onTap: onNotificationTap,
    onNotificationReceived: onNotificationReceived,
    preferences: preferences,
  );
}
