/// Notifications State Management with Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/notification_service.dart';

// ============== STATE PROVIDERS ==============

/// All notifications (reactive)
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<Notification>>((ref) {
  return NotificationsNotifier();
});

/// Unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

/// Unread notifications only
final unreadNotificationsProvider = Provider<List<Notification>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).toList();
});

/// Discount notifications only
final discountNotificationsProvider = Provider<List<Notification>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications
      .where((n) => NotificationService.isDiscountNotification(n))
      .toList();
});

/// Notification frequency preference (real-time, daily, or weekly)
final notificationFrequencyProvider =
    StateProvider<String>((ref) => 'real-time'); // 'real-time', 'daily', 'weekly'

/// Enable/disable discount notifications
final discountNotificationsEnabledProvider =
    StateProvider<bool>((ref) => true);

// ============== STATE NOTIFIER ==============

class NotificationsNotifier extends StateNotifier<List<Notification>> {
  NotificationsNotifier() : super(const []);

  /// Create and add a discount notification
  void addDiscountNotification({
    required String type, // 'price_drop', 'new_discount', 'price_target'
    required int userId,
    required String productId,
    required String productName,
    String? productImage,
    required double? oldPrice,
    required double newPrice,
    required String retailer,
    DateTime? expiresAt,
    String? actionUrl,
  }) {
    final id = state.isNotEmpty ? state.first.id + 1 : 1;

    late Notification notification;

    switch (type) {
      case 'price_drop':
        notification = NotificationService.createPriceDropNotification(
          id: id,
          userId: userId,
          productId: productId,
          productName: productName,
          productImage: productImage,
          oldPrice: oldPrice ?? newPrice,
          newPrice: newPrice,
          retailer: retailer,
          expiresAt: expiresAt,
          actionUrl: actionUrl,
        );
        break;
      case 'new_discount':
        notification = NotificationService.createNewDiscountNotification(
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
        break;
      case 'price_target':
        notification = NotificationService.createPriceTargetNotification(
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
        break;
      default:
        return;
    }

    state = [notification, ...state];
  }

  /// Create and add a time-limited deal notification
  void addTimeLimitedDealNotification({
    required int userId,
    required String productId,
    required String productName,
    String? productImage,
    required double originalPrice,
    required double dealPrice,
    required String retailer,
    required DateTime expiresAt,
    String? actionUrl,
  }) {
    final id = state.isNotEmpty ? state.first.id + 1 : 1;
    final notification = NotificationService.createTimeLimitedDealNotification(
      id: id,
      userId: userId,
      productId: productId,
      productName: productName,
      productImage: productImage,
      originalPrice: originalPrice,
      dealPrice: dealPrice,
      retailer: retailer,
      expiresAt: expiresAt,
      actionUrl: actionUrl,
    );
    state = [notification, ...state];
  }

  /// Create and add a flash sale notification
  void addFlashSaleNotification({
    required int userId,
    required String productId,
    required String productName,
    String? productImage,
    required double salePrice,
    required String retailer,
    required DateTime endsAt,
    String? actionUrl,
  }) {
    final id = state.isNotEmpty ? state.first.id + 1 : 1;
    final notification = NotificationService.createFlashSaleNotification(
      id: id,
      userId: userId,
      productId: productId,
      productName: productName,
      productImage: productImage,
      salePrice: salePrice,
      retailer: retailer,
      endsAt: endsAt,
      actionUrl: actionUrl,
    );
    state = [notification, ...state];
  }

  /// Mark notification as read
  void markAsRead(int notificationId) {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          )
        else
          notification,
    ];
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    state = [
      for (final notification in state)
        notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        ),
    ];
  }

  /// Delete notification
  void deleteNotification(int notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
  }

  /// Clear all read notifications
  void clearReadNotifications() {
    state = state.where((n) => !n.isRead).toList();
  }

  /// Add new notification (for testing)
  void addNotification(Notification notification) {
    state = [notification, ...state];
  }

  /// Add a weekly digest notification summarizing recent activity.
  Future<void> addWeeklyDigestNotification({
    required int userId,
  }) async {
    final id = state.isNotEmpty ? state.first.id + 1 : 1;
    final unreadNotifications = state.where((n) => !n.isRead).length;
    final priceAlerts = state.where((n) => n.type == 'price_drop' || n.type == 'price_target').length;
    final promotions = state.where((n) => n.type == 'new_discount' || n.type == 'deal').length;
    final budgetAlerts = state.where((n) => n.type == 'budget_alert').length;
    final shoppingReminders = state.where((n) => n.type == 'system').length;

    // Build a richer digest by aggregating price changes from Firestore.
    try {
      final digest = await NotificationService.buildWeeklyDigestFromFirestore(
        id: id,
        userId: userId,
      );

      // If needed, we can enrich counts from local state as well by copying message
      state = [digest, ...state];
    } catch (e) {
      // Fallback to local summary if Firestore aggregation fails
      final digest = NotificationService.createWeeklyDigestNotification(
        id: id,
        userId: userId,
        totalNotifications: state.length,
        unreadNotifications: unreadNotifications,
        priceAlerts: priceAlerts,
        promotions: promotions,
        budgetAlerts: budgetAlerts,
        shoppingReminders: shoppingReminders,
      );
      state = [digest, ...state];
    }
  }
}

