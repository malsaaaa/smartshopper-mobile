import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshopper_mobile/data/models/index.dart';
import 'package:smartshopper_mobile/services/firestore_budget_service.dart';
import 'package:smartshopper_mobile/providers/firestore_auth_provider.dart';

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
  final FirestoreBudgetService _service;

  BudgetNotifier(this._service) : super(const AsyncValue.loading()) {
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
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update budget limit
  Future<void> updateBudgetLimit(double newLimit) async {
    try {
      await _service.updateBudgetLimit(newLimit);
      await refreshBudget();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Budget Notifier Provider
final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  // Watch auth state to ensure notifier re-initializes on login/logout
  ref.watch(currentUserIdProvider);
  
  final service = ref.watch(firestoreBudgetServiceProvider);
  return BudgetNotifier(service);
});
