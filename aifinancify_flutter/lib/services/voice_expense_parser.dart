import '../models/transaction.dart';

/// Parsed result from a spoken voice expense or income statement.
class VoiceExpenseResult {
  final double? amount;
  final String type; // 'expense' or 'income'
  final String category; // Allowed category from app model
  final String paymentMode; // 'UPI', 'Cash', 'Card', 'Bank Transfer'
  final bool isPaymentModeExplicit;
  final String? paymentProvider; // 'Google Pay', 'PhonePe', 'Paytm', 'BHIM / CRED', 'QR Scan & Pay', 'UPI', 'Cash', 'Card', 'Bank Transfer'
  final String paymentExplanation; // Human-friendly explanation for UI notification
  final String description; // Merchant or item description
  final DateTime date;
  final bool isDateExplicit;
  final String originalTranscript;
  final String detectedLanguage; // 'en', 'hi', 'hi-en', 'ta', 'te', 'ta-en', 'te-en'
  final String detectedLanguageName; // e.g. 'Hindi (हिंदी)', 'Tamil (தமிழ்)', 'Telugu (తెలుగు)', 'English (en-IN)'
  final double confidence; // 0.0 to 1.0
  final bool isAmountCertain;
  final bool isCategoryCertain;
  final List<String> issues;

  VoiceExpenseResult({
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMode,
    required this.isPaymentModeExplicit,
    this.paymentProvider,
    this.paymentExplanation = '',
    required this.description,
    required this.date,
    required this.isDateExplicit,
    required this.originalTranscript,
    required this.detectedLanguage,
    this.detectedLanguageName = 'English',
    required this.confidence,
    required this.isAmountCertain,
    required this.isCategoryCertain,
    required this.issues,
  });

  /// Convert to app's TransactionModel
  TransactionModel toTransactionModel({int? id, String? userId}) {
    return TransactionModel(
      id: id,
      userId: userId,
      amount: amount ?? 0.0,
      description: description.isNotEmpty ? description : category,
      category: category,
      type: type,
      paymentMode: paymentMode,
      date: date,
    );
  }
}

/// Robust, Multilingual NLP Expense Parser supporting:
/// - English (en-IN)
/// - Hindi (hi-IN)
/// - Tamil (ta-IN)
/// - Telugu (te-IN)
/// - Code-switched / conversational mixed speech (Hinglish, Tanglish, Tenglish)
class VoiceExpenseParser {
  static const List<String> allowedCategories = [
    'Food & Dining',
    'Groceries',
    'Transport',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Salary',
    'Investment',
    'Other',
  ];

  static const List<String> allowedPaymentModes = [
    'UPI',
    'Cash',
    'Card',
    'Bank Transfer',
  ];

  // ===========================================================================
  // 1. LANGUAGE DETECTION
  // ===========================================================================
  static String detectLanguage(String text, {String? hintLocale}) {
    if (text.trim().isEmpty) {
      if (hintLocale != null) {
        if (hintLocale.startsWith('hi')) return 'hi';
        if (hintLocale.startsWith('ta')) return 'ta';
        if (hintLocale.startsWith('te')) return 'te';
        return 'en';
      }
      return 'en';
    }

    int devanagariChars = 0;
    int tamilChars = 0;
    int teluguChars = 0;
    int latinChars = 0;

    for (int rune in text.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) {
        devanagariChars++;
      } else if (rune >= 0x0B80 && rune <= 0x0BFF) {
        tamilChars++;
      } else if (rune >= 0x0C00 && rune <= 0x0C7F) {
        teluguChars++;
      } else if ((rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A)) {
        latinChars++;
      }
    }

    if (devanagariChars > 0 && latinChars > 0) return 'hi-en';
    if (tamilChars > 0 && latinChars > 0) return 'ta-en';
    if (teluguChars > 0 && latinChars > 0) return 'te-en';
    if (devanagariChars > 0) return 'hi';
    if (tamilChars > 0) return 'ta';
    if (teluguChars > 0) return 'te';

    final lower = text.toLowerCase();

    // Check for transliterated Hindi words (Hinglish)
    final hasHindiTranslit = RegExp(
      r'\b(aaj|kal|parso|parson|kharch|kharcha|khaye|khaya|diye|diya|liye|liya|kharida|kharide|bhara|bhari|bheja|bheje|mila|mili|mile|tankhwah|rupay|rupaye|dukaan|sabzi|doodh|dawa|dawai|bijli|paise|rokda|kiya|kiye|wali|wale|bhai|dost|karo|bhejo|diye the)\b',
    ).hasMatch(lower);
    if (hasHindiTranslit) return 'hi-en';

    // Check for transliterated Tamil words (Tanglish)
    final hasTamilTranslit = RegExp(
      r'\b(innikku|iniku|nethu|netru|munthanethu|selavu|saapten|kuduthen|vaanginen|vanthuchi|vanthathu|sambalam|roobai|rubai|kadai|kaaikari|kattinen|pannan|pannen|anupunen|kaasu|panam|rokkam)\b',
    ).hasMatch(lower);
    if (hasTamilTranslit) return 'ta-en';

    // Check for transliterated Telugu words (Tenglish)
    final hasTeluguTranslit = RegExp(
      r'\b(eroju|ninna|monna|kharchu|chesanu|ichanu|vachindi|vachayi|jeetham|rupai|rupayalu|kottu|bhojanam|kooragayalu|kattanu|chellinchanu|pampanu|dabbulu|nagadu)\b',
    ).hasMatch(lower);
    if (hasTeluguTranslit) return 'te-en';

    if (hintLocale != null) {
      if (hintLocale.startsWith('hi')) return 'hi';
      if (hintLocale.startsWith('ta')) return 'ta';
      if (hintLocale.startsWith('te')) return 'te';
    }

