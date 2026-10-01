import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import '../services/fraud_detection_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalIncome => _transactions
      .where((t) => t.type.toLowerCase() == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type.toLowerCase() == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpense;

  Map<String, double> get categoryBreakdown {
    final Map<String, double> map = {};
    for (var t in _transactions.where((t) => t.type.toLowerCase() == 'expense')) {
      final cat = t.category ?? 'Other';
      map[cat] = (map[cat] ?? 0.0) + t.amount;
    }
    return map;
  }

  List<TransactionModel> get flaggedTransactions =>
      _transactions.where((t) => t.isHighRisk || t.isMediumRisk).toList();

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteTxs = await _api.getTransactions();
      if (remoteTxs.isNotEmpty) {
        _transactions = remoteTxs;
        await _offline.saveLocalTransactions(remoteTxs);
      } else {
        // If remote returned empty or failed, load from local storage
        final local = await _offline.getLocalTransactions();
        if (local.isNotEmpty) {
          _transactions = local;
        }
      }
    } catch (_) {
      // Network offline/timeout -> load from local SQLite storage
      final local = await _offline.getLocalTransactions();
      if (local.isNotEmpty) {
        _transactions = local;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    // Perform heuristic multi-factor fraud detection
    final fraudAnalysis = FraudDetectionService.calculateFraudScore(tx, _transactions);
    final scoredTx = TransactionModel(
      id: tx.id,
      userId: tx.userId,
      amount: tx.amount,
      description: tx.description,
      category: tx.category,
      type: tx.type,
      paymentMode: tx.paymentMode,
      isRecurring: tx.isRecurring,
      recurringPeriod: tx.recurringPeriod,
      nextRecurringDate: tx.nextRecurringDate,
      date: tx.date,
      riskScore: fraudAnalysis.riskScore,
      riskReason: fraudAnalysis.reasons.join(' | '),
    );

    TransactionModel finalTx = scoredTx;

    try {
      final created = await _api.createTransaction(scoredTx);
      finalTx = created;
    } catch (_) {
      // Offline fallback: assign local ID and queue request
      finalTx = TransactionModel(
        id: scoredTx.id ?? DateTime.now().millisecondsSinceEpoch,
        userId: scoredTx.userId,
        amount: scoredTx.amount,
        description: scoredTx.description,
        category: scoredTx.category,
        type: scoredTx.type,
        paymentMode: scoredTx.paymentMode,
        isRecurring: scoredTx.isRecurring,
        recurringPeriod: scoredTx.recurringPeriod,
        nextRecurringDate: scoredTx.nextRecurringDate,
        date: scoredTx.date,
        riskScore: scoredTx.riskScore,
        riskReason: scoredTx.riskReason,
      );

      await _offline.queueRequest(
        url: '/api/transactions',
        method: 'POST',
        body: finalTx.toJson(),
      );
    }

    // Always save to local storage and update in-memory UI immediately
    await _offline.insertLocalTransaction(finalTx);
    _transactions.removeWhere((t) => t.id == finalTx.id);
    _transactions.insert(0, finalTx);
    notifyListeners();

    return finalTx;
  }

  Future<void> updateTransaction(int id, Map<String, dynamic> updates) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _transactions[index];
      final updated = TransactionModel(
        id: id,
        userId: current.userId,
        amount: updates['amount'] != null ? (updates['amount'] as num).toDouble() : current.amount,
        description: updates['description'] ?? current.description,
        category: updates['category'] ?? current.category,
        type: updates['type'] ?? current.type,
        paymentMode: updates['paymentMode'] ?? current.paymentMode,
        date: current.date,
        riskScore: updates['riskScore'] != null
            ? (updates['riskScore'] as num).toDouble()
            : (updates['status'] == 'normal' ? 0.0 : current.riskScore),
        riskReason: updates['riskReason'] ?? (updates['status'] == 'normal' ? 'Verified safe by user' : current.riskReason),
      );
      _transactions[index] = updated;
      await _offline.insertLocalTransaction(updated);
      notifyListeners();
    }

    try {
      await _api.updateTransaction(id, updates);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/transactions/$id',
        method: 'PUT',
        body: updates,
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _offline.saveLocalTransactions(_transactions);
    notifyListeners();

    try {
      await _api.deleteTransaction(id);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/transactions/$id',
        method: 'DELETE',
      );
    }
  }

  Future<int> importBatch(List<Map<String, dynamic>> items) async {
    for (var item in items) {
      final tx = TransactionModel(
        amount: (item['amount'] as num).toDouble(),
        description: item['description'] ?? 'Imported Transaction',
        category: item['category'] ?? 'General',
        type: item['type'] ?? 'expense',
        paymentMode: item['paymentMode'] ?? 'Bank Transfer',
        date: item['date'] != null ? (DateTime.tryParse(item['date']) ?? DateTime.now()) : DateTime.now(),
      );
      await addTransaction(tx);
    }
    return items.length;
  }
}

