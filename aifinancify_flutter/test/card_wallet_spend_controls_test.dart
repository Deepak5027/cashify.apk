import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aifinancify_flutter/models/virtual_card.dart';
import 'package:aifinancify_flutter/models/spend_controls.dart';
import 'package:aifinancify_flutter/models/transaction.dart';
import 'package:aifinancify_flutter/state/virtual_card_provider.dart';
import 'package:aifinancify_flutter/services/card_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VirtualCardModel Tests', () {
    test('Extracts last 4 digits properly from formatted number', () {
      final card1 = VirtualCardModel(cardNumber: '•••• •••• •••• 4321');
      expect(card1.lastFourDigits, '4321');
      expect(card1.maskedCardNumber, '•••• •••• •••• 4321');

      final card2 = VirtualCardModel(cardNumber: '5241665544339876');
      expect(card2.lastFourDigits, '9876');
      expect(card2.maskedCardNumber, '•••• •••• •••• 9876');
    });

    test('Identifies card type correctly', () {
      final credit = VirtualCardModel(cardType: 'Credit Card');
      expect(credit.isCredit, isTrue);
      expect(credit.isDebit, isFalse);

      final debit = VirtualCardModel(cardType: 'Debit Card');
      expect(debit.isDebit, isTrue);
      expect(debit.isCredit, isFalse);

      final prepaid = VirtualCardModel(cardType: 'Virtual Prepaid');
      expect(prepaid.isPrepaid, isTrue);
    });

    test('Validates required fields and formatting correctly', () {
      // Valid inputs
      final validErrors = VirtualCardModel.validateFields(
        cardName: 'Salary Card',
        bankName: 'HDFC Bank',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '1234',
        expiryDate: '12/28',
      );
      expect(validErrors.isEmpty, isTrue);

      // Missing card nickname
      final missingName = VirtualCardModel.validateFields(
        cardName: '',
        bankName: 'HDFC Bank',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '1234',
      );
      expect(missingName.containsKey('cardName'), isTrue);

      // Missing bank name
      final missingBank = VirtualCardModel.validateFields(
        cardName: 'My Card',
        bankName: '   ',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '1234',
      );
      expect(missingBank.containsKey('bankName'), isTrue);

      // Non-4 digits for last 4
      final invalidLast4 = VirtualCardModel.validateFields(
        cardName: 'My Card',
        bankName: 'HDFC Bank',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '123', // only 3 digits
      );
      expect(invalidLast4.containsKey('lastFourDigits'), isTrue);

      final invalidLast4Letters = VirtualCardModel.validateFields(
        cardName: 'My Card',
        bankName: 'HDFC Bank',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '12AB',
      );
      expect(invalidLast4Letters.containsKey('lastFourDigits'), isTrue);

      // Invalid expiry format
      final invalidExpiry = VirtualCardModel.validateFields(
        cardName: 'My Card',
        bankName: 'HDFC Bank',
        cardHolder: 'DEEPAK R',
        lastFourDigits: '1234',
        expiryDate: '15/28', // month 15 is invalid
      );
      expect(invalidExpiry.containsKey('expiryDate'), isTrue);
    });

    test('Never serializes or retains CVV for security compliance', () {
      final card = VirtualCardModel(
        cardName: 'Test',
        cvv: '999',
      );
      final json = card.toJson();
      expect(json['cvv'], equals(''));

      final deserialized = VirtualCardModel.fromJson({
        'cardNumber': '4532 9988 7766 1234',
        'cvv': '999',
      });
      expect(deserialized.cvv, equals(''));
      expect(deserialized.lastFourDigits, equals('1234'));
    });
  });

  group('SpendControls & SpendingSummary Calculation Tests', () {
    final refDate = DateTime(2026, 10, 27, 14, 30); // Tuesday

    final testTransactions = [
      // Today's expenses (Daily)
      TransactionModel(
        id: 1,
        amount: 250.0,
        type: 'expense',
        category: 'Food',
        date: DateTime(2026, 10, 27, 10, 0),
      ),
      TransactionModel(
        id: 2,
        amount: 500.0,
        type: 'expense',
        category: 'Transport',
        date: DateTime(2026, 10, 27, 12, 0),
      ),
      // Yesterday's expense (Same week and month, but NOT today)
      TransactionModel(
        id: 3,
        amount: 1500.0,
        type: 'expense',
        category: 'Shopping',
        date: DateTime(2026, 10, 26, 15, 0),
      ),
      // Earlier this month (Same month, NOT this week)
      TransactionModel(
        id: 4,
        amount: 8000.0,
        type: 'expense',
        category: 'Bills',
        date: DateTime(2026, 10, 5, 9, 0),
      ),
      // Income (MUST be excluded from spending calculations)
      TransactionModel(
        id: 5,
        amount: 50000.0,
        type: 'income',
        category: 'Salary',
        date: DateTime(2026, 10, 27, 8, 0),
      ),
      // Last month's expense (MUST be excluded from current month)
      TransactionModel(
        id: 6,
        amount: 12000.0,
        type: 'expense',
        category: 'Shopping',
        date: DateTime(2026, 9, 15, 12, 0),
      ),
    ];

    test('Calculates Daily spending summary accurately', () {
      final limits = SpendLimitModel(
        dailyLimit: 2000.0,
      );

      final summary = SpendingSummary.calculate(
        transactions: testTransactions,
        period: SpendPeriod.daily,
        limits: limits,
        referenceDate: refDate,
      );

      // Only tx 1 (250) + tx 2 (500) = 750
      expect(summary.totalSpent, equals(750.0));
      expect(summary.limitAmount, equals(2000.0));
      expect(summary.remainingBudget, equals(1250.0));
      expect(summary.spendPercentage, closeTo(0.375, 0.001));
      expect(summary.transactionCount, equals(2));
      expect(summary.categoryBreakdown['Food'], equals(250.0));
      expect(summary.categoryBreakdown['Transport'], equals(500.0));
    });

    test('Calculates Weekly spending summary accurately', () {
      final limits = SpendLimitModel(
        weeklyLimit: 10000.0,
      );

      final summary = SpendingSummary.calculate(
        transactions: testTransactions,
        period: SpendPeriod.weekly,
        limits: limits,
        referenceDate: refDate,
      );

      // Week contains Monday 26th (1500) and Tuesday 27th (250 + 500) = 2250
      expect(summary.totalSpent, equals(2250.0));
      expect(summary.limitAmount, equals(10000.0));
      expect(summary.remainingBudget, equals(7750.0));
      expect(summary.spendPercentage, closeTo(0.225, 0.001));
      expect(summary.transactionCount, equals(3));
    });

    test('Calculates Monthly spending summary accurately', () {
      final limits = SpendLimitModel(
        monthlyLimit: 20000.0,
      );

      final summary = SpendingSummary.calculate(
        transactions: testTransactions,
        period: SpendPeriod.monthly,
        limits: limits,
        referenceDate: refDate,
      );

      // Month contains: 250 + 500 + 1500 + 8000 = 10250. Income (50000) and Sep (12000) excluded!
      expect(summary.totalSpent, equals(10250.0));
      expect(summary.limitAmount, equals(20000.0));
      expect(summary.remainingBudget, equals(9750.0));
      expect(summary.spendPercentage, closeTo(0.5125, 0.001));
      expect(summary.transactionCount, equals(4));
    });

    test('Fires 50%, 80%, and 100% threshold alerts at correct spend levels', () {
      // 1. Spend is 5500 on 10000 limit = 55% -> triggers 50% info alert
      final limit50 = SpendLimitModel(
        dailyLimit: 10000.0,
        alertAt50: true,
      );
      final txs50 = [
        TransactionModel(
          amount: 5500.0,
          type: 'expense',
          category: 'Shopping',
          date: refDate,
        ),
      ];
      final summary50 = SpendingSummary.calculate(
        transactions: txs50,
        period: SpendPeriod.daily,
        limits: limit50,
        referenceDate: refDate,
      );
      expect(summary50.activeAlerts.length, equals(1));
      expect(summary50.activeAlerts.first.severity, equals('info'));

      // 2. Spend is 8500 on 10000 limit = 85% -> triggers 80% warning alert
      final limit80 = SpendLimitModel(
        dailyLimit: 10000.0,
        alertAt80: true,
      );
      final txs80 = [
        TransactionModel(
          amount: 8500.0,
          type: 'expense',
          category: 'Shopping',
          date: refDate,
        ),
      ];
      final summary80 = SpendingSummary.calculate(
        transactions: txs80,
        period: SpendPeriod.daily,
        limits: limit80,
        referenceDate: refDate,
      );
      expect(summary80.activeAlerts.length, equals(1));
      expect(summary80.activeAlerts.first.severity, equals('warning'));

      // 3. Spend is 12000 on 10000 limit = 120% -> triggers 100% danger alert
      final limit100 = SpendLimitModel(
        dailyLimit: 10000.0,
        alertAt100: true,
      );
      final txs100 = [
        TransactionModel(
          amount: 12000.0,
          type: 'expense',
          category: 'Shopping',
          date: refDate,
        ),
      ];
      final summary100 = SpendingSummary.calculate(
        transactions: txs100,
        period: SpendPeriod.daily,
        limits: limit100,
        referenceDate: refDate,
      );
      expect(summary100.activeAlerts.length, equals(1));
      expect(summary100.activeAlerts.first.severity, equals('danger'));
    });

    test('Alert deduplication: acknowledged alert IDs are not re-triggered', () {
      final limits = SpendLimitModel(
        dailyLimit: 5000.0,
        alertAt100: true,
      );

      final txs = [
        TransactionModel(
          amount: 6000.0,
          type: 'expense',
          category: 'Food',
          date: refDate,
        ),
      ];

      // First run: fires alert
      final firstSummary = SpendingSummary.calculate(
        transactions: txs,
        period: SpendPeriod.daily,
        limits: limits,
        referenceDate: refDate,
      );
      expect(firstSummary.activeAlerts.length, equals(1));
      final alertId = firstSummary.activeAlerts.first.id;

      // Second run with acknowledged alert ID: alert is suppressed
      final ackedLimits = limits.copyWith(
        acknowledgedAlertIds: [alertId],
      );
      final secondSummary = SpendingSummary.calculate(
        transactions: txs,
        period: SpendPeriod.daily,
        limits: ackedLimits,
        referenceDate: refDate,
      );
      expect(secondSummary.activeAlerts.isEmpty, isTrue);
    });

    test('Category-specific limits trigger alerts when category is exceeded', () {
      final limits = SpendLimitModel(
        monthlyLimit: 50000.0,
        categoryLimits: {
          'Food': 3000.0,
        },
      );

      final txs = [
        TransactionModel(
          amount: 3500.0,
          type: 'expense',
          category: 'Food',
          date: refDate,
        ),
      ];

      final summary = SpendingSummary.calculate(
        transactions: txs,
        period: SpendPeriod.monthly,
        limits: limits,
        referenceDate: refDate,
      );

      expect(summary.activeAlerts.any((a) => a.title.contains('Food Limit Exceeded')), isTrue);
    });
  });

  group('VirtualCardProvider Logic Tests', () {
    test('Provider starts cleanly and handles card addition and duplicates', () async {
      final provider = VirtualCardProvider(autoFetch: false);

      final addResult = await provider.addCard({
        'cardName': 'Test Card',
        'bankName': 'Federal Bank',
        'cardHolder': 'TEST USER',
        'lastFourDigits': '8821',
        'cardType': 'Debit Card',
        'cardNetwork': 'VISA',
      });
      expect(addResult, isTrue);
      expect(provider.cards.any((c) => c.lastFourDigits == '8821'), isTrue);

      // Attempting to add exact duplicate (same bank & last 4)
      final duplicateResult = await provider.addCard({
        'cardName': 'Another Card',
        'bankName': 'Federal Bank',
        'cardHolder': 'TEST USER',
        'lastFourDigits': '8821',
      });
      expect(duplicateResult, isFalse);
      expect(provider.error, contains('already in your wallet'));
    });

    test('Filtered cards search matches name, bank, and last 4 digits', () async {
      final provider = VirtualCardProvider(autoFetch: false);

      await provider.addCard({
        'cardName': 'Regalia Gold',
        'bankName': 'HDFC Bank',
        'cardHolder': 'DEEPAK',
        'lastFourDigits': '1111',
        'cardType': 'Credit Card',
      });

      await provider.addCard({
        'cardName': 'Global Debit',
        'bankName': 'State Bank of India',
        'cardHolder': 'DEEPAK',
        'lastFourDigits': '2222',
        'cardType': 'Debit Card',
      });

      // Search by nickname
      provider.setSearchQuery('Regalia');
      expect(provider.filteredCards.length, equals(1));
      expect(provider.filteredCards.first.lastFourDigits, equals('1111'));

      // Search by last 4 digits
      provider.setSearchQuery('2222');
      expect(provider.filteredCards.length, equals(1));
      expect(provider.filteredCards.first.bankName, equals('State Bank of India'));

      // Filter by card type
      provider.setSearchQuery('');
      provider.setTypeFilter('Credit Card');
      expect(provider.filteredCards.every((c) => c.isCredit), isTrue);

      provider.setTypeFilter('Debit Card');
      expect(provider.filteredCards.every((c) => c.isDebit), isTrue);
    });

    test('Updating limits and in-app preferences updates state without bank mock claims', () async {
      final provider = VirtualCardProvider(autoFetch: false);

      await provider.updatePeriodLimit(SpendPeriod.monthly, 85000.0);
      expect(provider.spendLimits.monthlyLimit, equals(85000.0));

      await provider.updatePeriodLimit(SpendPeriod.daily, 7500.0);
      expect(provider.spendLimits.dailyLimit, equals(7500.0));

      await provider.setCategoryLimit('Groceries', 12000.0);
      expect(provider.spendLimits.categoryLimits['Groceries'], equals(12000.0));

      await provider.deleteCategoryLimit('Groceries');
      expect(provider.spendLimits.categoryLimits.containsKey('Groceries'), isFalse);

      await provider.toggleInAppPreference('inAppCardLock', true);
      expect(provider.spendLimits.inAppCardLock, isTrue);
    });
  });

  group('CardScannerService OCR Parsing Tests', () {
    final scanner = CardScannerService();

    test('Parses full 16-digit PAN, network, bank, expiry, and holder name', () {
      const sampleOcrText = '''
        HDFC BANK
        MILLENNIA DEBIT CARD
        4532 9876 5432 1098
        VALID THRU 08/29
        DEEPAK R
        VISA
      ''';

      final result = scanner.parseCardText(sampleOcrText);

      expect(result.bankName, equals('HDFC Bank'));
      expect(result.cardNetwork, equals('VISA'));
      expect(result.cardType, equals('Debit Card'));
      expect(result.lastFourDigits, equals('1098'));
      expect(result.expiryDate, equals('08/29'));
      expect(result.cardHolder, equals('DEEPAK R'));
    });

    test('Parses State Bank of India with RuPay and 4-digit blocks', () {
      const sampleOcrText = '''
        STATE BANK OF INDIA
        GLOBAL INTERNATIONAL
        PLATINUM REWARDS
        6071 8899 4433 7654
        EXP 11/28
        RAHUL SHARMA
        RUPAY
      ''';

      final result = scanner.parseCardText(sampleOcrText);

      expect(result.bankName, equals('State Bank of India'));
      expect(result.cardNetwork, equals('RUPAY'));
      expect(result.cardType, equals('Credit Card'));
      expect(result.lastFourDigits, equals('7654'));
      expect(result.expiryDate, equals('11/28'));
      expect(result.cardHolder, equals('RAHUL SHARMA'));
    });

    test('Parses ICICI Bank Credit Card with Mastercard', () {
      const sampleOcrText = '''
        ICICI BANK
        CORAL CREDIT CARD
        5241 1234 9876 4321
        05/2030
        PRIYA M
        MASTERCARD
      ''';

      final result = scanner.parseCardText(sampleOcrText);

      expect(result.bankName, equals('ICICI Bank'));
      expect(result.cardNetwork, equals('MASTERCARD'));
      expect(result.cardType, equals('Credit Card'));
      expect(result.lastFourDigits, equals('4321'));
      expect(result.expiryDate, equals('05/30'));
      expect(result.cardHolder, equals('PRIYA M'));
    });

    test('Parses American Express 15-digit card', () {
      const sampleOcrText = '''
        AMERICAN EXPRESS
        MEMBERSHIP REWARDS
        3782 822468 95001
        GOOD THRU 10/27
        VIKRAMADITYA S
      ''';

      final result = scanner.parseCardText(sampleOcrText);

      expect(result.cardNetwork, equals('AMEX'));
      expect(result.lastFourDigits, equals('5001'));
      expect(result.expiryDate, equals('10/27'));
      expect(result.cardHolder, equals('VIKRAMADITYA S'));
    });
  });
}

