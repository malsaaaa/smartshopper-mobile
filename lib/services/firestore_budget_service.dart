import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:smartshopper_mobile/data/models/index.dart';

/// Firestore Budget Service
/// Handles budget operations with Firestore backend
class FirestoreBudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Get budget collection reference for current user
  CollectionReference<Map<String, dynamic>> _getBudgetsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  /// Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get current month's budget
  Future<Budget?> getCurrentBudget() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = now.month == 12
          ? DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1))
          : DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

      // Get all budgets and filter in code to avoid needing a compound index
      final snapshot = await _getBudgetsCollection(userId).limit(100).get();

      // Find the budget for the current month
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final budgetStartDate = (data['startDate'] as Timestamp?)?.toDate();
        
        if (budgetStartDate != null &&
            budgetStartDate.year == now.year &&
            budgetStartDate.month == now.month) {
          return _buildBudget(doc);
        }
      }

      // Create default budget if none exists for this month
      return await _createDefaultBudget(userId, startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  /// Create a new budget
  Future<Budget> createBudget({
    required double limit,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final docRef = _getBudgetsCollection(userId).doc();

      final budget = Budget(
        id: docRef.id.hashCode,
        userId: userId.hashCode,
        limit: limit,
        spent: 0,
        period: period,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
        history: [],
      );

      await docRef.set({
        'limit': limit,
        'spent': 0,
        'period': period,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return budget;
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  /// Add expense to budget history
  Future<void> addExpense({
    required double amount,
    required String description,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final budget = await getCurrentBudget();
      if (budget == null) throw Exception('No budget found');

      // Find budget document by filtering in code
      final budgetDocs = await _getBudgetsCollection(userId).limit(100).get();
      DocumentSnapshot<Map<String, dynamic>>? budgetDoc;

      for (final doc in budgetDocs.docs) {
        final data = doc.data();
        final docStartDate = (data['startDate'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        
        if (docStartDate != null &&
            docStartDate.year == now.year &&
            docStartDate.month == now.month) {
          budgetDoc = doc;
          break;
        }
      }

      if (budgetDoc == null) throw Exception('Budget not found');

      final newSpent = (budget.spent) + amount;

      // Add to history
      await budgetDoc.reference.collection('history').add({
        'amount': amount,
        'type': 'expense',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update spent amount
      await budgetDoc.reference.update({
        'spent': newSpent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Update budget limit
  Future<void> updateBudgetLimit(double newLimit) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final budget = await getCurrentBudget();
      if (budget == null) throw Exception('No budget found');

      // Find budget document by filtering in code
      final budgetDocs = await _getBudgetsCollection(userId).limit(100).get();
      DocumentSnapshot<Map<String, dynamic>>? budgetDoc;

      for (final doc in budgetDocs.docs) {
        final data = doc.data();
        final docStartDate = (data['startDate'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        
        if (docStartDate != null &&
            docStartDate.year == now.year &&
            docStartDate.month == now.month) {
          budgetDoc = doc;
          break;
        }
      }

      if (budgetDoc == null) throw Exception('Budget not found');

      await budgetDoc.reference.update({
        'limit': newLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update budget limit: $e');
    }
  }

  /// Create default budget if none exists
  Future<Budget> _createDefaultBudget(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final now = DateTime.now();
      final docRef = _getBudgetsCollection(userId).doc();

      await docRef.set({
        'limit': 500.0,
        'spent': 0,
        'period': 'monthly',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Budget(
        id: docRef.id.hashCode,
        userId: userId.hashCode,
        limit: 500.0,
        spent: 0,
        period: 'monthly',
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
        history: [],
      );
    } catch (e) {
      throw Exception('Failed to create default budget: $e');
    }
  }

  /// Build Budget from Firestore document
  Budget _buildBudget(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Get history
    final historyList = <BudgetHistory>[];
    if (data['history'] is List) {
      final history = data['history'] as List<dynamic>;
      for (int i = 0; i < history.length; i++) {
        final item = history[i] as Map<String, dynamic>;
        historyList.add(
          BudgetHistory(
            id: i + 1,
            budgetId: doc.id.hashCode,
            amount: (item['amount'] ?? 0.0).toDouble(),
            type: item['type'] ?? 'expense',
            description: item['description'] ?? '',
            createdAt: (item['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }
    }

    return Budget(
      id: doc.id.hashCode,
      userId: data['userId'] as int? ?? 0,
      limit: (data['limit'] ?? 500.0).toDouble(),
      spent: (data['spent'] ?? 0.0).toDouble(),
      period: data['period'] ?? 'monthly',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      history: historyList,
    );
  }
}
