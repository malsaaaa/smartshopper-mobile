import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartshopper_mobile/data/models/notification.dart' as notif;
import 'package:smartshopper_mobile/services/notification_service.dart';

/// Firebase Cloud Messaging Service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;

  // Callback for notification taps
  late Function(String? route, Map<String, dynamic>? data)? onNotificationTap;
  
  // Callback for creating in-app notifications
  late Function(notif.Notification)? onNotificationReceived;

  // ============== INITIALIZATION ==============

  /// Initialize FCM and local notifications
  /// Note: FCM only works on Android/iOS, skipped on web platforms
  Future<void> initialize({
    required Function(String? route, Map<String, dynamic>? data)? onTap,
    required Function(notif.Notification)? onNotificationReceived,
  }) async {
    // Skip FCM initialization on web platforms
    if (kIsWeb) {
      print('⚠️  FCM skipped on web platform. Only Android/iOS supported.');
      return;
    }
    
    _firebaseMessaging = FirebaseMessaging.instance;
    onNotificationTap = onTap;
    this.onNotificationReceived = onNotificationReceived;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions
    await _requestPermissions();

    // Get initial token
    final token = await _firebaseMessaging.getToken();
    print('🔐 FCM Token: $token');

    // Subscribe to default topics
    await subscribeToTopic('discounts');
    await subscribeToTopic('deals');
    await subscribeToTopic('price_alerts');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap (from terminated state)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(_handleMessageTap);

    // Handle notification tap (from background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  // ============== LOCAL NOTIFICATIONS ==============

  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Android setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          onNotificationTap?.call(
            response.payload,
            null,
          );
        }
      },
    );

    // Create default notification channel (Android)
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ============== PERMISSIONS ==============

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification Permission: ${settings.authorizationStatus}');
  }

  // ============== MESSAGE HANDLERS ==============

  /// Handle messages received in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground Message:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Create in-app notification
    final notification = notif.Notification(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 0, // Will be set by the app
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      type: message.data['type'] as String? ?? 'system',
      isRead: false,
      createdAt: DateTime.now(),
      productId: message.data['productId'] as String?,
      productName: message.data['productName'] as String?,
      productImage: message.data['productImage'] as String?,
      retailer: message.data['retailer'] as String?,
      oldPrice: double.tryParse(message.data['oldPrice'] as String? ?? ''),
      newPrice: double.tryParse(message.data['newPrice'] as String? ?? ''),
      discountPercentage: int.tryParse(message.data['discountPercentage'] as String? ?? ''),
      discountExpiresAt: message.data['discountExpiresAt'] != null
          ? DateTime.tryParse(message.data['discountExpiresAt'] as String)
          : null,
    );
    
    // Add to in-app notification list
    onNotificationReceived?.call(notification);

    // Display notification
    await _displayNotification(message);
  }

  /// Handle messages received in background (top-level function)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📩 Background Message: ${message.notification?.title}');
    // This runs in a separate isolate, can't access context
    // Just log or store for later processing
  }

  /// Handle notification tap
  Future<void> _handleMessageTap(RemoteMessage? message) async {
    if (message == null) return;

    print('🔔 Notification Tapped: ${message.notification?.title}');

    final route = message.data['route'] as String?;
    final productId = message.data['productId'] as String?;

    // Navigate to appropriate screen
    if (route != null) {
      onNotificationTap?.call(route, message.data);
    } else if (productId != null) {
      onNotificationTap?.call(
        '/product-details',
        {'productId': productId, ...message.data},
      );
    }
  }

  // ============== DISPLAY NOTIFICATIONS ==============

  Future<void> _displayNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'SmartShopper',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: true,
        contentTitle: notification.title,
      ),
    );

    const ios = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'] ?? message.data['productId'],
    );
  }

  // ============== PUBLIC METHODS ==============

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from topic: $topic');
  }

  /// Send test discount notification
  static Future<void> sendTestDiscountNotification({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    // This is a client-side example
    // In production, send from backend/admin panel via Firebase Console or Admin SDK
    print('📤 Would send: $title - $body');
    print('📦 Data: $data');
  }

  /// Log user for analytics (optional)
  Future<void> logNotificationEvent(String eventName) async {
    // Can integrate with Analytics here
    print('📊 Event logged: $eventName');
  }
}
