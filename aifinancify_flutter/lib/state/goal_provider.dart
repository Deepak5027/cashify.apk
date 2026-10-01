import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class GoalProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();

  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalTargetAmount => _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
  double get totalSavedAmount => _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  Future<void> fetchGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteGoals = await _api.getGoals();
      if (remoteGoals.isNotEmpty) {
        _goals = remoteGoals;
        await _offline.saveLocalGoals(remoteGoals);
      } else {
        _goals = await _offline.getLocalGoals();
      }
    } catch (_) {
      _goals = await _offline.getLocalGoals();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GoalModel> addGoal(GoalModel goal) async {
    GoalModel finalGoal = goal;
    try {
      final created = await _api.createGoal(goal);
      finalGoal = created;
    } catch (_) {
      finalGoal = GoalModel(
        id: goal.id ?? DateTime.now().millisecondsSinceEpoch,
        userId: goal.userId,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        deadline: goal.deadline,
      );
      await _offline.queueRequest(
        url: '/api/goals',
        method: 'POST',
        body: goal.toJson(),
      );
    }

    _goals.add(finalGoal);
    await _offline.saveLocalGoals(_goals);
    notifyListeners();
    return finalGoal;
  }

  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final current = _goals[index];
      _goals[index] = GoalModel(
        id: id,
        userId: current.userId,
        name: updates['name'] ?? current.name,
        targetAmount: updates['target'] != null ? (updates['target'] as num).toDouble() : current.targetAmount,
        currentAmount: updates['saved'] != null
            ? (updates['saved'] as num).toDouble()
            : (updates['current_amount'] != null ? (updates['current_amount'] as num).toDouble() : current.currentAmount),
        deadline: current.deadline,
      );
      await _offline.saveLocalGoals(_goals);
      notifyListeners();
    }

    try {
      await _api.updateGoal(id, updates);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/goals/$id',
        method: 'PUT',
        body: updates,
      );
    }
  }

  Future<void> depositToGoal(int id, double depositAmount) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final goal = _goals[index];
      final newAmount = goal.currentAmount + depositAmount;
      await updateGoal(id, {'saved': newAmount, 'current_amount': newAmount});
    }
  }

  Future<void> deleteGoal(int id) async {
    _goals.removeWhere((g) => g.id == id);
    await _offline.saveLocalGoals(_goals);
    notifyListeners();

    try {
      await _api.deleteGoal(id);
    } catch (_) {
      await _offline.queueRequest(
        url: '/api/goals/$id',
        method: 'DELETE',
      );
    }
  }
}
