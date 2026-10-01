import 'package:flutter_test/flutter_test.dart';
import 'package:aifinancify_flutter/models/transaction.dart';
import 'package:aifinancify_flutter/models/budget.dart';
import 'package:aifinancify_flutter/models/goal.dart';
import 'package:aifinancify_flutter/services/ml_prediction_service.dart';
import 'package:aifinancify_flutter/services/fraud_detection_service.dart';
import 'package:aifinancify_flutter/services/ai_assistant_service.dart';

void main() {
  group('TransactionModel Unit Tests', () {
    test('Correctly serializes and deserializes TransactionModel to/from JSON', () {
      final now = DateTime(2026, 8, 29, 10, 0, 0);
      final tx = TransactionModel(
        id: 101,
        amount: 250.75,
        description: 'Grocery Store Purchase',
        category: 'Groceries',
        type: 'expense',
        paymentMode: 'Card',
        date: now,
        riskScore: 0.1,
        riskReason: 'Normal transaction',
      );

      final json = tx.toJson();
      expect(json['id'], 101);
      expect(json['amount'], 250.75);
      expect(json['description'], 'Grocery Store Purchase');
      expect(json['category'], 'Groceries');
      expect(json['type'], 'expense');

      final fromJsonTx = TransactionModel.fromJson(json);
      expect(fromJsonTx.id, 101);
      expect(fromJsonTx.amount, 250.75);
      expect(fromJsonTx.description, 'Grocery Store Purchase');
      expect(fromJsonTx.category, 'Groceries');
      expect(fromJsonTx.merchant, 'Grocery Store Purchase');
    });
  });

  group('BudgetModel & GoalModel Unit Tests', () {
    test('BudgetModel correctly calculates percentage and limits', () {
      final budget = BudgetModel(
        id: 1,
        category: 'Dining',
        limit: 1000.0,
        spent: 750.0,
      );

      expect(budget.spent, 750.0);
      expect(budget.limit, 1000.0);
      expect(budget.percentageUsed, 75.0);
      expect(budget.remaining, 250.0);
    });

    test('GoalModel correctly parses and calculates target progress', () {
      final goal = GoalModel(
        id: 1,
        name: 'Emergency Fund',
        targetAmount: 50000.0,
        currentAmount: 20000.0,
        deadline: DateTime(2026, 12, 31),
      );

      expect(goal.progressPercentage, 40.0);
      expect(goal.remainingAmount, 30000.0);
      expect(goal.isCompleted, false);
    });
  });

  group('MLPredictionService Unit Tests', () {
    final mlService = MLPredictionService();

    test('Generates fallback predictions for empty transactions dataset', () async {
      final result = await mlService.predict([]);
      expect(result.cashFlowForecast.length, 6);
      expect(result.nextMonthExpense, 0.0);
      expect(result.insights.isNotEmpty, true);
    });

    test('Calculates time-series and trend forecast for historical expenses', () async {
      final transactions = List.generate(15, (index) {
        return TransactionModel(
          id: index,
          amount: 50.0 + (index * 10),
          category: 'Shopping',
          type: 'expense',
          date: DateTime.now().subtract(Duration(days: 15 - index)),
        );
      });

      final result = await mlService.predict(transactions);
      expect(result.cashFlowForecast.length, 6);
      expect(result.nextMonthExpense, greaterThan(0));
      expect(result.confidenceScore, greaterThan(0.5));
      expect(result.budgetRecommendation, greaterThan(0));
    });
  });

  group('FraudDetectionService Unit Tests', () {
    test('Correctly assesses normal transactions as low risk', () {
      final tx = TransactionModel(
        id: 1,
        amount: 15.0,
        description: 'Coffee Shop',
        category: 'Food & Dining',
        type: 'expense',
      );

      final result = FraudDetectionService.calculateFraudScore(tx, []);
      expect(result.riskLevel, 'low');
      expect(result.isFlagged, false);
    });

    test('Flags suspicious keywords as higher risk factor', () {
      final tx = TransactionModel(
        id: 2,
        amount: 8500.0,
        description: 'Unknown Exchange Wire Transfer',
        category: 'Transfer',
        type: 'expense',
      );

      final result = FraudDetectionService.calculateFraudScore(tx, []);
      expect(result.factors['suspiciousMerchant'], true);
      expect(result.riskScore, greaterThan(0.2));
    });
  });

  group('AIFinancialAssistant Unit Tests', () {
    final assistant = AIFinancialAssistant();

    test('Answers user chatbot questions intelligently', () async {
      final transactions = [
        TransactionModel(amount: 250, type: 'expense', category: 'Dining'),
      ];

      final reply = await assistant.generateResponse(
        userQuestion: "How much did I spend on dining?",
        transactions: transactions,
        budgets: [],
        goals: [],
        insights: [],
      );
      expect(reply.isNotEmpty, true);
      expect(reply.toLowerCase(), contains('dining'));
    });
  });
}
