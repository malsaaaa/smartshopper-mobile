/// Notifications State Management with Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/data/mock_data.dart';

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

// ============== STATE NOTIFIER ==============

class NotificationsNotifier extends StateNotifier<List<Notification>> {
  NotificationsNotifier() : super(MockData.notifications);

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
}
