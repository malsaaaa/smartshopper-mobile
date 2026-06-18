import 'package:flutter_test/flutter_test.dart';
import 'package:smartshopper_mobile/providers/notifications_provider.dart';

void main() {
  test('addWeeklyDigestNotification adds weekly_digest to state (fallback)', () async {
    final notifier = NotificationsNotifier();
    await notifier.addWeeklyDigestNotification(userId: 1);
    final first = notifier.state.first;
    expect(first.type, 'weekly_digest');
    expect(first.title.startsWith('📬 Weekly Digest'), isTrue);
  });
}
