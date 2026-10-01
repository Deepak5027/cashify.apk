import 'package:flutter_test/flutter_test.dart';
import 'package:aifinancify_flutter/models/transaction.dart';
import 'package:aifinancify_flutter/models/budget.dart';
import 'package:aifinancify_flutter/models/goal.dart';
import 'package:aifinancify_flutter/models/virtual_card.dart';
import 'package:aifinancify_flutter/models/invoice.dart';
import 'package:aifinancify_flutter/services/statement_pdf_service.dart';
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
      expect(result.nextMonthExpense, 0.0);
      expect(result.cashFlowForecast.length, 6);
      expect(result.overspendingRisk, 0.0);
    });

    test('Calculates time-series and trend forecast for historical expenses', () async {
      final txs = [
        TransactionModel(amount: 1200, category: 'Food', type: 'expense', date: DateTime(2026, 3, 15)),
        TransactionModel(amount: 1500, category: 'Food', type: 'expense', date: DateTime(2026, 4, 15)),
        TransactionModel(amount: 1800, category: 'Food', type: 'expense', date: DateTime(2026, 5, 15)),
        TransactionModel(amount: 2100, category: 'Food', type: 'expense', date: DateTime(2026, 6, 15)),
        TransactionModel(amount: 2400, category: 'Food', type: 'expense', date: DateTime(2026, 7, 15)),
      ];

      final result = await mlService.predict(txs);
      expect(result.nextMonthExpense, greaterThan(0.0));
      expect(result.cashFlowForecast.length, 6);
      expect(result.insights.isNotEmpty, true);
    });
  });

  group('FraudDetectionService Unit Tests', () {
    test('Correctly assesses normal transactions as low risk', () {
      final history = [
        TransactionModel(amount: 100, category: 'Food', date: DateTime(2026, 8, 1)),
        TransactionModel(amount: 150, category: 'Food', date: DateTime(2026, 8, 2)),
        TransactionModel(amount: 120, category: 'Food', date: DateTime(2026, 8, 3)),
        TransactionModel(amount: 130, category: 'Food', date: DateTime(2026, 8, 4)),
      ];

      final tx = TransactionModel(amount: 140, category: 'Food', date: DateTime(2026, 8, 5));
      final analysis = FraudDetectionService.calculateFraudScore(tx, history);

      expect(analysis.isFlagged, false);
      expect(analysis.riskScore, lessThan(0.4));
    });

    test('Flags suspicious keywords as higher risk factor', () {
      final history = [
        TransactionModel(amount: 500, category: 'General', date: DateTime(2026, 8, 1)),
      ];

      final tx = TransactionModel(amount: 500, description: 'Casino gamble betting', category: 'General', date: DateTime(2026, 8, 2));
      final analysis = FraudDetectionService.calculateFraudScore(tx, history);

      expect(analysis.riskScore, greaterThanOrEqualTo(0.2));
      expect(analysis.reasons.isNotEmpty, true);
    });
  });

  group('AIFinancialAssistant Unit Tests', () {
    final ai = AIFinancialAssistant();

    test('Answers user chatbot questions intelligently', () async {
      final transactions = [
        TransactionModel(amount: 5000, category: 'Salary', type: 'income', date: DateTime(2026, 8, 1)),
        TransactionModel(amount: 1200, category: 'Dining', type: 'expense', date: DateTime(2026, 8, 5)),
      ];

      final reply = await ai.generateResponse(
        userQuestion: 'How much did I spend this month?',
        transactions: transactions,
        budgets: [],
        goals: [],
        insights: [],
      );

      expect(reply.contains('Spending'), true);
      expect(reply.contains('1200'), true);
    });
  });

  group('VirtualCardModel & SubscriptionModel Unit Tests', () {
    test('VirtualCardModel computes remaining budget and spend percentage', () {
      final card = VirtualCardModel(
        id: 1,
        cardNumber: '•••• •••• •••• 1234',
        cardHolder: 'DEEPAK R',
        spendingLimit: 50000.0,
        currentSpend: 15000.0,
        isFrozen: false,
      );

      expect(card.remainingBudget, 35000.0);
      expect(card.spendPercentage, 0.30);
      expect(card.isFrozen, false);

      final json = card.toJson();
      final fromJson = VirtualCardModel.fromJson(json);
      expect(fromJson.cardNumber, '•••• •••• •••• 1234');
      expect(fromJson.spendingLimit, 50000.0);
      expect(fromJson.currentSpend, 15000.0);
    });

    test('VirtualCardModel supports multi-card wallet attributes and custom limits', () {
      final card = VirtualCardModel(
        id: 1,
        cardName: 'HDFC Regalia Gold',
        cardType: 'Credit Card',
        cardNetwork: 'VISA',
        bankName: 'HDFC Bank',
        cardNumber: '4532 9988 7766 1234',
        cardHolder: 'DEEPAK R',
        spendingLimit: 75000.0,
        currentSpend: 25000.0,
        isFrozen: false,
      );

      expect(card.remainingBudget, 50000.0);
      expect(card.spendPercentage, closeTo(0.333, 0.01));
      expect(card.cardName, 'HDFC Regalia Gold');
      expect(card.bankName, 'HDFC Bank');

      final json = card.toJson();
      final fromJson = VirtualCardModel.fromJson(json);
      expect(fromJson.cardName, 'HDFC Regalia Gold');
      expect(fromJson.cardNumber, '4532 9988 7766 1234');
      expect(fromJson.spendingLimit, 75000.0);
    });
  });

  group('InvoiceModel & StatementPdfService Unit Tests', () {
    test('InvoiceModel calculates subtotal, GST tax, and valid UPI payment link', () {
      final invoice = InvoiceModel(
        id: 1,
        invoiceNo: 'INV-2026-0001',
        clientName: 'Acme Corp',
        upiId: 'deepak@okaxis',
        taxRate: 18.0,
        items: [
          InvoiceItemModel(description: 'UI/UX Design', quantity: 1, unitPrice: 20000.0),
          InvoiceItemModel(description: 'Mobile App Architecture', quantity: 2, unitPrice: 15000.0),
        ],
      );

      expect(invoice.subtotal, 50000.0);
      expect(invoice.taxAmount, 9000.0);
      expect(invoice.calculatedTotal, 59000.0);
      expect(invoice.upiPaymentUrl.contains('upi://pay?pa=deepak%40okaxis'), true);
      expect(invoice.upiPaymentUrl.contains('59000.00'), true);
    });

    test('StatementPdfService renders valid HTML with totals and tables', () {
      final pdfService = StatementPdfService();
      final html = pdfService.buildFinancialStatementHtml(
        userName: 'Deepak R',
        currency: '₹',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 30),
        transactions: [
          TransactionModel(amount: 50000, type: 'income', category: 'Salary', date: DateTime(2026, 8, 1)),
          TransactionModel(amount: 12000, type: 'expense', category: 'Rent', date: DateTime(2026, 8, 5)),
        ],
        totalIncome: 50000.0,
        totalExpense: 12000.0,
        netBalance: 38000.0,
      );

      expect(html.contains('Official Financial Statement'), true);
      expect(html.contains('Deepak R'), true);
      expect(html.contains('38000.00'), true);
      expect(html.contains('Rent'), true);
    });

    test('StatementPdfService renders valid Expense Reimbursement Claim Slip', () {
      final pdfService = StatementPdfService();
      final html = pdfService.buildReimbursementSlipHtml(
        employeeName: 'Deepak R',
        purpose: 'Client Onsite Presentation & Travel',
        department: 'Engineering & Tech',
        currency: '₹',
        claimItems: [
          TransactionModel(amount: 1500.0, description: 'Flight Uber Cab', category: 'Travel', paymentMode: 'UPI', date: DateTime(2026, 8, 10)),
          TransactionModel(amount: 2800.0, description: 'Client Dinner Meeting', category: 'Food & Dining', paymentMode: 'Card', date: DateTime(2026, 8, 10)),
        ],
      );

      expect(html.contains('EXPENSE REIMBURSEMENT CLAIM'), true);
      expect(html.contains('Deepak R'), true);
      expect(html.contains('Engineering & Tech'), true);
      expect(html.contains('Client Onsite Presentation'), true);
      expect(html.contains('4300.00'), true);
      expect(html.contains('Employee Signature'), true);
      expect(html.contains('Approving Manager Signature'), true);
    });

    test('InvoiceModel serializes and deserializes correctly to/from JSON with items', () {
      final now = DateTime(2026, 8, 30);
      final invoice = InvoiceModel(
        id: 42,
        invoiceNo: 'INV-2026-0042',
        clientName: 'Google Cloud Partner',
        clientEmail: 'billing@client.com',
        clientPhone: '+91 9876543210',
        upiId: 'deepak@okaxis',
        issueDate: now,
        dueDate: now.add(const Duration(days: 15)),
        status: 'unpaid',
        taxRate: 18.0,
        notes: 'Net 15 payment terms apply',
        items: [
          InvoiceItemModel(description: 'Cloud Consulting', quantity: 10, unitPrice: 3500.0),
        ],
      );

      final json = invoice.toJson();
      expect(json['invoiceNo'], 'INV-2026-0042');
      expect(json['clientName'], 'Google Cloud Partner');
      expect(json['clientEmail'], 'billing@client.com');
      expect(json['taxRate'], 18.0);
      expect((json['items'] as List).length, 1);

      final fromJson = InvoiceModel.fromJson(json);
      expect(fromJson.id, 42);
      expect(fromJson.invoiceNo, 'INV-2026-0042');
      expect(fromJson.subtotal, 35000.0);
      expect(fromJson.taxAmount, 6300.0);
      expect(fromJson.calculatedTotal, 41300.0);
      expect(fromJson.status, 'unpaid');
    });
  });
}



