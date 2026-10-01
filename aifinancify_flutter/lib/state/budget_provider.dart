import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalBudgetLimit => _budgets.fold(0.0, (sum, b) => sum + b.limit);
  double get totalBudgetSpent => _budgets.fold(0.0, (sum, b) => sum + b.spent);

  Future<void> fetchBudgets([List<TransactionModel>? currentTransactions]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<BudgetModel> rawBudgets = [];
      try {
        rawBudgets = await _api.getBudgets();
        if (rawBudgets.isNotEmpty) {
          await _offline.saveLocalBudgets(rawBudgets);
        }
      } catch (_) {
        rawBudgets = await _offline.getLocalBudgets();
      }

      if (rawBudgets.isEmpty) {
        rawBudgets = await _offline.getLocalBudgets();
      }

      if (currentTransactions != null && currentTransactions.isNotEmpty) {
        final now = DateTime.now();
        final daysPassed = now.day.clamp(1, 31);
        final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final Map<String, double> categorySpent = {};

        for (var t in currentTransactions.where((t) =>
            t.type.toLowerCase() == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)) {
          final cat = (t.category ?? 'Other').toLowerCase();
          categorySpent[cat] = (categorySpent[cat] ?? 0.0) + t.amount;
        }

        _budgets = rawBudgets.map((b) {
          final cat = b.category.toLowerCase();
          final realSpent = categorySpent[cat] ?? b.spent;
          final realPredicted = ((realSpent / daysPassed) * totalDaysInMonth).roundToDouble();
          return BudgetModel(
            id: b.id,
            userId: b.userId,
            category: b.category,
            limit: b.limit,
            period: b.period,
            spent: realSpent,
            predicted: realPredicted,
            createdAt: b.createdAt,
            updatedAt: b.updatedAt,
          );
        }).toList();
      } else {
        _budgets = rawBudgets;
      }
    } catch (_) {
      _budgets = await _offline.getLocalBudgets();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BudgetModel> addBudget(BudgetModel budget) async {
    BudgetModel finalBudget = budget;
    try {
      final created = await _api.createBudget(budget);
      finalBudget = created;
    } catch (_) {
      finalBudget = BudgetModel(
        id: budget.id ?? DateTime.now().millisecondsSinceEpoch,
        userId: budget.userId,
        category: budget.category,
        limit: budget.limit,
        period: budget.period,
        spent: budget.spent,
      );
      await _offline.queueRequest(
        url: '/api/budgets',
        method: 'POST',
        body: budget.toJson(),
      );
    }

    _budgets.add(finalBudget);
    await _offline.saveLocalBudgets(_budgets);
    notifyListeners();
    return finalBudget;
  }

  Future<void> updateBudget(int id, Map<String, dynamic> updates) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index != -1) {
      final current = _budgets[index];
      _budgets[index] = BudgetModel(
        id: id,
        userId: current.userId,
        category: updates['name'] ?? updates['category'] ?? current.category,
        limit: updates['limit'] != null ? (updates['limit'] as num).toDouble() : current.limit,
        spent: current.spent,
      );
      await _offline.saveLocalBudgets(_budgets);
      notifyListeners();
    }

    try {
      await _api.updateBudget(id, updates);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/budgets/$id',
        method: 'PUT',
        body: updates,
      );
    }
  }

  Future<void> deleteBudget(int id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _offline.saveLocalBudgets(_budgets);
    notifyListeners();

    try {
      await _api.deleteBudget(id);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/budgets/$id',
        method: 'DELETE',
      );
    }
  }
}
