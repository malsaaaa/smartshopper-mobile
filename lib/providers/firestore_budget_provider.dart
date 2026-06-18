import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/firestore_budget_service.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';
import 'package:smartshopper_mobile/providers/notification_preferences_provider.dart';
import 'package:smartshopper_mobile/providers/notifications_provider.dart';
import 'package:smartshopper_mobile/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firestore Budget Service Provider
final firestoreBudgetServiceProvider = Provider((ref) {
  return FirestoreBudgetService();
});

/// Current Budget Provider (reads from Firestore)
final currentBudgetProvider = FutureProvider<Budget?>((ref) async {
  final service = ref.watch(firestoreBudgetServiceProvider);
  return service.getCurrentBudget();
});

/// Budget Notifier for managing budget state
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final Ref _ref;
  final FirestoreBudgetService _service;
  static const String _budgetAlertLastSentAtKey = 'budget_alert_last_sent_at';

  BudgetNotifier(this._ref, this._service) : super(const AsyncValue.loading()) {
    _loadBudget();
  }

  /// Load current budget from Firestore
  Future<void> _loadBudget() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getCurrentBudget());
  }

  /// Refresh budget data
  Future<void> refreshBudget() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getCurrentBudget());
  }

  /// Create new budget
  Future<void> createBudget({
    required double limit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _service.createBudget(
        limit: limit,
        period: 'monthly',
        startDate: startDate,
        endDate: endDate,
      );
      await refreshBudget();
      final budget = state.valueOrNull;
      if (budget != null) {
        await _maybeSendBudgetAlert(budget);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Add expense to budget
  Future<void> addExpense({
    required double amount,
    required String description,
  }) async {
    try {
      await _service.addExpense(
        amount: amount,
        description: description,
      );
      await refreshBudget();
      final budget = state.valueOrNull;
      if (budget != null) {
        await _maybeSendBudgetAlert(budget);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update budget limit
  Future<void> updateBudgetLimit(double newLimit) async {
    try {
      await _service.updateBudgetLimit(newLimit);
      await refreshBudget();
      final budget = state.valueOrNull;
      if (budget != null) {
        await _maybeSendBudgetAlert(budget);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _maybeSendBudgetAlert(Budget budget) async {
    final preferences = _ref.read(notificationPreferencesProvider);
    if (!preferences.budgetAlerts) return;

    final alertNeeded = budget.isExceeded || budget.percentageUsed >= 0.8;
    if (!alertNeeded) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSentIso = prefs.getString(_budgetAlertLastSentAtKey);
    if (lastSentIso != null) {
      final lastSent = DateTime.tryParse(lastSentIso);
      if (lastSent != null && DateTime.now().difference(lastSent).inHours < 24) {
        return;
      }
    }

    final userIdString = _ref.read(currentUserIdProvider) ?? '';
    final notificationId = DateTime.now().millisecondsSinceEpoch;
    final notification = NotificationService.createBudgetAlertNotification(
      id: notificationId,
      userId: int.tryParse(userIdString) ?? 0,
      spent: budget.spent,
      limit: budget.limit,
      exceeded: budget.isExceeded,
    );

    _ref.read(notificationsProvider.notifier).addNotification(notification);
    await prefs.setString(_budgetAlertLastSentAtKey, DateTime.now().toIso8601String());
  }
}

/// Budget Notifier Provider
final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  // Watch auth state to ensure notifier re-initializes on login/logout
  ref.watch(currentUserIdProvider);
  
  final service = ref.watch(firestoreBudgetServiceProvider);
  return BudgetNotifier(ref, service);
});
