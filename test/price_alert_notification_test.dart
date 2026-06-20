import 'package:flutter_test/flutter_test.dart';
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
import 'package:smartshopper_mobile/services/notification_service.dart';

void main() {
  test('price alert notifications are allowed when price alerts are enabled', () {
    final preferences = NotificationPreferences.defaults();

    expect(preferences.allowsNotificationType('price_drop'), isTrue);
    expect(preferences.allowsNotificationType('price_target'), isTrue);
    expect(preferences.allowsNotificationType('new_discount'), isFalse);
  });

  test('price drop notification factory builds the expected payload', () {
    final notification = NotificationService.createPriceDropNotification(
      id: 1,
      userId: 42,
      productId: 'milo-001',
      productName: 'Milo Activ-Go 400g',
      productImage: 'assets/images/products/milo.png',
      oldPrice: 15.50,
      newPrice: 12.50,
      retailer: 'Mydin',
    );

    expect(notification.type, 'price_drop');
    expect(notification.title, contains('Price Drop'));
    expect(notification.newPrice, 12.50);
    expect(notification.oldPrice, 15.50);
    expect(notification.calculatedDiscount, 19);
  });

  test('price target notification factory builds the expected payload', () {
    final notification = NotificationService.createPriceTargetNotification(
      id: 2,
      userId: 42,
      productId: 'coffee-001',
      productName: 'Nescafe Gold',
      productImage: 'assets/images/products/nescafe.png',
      currentPrice: 9.99,
      targetPrice: 11.99,
      retailer: 'myAEON2go',
    );

    expect(notification.type, 'price_target');
    expect(notification.title, contains('Price Alert'));
    expect(notification.newPrice, 9.99);
    expect(notification.oldPrice, 11.99);
    expect(NotificationService.isDiscountNotification(notification), isTrue);
  });
}
