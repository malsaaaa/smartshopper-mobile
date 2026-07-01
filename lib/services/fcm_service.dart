import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartshopper_mobile/data/models/notification.dart' as notif;
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
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

  NotificationPreferences _preferences = NotificationPreferences.defaults();

  // ============== INITIALIZATION ==============

  /// Initialize FCM and local notifications
  /// Note: FCM only works on Android/iOS, skipped on web platforms
  Future<void> initialize({
    required Function(String? route, Map<String, dynamic>? data)? onTap,
    required Function(notif.Notification)? onNotificationReceived,
    required NotificationPreferences preferences,
  }) async {
    // Skip FCM initialization on web platforms
    if (kIsWeb) {
      print('⚠️  FCM skipped on web platform. Only Android/iOS supported.');
      return;
    }
    
    _firebaseMessaging = FirebaseMessaging.instance;
    onNotificationTap = onTap;
    this.onNotificationReceived = onNotificationReceived;
    _preferences = preferences;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get initial token (permissions requested separately on login)
    final token = await _firebaseMessaging.getToken();
    print('🔐 FCM Token: $token');

    // Sync topic subscriptions to the current preference state
    await _syncTopicSubscriptions();

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

  /// Update the in-memory preferences and resync topic subscriptions.
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _preferences = preferences;
    if (!kIsWeb) {
      await _syncTopicSubscriptions();
    }
  }

  Future<void> _syncTopicSubscriptions() async {
      if (_preferences.priceAlerts) {
        await _syncTopics(['price_alerts'], subscribe: true);
      } else {
        await _syncTopics(['price_alerts'], subscribe: false);
      }

    if (_preferences.pushNotifications) {
      await _syncTopics(
        ['discounts', 'deals', 'promotions'],
        subscribe: _preferences.promotions,
      );
      await _syncTopics(
        ['budget_alerts'],
        subscribe: _preferences.budgetAlerts,
      );
      await _syncTopics(
        ['shopping_reminders'],
        subscribe: _preferences.shoppingReminders,
      );
      await _syncTopics(
        ['weekly_digest'],
        subscribe: _preferences.weeklyDigest,
      );
    } else {
      await _syncTopics(
        [
          'discounts',
          'deals',
          'promotions',
          'price_alerts',
          'budget_alerts',
          'shopping_reminders',
          'weekly_digest',
        ],
        subscribe: false,
      );
    }
  }

  Future<void> _syncTopics(List<String> topics, {required bool subscribe}) async {
    for (final topic in topics) {
      if (subscribe) {
        await subscribeToTopic(topic);
      } else {
        await unsubscribeFromTopic(topic);
      }
    }
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

  /// Request notification permissions from the user (called on login)
  Future<void> requestNotificationPermission() async {
    if (kIsWeb) return;
    await _requestPermissions();
  }

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
    final type = message.data['type']?.toString();
    if (!_preferences.allowsNotificationType(type)) {
      print('🔕 Notification suppressed by preferences: $type');
      return;
    }

    print('📩 Foreground Message:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Create in-app notification using a typed-safe builder.
    final notification = _buildInAppNotification(message);
    
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
    final type = message.data['type']?.toString();
    if (!_preferences.allowsNotificationType(type)) {
      return;
    }

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

  notif.Notification _buildInAppNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString() ?? 'system';
    final userId = _parseInt(data['userId']) ?? 0;
    final productId = _readString(data['productId']);
    final productName = _readString(data['productName']);
    final productImage = _readString(data['productImage']);
    final retailer = _readString(data['retailer']);
    final oldPrice = _parseDouble(data['oldPrice']);
    final newPrice = _parseDouble(data['newPrice']);
    final discountPercentage = _parseInt(data['discountPercentage']);
    final expiresAt = _parseDateTime(data['discountExpiresAt']);
    final actionUrl = _readString(data['actionUrl']);
    final id = DateTime.now().millisecondsSinceEpoch;

    if (type == 'price_drop' &&
        productId != null &&
        productName != null &&
        retailer != null &&
        oldPrice != null &&
        newPrice != null) {
      return NotificationService.createPriceDropNotification(
        id: id,
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        oldPrice: oldPrice,
        newPrice: newPrice,
        retailer: retailer,
        expiresAt: expiresAt,
        actionUrl: actionUrl,
      );
    }

    if (type == 'price_target' &&
        productId != null &&
        productName != null &&
        retailer != null &&
        newPrice != null) {
      return NotificationService.createPriceTargetNotification(
        id: id,
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        currentPrice: newPrice,
        targetPrice: oldPrice ?? newPrice,
        retailer: retailer,
        actionUrl: actionUrl,
      );
    }

    if (type == 'new_discount' &&
        productId != null &&
        productName != null &&
        retailer != null &&
        newPrice != null) {
      return NotificationService.createNewDiscountNotification(
        id: id,
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        currentPrice: oldPrice ?? newPrice,
        discountedPrice: newPrice,
        retailer: retailer,
        expiresAt: expiresAt,
        actionUrl: actionUrl,
      );
    }

    return notif.Notification(
      id: id,
      userId: userId,
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      retailer: retailer,
      oldPrice: oldPrice,
      newPrice: newPrice,
      discountPercentage: discountPercentage,
      discountExpiresAt: expiresAt,
      actionUrl: actionUrl,
    );
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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