    return 'en';
  }

  /// Convert language code to human-friendly display name
  static String languageCodeToName(String code) {
    switch (code) {
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'hi-en':
        return 'Hindi + English (Hinglish)';
      case 'ta':
        return 'Tamil (தமிழ்)';
      case 'ta-en':
        return 'Tamil + English (Tanglish)';
      case 'te':
        return 'Telugu (తెలుగు)';
      case 'te-en':
        return 'Telugu + English (Tenglish)';
      case 'en':
      default:
        return 'English (en-IN)';
    }
  }

  // ===========================================================================
  // 2. MAIN PARSE PIPELINE
  // ===========================================================================
  static VoiceExpenseResult parse(
    String transcript, {
    String? hintLocale,
    String defaultPaymentMode = 'UPI',
    double? speechConfidence,
  }) {
    final raw = transcript.trim();
    final issues = <String>[];

    if (raw.isEmpty) {
      final lang = detectLanguage('', hintLocale: hintLocale);
      return VoiceExpenseResult(
        amount: null,
        type: 'expense',
        category: 'Other',
        paymentMode: defaultPaymentMode,
        isPaymentModeExplicit: false,
        paymentProvider: null,
        paymentExplanation: 'No speech transcript provided',
        description: '',
        date: DateTime.now(),
        isDateExplicit: false,
        originalTranscript: raw,
        detectedLanguage: lang,
        detectedLanguageName: languageCodeToName(lang),
        confidence: 0.0,
        isAmountCertain: false,
        isCategoryCertain: false,
        issues: ['No speech transcript provided'],
      );
    }

    final detectedLang = detectLanguage(raw, hintLocale: hintLocale);

    // Normalize text for parsing
    final normalized = _normalizeText(raw);

    // 1. Parse Transaction Type (Income vs Expense)
    final typeResult = _parseType(normalized);
    final type = typeResult.type;
    final isTypeExplicit = typeResult.isExplicit;

    // 2. Parse Amount (supporting digits, words, multipliers, corrections, disambiguating quantities)
    final amountResult = _parseAmount(normalized);
    final amount = amountResult.amount;
    final isAmountCertain = amountResult.isCertain;
    if (amount == null || amount <= 0) {
      issues.add('Could not clearly determine transaction amount');
    }

    // 3. Parse Date (Today, Yesterday, Day Before Yesterday, etc.)
    final dateResult = _parseDate(normalized);
    final date = dateResult.date;
    final isDateExplicit = dateResult.isExplicit;

    // 4. Parse Payment Mode with provider identification & notification explanation
    final paymentResult = _parsePaymentMode(normalized, defaultPaymentMode);
    final paymentMode = paymentResult.paymentMode;
    final isPaymentExplicit = paymentResult.isExplicit;

    // 5. Parse Category
    final categoryResult = _parseCategory(normalized, type);
    final category = categoryResult.category;
    final isCategoryCertain = categoryResult.isCertain;
    if (category == 'Other') {
      issues.add('Category is unstated or uncertain');
    }

    // 6. Extract Merchant / Description
    final description = _extractDescription(
      raw,
      normalized,
      amountResult,
      category,
      paymentResult,
      typeResult,
      dateResult,
    );

    // 7. Calculate calibrated confidence
    double confidence = speechConfidence != null && speechConfidence > 0
        ? (speechConfidence * 0.40)
        : 0.20;

    if (amount != null && amount > 0) {
      confidence += isAmountCertain ? 0.40 : 0.25;
    } else {
      confidence = (confidence * 0.5).clamp(0.0, 0.40);
    }

    if (isCategoryCertain) {
      confidence += 0.20;
    } else if (category != 'Other') {
      confidence += 0.10;
    }

    if (isPaymentExplicit) {
      confidence += 0.10;
    }
    if (isTypeExplicit) {
      confidence += 0.10;
    }
    confidence = confidence.clamp(0.0, 1.0);

    return VoiceExpenseResult(
      amount: amount,
      type: type,
      category: category,
      paymentMode: paymentMode,
      isPaymentModeExplicit: isPaymentExplicit,
      paymentProvider: paymentResult.paymentProvider,
      paymentExplanation: paymentResult.explanation,
      description: description,
      date: date,
      isDateExplicit: isDateExplicit,
      originalTranscript: raw,
      detectedLanguage: detectedLang,
      detectedLanguageName: languageCodeToName(detectedLang),
      confidence: double.parse(confidence.toStringAsFixed(2)),
      isAmountCertain: isAmountCertain,
      isCategoryCertain: isCategoryCertain,
      issues: issues,
    );
  }

  // ===========================================================================
  // 3. TEXT NORMALIZATION
  // ===========================================================================
  static String _normalizeText(String input) {
    String text = input.toLowerCase();

    // Replace native Devanagari (Hindi) numerals with Arabic digits
    const hindiDigits = {
      '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
      '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
    };
    hindiDigits.forEach((k, v) => text = text.replaceAll(k, v));

    // Replace native Tamil numerals with Arabic digits
    const tamilDigits = {
      '௧': '1', '௨': '2', '௩': '3', '௪': '4', '௫': '5',
      '௬': '6', '௭': '7', '௮': '8', '௯': '9', '௰': '10',
      '௱': '100', '௲': '1000',
    };
    tamilDigits.forEach((k, v) => text = text.replaceAll(k, v));

    // Replace native Telugu numerals with Arabic digits
    const teluguDigits = {
      '౦': '0', '౧': '1', '౨': '2', '౩': '3', '౪': '4',
      '౫': '5', '౬': '6', '౭': '7', '౮': '8', '౯': '9',
    };
    teluguDigits.forEach((k, v) => text = text.replaceAll(k, v));

    // Normalize currency symbols & words to isolated token 'rs'
    text = text.replaceAll('₹', ' rs ');
    text = text.replaceAll(RegExp(r'(?<=\d)\s*(?:rs|inr)\b|\b(?:rs|inr)\.?\b', caseSensitive: false), ' rs ');
    text = text.replaceAll(RegExp(r'\b(roobai|rubai|rooba|rupayalu|rupai|roopayalu|rupaye|rupay|rupiya|rupaiah|bucks)\b', caseSensitive: false), ' rs ');
    text = text.replaceAll(RegExp(r'\b(रुपये|रुपयों|रुपया|रुपए|रू|रु|रू\.)\b'), ' rs ');
    text = text.replaceAll(RegExp(r'\b(ரூபாய்|ரூபாய்க்கு|ரூபாயில்|ரூபாய்க்குள்)\b'), ' rs ');
    text = text.replaceAll(RegExp(r'\bரூ\.?\b'), ' rs ');
    text = text.replaceAll(RegExp(r'\b(రూపాయలు|రూపాయి|రూపాయల|రూపాయలకు)\b'), ' rs ');
    text = text.replaceAll(RegExp(r'\bరూ\.?\b'), ' rs ');
    text = text.replaceAll(RegExp(r'\b(rupees?)\b', caseSensitive: false), ' rs ');

    // Normalize spacing around punctuation
    text = text.replaceAll(RegExp(r'[,:;!?]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  // ===========================================================================
  // 4. AMOUNT EXTRACTION WITH MULTILINGUAL WORD NUMBERS & DISAMBIGUATION
  // ===========================================================================
  static _AmountResult _parseAmount(String text) {
    // A. Check for spoken corrections first:
    // 1. Postfix negation on first number: <num1> (இல்லை / இல்ல / కాదు / नहीं / नही / nahi) <num2>
    // e.g. "250 இல்லை 350", "250 இல்ல 350", "250 కాదు 350", "250 नहीं 350", "250 nahi 350"
    final corrPostfix1 = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rs)?\s*(?:இல்லை|இல்ல|కాదు|नहीं|नही|nahi)\s*(?:,\s*|\s+(?:it\s+was|it\s+is|but|balki|பதிலா)?\s*)(\d+(?:\.\d+)?)\s*(?:rs)?\b',
      caseSensitive: false,
    );
    final matchPostfix1 = corrPostfix1.firstMatch(text);
    if (matchPostfix1 != null) {
      final correctedVal = double.tryParse(matchPostfix1.group(2) ?? '');
      if (correctedVal != null && correctedVal > 0) {
        return _AmountResult(amount: correctedVal, isCertain: true, matchedRaw: matchPostfix1.group(0)!);
      }
    }

    // 2. Prefix negation on first number: (actually / sorry / no / nahi)? (not / no / nahi) <num1> <num2>
    // e.g. "actually not 250, it was 350", "not 250, 350", "nahi 250, 350"
    final corrPrefix1 = RegExp(
      r'(?:actually\s+|sorry\s+|no\s+|nahi\s+)?(?:not|no|nahi|இல்ல|కాదు)\s+(\d+(?:\.\d+)?)\s*(?:rs)?(?:,\s*|\s+(?:it\s+was|it\s+is|its|but|rather|balki)?\s*)(\d+(?:\.\d+)?)\s*(?:rs)?\b',
      caseSensitive: false,
    );
    final matchPrefix1 = corrPrefix1.firstMatch(text);
    if (matchPrefix1 != null) {
      final correctedVal = double.tryParse(matchPrefix1.group(2) ?? '');
      if (correctedVal != null && correctedVal > 0) {
        return _AmountResult(amount: correctedVal, isCertain: true, matchedRaw: matchPrefix1.group(0)!);
      }
    }

    // 3. Negation on second number: <num1> (actually / it was)? (not / no / nahi) <num2>
    // e.g. "actually 350 not 250", "350 rs not 250", "350 not 250", "actually 350 250 nahi"
    final corrPrefix2 = RegExp(
      r'(?:actually\s+)?(\d+(?:\.\d+)?)\s*(?:rs)?(?:,\s*|\s+(?:actually|it\s+was)?\s*)(?:not|no|nahi|இல்லை|இல்ல|కాదు)\s+(\d+(?:\.\d+)?)\s*(?:rs)?\b',
      caseSensitive: false,
    );
    final matchPrefix2 = corrPrefix2.firstMatch(text);
    if (matchPrefix2 != null) {
      final correctedVal = double.tryParse(matchPrefix2.group(1) ?? '');
      if (correctedVal != null && correctedVal > 0) {
        return _AmountResult(amount: correctedVal, isCertain: true, matchedRaw: matchPrefix2.group(0)!);
      }
    }

    // 4. Postfix negation on second number: <num1> rs <num2> (இல்லை / இல்ல / కాదు / नहीं / nahi)
    // e.g. "350 ரூபாய் 250 இல்லை", "350 రూపాయలు 250 కాదు", "350 रुपये 250 नहीं"
    final corrPostfix2 = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rs)?\s+(\d+(?:\.\d+)?)\s*(?:rs)?\s*(?:இல்லை|இல்ல|కాదు|नहीं|नही|nahi)\b',
      caseSensitive: false,
    );
    final matchPostfix2 = corrPostfix2.firstMatch(text);
    if (matchPostfix2 != null) {
      final correctedVal = double.tryParse(matchPostfix2.group(1) ?? '');
      if (correctedVal != null && correctedVal > 0) {
        return _AmountResult(amount: correctedVal, isCertain: true, matchedRaw: matchPostfix2.group(0)!);
      }
    }

    // B. Extract candidate numbers with multipliers and context
    final numberRegex = RegExp(
      r'(?:rs\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*(k|thousand|thousands|lakh|lakhs|lac|lacs|cr|crore|crores|हजार|हज़ार|लाख|करोड़|करोड|ஆயிரம்|லட்சம்|கோடி|లక్ష|వేలు|కోటి)?(?:\s*rs)?\b',
      caseSensitive: false,
    );

    final matches = numberRegex.allMatches(text).toList();
    _CandidateNumber? bestCandidate;

    for (var m in matches) {
      final rawDigits = m.group(1)?.replaceAll(',', '') ?? '0';
      double val = double.tryParse(rawDigits) ?? 0.0;
      if (val <= 0) continue;

      final mult = (m.group(2) ?? '').toLowerCase();
      if (mult == 'k' || mult.startsWith('thousand') || mult == 'ஆயிரம்' || mult == 'వేలు' || mult == 'हजार' || mult == 'हज़ार') {
        val *= 1000;
      } else if (mult.startsWith('lakh') || mult.startsWith('lac') || mult == 'லட்சம்' || mult == 'లక్ష' || mult == 'लाख') {
        val *= 100000;
      } else if (mult.startsWith('cr') || mult.startsWith('crore') || mult == 'கோடி' || mult == 'కోటి' || mult == 'करोड़' || mult == 'करोड') {
        val *= 10000000;
      }

      int score = 0;
      final fullMatchStr = m.group(0)!;
      final start = m.start;
      final end = m.end;

      final textAfter = text.substring(end).trimLeft();
      final textBefore = text.substring(0, start).trimRight();

      // Check if this number is a quantity (e.g. 2 coffees, 3 shirts, 5 kg, 1 liter milk, 2 समोसे)
      final isQuantity = RegExp(
        r'^(?:cups?|coffees?|teas?|items?|pizzas?|shirts?|pants?|kg|kgs?|grams?|gm|gms?|liters?|litres?|l|ml|plates?|bottles?|packets?|packs?|boxes?|tickets?|piece|pieces?|டீ|காபி|தோசை|சட்டை|தட்டு|லிட்டர்|கிலோ|பாக்கெட்|టీ|టీలు|దోశలు|కప్పులు|ప్లేట్లు|లీటర్లు|కిలో|ప్యాకెట్|कप|चाय|समोसे|समोसा|प्लेट|किलो|लीटर|पैकेट|बोतल|पीस)\b',
        caseSensitive: false,
      ).hasMatch(textAfter);

      if (isQuantity) {
        score -= 50; // Heavily penalize item quantities
      }

      // Check if this number is a date ordinal (e.g., "25th", "1st")
      if (RegExp(r'^(?:st|nd|rd|th)\b', caseSensitive: false).hasMatch(textAfter)) {
        score -= 40;
      }

      // Heavily penalize 10-digit mobile phone numbers or bank accounts
      if (rawDigits.length >= 10 && !rawDigits.contains('.')) {
        score -= 100;
      }

      // Direct currency marker attached or adjacent
      if (fullMatchStr.contains('rs') ||
          textBefore.endsWith('rs') ||
          textAfter.startsWith('rs') ||
          textAfter.startsWith('for') ||
          textAfter.startsWith('का') ||
          textAfter.startsWith('के') ||
          textAfter.startsWith('ஆச்சு') ||
          textAfter.startsWith('செலவு') ||
          textAfter.startsWith('கொடுத்தேன்') ||
          textAfter.startsWith('ఖర్చు') ||
          textAfter.startsWith('ఇచ్చాను') ||
          textAfter.startsWith('खर्च') ||
          textAfter.startsWith('दिए')) {
        score += 35;
      }

      // Preceded by transaction prepositions: "for 650", "of 500", "spent 250", "paid 80"
      if (RegExp(r'\b(for|of|spent|spend|paid|pay|bought|buy|செலவு|செலுத்தினேன்|கொடுத்தேன்|வாங்கினேன்|ఖర్చు|ఇచ్చాను|చెల్లించాను|కొన్నాను|खर्च|दिए|दिया|खरीदा|भरे)\s*$', caseSensitive: false).hasMatch(textBefore)) {
        score += 30;
      }

      // Higher amounts are generally transaction totals rather than quantities
      if (val >= 10) score += 10;
      if (val >= 100) score += 10;

      final cand = _CandidateNumber(value: val, score: score, matchStr: fullMatchStr);
      if (bestCandidate == null || cand.score > bestCandidate.score) {
        bestCandidate = cand;
      }
    }

    if (bestCandidate != null && bestCandidate.value > 0) {
      return _AmountResult(
        amount: bestCandidate.value,
        isCertain: bestCandidate.score >= 20,
        matchedRaw: bestCandidate.matchStr,
      );
    }

    // C. Check for Hindi spoken number words
    final hindiWordAmount = _extractHindiWordAmount(text);
    if (hindiWordAmount != null && hindiWordAmount > 0) {
      return _AmountResult(amount: hindiWordAmount, isCertain: true, matchedRaw: '');
    }

    // D. Check for Tamil spoken number words
    final tamilWordAmount = _extractTamilWordAmount(text);
    if (tamilWordAmount != null && tamilWordAmount > 0) {
      return _AmountResult(amount: tamilWordAmount, isCertain: true, matchedRaw: '');
    }

    // E. Check for Telugu spoken number words
    final teluguWordAmount = _extractTeluguWordAmount(text);
    if (teluguWordAmount != null && teluguWordAmount > 0) {
      return _AmountResult(amount: teluguWordAmount, isCertain: true, matchedRaw: '');
    }

    // F. Check for English spoken number words
    final englishWordAmount = _extractEnglishWordAmount(text);
    if (englishWordAmount != null && englishWordAmount > 0) {
      return _AmountResult(amount: englishWordAmount, isCertain: true, matchedRaw: '');
    }

    return _AmountResult(amount: null, isCertain: false, matchedRaw: '');
  }

  // Helper: Hindi spoken number words
  static double? _extractHindiWordAmount(String text) {
    final Map<String, double> hindiNums = {
      // Crores & Lakhs
      'एक करोड़': 10000000.0,
      'दो लाख': 200000.0,
      'डेढ़ लाख': 150000.0,
      'एक लाख': 100000.0,
      'लाख': 100000.0,

      // Thousands combinations
      'नब्बे हजार': 90000.0,
      'अस्सी हजार': 80000.0,
      'सत्तर हजार': 70000.0,
      'साठ हजार': 60000.0,
      'पचास हजार': 50000.0,
      'चालीस हजार': 40000.0,
      'पैंतीस हजार': 35000.0,
      'तीस हजार': 30000.0,
      'पच्चीस हजार': 25000.0,
      'बीस हजार': 20000.0,
      'पंद्रह हजार': 15000.0,
      'बारह हजार': 12000.0,
      'दस हजार': 10000.0,
      'नौ हजार': 9000.0,
      'आठ हजार': 8000.0,
      'सात हजार': 7000.0,
      'छह हजार': 6000.0,
      'पांच हजार पांच सौ': 5500.0,
      'पांच हजार': 5000.0,
      'चार हजार': 4000.0,
      'साढ़े तीन हजार': 3500.0,
      'तीन हजार': 3000.0,
      'ढाई हजार': 2500.0,
      'दो हजार पांच सौ': 2500.0,
      'दो हजार': 2000.0,
      'डेढ़ हजार': 1500.0,
      'एक हजार पांच सौ': 1500.0,
      'एक हजार': 1000.0,
      'हजार': 1000.0,

      // Hundreds combinations
      'साढ़े नौ सौ': 950.0,
      'नौ सौ पचास': 950.0,
      'नौ सौ': 900.0,
      'साढ़े आठ सौ': 850.0,
      'आठ सौ पचास': 850.0,
      'आठ सौ': 800.0,
      'साढ़े सात सौ': 750.0,
      'सात सौ पचास': 750.0,
      'सात सौ': 700.0,
      'साढ़े छह सौ': 650.0,
      'छह सौ पचास': 650.0,
      'छह सौ': 600.0,
      'साढ़े पांच सौ': 550.0,
      'पांच सौ पचास': 550.0,
      'पांच सौ': 500.0,
      'साढ़े चार सौ': 450.0,
      'चार सौ पचास': 450.0,
      'चार सौ': 400.0,
      'साढ़े तीन सौ': 350.0,
      'तीन सौ पचास': 350.0,
      'तीन सौ': 300.0,
      'ढाई सौ': 250.0,
      'दो सौ पचास': 250.0,
      'दो सौ': 200.0,
      'डेढ़ सौ': 150.0,
      'एक सौ पचास': 150.0,
      'एक सौ बीस': 120.0,
      'एक सौ अस्सी': 180.0,
      'एक सौ': 100.0,
      'सौ': 100.0,

      // Tens & Units
      'नब्बे': 90.0,
      'पिचयासी': 85.0,
      'अस्सी': 80.0,
      'पचहत्तर': 75.0,
      'सत्तर': 70.0,
      'पैंसठ': 65.0,
      'साठ': 60.0,
      'पचपन': 55.0,
      'पचास': 50.0,
      'पैंतालीस': 45.0,
      'चालीस': 40.0,
      'पैंतीस': 35.0,
      'तीस': 30.0,
      'पच्चीस': 25.0,
      'बीस': 20.0,
      'पंद्रह': 15.0,
      'बारह': 12.0,
      'दस': 10.0,
      'आठ': 8.0,
      'सात': 7.0,
      'छह': 6.0,
      'पांच': 5.0,
    };

    for (var entry in hindiNums.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // Helper: Tamil spoken number words
  static double? _extractTamilWordAmount(String text) {
    final Map<String, double> tamilNums = {
      // Thousands & Lakhs combinations
      'ஒரு கோடி': 10000000.0,
      'இரண்டு லட்சம்': 200000.0,
      'ரெண்டு லட்சம்': 200000.0,
      'ஒரு லட்சம்': 100000.0,
      'தொண்ணூறாயிரம்': 90000.0,
      'எண்பதாயிரம்': 80000.0,
      'எழுபதாயிரம்': 70000.0,
      'அறுபதாயிரம்': 60000.0,
      'ஐம்பதாயிரம்': 50000.0,
      'நாற்பதாயிரம்': 40000.0,
      'முப்பதாயிரம்': 30000.0,
      'இருபதாயிரம்': 20000.0,
      'பதினைந்தாயிரம்': 15000.0,
      'பதினஞ்சாயிரம்': 15000.0,
      'பன்னிரண்டாயிரம்': 12000.0,
      'பத்தாயிரம்': 10000.0,
      'ஒன்பதாயிரம்': 9000.0,
      'எட்டாயிரம்': 8000.0,
      'ஏழாயிரம்': 7000.0,
      'ஆறாயிரம்': 6000.0,
      'ஐந்தாயிரத்து ஐந்நூறு': 5500.0,
      'ஐந்தாயிரம்': 5000.0,
      'அஞ்சாயிரம்': 5000.0,
      'நான்காயிரம்': 4000.0,
      'மூன்றாயிரத்து ஐந்நூறு': 3500.0,
      'மூன்றாயிரம்': 3000.0,
      'மூவாயிரம்': 3000.0,
      'இரண்டாயிரத்து ஐந்நூறு': 2500.0,
      'ரெண்டாயிரத்து ஐந்நூறு': 2500.0,
      'இரண்டாயிரம்': 2000.0,
      'ரெண்டாயிரம்': 2000.0,
      'ஆயிரத்து ஐந்நூறு': 1500.0,
      'ஆயிரம்': 1000.0,
      'லட்சம்': 100000.0,

      // Hundreds combinations
      'ஐந்நூற்றைம்பது': 550.0,
      'ஐந்நூற்று ஐம்பது': 550.0,
      'ஐநூற்று ஐம்பது': 550.0,
      'நானூற்றைம்பது': 450.0,
      'நானூற்று ஐம்பது': 450.0,
      'முந்நூற்றைம்பது': 350.0,
      'முந்நூற்று ஐம்பது': 350.0,
      'முன்னூற்று ஐம்பது': 350.0,
      'இருநூற்றைம்பது': 250.0,
      'இருநூற்று ஐம்பது': 250.0,
      'இருநூற்றி ஐம்பது': 250.0,
      'நூற்றைம்பது': 150.0,
      'நூற்றி ஐம்பது': 150.0,
      'நூற்று ஐம்பது': 150.0,
      'நூற்றி இருபது': 120.0,
      'நூற்று இருபது': 120.0,
      'நூற்றி எண்பது': 180.0,
      'நூற்று எண்பது': 180.0,
      'நூற்றெண்பது': 180.0,

      // Hundreds
      'தொள்ளாயிரம்': 900.0,
      'எண்ணூறு': 800.0,
      'எழுநூறு': 700.0,
      'அறுநூறு': 600.0,
      'ஐந்நூறு': 500.0,
      'ஐநூறு': 500.0,
      'நானூறு': 400.0,
      'முந்நூறு': 300.0,
      'முன்னூறு': 300.0,
      'இருநூறு': 200.0,
      'நூறு': 100.0,

      // Tens
      'தொண்ணூறு': 90.0,
      'எண்பது': 80.0,
      'எழுபது': 70.0,
      'அறுபது': 60.0,
      'ஐம்பது': 50.0,
      'நாற்பது': 40.0,
      'முப்பது': 30.0,
      'இருபது': 20.0,
      'பத்து': 10.0,
    };

    for (var entry in tamilNums.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // Helper: Telugu spoken number words
  static double? _extractTeluguWordAmount(String text) {
    final Map<String, double> teluguNums = {
      // Thousands & Lakhs combinations
      'ఒక కోటి': 10000000.0,
      'రెండు లక్షలు': 200000.0,
      'ఒక లక్ష': 100000.0,
      'తొంభై వేలు': 90000.0,
      'ఎనభై వేలు': 80000.0,
      'డెబ్బై వేలు': 70000.0,
      'అరవై వేలు': 60000.0,
      'యాభై వేలు': 50000.0,
      'నలభై వేలు': 40000.0,
      'ముప్పై వేలు': 30000.0,
      'ఇరవై వేలు': 20000.0,
      'పదిహేను వేలు': 15000.0,
      'పన్నెండు వేలు': 12000.0,
      'పది వేలు': 10000.0,
      'తొమ్మిది వేలు': 9000.0,
      'ఎనిమిది వేలు': 8000.0,
      'ఏడు వేలు': 7000.0,
      'ఆరు వేలు': 6000.0,
      'ఐదు వేలు': 5000.0,
      'నాలుగు వేలు': 4000.0,
      'మూడు వేలు': 3000.0,
      'రెండు వేల ఐదు వందలు': 2500.0,
      'రెండు వేలు': 2000.0,
      'పదిహేను వందలు': 1500.0,
      'వెయ్యి': 1000.0,
      'వెయ్య': 1000.0,
      'లక్ష': 100000.0,

      // Hundreds combinations
      'తొమ్మిది వందల యాభై': 950.0,
      'ఎనిమిది వందల యాభై': 850.0,
      'ఏడు వందల యాభై': 750.0,
      'ఆరు వందల యాభై': 650.0,
      'ఐదు వందల యాభై': 550.0,
      'నాలుగు వందల యాభై': 450.0,
      'మూడు వందల యాభై': 350.0,
      'రెండు వందల యాభై': 250.0,
      'నూట యాభై': 150.0,
      'నూట ఎనభై': 180.0,
      'నూరు ఎనభై': 180.0,
      'నూట ఇరవై': 120.0,

      // Hundreds
      'తొమ్మిది వందలు': 900.0,
      'ఎనిమిది వందలు': 800.0,
      'ఏడు వందలు': 700.0,
      'ఆరు వందలు': 600.0,
      'ఐదు వందలు': 500.0,
      'నాలుగు వందలు': 400.0,
      'మూడు వందలు': 300.0,
      'రెండు వందలు': 200.0,
      'వంద': 100.0,
      'నూరు': 100.0,

      // Tens
      'తొంభై': 90.0,
      'ఎనభై': 80.0,
      'దెబ్బై': 70.0,
      'అరవై': 60.0,
      'యాభై': 50.0,
      'నలభై': 40.0,
      'ముప్పై': 30.0,
      'ఇరవై': 20.0,
      'పది': 10.0,
    };

    for (var entry in teluguNums.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // Helper: English spoken word numbers & colloquial expressions
  static double? _extractEnglishWordAmount(String text) {
    final Map<String, double> commonPhrases = {
      // Colloquial expressions common in spoken Indian English
      'two fifty': 250.0,
      'three fifty': 350.0,
      'four fifty': 450.0,
      'five fifty': 550.0,
      'six fifty': 650.0,
      'seven fifty': 750.0,
      'eight fifty': 850.0,
      'nine fifty': 950.0,
      'twelve fifty': 1250.0,
      'fifteen hundred': 1500.0,
      'twenty five hundred': 2500.0,
      'thirty five hundred': 3500.0,
      'forty five hundred': 4500.0,
      'three thousand five hundred': 3500.0,
      'two thousand five hundred': 2500.0,
      'one thousand five hundred': 1500.0,
      'twenty five thousand': 25000.0,
      'fifteen thousand': 15000.0,
      'twenty thousand': 20000.0,
      'ten thousand': 10000.0,
      'five thousand': 5000.0,
      'two thousand': 2000.0,
      'one thousand': 1000.0,
      'one lakh': 100000.0,
      'two lakhs': 200000.0,
      'one crore': 10000000.0,
      'two hundred and fifty': 250.0,
      'two hundred fifty': 250.0,
      'three hundred and fifty': 350.0,
      'three hundred fifty': 350.0,
      'four hundred and fifty': 450.0,
      'four hundred fifty': 450.0,
      'five hundred and fifty': 550.0,
      'five hundred fifty': 550.0,
      'one hundred and fifty': 150.0,
      'one hundred fifty': 150.0,
      'one hundred and twenty': 120.0,
      'one hundred twenty': 120.0,
      'one hundred and eighty': 180.0,
      'one hundred eighty': 180.0,
      'nine hundred': 900.0,
      'eight hundred': 800.0,
      'seven hundred': 700.0,
      'six hundred': 600.0,
      'five hundred': 500.0,
      'four hundred': 400.0,
      'three hundred': 300.0,
      'two hundred': 200.0,
      'one hundred': 100.0,
      'ninety': 90.0,
      'eighty five': 85.0,
      'eighty': 80.0,
      'seventy five': 75.0,
      'seventy': 70.0,
      'sixty five': 65.0,
      'sixty': 60.0,
      'fifty five': 55.0,
      'fifty': 50.0,
      'forty five': 45.0,
      'forty': 40.0,
      'thirty five': 35.0,
      'thirty': 30.0,
      'twenty five': 25.0,
      'twenty': 20.0,
      'fifteen': 15.0,
      'twelve': 12.0,
      'ten': 10.0,
    };

    for (var entry in commonPhrases.entries) {
      final reg = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
      if (reg.hasMatch(text)) {
        return entry.value;
      }
    }

    return _parseComposableEnglishWords(text);
  }

  static double? _parseComposableEnglishWords(String text) {
    const Map<String, int> units = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
      'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
      'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
      'eighteen': 18, 'nineteen': 19,
    };
    const Map<String, int> tens = {
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    };

    final tokens = text.toLowerCase().split(RegExp(r'\s+'));
    double total = 0.0;
    double current = 0.0;
    bool foundAny = false;

    for (var token in tokens) {
      if (token == 'and') continue;

      if (units.containsKey(token)) {
        current += units[token]!;
        foundAny = true;
      } else if (tens.containsKey(token)) {
        current += tens[token]!;
        foundAny = true;
      } else if (token == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
        foundAny = true;
      } else if (token == 'thousand' || token == 'thousands') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
        foundAny = true;
      } else if (token == 'lakh' || token == 'lakhs' || token == 'lac' || token == 'lacs') {
        total += (current == 0 ? 1 : current) * 100000;
        current = 0;
        foundAny = true;
      } else if (token == 'crore' || token == 'crores') {
        total += (current == 0 ? 1 : current) * 10000000;
        current = 0;
        foundAny = true;
      } else {
        if (foundAny && (total > 0 || current > 0)) {
          break;
        }
      }
    }

    final result = total + current;
    return (foundAny && result > 0) ? result : null;
  }

  // ===========================================================================
  // 5. TRANSACTION TYPE (EXPENSE VS INCOME)
  // ===========================================================================
  static _TypeResult _parseType(String text) {
    // Income signals across English, Hindi, Tamil, Telugu
    final incomePatterns = [
      RegExp(r'\b(received|salary|income|refund|earned|deposit|credited|got paid|stipend|bonus|cashback|dividend|interest|revenue)\b', caseSensitive: false),
      RegExp(r'(सैलरी|वेतन|तनख्वाह|मिला|मिली|मिले|आया|आई|आए|जमा हुआ|क्रेडिट हुआ|कमाई|ब्याज|tankhwah|salary mili|aaya|mila)'),
      RegExp(r'(சம்பளம்|சம்பளம|சம்பளமா|ஊதியம்|வந்தது|கிடைத்தது|வரவு|வருமானம்|சேர்த்தது|பெற்றேன்|போட்டார்கள்|வரவு வைக்கப்பட்டது|sambalam|vanthuchu|vanthathu|kidaichathu)'),
      RegExp(r'(జీతం|జీతంగా|జీతము|వచ్చింది|వచ్చాయి|ఆదాయం|జమ అయింది|సంపాదించాను|లభించింది|క్రెడిట్ అయింది|వచ్చెను|jeetham|vachindi|vachayi)'),
    ];

    for (var pat in incomePatterns) {
      if (pat.hasMatch(text)) {
        return _TypeResult(type: 'income', isExplicit: true);
      }
    }

    // Expense signals
    final expensePatterns = [
      RegExp(r'\b(spent|spend|paid|pay|bought|buy|cost|gave|ordered|expense|purchased|billed)\b', caseSensitive: false),
      RegExp(r'(खर्च|खर्चा|खर्च किया|दिया|दिए|खरीदे|खरीदा|भरा|भरी|चुकाया|खाया|पीया|kharch|kharcha|diya|diye|khata|bhara)'),
      RegExp(r'(செலவு|செலவு ஆச்சு|செலவு பண்ணேன்|செலவு செய்தேன்|கொடுத்தேன்|வாங்கினேன்|சாப்பிட்டேன்|செலுத்தினேன்|போட்டேன்|கட்டினேன்|selavu|kuduthen|vaanginen|saapten|kattinen)'),
      RegExp(r'(ఖర్చు|ఖర్చు చేశాను|ఇచ్చాను|కొన్నాను|చెల్లించాను|తిన్నాను|కట్టాను|పెట్టాను|kharchu|chesanu|ichanu|konnanu|chellinchanu|tinnanu|kattanu)'),
    ];

    for (var pat in expensePatterns) {
      if (pat.hasMatch(text)) {
        return _TypeResult(type: 'expense', isExplicit: true);
      }
    }

    // Default is expense
    return _TypeResult(type: 'expense', isExplicit: false);
  }

  // ===========================================================================
  // 6. PAYMENT METHOD DETECTION & AUTOMATIC NOTIFICATION
  // ===========================================================================
  static _PaymentResult _parsePaymentMode(String text, String defaultMode) {
    // 1. Google Pay
    final gpayPattern = RegExp(
      r'(\b(gpay|google pay|googlepay|g pay)\b|ஜிபே|கூகுள் பே|கூகுள்பே|గూగుల్ పే|गूगल पे|गूगलपे)',
      caseSensitive: false,
    );
    if (gpayPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'Google Pay',
        explanation: 'Auto-detected: Paid via UPI (Google Pay)',
      );
    }

    // 2. PhonePe
    final phonepePattern = RegExp(
      r'(\b(phonepe|phone pe|phonepay|phone pay)\b|போன்பே|போன் பே|ఫోన్‌పే|ఫోన్ పే|फोनपे|फोन पे)',
      caseSensitive: false,
    );
    if (phonepePattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'PhonePe',
        explanation: 'Auto-detected: Paid via UPI (PhonePe)',
      );
    }

    // 3. Paytm
    final paytmPattern = RegExp(
      r'(\b(paytm|pay tm)\b|பேடிஎம்|పేటీఎం|पेटीएम|पे टीम)',
      caseSensitive: false,
    );
    if (paytmPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'Paytm',
        explanation: 'Auto-detected: Paid via UPI (Paytm)',
      );
    }

    // 4. BHIM / CRED / Amazon Pay
    final bhimPattern = RegExp(
      r'(\b(bhim|bhim upi|cred|amazon pay)\b|பீம்|భీమ్|भीम)',
      caseSensitive: false,
    );
    if (bhimPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'BHIM / CRED',
        explanation: 'Auto-detected: Paid via UPI (BHIM/CRED)',
      );
    }

    // 5. QR Code / Scan & Pay
    final qrPattern = RegExp(
      r'(\b(qr|qr code|scan|scanned|scan and pay|scan pay)\b|ஸ்கேன்|கியூஆர்|స్కాన్|क्यूआर|स्कैन|scan karke|scan panni|scan chesi|qr scan)',
      caseSensitive: false,
    );
    if (qrPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'QR Scan & Pay',
        explanation: 'Auto-detected: Paid via UPI (QR Scan & Pay)',
      );
    }

    // 6. Generic UPI / Online Payment
    final upiPattern = RegExp(
      r'(\b(upi|u p i|you pay eye|via upi|through upi|by upi|online payment|paid online|sent online|digital payment|digitally)\b|யுபிஐ|ஆன்லைன்|ஆன்லைனில்|యూపీఐ|ఆన్‌లైన్|ఆన్‌లైన్‌లో|यूपीआई|ऑनलाइन|gpay pannen|gpay chesa|gpay kiya|phonepe kiya|upi kiya|paytm kiya|upi se|upi la|upi lo|online la|online lo|online se)',
      caseSensitive: false,
    );
    if (upiPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'UPI',
        explanation: 'Auto-detected: Paid via UPI',
      );
    }

    // 7. Cash patterns (Exclude false positives like cashback or cashew)
    final isCashback = RegExp(r'\b(cashback|cash back|cashew)\b', caseSensitive: false).hasMatch(text);
    if (!isCashback) {
      final cashPattern = RegExp(
        r'(\b(cash|by cash|in cash|hard cash|paid cash|gave cash|cash payment|notes|cod|cash on delivery)\b|ரொக்கம்|ரொக்கமாக|ரொக்கமாய்|ரொக்கப்பணம்|கை ரொக்கம்|பணமாக|பணம் கொடுத்தேன்|பணமா கொடுத்தேன்|நேர்ல கொடுத்தேன்|கைல கொடுத்தேன்|நோட்டா கொடுத்தேன்|నగదు|నగదుగా|చేతి నగదు|నగదు ఇచ్చాను|నగదు రూపంలో|డబ్బులు|డబ్బులిచ్చాను|చేతిలో ఇచ్చాను|చేతికి ఇచ్చాను|నकद|रोकड़ा|कैश|हाथ में दिया|नगद|कैश दिया|कैश में|नकद दिया|rokkam|rokama|panama|panam kuduthen|cash ah|cash kuduthen|nagadu|dabbulu|cash lo|cash ichanu|cash diya|cash me|nagad diya|hath me diya|rokda|cash se)',
        caseSensitive: false,
      );
      if (cashPattern.hasMatch(text)) {
        return _PaymentResult(
          paymentMode: 'Cash',
          isExplicit: true,
          paymentProvider: 'Cash',
          explanation: 'Auto-detected: Paid in Cash',
        );
      }
    }

    // 8. Card patterns
    final cardPattern = RegExp(
      r'(\b(debit card|credit card|card|cards|visa|mastercard|rupay|amex|swipe|swiped|tap and pay|tapped card|pos|pos machine)\b|டெபிட் கார்டு|கிரெடிட் கார்டு|கார்டு|கார்டில்|கார்ட்|சுவைப்|கார்டு தேய்த்தேன்|డెబిట్ కార్డు|క్రెడిట్ కార్డు|కార్డు|కార్డుతో|స్వైప్|डेबिट कार्ड|क्रेडिट कार्ड|कार्ड|स्वाइप|स्वाइप किया|कार्ड लगाया|card la|card tho|card se|credit card se|debit card se|swipe kiya)',
      caseSensitive: false,
    );
    if (cardPattern.hasMatch(text)) {
      final isCredit = RegExp(r'\bcredit|கிரெடிட்|క్రెడిట్|क्रेडिट\b', caseSensitive: false).hasMatch(text);
      final isDebit = RegExp(r'\bdebit|டெபிட்|డెబిట్|डेबिट\b', caseSensitive: false).hasMatch(text);
      final provider = isCredit ? 'Credit Card' : isDebit ? 'Debit Card' : 'Card';
      return _PaymentResult(
        paymentMode: 'Card',
        isExplicit: true,
        paymentProvider: provider,
        explanation: 'Auto-detected: Paid with $provider',
      );
    }

    // 9. Bank Transfer patterns
    final bankPattern = RegExp(
      r'(\b(bank|bank transfer|account|net banking|netbanking|internet banking|neft|rtgs|imps|wire transfer|cheque|check|transferred to account)\b|வங்கி|வங்கி பரிமாற்றம்|வங்கி கணக்கு|நெட் பேங்கிங்|காசோலை|బ్యాంక్|బ్యాంకు|బ్యాంక్ బదిలీ|బ్యాంక్ ఖాతా|నెట్ బ్యాంకింగ్|ఖాతాలో|बैंक|बैंक ट्रांसफर|खाता|बैंक खाता|नेट बैंकिंग|चेक|bank me|khate me|account me|transfer kiya|bank la|account la|bank lo|account lo)',
      caseSensitive: false,
    );
    if (bankPattern.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'Bank Transfer',
        isExplicit: true,
        paymentProvider: 'Bank Transfer',
        explanation: 'Auto-detected: Paid via Bank Transfer',
      );
    }

    // 10. Contextual digital apps (Swiggy, Zomato, Blinkit, etc. when not specifying cash)
    final deliveryApps = RegExp(
      r'\b(swiggy|zomato|zepto|blinkit|instamart|uber|ola|rapido)\b',
      caseSensitive: false,
    );
    if (deliveryApps.hasMatch(text)) {
      return _PaymentResult(
        paymentMode: 'UPI',
        isExplicit: true,
        paymentProvider: 'UPI (App Order)',
        explanation: 'Auto-detected: Paid via UPI (Digital Order)',
      );
    }

    // Fallback: Use defaultMode or UPI as default
    final fallbackMode = defaultMode.isNotEmpty ? defaultMode : 'UPI';
    return _PaymentResult(
      paymentMode: fallbackMode,
      isExplicit: false,
      paymentProvider: null,
      explanation: 'Payment mode not mentioned — Defaulted to $fallbackMode',
    );
  }

  // ===========================================================================
  // 7. CATEGORY SELECTION (CONTEXTUAL & MULTILINGUAL)
  // ===========================================================================
  static _CategoryResult _parseCategory(String text, String type) {
    // A. If type is income, check for Salary first
    if (type == 'income') {
      if (RegExp(r'\b(salary|stipend|wage|wages|bonus|payroll)\b|சம்பளம்|ஊதியம்|ஜீதம்|వేతనం|सैलरी|वेतन|तनख्वाह', caseSensitive: false).hasMatch(text)) {
        return _CategoryResult(category: 'Salary', isCertain: true);
      }
      if (RegExp(r'\b(invest|investment|stocks?|dividend|mutual fund|interest|crypto)\b|முதலீடு|பங்கு|பெట్టుబడి|వడ్డీ|निवेश|शेयर|ब्याज', caseSensitive: false).hasMatch(text)) {
        return _CategoryResult(category: 'Investment', isCertain: true);
      }
      return _CategoryResult(category: 'Salary', isCertain: false);
    }

    // B. Contextual overrides (Compound concepts)
    // Medical shop / Pharmacy -> Health
    if (RegExp(r'\b(medical shop|pharmacy|chemist|hospital|clinic)\b|மருந்தகம்|மருந்துக் கடை|மெடிக்கல் ஷாப்|ఫార్మసీ|दवा दुकान|मेडिकल स्टोर|अस्पताल', caseSensitive: false).hasMatch(text)) {
      return _CategoryResult(category: 'Health', isCertain: true);
    }

    // Vegetable shop / Grocery store -> Groceries
    if (RegExp(r'\b(vegetable shop|grocery store|supermarket|dmart)\b|மளிகைக்கடை|காய்கறிக்கடை|కిరాణా కొట్టు|किराना दुकान|सब्जी मंडी|राशन दुकान', caseSensitive: false).hasMatch(text)) {
      return _CategoryResult(category: 'Groceries', isCertain: true);
    }

    // Gas cylinder / LPG / Gas bill -> Bills & Utilities
    if (RegExp(r'\b(gas cylinder|lpg|gas bill|cylinder booking)\b|கேஸ் சிலிண்டர்|சிலிண்டர்|గ్యాస్ సిలిండర్|సిలిండర్|गैस सिलेंडर|सिलेंडर', caseSensitive: false).hasMatch(text)) {
      return _CategoryResult(category: 'Bills & Utilities', isCertain: true);
    }

    // Movie ticket -> Entertainment
    if (RegExp(r'\b(movie ticket|cinema ticket|film ticket)\b|சினிமா டிக்கெட்|திரைப்பட டிக்கெட்|సినిమా టికెట్|मूवी टिकट|फिल्म टिकट', caseSensitive: false).hasMatch(text)) {
      return _CategoryResult(category: 'Entertainment', isCertain: true);
    }

    // Bus ticket / Train ticket / Flight ticket -> Transport
    if (RegExp(r'\b(bus ticket|train ticket|flight ticket|metro ticket|auto fare|cab fare|toll)\b|பேருந்து டிக்கெட்|ரயில் டிக்கெட்|பஸ் டிக்கெட்|బస్సు టికెట్|రైలు టికెట్|बस टिकट|ट्रेन टिकट|मेट्रो टिकट|ऑटो किराया', caseSensitive: false).hasMatch(text)) {
      return _CategoryResult(category: 'Transport', isCertain: true);
    }

    // C. Multilingual Semantic Category Rules:

    // 1. Food & Dining
    final foodKeywords = RegExp(
      r'(\b(lunch|dinner|breakfast|food|dining|meal|meals|snacks?|tea|chai|coffees?|biryani|pizza|burger|swiggy|zomato|starbucks|dominos|drinks?|tiffin|hotel|roti|rotis|dosas?|idlis?|parottas?|chapatis?|samosas?)\b|சாப்பாடு|சாப்பாட்டு|உணவு|மதிய உணவு|இரவு உணவு|காலை உணவு|டிபன்|சிற்றுண்டி|உணவகம்|ஹோட்டல்|டீ|காபி|தேநீர்|பிரியாணி|சாப்பிட்டேன்|டீக்கடை|பேக்கரி|தோசை|இட்லி|భోజనం|భోజనానికి|ఆహారం|లంచ్|డిన్నర్|అల్పాహారం|టిఫిన్|తిండి|హోటల్|టీ|టీకి|కాఫీ|బిర్యానీ|తిన్నాను|టీ కొట్టు|బేకరీ|రెస్టారెంట్|దోశ|ఇడ్లీ|खाना|खाने|नाश्ता|नाश्ते|चाय|समोसा|समोसे|रोटी|होटल|ढाबा|बिरयानी|पिज्जा|बर्गर|जोमैटो|स्विगी|मिठाई|रेस्टोरेंट|खाया|पीया|भोजन|saapten|bhojanam|tinnanu|khana|khane|nashta|chai|samosa)',
      caseSensitive: false,
    );
    if (foodKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Food & Dining', isCertain: true);
    }

    // 2. Groceries
    final groceryKeywords = RegExp(
      r'(\b(grocer(?:y|ies)|supermarket|market|vegetables?|fruits?|milk|curd|rice|dal|provisions?|dmart|bigbazaar|reliance|instamart|blinkit|zepto|jiomart|walmart)\b|காய்கறி|காய்கறிகள்|மளிகை|பழங்கள்|பால்|தயிர்|அரிசி|பருப்பு|சூப்பர் மார்க்கெட்|சந்தை|மளிகைக்கடை|கூరగాయలు|కూరగాయల|కిరాణా|సరుకులు|పండ్లు|పాలు|పెరుగు|బియ్యం|పప్పు|సూపర్ మార్కెట్|మార్కెట్|किराना|राशन|सब्जी|सब्जियां|फल|दूध|दही|आटा|चावल|दाल|सुपरमार्केट|मंडी|किराना दुकान|kaaikari|kooragayalu|sabzi|rashan|doodh|dahi)',
      caseSensitive: false,
    );
    if (groceryKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Groceries', isCertain: true);
    }

    // 3. Bills & Utilities (checked before Transport so current bills take precedence)
    final billKeywords = RegExp(
      r'(\b(bill|bills|electricity|power|current bill|eb bill|water bill|gas|cylinder|lpg|internet|wifi|broadband|recharge|dth|rent|postpaid|maintenance)\b|மின்சாரம்|மின்சாரக் கட்டணம்|மின்சார கட்டணம்|கரண்ட் பில்|தண்ணீர் பில்|குடிநீர்|கேஸ்|சிலிண்டர்|இணையம்|வைஃபை|ரீசார்ஜ்|வாடகை|విద్యుత్|విద్యుత్ బిల్లు|కరెంట్ బిల్లు|నీటి బిల్లు|గ్యాస్|సిలిండర్|ఇంటర్నెట్|వైఫై|రీఛార్జ్|అద్దె|కిరాయి|बिजली|बिजली का बिल|बिजली बिल|पानी का बिल|पानी बिल|गैस|सिलेंडर|गैस सिलेंडर|रिचार्ज|मोबाइल रिचार्ज|इंटरनेट|वाईफाई|किराया|bijli bill|cylinder|recharge|kiraya)',
      caseSensitive: false,
    );
    if (billKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Bills & Utilities', isCertain: true);
    }

    // 4. Transport
    final transportKeywords = RegExp(
      r'(\b(petrol|diesel|fuel|gas|auto|taxi|cab|uber|ola|rapido|bus|train|metro|flight|ticket|fare|toll|parking|travel|petrol bunk|petrol pump)\b|பெட்ரோல்|பெட்ரோல|டீசல்|டீசல|எரிபொருள்|பேருந்து|பஸ்|ரயில்|ஆட்டோ|வாடகை வண்டி|டாக்ஸி|உபேர்|ஓலா|ரேபிடோ|மெட்ரோ|டிக்கெட்|பயணக் கட்டணம்|பயண கட்டணம்|பயணம்|சுங்கச்சாவடி|பெட்ரோல் பங்க்|పెట్రోల్|పెట్రోలు|డీజిల్|ఇంధనం|బస్సు|రైలు|ఆటో|క్యాబ్|టాక్సీ|ఊబర్|ఓలా|ర్యాపిడో|మెట్రో|టికెట్|ఛార్జీ|ప్రయాణం|టోల్|పెట్రోల్ బంక్|पेट्रोल|डीजल|ईंधन|ऑटो|टैक्सी|कैब|उबर|ओला|रैपिडो|बस|ट्रेन|रेल|मेट्रो|फ्लाइट|किराया|टोल|पेट्रोल पंप|petrol|diesel|auto|cab)',
      caseSensitive: false,
    );
    if (transportKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Transport', isCertain: true);
    }

    // 5. Health
    final healthKeywords = RegExp(
      r'(\b(hospital|doctor|clinic|medicine|medicines|pharmacy|medical|apollo|tablets?|dental|checkup|test|lab|pills)\b|மருத்துவர்|டாக்டர்|மருத்துவமனை|மருந்து|மருந்துகள்|மாத்திரை|மாத்திரைகள்|மருந்தகம்|கிளினிக்|பரிசோதனை|சிகிச்சை|వైద్యుడు|డాక్టర్|ఆసుపత్రి|మందులు|మందు|మాత్రలు|మెడికల్|క్లినిక్|చికిత్స|ఆరోగ్యం|दवा|दवाइयां|दवाई|डॉक्टर|अस्पताल|हॉस्पिटल|मेडिकल|क्लिनिक|टेस्ट|लैब|गोली|गोलियां|dawa|dawai|doctor|hospital)',
      caseSensitive: false,
    );
    if (healthKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Health', isCertain: true);
    }

    // 6. Shopping
    final shoppingKeywords = RegExp(
      r'(\b(shopping|clothes|clothing|shirt|pant|dress|shoes?|sandals?|amazon|flipkart|myntra|meesho|zara|mall|apparel|footwear)\b|துணி|ஆடைகள்|சட்டை|பேண்ட்|காலணி|செருப்பு|ஷாப்பிங்|அமேசான்|பிளிப்கார்ட்|துணிக்கடை|బట్టలు|బట్టల|దుస్తులు|దుస్తుల|చొక్కా|ప్యాంట్|చెప్పులు|షాపింగ్|అమెజాన్|ఫ్లిప్‌కార్ట్|వస్త్రాలు|कपड़े|कपड़ा|कपड़े|जूते|चप्पल|शॉपिंग|साड़ी|शर्ट|पैंट|मॉल|अमेज़न|फ्लिपकार्ट|दुकान से कपड़े|kapde|shopping|joote)',
      caseSensitive: false,
    );
    if (shoppingKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Shopping', isCertain: true);
    }

    // 7. Entertainment
    final entertainmentKeywords = RegExp(
      r'(\b(movie|movies|cinema|film|theater|theatre|netflix|spotify|prime|hotstar|youtube|concert|game|gaming|bookmyshow)\b|திரைப்படம்|சினிமா|படம்|தியேட்டர்|நெட்பிளிக்ஸ்|பொழுதுபோக்கு|సినిమా|సినిమాలు|చిత్రం|థియేటర్|నెట్‌ఫ్లిక్స్|విలక్షణ|వినోదం|फिल्म|मूवी|सिनेमा|थिएटर|नेटफ्लिक्स|हॉटस्टार|यूट्यूब|कंसर्ट|गेम|मूवी टिकट|movie|film|cinema)',
      caseSensitive: false,
    );
    if (entertainmentKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Entertainment', isCertain: true);
    }

    // 8. Investment
    final investmentKeywords = RegExp(
      r'(\b(invest|investment|mutual fund|sip|stocks?|shares?|crypto|gold|zerodha|groww|trading)\b|முதலீடு|பங்கு|பங்குகள்|தங்கம்|சேமிப்பு|పెట్టుబడి|షేర్లు|స్టాక్స్|బంగారం|పొదుపు|निवेश|शेयर|स्टॉक|म्यूच्यूअल फण्ड|एसआईपी|गोल्ड|सोना|ट्रेडिंग|nivesh|shares|gold)',
      caseSensitive: false,
    );
    if (investmentKeywords.hasMatch(text)) {
      return _CategoryResult(category: 'Investment', isCertain: true);
    }

    // Fallback: Other
    return _CategoryResult(category: 'Other', isCertain: false);
  }

  // ===========================================================================
  // 8. DATE EXTRACTION
  // ===========================================================================
  static _DateResult _parseDate(String text) {
    final now = DateTime.now();

    // Day before yesterday
    if (RegExp(r'\b(day before yesterday)\b|முந்தாநேத்து|முந்தைய நாள்|మొన్న|परसों|परसो|parso|parson', caseSensitive: false).hasMatch(text)) {
      final target = now.subtract(const Duration(days: 2));
      return _DateResult(date: target, isExplicit: true);
    }

    // Yesterday
    if (RegExp(r'\b(yesterday|yday|last night)\b|நேத்து|நேற்று|நின்ன|నిన్న|నిన్నటి|कल रात|बीता कल|कल|nethu|netru|ninna|kal', caseSensitive: false).hasMatch(text)) {
      final target = now.subtract(const Duration(days: 1));
      return _DateResult(date: target, isExplicit: true);
    }

    // Today
    if (RegExp(r'\b(today|this morning|tonight)\b|இன்னைக்கு|இன்று|இந்த காலை|ఈరోజు|ఈ రోజు|आज सुबह|आज रात|आज|innikku|eroju|aaj', caseSensitive: false).hasMatch(text)) {
      return _DateResult(date: now, isExplicit: true);
    }

    // Default is today
    return _DateResult(date: now, isExplicit: false);
  }

  // ===========================================================================
  // 9. MERCHANT & DESCRIPTION EXTRACTION
  // ===========================================================================
  static String _extractDescription(
    String rawOriginal,
    String normalized,
    _AmountResult amountResult,
    String category,
    _PaymentResult paymentResult,
    _TypeResult typeResult,
    _DateResult dateResult,
  ) {
    // 1. Check for specific named merchants / entities (Multilingual)
    final knownMerchants = {
      'tea shop': 'Tea Shop',
      'tea stall': 'Tea Stall',
      'chai shop': 'Tea Stall',
      'டீக்கடை': 'டீக்கடை',
      'டீ கடை': 'டீக்கடை',
      'టీ కొట్టు': 'టీ కొట్టు',
      'టీ షాప్': 'టీ కొట్టు',
      'चाय की दुकान': 'चाय की दुकान',
      'चाय दुकान': 'चाय की दुकान',
      'किराना दुकान': 'किराना दुकान',
      'किराना स्टोर': 'किराना स्टोर',
      'petrol bunk': 'Petrol Bunk',
      'petrol pump': 'Petrol Pump',
      'பெட்ரோல் பங்க்': 'பெட்ரோல் பங்க்',
      'పెట్రోల్ బంక్': 'పెట్రోల్ బంక్',
      'पेट्रोल पंप': 'पेट्रोल पंप',
      'starbucks': 'Starbucks',
      'zomato': 'Zomato',
      'swiggy': 'Swiggy',
      'dominos': 'Dominos Pizza',
      'mcdonalds': 'McDonalds',
      'amazon': 'Amazon',
      'flipkart': 'Flipkart',
      'dmart': 'DMart Supermarket',
      'டிமார்ட்': 'DMart Supermarket',
      'డిమార్ట్': 'DMart Supermarket',
      'jiomart': 'JioMart',
      'blinkit': 'Blinkit',
      'zepto': 'Zepto',
      'instamart': 'Swiggy Instamart',
      'netflix': 'Netflix',
      'spotify': 'Spotify',
      'uber': 'Uber',
      'ola': 'Ola Cabs',
      'rapido': 'Rapido',
      'apollo': 'Apollo Pharmacy',
      'அப்போலோ': 'Apollo Pharmacy',
      'అపోలో': 'Apollo Pharmacy',
      'dhaba': 'Dhaba',
      'ढाबा': 'ढाबा',
    };

    for (var entry in knownMerchants.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Identify key item nouns based on language
    // Hindi items
    if (normalized.contains('खाना') || normalized.contains('खाने') || normalized.contains('लंच') || normalized.contains('डिनर') || normalized.contains('नाश्ता')) {
      return 'खाना';
    }
    if (normalized.contains('चाय')) return 'चाय';
    if (normalized.contains('समोसा') || normalized.contains('समोसे')) return 'समोसा';
    if (normalized.contains('पेट्रोल')) return 'पेट्रोल';
    if (normalized.contains('डीजल')) return 'डीजल';
    if (normalized.contains('सब्जी') || normalized.contains('सब्जियां')) return 'सब्जी';
    if (normalized.contains('दूध')) return 'दूध';
    if (normalized.contains('दवाई') || normalized.contains('दवा')) return 'दवाई';
    if (normalized.contains('सैलरी') || normalized.contains('तनख्वाह')) return 'सैलरी';
    if (normalized.contains('कपड़े') || normalized.contains('कपड़े')) return 'कपड़े';

    // Tamil items
    if (normalized.contains('சாப்பிட்டேன்') || normalized.contains('சாப்பாடு') || normalized.contains('சாப்பாட்டு')) {
      return 'சாப்பாடு';
    }
    if (normalized.contains('பெட்ரோல்') || normalized.contains('பெட்ரோல')) return 'பெட்ரோல்';
    if (normalized.contains('டீசல்') || normalized.contains('டீசல')) return 'டீசல்';
    if (normalized.contains('காய்கறி')) return 'காய்கறி';
    if (normalized.contains('சம்பளம்') || normalized.contains('சம்பளம') || normalized.contains('சம்பளமா')) return 'சம்பளம்';
    if (normalized.contains('கடையில்') || normalized.contains('கடை')) return 'கடை';
    if (normalized.contains('டீ')) return 'டீ';
    if (normalized.contains('காபி')) return 'காபி';

    // Telugu items
    if (normalized.contains('భోజనానికి') || normalized.contains('భోజనం')) {
      return 'భోజనం';
    }
    if (normalized.contains('పెట్రోల్') || normalized.contains('పెట్రోలు')) return 'పెట్రోల్';
    if (normalized.contains('డీజిల్') || normalized.contains('డీజిలు')) return 'డీజిల్';
    if (normalized.contains('కూరగాయలు') || normalized.contains('కూరగాయల')) return 'కూరగాయలు';
    if (normalized.contains('జీతం') || normalized.contains('జీతంగా')) return 'జీతం';
    if (normalized.contains('టీకి') || normalized.contains('టీ')) return 'టీ';
    if (normalized.contains('కాఫీ')) return 'కాఫీ';

    // English items
    final itemMatches = [
      RegExp(r'\b(lunch|dinner|breakfast|food|coffee|coffees|tea|teas|groceries|petrol|diesel|fuel|salary|bonus|stipend|movie|cinema|electricity bill|water bill|wifi|snacks?|medicines?|shopping)\b', caseSensitive: false),
    ];
    for (var reg in itemMatches) {
      final m = reg.firstMatch(rawOriginal);
      if (m != null) {
        final val = m.group(0)!;
        return val[0].toUpperCase() + val.substring(1).toLowerCase();
      }
    }

    // 3. Fallback: Clean sentence by stripping conversational fillers and payment tokens
    String cleaned = rawOriginal;

    // Strip matched amount
    if (amountResult.matchedRaw.isNotEmpty) {
      cleaned = cleaned.replaceFirst(amountResult.matchedRaw, ' ');
    }

    final fillers = [
      RegExp(r'\b(i|we|my|me|spent|spend|paid|pay|bought|buy|received|credited|for|at|on|in|to|by|via|using|with|rs|rupees?|please|add|expense|income|transaction|yesterday|today|last night|this morning)\b', caseSensitive: false),
      RegExp(r'\b(upi|gpay|google pay|phonepe|paytm|cash|card|bank account|bank|scan|qr|bhim|cred)\b', caseSensitive: false),
      RegExp(r'(आज|कल|परसों|रुपये|रुपया|रुपए|खर्च|खर्चा|किया|दिए|दिया|भरे|भरा|भेजा|खाया|पीया|लिया|के लिए|को|में|से|कैश|नकद|गूगल पे|फोनपे|पेटीएम|यूपीआई|ऑनलाइन)'),
      RegExp(r'(இன்னைக்கு|நேத்து|நேற்று|ரூபாய்|ரூபாய்க்கு|ரூ|செலவு|செலவு ஆச்சு|கொடுத்தேன்|மூலம்|மூலமா|வந்தது|சாப்பிட்டேன்|வாங்க|வாங்கினேன்|சம்பளமா|ரொக்கமாக|ரொக்கம்|பணமாக)'),
      RegExp(r'(ఈరోజు|నిన్న|రూపాయలు|రూపాయి|ఖర్చు|ఖర్చు చేశాను|ఇచ్చాను|ద్వారా|వచ్చాయి|వచ్చింది|కోసం|జీతంగా|చెల్లించాను|నగదుగా|నగదు|డబ్బులు)'),
      RegExp(r'[,:;!?\.\-_"()]'),
    ];

    for (var f in fillers) {
      cleaned = cleaned.replaceAll(f, ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.length >= 3) {
      final words = cleaned.split(' ');
      return words.map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : '').join(' ');
    }

    // Safe fallback to category name
    return category;
  }
}

// Internal helper structures
class _AmountResult {
  final double? amount;
  final bool isCertain;
  final String matchedRaw;

  _AmountResult({required this.amount, required this.isCertain, required this.matchedRaw});
}

class _CandidateNumber {
  final double value;
  final int score;
  final String matchStr;

  _CandidateNumber({required this.value, required this.score, required this.matchStr});
}

class _TypeResult {
  final String type;
  final bool isExplicit;

  _TypeResult({required this.type, required this.isExplicit});
}

class _PaymentResult {
  final String paymentMode;
  final bool isExplicit;
  final String? paymentProvider;
  final String explanation;

  _PaymentResult({
    required this.paymentMode,
    required this.isExplicit,
    this.paymentProvider,
    required this.explanation,
  });
}

class _CategoryResult {
  final String category;
  final bool isCertain;

  _CategoryResult({required this.category, required this.isCertain});
}

class _DateResult {
  final DateTime date;
  final bool isExplicit;

  _DateResult({required this.date, required this.isExplicit});
}
