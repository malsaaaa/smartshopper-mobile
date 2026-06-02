/// BudgetHistory model tracking budget transactions
class BudgetHistory {
  final int id;
  final int budgetId;
  final double amount;
  final String type; // 'expense' or 'income'
  final String description;
  final DateTime createdAt;

  BudgetHistory({
    required this.id,
    required this.budgetId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  /// Factory constructor for creating from JSON
  factory BudgetHistory.fromJson(Map<String, dynamic> json) {
    return BudgetHistory(
      id: json['id'] as int,
      budgetId: json['budgetId'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budgetId': budgetId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'BudgetHistory(id: $id, type: $type, amount: RM${amount.toStringAsFixed(2)}, desc: $description)';
}

/// Budget model representing a user's spending budget
class Budget {
  final int id;
  final int userId;
  final double limit;
  final double spent;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BudgetHistory> history;

  Budget({
    required this.id,
    required this.userId,
    required this.limit,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
  });

  /// Calculate remaining budget
  double get remaining {
    return (limit - spent).clamp(0.0, double.infinity);
  }

  /// Calculate budget percentage used (0.0 to 1.0)
  double get percentageUsed {
    return (spent / limit).clamp(0.0, 1.0);
  }

  /// Check if budget is exceeded
  bool get isExceeded {
    return spent > limit;
  }

  /// Calculate days remaining in budget period
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Calculate remaining days for budget period
  int get totalDaysInPeriod {
    return endDate.difference(startDate).inDays;
  }

  /// Factory constructor for creating from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int,
      userId: json['userId'] as int,
      limit: (json['limit'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      period: json['period'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      history: (json['history'] as List<dynamic>?)
              ?.map((h) => BudgetHistory.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'limit': limit,
      'spent': spent,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Budget(id: $id, limit: RM${limit.toStringAsFixed(2)}, spent: RM${spent.toStringAsFixed(2)}, remaining: RM${remaining.toStringAsFixed(2)})';
}
