import 'package:flutter_test/flutter_test.dart';
import 'package:smartshopper_mobile/services/notification_service.dart';

void main() {
  test('createWeeklyDigestNotification includes period and savings', () {
    final notif = NotificationService.createWeeklyDigestNotification(
      id: 1,
      userId: 1,
      totalNotifications: 0,
      unreadNotifications: 0,
      priceAlerts: 0,
      promotions: 0,
      budgetAlerts: 0,
      shoppingReminders: 0,
      period: '2026-06-12—2026-06-18',
      summaryText: '3 items dropped this week — estimated savings RM12.40',
      totalEstimatedSavings: 12.4,
    );

    expect(notif.title, '📬 Weekly Digest — 2026-06-12—2026-06-18');
    expect(notif.message.contains('Estimated savings'), isTrue);
    expect(notif.message.contains('RM12.40'), isTrue);
  });
}
