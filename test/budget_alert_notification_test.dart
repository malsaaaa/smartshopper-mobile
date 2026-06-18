import 'package:flutter_test/flutter_test.dart';
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
import 'package:smartshopper_mobile/services/notification_service.dart';

void main() {
  test('budget alerts are allowed only when budget alerts are enabled', () {
    final preferences = NotificationPreferences.defaults();

    expect(preferences.allowsNotificationType('budget_alert'), isTrue);

    final disabled = preferences.copyWith(budgetAlerts: false);
    expect(disabled.allowsNotificationType('budget_alert'), isFalse);
  });

  test('budget alert notification factory builds the expected payload', () {
    final exceededNotification = NotificationService.createBudgetAlertNotification(
      id: 11,
      userId: 77,
      spent: 510.00,
      limit: 500.00,
      exceeded: true,
    );

    expect(exceededNotification.type, 'budget_alert');
    expect(exceededNotification.title, contains('Budget Exceeded'));
    expect(exceededNotification.message, contains('RM510.00'));
    expect(exceededNotification.oldPrice, 500.00);
    expect(exceededNotification.newPrice, 510.00);
  });

  test('budget warning notification factory builds the expected payload', () {
    final warningNotification = NotificationService.createBudgetAlertNotification(
      id: 12,
      userId: 77,
      spent: 400.00,
      limit: 500.00,
      exceeded: false,
    );

    expect(warningNotification.type, 'budget_alert');
    expect(warningNotification.title, contains('Budget Warning'));
    expect(warningNotification.message, contains('80%'));
    expect(warningNotification.oldPrice, 500.00);
    expect(warningNotification.newPrice, 400.00);
  });
}
