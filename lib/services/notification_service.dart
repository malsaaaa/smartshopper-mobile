import 'package:smartshopper_mobile/data/models/notification.dart' as notif;

/// Notification Service for handling Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // ============== DISCOUNT NOTIFICATION FACTORY METHODS ==============

  /// Create a price drop notification
  static notif.Notification createPriceDropNotification({
    required int id,
    required int userId,
    required String productId,
    required String productName,
    required String? productImage,
    required double oldPrice,
    required double newPrice,
    required String retailer,
    DateTime? expiresAt,
    String? actionUrl,
  }) {
    final discountPercent = ((oldPrice - newPrice) / oldPrice * 100).round();
    
    return notif.Notification(
      id: id,
      userId: userId,
      title: '🎉 Price Drop! $productName',
      message: '$retailer: RM${newPrice.toStringAsFixed(2)} (was RM${oldPrice.toStringAsFixed(2)})',
      type: 'price_drop',
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      oldPrice: oldPrice,
      newPrice: newPrice,
      discountPercentage: discountPercent,
      retailer: retailer,
      discountExpiresAt: expiresAt,
      actionUrl: actionUrl,
    );
  }

  /// Create a new discount notification
  static notif.Notification createNewDiscountNotification({
    required int id,
    required int userId,
    required String productId,
    required String productName,
    required String? productImage,
    required double currentPrice,
    required double discountedPrice,
    required String retailer,
    DateTime? expiresAt,
    String? actionUrl,
  }) {
    final discountPercent = ((currentPrice - discountedPrice) / currentPrice * 100).round();
    
    return notif.Notification(
      id: id,
      userId: userId,
      title: '🛍️ New Deal! $productName',
      message: '$retailer: $discountPercent% off - Now RM${discountedPrice.toStringAsFixed(2)}',
      type: 'new_discount',
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      oldPrice: currentPrice,
      newPrice: discountedPrice,
      discountPercentage: discountPercent,
      retailer: retailer,
      discountExpiresAt: expiresAt,
      actionUrl: actionUrl,
    );
  }

  /// Create a price target notification (when product reaches desired price)
  static notif.Notification createPriceTargetNotification({
    required int id,
    required int userId,
    required String productId,
    required String productName,
    required String? productImage,
    required double currentPrice,
    required double targetPrice,
    required String retailer,
    String? actionUrl,
  }) {
    return notif.Notification(
      id: id,
      userId: userId,
      title: '✅ Price Alert! $productName',
      message: '$retailer: Reached your target price of RM${currentPrice.toStringAsFixed(2)}',
      type: 'price_target',
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      oldPrice: targetPrice,
      newPrice: currentPrice,
      retailer: retailer,
      actionUrl: actionUrl,
    );
  }

  /// Create a time-limited deal notification
  static notif.Notification createTimeLimitedDealNotification({
    required int id,
    required int userId,
    required String productId,
    required String productName,
    required String? productImage,
    required double originalPrice,
    required double dealPrice,
    required String retailer,
    required DateTime expiresAt,
    String? actionUrl,
  }) {
    final discountPercent = ((originalPrice - dealPrice) / originalPrice * 100).round();
    final hoursRemaining = expiresAt.difference(DateTime.now()).inHours;
    
    return notif.Notification(
      id: id,
      userId: userId,
      title: '⏰ Limited Time Deal! $productName',
      message: '$retailer: $discountPercent% off - Only ${hoursRemaining}h left! RM${dealPrice.toStringAsFixed(2)}',
      type: 'new_discount',
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      oldPrice: originalPrice,
      newPrice: dealPrice,
      discountPercentage: discountPercent,
      retailer: retailer,
      discountExpiresAt: expiresAt,
      actionUrl: actionUrl,
    );
  }

  /// Create a flash sale notification
  static notif.Notification createFlashSaleNotification({
    required int id,
    required int userId,
    required String productId,
    required String productName,
    required String? productImage,
    required double salePrice,
    required String retailer,
    required DateTime endsAt,
    String? actionUrl,
  }) {
    return notif.Notification(
      id: id,
      userId: userId,
      title: '⚡ FLASH SALE! $productName',
      message: '$retailer: Ends in ${endsAt.difference(DateTime.now()).inMinutes} minutes - RM${salePrice.toStringAsFixed(2)}',
      type: 'new_discount',
      createdAt: DateTime.now(),
      productId: productId,
      productName: productName,
      productImage: productImage,
      newPrice: salePrice,
      retailer: retailer,
      discountExpiresAt: endsAt,
      actionUrl: actionUrl,
    );
  }

  // ============== NOTIFICATION HELPERS ==============

  /// Format time remaining for expiring discount
  static String formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) return 'Expired';
    if (difference.inMinutes < 1) return 'Expires soon';
    if (difference.inMinutes < 60) return 'Expires in ${difference.inMinutes}m';
    if (difference.inHours < 24) return 'Expires in ${difference.inHours}h';
    return 'Expires in ${difference.inDays}d';
  }

  /// Check if notification is a discount type
  static bool isDiscountNotification(notif.Notification notification) {
    return ['price_drop', 'new_discount', 'price_target'].contains(notification.type);
  }

  /// Get badge icon based on notification type
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'price_drop':
        return '📉';
      case 'new_discount':
        return '🎉';
      case 'price_target':
        return '✅';
      case 'budget_alert':
        return '⚠️';
      case 'deal':
        return '🛍️';
      default:
        return 'ℹ️';
    }
  }

  /// Simulate sending push notification (in production, use Firebase Cloud Messaging)
  Future<void> sendPushNotification({
    required String title,
    required String message,
    Map<String, String>? data,
  }) async {
    // In production, integrate with Firebase Cloud Messaging (FCM)
    // Example:
    // await FirebaseMessaging.instance.sendMulticast(...)
    
    print('📱 Push Notification Sent:');
    print('Title: $title');
    print('Message: $message');
    if (data != null) print('Data: $data');
  }
}
