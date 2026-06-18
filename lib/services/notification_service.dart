import 'package:smartshopper_mobile/data/models/notification.dart' as notif;
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Create a budget alert notification when a budget is near or over limit.
  static notif.Notification createBudgetAlertNotification({
    required int id,
    required int userId,
    required double spent,
    required double limit,
    required bool exceeded,
  }) {
    final percentageUsed = limit > 0 ? ((spent / limit) * 100).clamp(0, 999).toStringAsFixed(0) : '0';

    return notif.Notification(
      id: id,
      userId: userId,
      title: exceeded ? '⚠️ Budget Exceeded' : '📊 Budget Warning',
      message: exceeded
          ? 'You have spent RM${spent.toStringAsFixed(2)} of your RM${limit.toStringAsFixed(2)} budget.'
          : 'You have used $percentageUsed% of your RM${limit.toStringAsFixed(2)} budget.',
      type: 'budget_alert',
      createdAt: DateTime.now(),
      oldPrice: limit,
      newPrice: spent,
    );
  }

  /// Create a weekly digest notification summarizing activity.
  static notif.Notification createWeeklyDigestNotification({
    required int id,
    required int userId,
    required int totalNotifications,
    required int unreadNotifications,
    required int priceAlerts,
    required int promotions,
    required int budgetAlerts,
    required int shoppingReminders,
    // Optional richer fields
    String? period,
    String? summaryText,
    double? totalEstimatedSavings,
  }) {
    final message = summaryText ??
        'This week: $totalNotifications notifications, $unreadNotifications unread, $priceAlerts price alerts, $promotions promotions, $budgetAlerts budget alerts, $shoppingReminders reminders.';

    final title = period != null ? '📬 Weekly Digest — $period' : '📬 Weekly Digest';

    // Append simple savings if provided
    final enrichedMessage = totalEstimatedSavings != null
        ? '$message\nEstimated savings: RM${totalEstimatedSavings.toStringAsFixed(2)}'
        : message;

    return notif.Notification(
      id: id,
      userId: userId,
      title: title,
      message: enrichedMessage,
      type: 'weekly_digest',
      createdAt: DateTime.now(),
    );
  }

  /// Build a weekly digest by aggregating recent price changes from Firestore.
  /// Returns a `Notification` suitable for adding to the in-app list.
  static Future<notif.Notification> buildWeeklyDigestFromFirestore({
    required int id,
    required int userId,
    Duration period = const Duration(days: 7),
    int maxTopItems = 5,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(period);
    final firestore = FirebaseFirestore.instance;

    // Query prices updated in the period
    final recentSnapshot = await firestore
        .collection('prices')
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final List<Map<String, dynamic>> drops = [];
    double totalEstimatedSavings = 0.0;

    for (final doc in recentSnapshot.docs) {
      final data = doc.data();
      final productId = data['productId']?.toString();
      if (productId == null) continue;

      final newPrice = (data['price'] as num?)?.toDouble() ?? 0.0;

      // Find most recent price before the period start
      final prevQ = await firestore
          .collection('prices')
          .where('productId', isEqualTo: productId)
          .where('updatedAt', isLessThan: Timestamp.fromDate(start))
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (prevQ.docs.isEmpty) continue;

      final prevData = prevQ.docs.first.data();
      final prevPrice = (prevData['price'] as num?)?.toDouble() ?? 0.0;
      if (prevPrice <= newPrice) continue; // not a drop

      final dropAmount = prevPrice - newPrice;
      final dropPercent = prevPrice > 0 ? ((dropAmount / prevPrice) * 100).round() : 0;

      // Attempt to resolve product name and retailer
      String productName = productId;
      try {
        final prodDoc = await firestore.collection('products').doc(productId).get();
        if (prodDoc.exists) productName = (prodDoc.data()?['name'] as String?) ?? productName;
      } catch (_) {}

      String retailerName = (data['retailerId']?.toString() ?? '') ;
      try {
        final retDoc = await firestore.collection('retailers').doc(data['retailerId']?.toString() ?? '').get();
        if (retDoc.exists) retailerName = (retDoc.data()?['name'] as String?) ?? retailerName;
      } catch (_) {}

      drops.add({
        'productId': productId,
        'productName': productName,
        'retailer': retailerName,
        'oldPrice': prevPrice,
        'newPrice': newPrice,
        'dropAmount': dropAmount,
        'dropPercent': dropPercent,
        'productUrl': data['productUrl'] as String? ?? '',
      });

      totalEstimatedSavings += dropAmount;
    }

    // Sort by drop amount descending and pick top items
    drops.sort((a, b) => (b['dropAmount'] as double).compareTo(a['dropAmount'] as double));
    final topPriceDrops = drops.take(maxTopItems).toList();

    final periodLabel = '${start.toIso8601String().split('T').first}—${now.toIso8601String().split('T').first}';
    final summaryText = topPriceDrops.isNotEmpty
        ? '${topPriceDrops.length} items dropped this week — estimated savings RM${totalEstimatedSavings.toStringAsFixed(2)}'
        : 'No notable price drops in the past ${period.inDays} days.';

    // Construct a digest notification (message contains human summary; app can fetch richer details from Firestore if needed)
    return createWeeklyDigestNotification(
      id: id,
      userId: userId,
      totalNotifications: 0,
      unreadNotifications: 0,
      priceAlerts: 0,
      promotions: 0,
      budgetAlerts: 0,
      shoppingReminders: 0,
      period: periodLabel,
      summaryText: summaryText,
      totalEstimatedSavings: totalEstimatedSavings,
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
      case 'weekly_digest':
        return '📬';
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
