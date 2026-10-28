import 'package:flutter_test/flutter_test.dart';
import 'package:aifinancify_flutter/services/voice_expense_parser.dart';

void main() {
  group('Multilingual VoiceExpenseParser Tests', () {
    // =========================================================================
    // 1. ENGLISH TEST CASES
    // =========================================================================
    group('English (en-IN) Speech Parsing', () {
      test('Parses English: "I spent 250 rupees on lunch using Google Pay."', () {
        final result = VoiceExpenseParser.parse("I spent 250 rupees on lunch using Google Pay.");

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.description.toLowerCase().contains('lunch'), true);
        expect(result.confidence, greaterThanOrEqualTo(0.8));
      });

      test('Parses English: "Paid 80 for petrol by cash."', () {
        final result = VoiceExpenseParser.parse("Paid 80 for petrol by cash.");

        expect(result.amount, 80.0);
        expect(result.type, 'expense');
        expect(result.category, 'Transport');
        expect(result.paymentMode, 'Cash');
        expect(result.isPaymentModeExplicit, true);
        expect(result.description.toLowerCase().contains('petrol'), true);
      });

      test('Parses English: "Yesterday I bought groceries for 650 using my debit card."', () {
        final result = VoiceExpenseParser.parse("Yesterday I bought groceries for 650 using my debit card.");

        expect(result.amount, 650.0);
        expect(result.type, 'expense');
        expect(result.category, 'Groceries');
        expect(result.paymentMode, 'Card');
        expect(result.isDateExplicit, true);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(result.date.day, yesterday.day);
      });

      test('Parses English: "I received 5000 as salary in my bank account."', () {
        final result = VoiceExpenseParser.parse("I received 5000 as salary in my bank account.");

        expect(result.amount, 5000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
        expect(result.paymentMode, 'Bank Transfer');
      });

      test('Parses English: "Spent 120 at the tea shop through UPI."', () {
        final result = VoiceExpenseParser.parse("Spent 120 at the tea shop through UPI.");

        expect(result.amount, 120.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.description, 'Tea Shop');
      });
    });

    // =========================================================================
    // 2. TAMIL TEST CASES
    // =========================================================================
    group('Tamil (ta-IN) Speech Parsing', () {
      test('Parses Tamil: "இன்னைக்கு கடையில் 250 ரூபாய்க்கு சாப்பிட்டேன், GPay மூலம் கொடுத்தேன்."', () {
        final result = VoiceExpenseParser.parse(
          "இன்னைக்கு கடையில் 250 ரூபாய்க்கு சாப்பிட்டேன், GPay மூலம் கொடுத்தேன்.",
          hintLocale: 'ta-IN',
        );

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.detectedLanguage.contains('ta'), true);
      });

      test('Parses Tamil: "பெட்ரோலுக்கு 500 ரூபாய் ரொக்கமாக கொடுத்தேன்."', () {
        final result = VoiceExpenseParser.parse(
          "பெட்ரோலுக்கு 500 ரூபாய் ரொக்கமாக கொடுத்தேன்.",
          hintLocale: 'ta-IN',
        );

        expect(result.amount, 500.0);
        expect(result.type, 'expense');
        expect(result.category, 'Transport');
        expect(result.paymentMode, 'Cash');
        expect(result.description, 'பெட்ரோல்');
      });

      test('Parses Tamil: "காய்கறி வாங்க 180 ரூபாய் செலவு ஆச்சு."', () {
        final result = VoiceExpenseParser.parse(
          "காய்கறி வாங்க 180 ரூபாய் செலவு ஆச்சு.",
          hintLocale: 'ta-IN',
        );

        expect(result.amount, 180.0);
        expect(result.type, 'expense');
        expect(result.category, 'Groceries');
        expect(result.description, 'காய்கறி');
      });

      test('Parses Tamil: "நேத்து சம்பளமா 15000 ரூபாய் வந்தது."', () {
        final result = VoiceExpenseParser.parse(
          "நேத்து சம்பளமா 15000 ரூபாய் வந்தது.",
          hintLocale: 'ta-IN',
        );

        expect(result.amount, 15000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
        expect(result.isDateExplicit, true);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(result.date.day, yesterday.day);
      });

      test('Parses Tamil: "PhonePe மூலமா 300 ரூபாய் டீக்கடைக்கு கொடுத்தேன்."', () {
        final result = VoiceExpenseParser.parse(
          "PhonePe மூலமா 300 ரூபாய் டீக்கடைக்கு கொடுத்தேன்.",
          hintLocale: 'ta-IN',
        );

        expect(result.amount, 300.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.description, 'டீக்கடை');
      });

      test('Parses Tamil Word Numbers: "ஐந்நூறு ரூபாய் பெட்ரோல்"', () {
        final result = VoiceExpenseParser.parse("ஐந்நூறு ரூபாய் பெட்ரோல்");

        expect(result.amount, 500.0);
        expect(result.category, 'Transport');
      });

      test('Parses Tamil Word Numbers: "இருநூற்றைம்பது ரூபாய் உணவு"', () {
        final result = VoiceExpenseParser.parse("இருநூற்றைம்பது ரூபாய் உணவு");

        expect(result.amount, 250.0);
        expect(result.category, 'Food & Dining');
      });
    });

    // =========================================================================
    // 3. TELUGU TEST CASES
    // =========================================================================
    group('Telugu (te-IN) Speech Parsing', () {
      test('Parses Telugu: "ఈరోజు భోజనానికి 250 రూపాయలు ఖర్చు చేశాను, Google Pay ద్వారా చెల్లించాను."', () {
        final result = VoiceExpenseParser.parse(
          "ఈరోజు భోజనానికి 250 రూపాయలు ఖర్చు చేశాను, Google Pay ద్వారా చెల్లించాను.",
          hintLocale: 'te-IN',
        );

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.detectedLanguage.contains('te'), true);
      });

      test('Parses Telugu: "పెట్రోల్ కోసం 500 రూపాయలు నగదు ఇచ్చాను."', () {
        final result = VoiceExpenseParser.parse(
          "పెట్రోల్ కోసం 500 రూపాయలు నగదు ఇచ్చాను.",
          hintLocale: 'te-IN',
        );

        expect(result.amount, 500.0);
        expect(result.type, 'expense');
        expect(result.category, 'Transport');
        expect(result.paymentMode, 'Cash');
        expect(result.description, 'పెట్రోల్');
      });

      test('Parses Telugu: "కూరగాయల కోసం 180 రూపాయలు ఖర్చు చేశాను."', () {
        final result = VoiceExpenseParser.parse(
          "కూరగాయల కోసం 180 రూపాయలు ఖర్చు చేశాను.",
          hintLocale: 'te-IN',
        );

        expect(result.amount, 180.0);
        expect(result.type, 'expense');
        expect(result.category, 'Groceries');
        expect(result.description, 'కూరగాయలు');
      });

      test('Parses Telugu: "నిన్న జీతంగా 15000 రూపాయలు వచ్చాయి."', () {
        final result = VoiceExpenseParser.parse(
          "నిన్న జీతంగా 15000 రూపాయలు వచ్చాయి.",
          hintLocale: 'te-IN',
        );

        expect(result.amount, 15000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
        expect(result.isDateExplicit, true);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(result.date.day, yesterday.day);
      });

      test('Parses Telugu: "PhonePe ద్వారా టీకి 50 రూపాయలు చెల్లించాను."', () {
        final result = VoiceExpenseParser.parse(
          "PhonePe ద్వారా టీకి 50 రూపాయలు చెల్లించాను.",
          hintLocale: 'te-IN',
        );

        expect(result.amount, 50.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.description, 'టీ');
      });

      test('Parses Telugu Word Numbers: "రెండు వందల యాభై రూపాయలు భోజనం"', () {
        final result = VoiceExpenseParser.parse("రెండు వందల యాభై రూపాయలు భోజనం");

        expect(result.amount, 250.0);
        expect(result.category, 'Food & Dining');
      });
    });

    // =========================================================================
    // 4. CODE-SWITCHING & MIXED LANGUAGE CASES
    // =========================================================================
    group('Code-Switching & Mixed Language Parsing', () {
      test('Handles Tamil-English code-switch: "இன்னைக்கு 250 rupees lunchக்கு செலவு பண்ணேன்"', () {
        final result = VoiceExpenseParser.parse("இன்னைக்கு 250 rupees lunchக்கு செலவு பண்ணேன்");

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.description.toLowerCase().contains('lunch'), true);
      });

      test('Handles Telugu-English code-switch: "ఈరోజు 250 rupees petrol కోసం ఖర్చు చేశాను"', () {
        final result = VoiceExpenseParser.parse("ఈరోజు 250 rupees petrol కోసం ఖర్చు చేశాను");

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Transport');
        expect(result.description.toLowerCase().contains('petrol'), true);
      });

      test('Handles English spoken corrections: "Actually not 250, it was 350 for dinner"', () {
        final result = VoiceExpenseParser.parse("Actually not 250, it was 350 for dinner");

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Disambiguates item quantities from amount: "Bought 2 coffees for 200 rs"', () {
        final result = VoiceExpenseParser.parse("Bought 2 coffees for 200 rs");

        expect(result.amount, 200.0);
        expect(result.category, 'Food & Dining');
      });

      test('Handles multiplier expressions: "Spent 5k on shopping via card"', () {
        final result = VoiceExpenseParser.parse("Spent 5k on shopping via card");

        expect(result.amount, 5000.0);
        expect(result.category, 'Shopping');
        expect(result.paymentMode, 'Card');
      });

      test('Handles lakhs: "Received 1.5 lakh bonus"', () {
        final result = VoiceExpenseParser.parse("Received 1.5 lakh bonus");

        expect(result.amount, 150000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
      });
    });

    // =========================================================================
    // 5. DATA MODEL & EDGE CASE VALIDATION
    // =========================================================================
    group('Validation & Edge Cases', () {
      test('Never invents invalid categories', () {
        final result = VoiceExpenseParser.parse("Something strange happened 100 rupees");

        expect(VoiceExpenseParser.allowedCategories.contains(result.category), true);
        expect(result.amount, 100.0);
      });

      test('Never invents invalid payment modes', () {
        final result = VoiceExpenseParser.parse("Bought food 300");

        expect(VoiceExpenseParser.allowedPaymentModes.contains(result.paymentMode), true);
        expect(result.isPaymentModeExplicit, false);
      });

      test('Identifies missing amount gracefully', () {
        final result = VoiceExpenseParser.parse("Had delicious dinner at cafe");

        expect(result.amount, isNull);
        expect(result.isAmountCertain, false);
        expect(result.category, 'Food & Dining');
        expect(result.issues.isNotEmpty, true);
        expect(result.confidence, lessThan(0.5));
      });

      test('Handles prompt test case: "ரூபாய் 300 செலவு ஆனது"', () {
        final result = VoiceExpenseParser.parse("ரூபாய் 300 செலவு ஆனது", hintLocale: 'ta-IN');

        expect(result.amount, 300.0);
        expect(result.type, 'expense');
      });

      test('Handles prompt test case: "எனக்கு 2000 ரூபாய் வந்தது"', () {
        final result = VoiceExpenseParser.parse("எனக்கு 2000 ரூபாய் வந்தது", hintLocale: 'ta-IN');

        expect(result.amount, 2000.0);
        expect(result.type, 'income');
      });

      test('Handles prompt test case: "నాకు 5000 జీతం వచ్చింది"', () {
        final result = VoiceExpenseParser.parse("నాకు 5000 జీతం వచ్చింది", hintLocale: 'te-IN');

        expect(result.amount, 5000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
      });

      test('Handles decimal amounts: "Spent 120.50 on snacks via cash"', () {
        final result = VoiceExpenseParser.parse("Spent 120.50 on snacks via cash");

        expect(result.amount, 120.50);
        expect(result.paymentMode, 'Cash');
        expect(result.category, 'Food & Dining');
      });

      test('Handles currency symbol prefix: "₹1500 for medicines"', () {
        final result = VoiceExpenseParser.parse("₹1500 for medicines");

        expect(result.amount, 1500.0);
        expect(result.category, 'Health');
      });

      test('Handles empty and whitespace input gracefully', () {
        final result = VoiceExpenseParser.parse("   ");

        expect(result.amount, isNull);
        expect(result.confidence, 0.0);
        expect(result.issues.isNotEmpty, true);
      });
    });

    // =========================================================================
    // 6. MULTILINGUAL SPOKEN CORRECTIONS
    // =========================================================================
    group('Multilingual Spoken Corrections', () {
      test('Handles Tamil correction: "250 இல்லை 350 உணவு"', () {
        final result = VoiceExpenseParser.parse("250 இல்லை 350 உணவு", hintLocale: 'ta-IN');

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Handles Tamil correction: "250 இல்ல 350 பெட்ரோலுக்கு"', () {
        final result = VoiceExpenseParser.parse("250 இல்ல 350 பெட்ரோலுக்கு", hintLocale: 'ta-IN');

        expect(result.amount, 350.0);
        expect(result.category, 'Transport');
      });

      test('Handles Telugu correction: "250 కాదు 350 భోజనం"', () {
        final result = VoiceExpenseParser.parse("250 కాదు 350 భోజనం", hintLocale: 'te-IN');

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Handles English correction: "actually 350 not 250 for dinner"', () {
        final result = VoiceExpenseParser.parse("actually 350 not 250 for dinner");

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Handles Tamil postfix negation: "350 ரூபாய் 250 இல்லை"', () {
        final result = VoiceExpenseParser.parse("350 ரூபாய் 250 இல்லை", hintLocale: 'ta-IN');

        expect(result.amount, 350.0);
      });

      test('Handles Telugu postfix negation: "350 రూపాయలు 250 కాదు"', () {
        final result = VoiceExpenseParser.parse("350 రూపాయలు 250 కాదు", hintLocale: 'te-IN');

        expect(result.amount, 350.0);
      });
    });

    // =========================================================================
    // 7. CONTEXTUAL CLASSIFICATION & DISAMBIGUATION
    // =========================================================================
    group('Contextual Classification & Quantity Disambiguation', () {
      test('Contextual: "tea shop 80 rs" maps to Food & Dining, not Shopping', () {
        final result = VoiceExpenseParser.parse("tea shop 80 rs");

        expect(result.amount, 80.0);
        expect(result.category, 'Food & Dining');
        expect(result.description, 'Tea Shop');
      });

      test('Contextual: "pharmacy 450 rs" maps to Health, not Shopping', () {
        final result = VoiceExpenseParser.parse("pharmacy 450 rs");

        expect(result.amount, 450.0);
        expect(result.category, 'Health');
      });

      test('Contextual: "dmart 1200 rs" maps to Groceries, not Shopping', () {
        final result = VoiceExpenseParser.parse("dmart 1200 rs");

        expect(result.amount, 1200.0);
        expect(result.category, 'Groceries');
      });

      test('Contextual: "gas cylinder 950 rs" maps to Bills & Utilities, not Transport', () {
        final result = VoiceExpenseParser.parse("gas cylinder 950 rs");

        expect(result.amount, 950.0);
        expect(result.category, 'Bills & Utilities');
      });

      test('Contextual: "movie ticket 250" maps to Entertainment', () {
        final result = VoiceExpenseParser.parse("movie ticket 250");

        expect(result.amount, 250.0);
        expect(result.category, 'Entertainment');
      });

      test('Contextual: "bus ticket 60" maps to Transport', () {
        final result = VoiceExpenseParser.parse("bus ticket 60");

        expect(result.amount, 60.0);
        expect(result.category, 'Transport');
      });

      test('Disambiguation: "Paid 500 for 10 liters petrol" picks 500', () {
        final result = VoiceExpenseParser.parse("Paid 500 for 10 liters petrol");

        expect(result.amount, 500.0);
        expect(result.category, 'Transport');
      });

      test('Disambiguation: "Ordered 4 dosas for 160 rs" picks 160', () {
        final result = VoiceExpenseParser.parse("Ordered 4 dosas for 160 rs");

        expect(result.amount, 160.0);
        expect(result.category, 'Food & Dining');
      });

      test('Disambiguation: "Bought 1 liter milk for 55" picks 55', () {
        final result = VoiceExpenseParser.parse("Bought 1 liter milk for 55");

        expect(result.amount, 55.0);
        expect(result.category, 'Groceries');
      });

      test('Phone Number Filter: "Called 9876543210 and spent 150 on recharge" picks 150', () {
        final result = VoiceExpenseParser.parse("Called 9876543210 and spent 150 on recharge");

        expect(result.amount, 150.0);
        expect(result.category, 'Bills & Utilities');
      });
    });

    // =========================================================================
    // 8. ADDITIONAL MULTILINGUAL SCENARIOS
    // =========================================================================
    group('Additional Multilingual & Date Scenarios', () {
      test('Tamil word amount: "நானூறு ரூபாய் மின்சார கட்டணம்"', () {
        final result = VoiceExpenseParser.parse("நானூறு ரூபாய் மின்சார கட்டணம்", hintLocale: 'ta-IN');

        expect(result.amount, 400.0);
        expect(result.category, 'Bills & Utilities');
      });

      test('Tamil word amount: "ஆயிரம் ரூபாய் டாக்டர் பீஸ்"', () {
        final result = VoiceExpenseParser.parse("ஆயிரம் ரூபாய் டாக்டர் பீஸ்", hintLocale: 'ta-IN');

        expect(result.amount, 1000.0);
        expect(result.category, 'Health');
      });

      test('Telugu word amount: "రెండు వేలు బట్టల కోసం ఖర్చు చేశాను"', () {
        final result = VoiceExpenseParser.parse("రెండు వేలు బట్టల కోసం ఖర్చు చేశాను", hintLocale: 'te-IN');

        expect(result.amount, 2000.0);
        expect(result.category, 'Shopping');
      });

      test('Telugu word amount: "వెయ్యి రూపాయలు కరెంట్ బిల్లు కట్టాను"', () {
        final result = VoiceExpenseParser.parse("వెయ్యి రూపాయలు కరెంట్ బిల్లు కట్టాను", hintLocale: 'te-IN');

        expect(result.amount, 1000.0);
        expect(result.category, 'Bills & Utilities');
      });

      test('Day before yesterday Tamil: "முந்தாநேத்து 500 ரூபாய் செலவு ஆச்சு"', () {
        final result = VoiceExpenseParser.parse("முந்தாநேத்து 500 ரூபாய் செலவு ஆச்சு", hintLocale: 'ta-IN');

        expect(result.amount, 500.0);
        expect(result.isDateExplicit, true);
        final dayBeforeYesterday = DateTime.now().subtract(const Duration(days: 2));
        expect(result.date.day, dayBeforeYesterday.day);
      });

      test('Day before yesterday Telugu: "మొన్న పెట్రోల్ కోసం 500 ఖర్చు చేశాను"', () {
        final result = VoiceExpenseParser.parse("మొన్న పెట్రోల్ కోసం 500 ఖర్చు చేశాను", hintLocale: 'te-IN');

        expect(result.amount, 500.0);
        expect(result.isDateExplicit, true);
        final dayBeforeYesterday = DateTime.now().subtract(const Duration(days: 2));
        expect(result.date.day, dayBeforeYesterday.day);
      });

      test('Converts result to TransactionModel accurately', () {
        final result = VoiceExpenseParser.parse("Spent 250 rupees on lunch using Google Pay.");
        final tx = result.toTransactionModel(id: 1, userId: 'user-123');

        expect(tx.id, 1);
        expect(tx.userId, 'user-123');
        expect(tx.amount, 250.0);
        expect(tx.category, 'Food & Dining');
        expect(tx.paymentMode, 'UPI');
        expect(tx.type, 'expense');
      });
    });

    // =========================================================================
    // 9. HINDI (hi-IN) & HINGLISH SPEECH PARSING
    // =========================================================================
    group('Hindi (hi-IN) & Hinglish Speech Parsing', () {
      test('Parses Hindi: "आज 250 रुपये खाने के लिए Google Pay से दिए"', () {
        final result = VoiceExpenseParser.parse(
          "आज 250 रुपये खाने के लिए Google Pay से दिए",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 250.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.paymentProvider, 'Google Pay');
        expect(result.isPaymentModeExplicit, true);
        expect(result.detectedLanguage.contains('hi'), true);
        expect(result.detectedLanguageName.contains('Hindi'), true);
      });

      test('Parses Hindi: "पेट्रोल के लिए 500 रुपये कैश दिए"', () {
        final result = VoiceExpenseParser.parse(
          "पेट्रोल के लिए 500 रुपये कैश दिए",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 500.0);
        expect(result.type, 'expense');
        expect(result.category, 'Transport');
        expect(result.paymentMode, 'Cash');
        expect(result.isPaymentModeExplicit, true);
        expect(result.description, 'पेट्रोल');
      });

      test('Parses Hindi: "बिजली का बिल 1200 रुपये भरा"', () {
        final result = VoiceExpenseParser.parse(
          "बिजली का बिल 1200 रुपये भरा",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 1200.0);
        expect(result.type, 'expense');
        expect(result.category, 'Bills & Utilities');
      });

      test('Parses Hindi: "सैलरी 40000 रुपये बैंक में आई"', () {
        final result = VoiceExpenseParser.parse(
          "सैलरी 40000 रुपये बैंक में आई",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 40000.0);
        expect(result.type, 'income');
        expect(result.category, 'Salary');
        expect(result.paymentMode, 'Bank Transfer');
      });

      test('Parses Hindi spoken words: "साढ़े तीन सौ रुपये चाय और नाश्ता"', () {
        final result = VoiceExpenseParser.parse(
          "साढ़े तीन सौ रुपये चाय और नाश्ता",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Parses Hindi spoken words: "ढाई हजार रुपये कपड़े खरीदे"', () {
        final result = VoiceExpenseParser.parse(
          "ढाई हजार रुपये कपड़े खरीदे",
          hintLocale: 'hi-IN',
        );

        expect(result.amount, 2500.0);
        expect(result.category, 'Shopping');
      });

      test('Parses Hinglish: "chai ke liye 20 rupaye diye PhonePe se"', () {
        final result = VoiceExpenseParser.parse("chai ke liye 20 rupaye diye PhonePe se");

        expect(result.amount, 20.0);
        expect(result.type, 'expense');
        expect(result.category, 'Food & Dining');
        expect(result.paymentMode, 'UPI');
        expect(result.paymentProvider, 'PhonePe');
        expect(result.isPaymentModeExplicit, true);
        expect(result.detectedLanguage.contains('hi'), true);
      });

      test('Parses Hindi correction: "250 नहीं 350 खाना"', () {
        final result = VoiceExpenseParser.parse("250 नहीं 350 खाना", hintLocale: 'hi-IN');

        expect(result.amount, 350.0);
        expect(result.category, 'Food & Dining');
      });

      test('Parses Hindi correction: "actually 350 250 nahi"', () {
        final result = VoiceExpenseParser.parse("actually 350 250 nahi", hintLocale: 'hi-IN');

        expect(result.amount, 350.0);
      });
    });

    // =========================================================================
    // 10. PAYMENT MODE & AUTOMATIC NOTIFICATION EXPLANATIONS
    // =========================================================================
    group('Payment Mode & Notification Provider Tests', () {
      test('Detects Google Pay and generates notification explanation', () {
        final result = VoiceExpenseParser.parse("Spent 350 for lunch on Google Pay");

        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'Google Pay');
        expect(result.paymentExplanation, 'Auto-detected: Paid via UPI (Google Pay)');
      });

      test('Detects PhonePe and generates notification explanation', () {
        final result = VoiceExpenseParser.parse("PhonePe ద్వారా 50 రూపాయలు ఇచ్చాను");

        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'PhonePe');
        expect(result.paymentExplanation, 'Auto-detected: Paid via UPI (PhonePe)');
      });

      test('Detects Paytm and generates notification explanation', () {
        final result = VoiceExpenseParser.parse("Paytm la 180 kuduthen");

        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'Paytm');
      });

      test('Detects QR / Scan and generates notification explanation', () {
        final result = VoiceExpenseParser.parse("Scanned QR code and paid 120 at bakery");

        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'QR Scan & Pay');
      });

      test('Detects Cash explicitly in multiple languages', () {
        final resultEn = VoiceExpenseParser.parse("Paid 90 cash for tea");
        expect(resultEn.paymentMode, 'Cash');
        expect(resultEn.isPaymentModeExplicit, true);
        expect(resultEn.paymentExplanation, 'Auto-detected: Paid in Cash');

        final resultTa = VoiceExpenseParser.parse("500 ரூபாய் ரொக்கமாக கொடுத்தேன்");
        expect(resultTa.paymentMode, 'Cash');
        expect(resultTa.isPaymentModeExplicit, true);

        final resultTe = VoiceExpenseParser.parse("500 రూపాయలు నగదు ఇచ్చాను");
        expect(resultTe.paymentMode, 'Cash');
        expect(resultTe.isPaymentModeExplicit, true);

        final resultHi = VoiceExpenseParser.parse("500 रुपये नकद दिया");
        expect(resultHi.paymentMode, 'Cash');
        expect(resultHi.isPaymentModeExplicit, true);
      });

      test('Detects Credit Card swipe', () {
        final result = VoiceExpenseParser.parse("Bought dress for 2500 using credit card swipe");

        expect(result.paymentMode, 'Card');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'Credit Card');
      });

      test('Detects Bank Transfer', () {
        final result = VoiceExpenseParser.parse("Transferred 15000 to bank account for rent");

        expect(result.paymentMode, 'Bank Transfer');
        expect(result.isPaymentModeExplicit, true);
        expect(result.paymentProvider, 'Bank Transfer');
      });

      test('Reports default fallback when payment mode is not spoken', () {
        final result = VoiceExpenseParser.parse("Had lunch for 150 rs");

        expect(result.paymentMode, 'UPI');
        expect(result.isPaymentModeExplicit, false);
        expect(result.paymentProvider, isNull);
        expect(result.paymentExplanation.contains('Defaulted to UPI'), true);
      });
    });

    // =========================================================================
    // 11. COLLOQUIAL SPOKEN ENGLISH NUMBERS
    // =========================================================================
    group('Colloquial Spoken English Numbers', () {
      test('Parses "two fifty" as 250', () {
        final result = VoiceExpenseParser.parse("Spent two fifty on lunch");
        expect(result.amount, 250.0);
        expect(result.category, 'Food & Dining');
      });

      test('Parses "three fifty" as 350', () {
        final result = VoiceExpenseParser.parse("Paid three fifty for petrol");
        expect(result.amount, 350.0);
        expect(result.category, 'Transport');
      });

      test('Parses "fifteen hundred" as 1500', () {
        final result = VoiceExpenseParser.parse("Bought groceries for fifteen hundred");
        expect(result.amount, 1500.0);
        expect(result.category, 'Groceries');
      });

      test('Parses "twenty five hundred" as 2500', () {
        final result = VoiceExpenseParser.parse("Spent twenty five hundred on shoes");
        expect(result.amount, 2500.0);
        expect(result.category, 'Shopping');
      });
    });
  });
}
