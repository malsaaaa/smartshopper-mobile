import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final bool pushNotifications;
  final bool priceAlerts;
  final bool budgetAlerts;
  final bool shoppingReminders;
  final bool promotions;
  final bool weeklyDigest;

  const NotificationPreferences({
    required this.pushNotifications,
    required this.priceAlerts,
    required this.budgetAlerts,
    required this.shoppingReminders,
    required this.promotions,
    required this.weeklyDigest,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      pushNotifications: true,
      priceAlerts: true,
      budgetAlerts: true,
      shoppingReminders: true,
      promotions: false,
      weeklyDigest: true,
    );
  }

  NotificationPreferences copyWith({
    bool? pushNotifications,
    bool? priceAlerts,
    bool? budgetAlerts,
    bool? shoppingReminders,
    bool? promotions,
    bool? weeklyDigest,
  }) {
    return NotificationPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      shoppingReminders: shoppingReminders ?? this.shoppingReminders,
      promotions: promotions ?? this.promotions,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
    );
  }

  bool allowsNotificationType(String? type) {
    final normalizedType = (type ?? '').toLowerCase();

    if (!pushNotifications) return false;
    if (normalizedType.isEmpty) return true;

    const priceAlertTypes = {'price_drop', 'price_target'};
    const promotionTypes = {'new_discount', 'time_limited_deal', 'flash_sale', 'deal'};
    const shoppingReminderTypes = {'shopping_reminder', 'shopping_reminders', 'system'};
    const budgetAlertTypes = {'budget_alert', 'budget'};
    const weeklyDigestTypes = {'weekly_digest', 'digest'};

    if (priceAlertTypes.contains(normalizedType)) return priceAlerts;
    if (promotionTypes.contains(normalizedType)) return promotions;
    if (shoppingReminderTypes.contains(normalizedType)) return shoppingReminders;
    if (budgetAlertTypes.contains(normalizedType)) return budgetAlerts;
    if (weeklyDigestTypes.contains(normalizedType)) return weeklyDigest;

    return true;
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(),
);

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  static const String _pushKey = 'notification_push_enabled';
  static const String _priceKey = 'notification_price_alerts';
  static const String _budgetKey = 'notification_budget_alerts';
  static const String _shoppingKey = 'notification_shopping_reminders';
  static const String _promotionsKey = 'notification_promotions';
  static const String _weeklyDigestKey = 'notification_weekly_digest';

  NotificationPreferencesNotifier() : super(NotificationPreferences.defaults()) {
    _load();
  }

  NotificationPreferences get currentPreferences => state;

  Future<void> loadFromStorage() async {
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      pushNotifications: prefs.getBool(_pushKey) ?? state.pushNotifications,
      priceAlerts: prefs.getBool(_priceKey) ?? state.priceAlerts,
      budgetAlerts: prefs.getBool(_budgetKey) ?? state.budgetAlerts,
      shoppingReminders: prefs.getBool(_shoppingKey) ?? state.shoppingReminders,
      promotions: prefs.getBool(_promotionsKey) ?? state.promotions,
      weeklyDigest: prefs.getBool(_weeklyDigestKey) ?? state.weeklyDigest,
    );
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> setPushNotifications(bool value) async {
    state = state.copyWith(pushNotifications: value);
    await _save(_pushKey, value);
  }

  Future<void> setPriceAlerts(bool value) async {
    state = state.copyWith(priceAlerts: value);
    await _save(_priceKey, value);
  }

  Future<void> setBudgetAlerts(bool value) async {
    state = state.copyWith(budgetAlerts: value);
    await _save(_budgetKey, value);
  }

  Future<void> setShoppingReminders(bool value) async {
    state = state.copyWith(shoppingReminders: value);
    await _save(_shoppingKey, value);
  }

  Future<void> setPromotions(bool value) async {
    state = state.copyWith(promotions: value);
    await _save(_promotionsKey, value);
  }

  Future<void> setWeeklyDigest(bool value) async {
    state = state.copyWith(weeklyDigest: value);
    await _save(_weeklyDigestKey, value);
  }
}
