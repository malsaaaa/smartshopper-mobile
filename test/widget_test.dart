import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartshopper_mobile/screens/profile/notifications_screen.dart';

void main() {
  testWidgets('notifications settings screen shows all functional toggles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotificationsScreen(),
        ),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);
    expect(find.text('Price Drop Alerts'), findsOneWidget);
    expect(find.text('Budget Alerts'), findsOneWidget);
    expect(find.text('Shopping Reminders'), findsOneWidget);
    expect(find.text('Promotional Offers'), findsOneWidget);
    expect(find.text('Weekly Digest'), findsOneWidget);

    await tester.tap(find.text('Push Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });
}
