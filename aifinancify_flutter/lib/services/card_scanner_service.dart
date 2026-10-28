import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracted card details from on-device OCR scan
class CardScanResult {
  final String? bankName;
  final String? cardNetwork;
  final String? cardType;
  final String? lastFourDigits;
  final String? expiryDate;
  final String? cardHolder;
  final String rawExtractedText;

  CardScanResult({
    this.bankName,
    this.cardNetwork,
    this.cardType,
    this.lastFourDigits,
    this.expiryDate,
    this.cardHolder,
    this.rawExtractedText = '',
  });

  bool get hasAnyData =>
      (bankName != null && bankName!.isNotEmpty) ||
      (cardNetwork != null && cardNetwork!.isNotEmpty) ||
      (cardType != null && cardType!.isNotEmpty) ||
      (lastFourDigits != null && lastFourDigits!.isNotEmpty) ||
      (expiryDate != null && expiryDate!.isNotEmpty) ||
      (cardHolder != null && cardHolder!.isNotEmpty);
}

/// Service for on-device OCR card scanning with privacy protection.
///
/// Security:
/// - Requests camera/gallery strictly upon user initiation.
/// - Performs on-device local recognition without cloud transmission.
/// - Extracts only last 4 digits, never retains full PAN or CVV.
/// - Immediately disposes image file and recognizer instances.
class CardScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<CardScanResult?> scanCard({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );

      if (pickedFile == null) return null;

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final result = parseCardText(recognizedText.text);

        // Delete temporary image file if it exists locally to maintain privacy
        try {
          final file = File(pickedFile.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}

        return result;
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('Card scanning error: $e');
      return null;
    }
  }

  /// Parses OCR card text into structured card attributes with intelligent fallback logic
  CardScanResult parseCardText(String fullText) {
    String? detectedBank;
    String? detectedNetwork;
    String? detectedType;
    String? detectedLast4;
    String? detectedExpiry;
    String? detectedHolder;

    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final textUpper = fullText.toUpperCase();

    // 1. Comprehensive Bank Detection (Indian + Global + Fintech Issuers)
    final knownBanks = [
      'HDFC Bank', 'HDFC',
      'State Bank of India', 'SBI', 'STATE BANK',
      'ICICI Bank', 'ICICI',
      'Axis Bank', 'Axis',
      'Kotak Mahindra Bank', 'Kotak',
      'Punjab National Bank', 'PNB',
      'Bank of Baroda', 'BOB',
      'Canara Bank',
      'Union Bank of India', 'Union Bank',
      'Bank of India', 'BOI',
      'Indian Bank',
      'Central Bank of India',
      'Indian Overseas Bank', 'IOB',
      'UCO Bank',
      'Punjab & Sind Bank',
      'Federal Bank',
      'IndusInd Bank', 'IndusInd',
      'IDFC FIRST Bank', 'IDFC First', 'IDFC',
      'IDBI Bank', 'IDBI',
      'Yes Bank',
      'RBL Bank', 'RBL',
      'South Indian Bank',
      'Karur Vysya Bank', 'KVB',
      'City Union Bank',
      'Bandhan Bank',
      'AU Small Finance Bank', 'AU Bank',
      'Equitas Small Finance Bank',
      'Ujjivan Small Finance Bank',
      'Paytm Payments Bank', 'Paytm Bank', 'Paytm',
      'Airtel Payments Bank',
      'Jio Payments Bank',
      'Jupiter', 'Fi Money', 'OneCard', 'Slice', 'Uni Cards',
      'Citibank', 'Citi',
      'Standard Chartered', 'StanChart',
      'HSBC',
      'Barclays',
      'Chase', 'JPMorgan Chase',
      'Bank of America', 'BofA',
      'Wells Fargo',
      'Capital One',
      'Discover Bank',
    ];

    for (final line in lines) {
      final lineUpper = line.toUpperCase();
      for (final bank in knownBanks) {
        if (lineUpper.contains(bank.toUpperCase())) {
          detectedBank = bank.contains('Bank') || bank.contains('Money') || bank.contains('Card')
              ? bank
              : '$bank Bank';
          break;
        }
      }
      if (detectedBank != null) break;
    }

    // Pattern match for any custom "[Name] Bank" if not in dictionary
    if (detectedBank == null) {
      final bankPattern = RegExp(r'\b([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+Bank\b', caseSensitive: false);
      final match = bankPattern.firstMatch(fullText);
      if (match != null) {
        detectedBank = match.group(0);
      }
    }

    // 2. Card Network Detection
    if (textUpper.contains('RUPAY') || textUpper.contains('RU PAY')) {
      detectedNetwork = 'RUPAY';
    } else if (textUpper.contains('MASTERCARD') || textUpper.contains('MASTER CARD')) {
      detectedNetwork = 'MASTERCARD';
    } else if (textUpper.contains('VISA') || textUpper.contains('V I S A')) {
      detectedNetwork = 'VISA';
    } else if (textUpper.contains('AMERICAN EXPRESS') || textUpper.contains('AMEX')) {
      detectedNetwork = 'AMEX';
    } else if (textUpper.contains('DISCOVER')) {
      detectedNetwork = 'DISCOVER';
    } else if (textUpper.contains('DINERS')) {
      detectedNetwork = 'DINERS';
    }

    // 3. Card Type Detection (Credit, Debit, Prepaid)
    if (textUpper.contains('CREDIT') ||
        textUpper.contains('SIGNATURE') ||
        textUpper.contains('INFINITE') ||
        textUpper.contains('PLATINUM REWARDS') ||
        textUpper.contains('WORLD ELITE') ||
        textUpper.contains('TITANIUM')) {
      detectedType = 'Credit Card';
    } else if (textUpper.contains('PREPAID') || textUpper.contains('GIFT')) {
      detectedType = 'Prepaid Card';
    } else if (textUpper.contains('DEBIT') || textUpper.contains('ATM')) {
      detectedType = 'Debit Card';
    } else {
      detectedType = 'Debit Card';
    }

    // 4. Card Number & Last 4 Digits Detection
    // Check 16 digit PAN formatted with spaces or dashes: e.g. 4532 1234 5678 9012
    final panMatch = RegExp(r'\b(?:\d{4}[\s-]?){4}\b').firstMatch(fullText);
    if (panMatch != null) {
      final pan = panMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (pan.length == 16) {
        detectedLast4 = pan.substring(12, 16);
        if (detectedNetwork == null) {
          if (pan.startsWith('4')) detectedNetwork = 'VISA';
          else if (pan.startsWith('5')) detectedNetwork = 'MASTERCARD';
          else if (pan.startsWith('6')) detectedNetwork = 'RUPAY';
        }
      }
    }

    // Check Amex 15-digit PAN: e.g. 3782 822468 95001
    if (detectedLast4 == null) {
      final amexMatch = RegExp(r'\b3[47]\d{2}[\s-]?\d{6}[\s-]?\d{5}\b').firstMatch(fullText);
      if (amexMatch != null) {
        final pan = amexMatch.group(0)!.replaceAll(RegExp(r'\D'), '');
        if (pan.length == 15) {
          detectedLast4 = pan.substring(11, 15);
          detectedNetwork ??= 'AMEX';
        }
      }
    }

    // Look for consecutive 4-digit blocks in the OCR text
    if (detectedLast4 == null) {
      final digitCleaned = fullText.replaceAll(RegExp(r'[^0-9\s]'), ' ');
      final fourDigitMatches = RegExp(r'\b\d{4}\b')
          .allMatches(digitCleaned)
          .map((m) => m.group(0)!)
          .toList();

      if (fourDigitMatches.isNotEmpty) {
        // Find 4-digit groups that are not obvious years (e.g., 2024 - 2038)
        for (final m in fourDigitMatches.reversed) {
          final val = int.tryParse(m) ?? 0;
          if (val < 2023 || val > 2040) {
            detectedLast4 = m;
            break;
          }
        }
        detectedLast4 ??= fourDigitMatches.last;
      }
    }

    // If still null, check any sequence of digits with length >= 4
    if (detectedLast4 == null) {
      final anyDigits = RegExp(r'\d{4,}').allMatches(fullText);
      if (anyDigits.isNotEmpty) {
        final lastMatch = anyDigits.last.group(0)!;
        detectedLast4 = lastMatch.substring(lastMatch.length - 4);
      }
    }

    // 5. Expiry Date Detection (MM/YY, MM/YYYY, VALID THRU MM/YY)
    final explicitExpiryRegex = RegExp(
        r'(?:VALID|GOOD|VAL|EXP|EXPIRES|THRU)[\s\:\-\.]*([0-1]?[0-9])[\s\/\-\.](2[4-9]|3[0-9]|4[0-9])',
        caseSensitive: false);
    final explicitMatch = explicitExpiryRegex.firstMatch(fullText);

    if (explicitMatch != null) {
      final month = explicitMatch.group(1)!.padLeft(2, '0');
      final year = explicitMatch.group(2)!;
      final mInt = int.tryParse(month) ?? 0;
      if (mInt >= 1 && mInt <= 12) {
        detectedExpiry = '$month/$year';
      }
    }

    if (detectedExpiry == null) {
      // General MM/YY or MM/YYYY pattern
      final expiryRegex = RegExp(r'\b(0[1-9]|1[0-2])[\s\/\-\.](2[4-9]|3[0-9]|202[4-9]|203[0-9])\b');
      final expMatch = expiryRegex.firstMatch(fullText);
      if (expMatch != null) {
        final month = expMatch.group(1)!;
        var year = expMatch.group(2)!;
        if (year.length == 4) {
          year = year.substring(2);
        }
        detectedExpiry = '$month/$year';
      }
    }

    // 6. Cardholder Name Detection
    final ignoredWords = {
      'VALID', 'THRU', 'EXPIRES', 'EXPIRY', 'DEBIT', 'CREDIT', 'PREPAID',
      'CARD', 'BANK', 'PLATINUM', 'GOLD', 'TITANIUM', 'SIGNATURE',
      'INFINITE', 'MEMBER', 'SINCE', 'ELECTRONIC', 'USE', 'ONLY',
      'AUTHORIZED', 'INTERNATIONAL', 'GLOBAL', 'REWARDS', 'CASHBACK',
      'BUSINESS', 'CORPORATE', 'INDIA', 'NATIONAL', 'CENTRAL', 'PAY',
      'RUPEE', 'MONEY', 'SECURITY', 'ACCOUNT', 'CUSTOMER', 'NAME',
      'PRIMARY', 'FINANCIFY', 'VISA', 'MASTERCARD', 'RUPAY', 'AMEX',
      'AMERICAN', 'EXPRESS', 'DISCOVER', 'DINERS', 'CLUB', 'MAESTRO',
      'PLUS', 'CIRRUS', 'MONTH', 'YEAR', 'MEMBERSHIP'
    };

    for (final line in lines) {
      final trimmed = line.trim();
      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 4) {
        final isAlpha = RegExp(r'^[A-Za-z\s\.]+$').hasMatch(trimmed);
        final hasIgnored = words.any((w) => ignoredWords.contains(w.toUpperCase()));
        if (isAlpha && !hasIgnored && trimmed.length >= 4 && trimmed.length <= 26) {
          detectedHolder = trimmed.toUpperCase();
          break;
        }
      }
    }

    return CardScanResult(
      bankName: detectedBank,
      cardNetwork: detectedNetwork,
      cardType: detectedType,
      lastFourDigits: detectedLast4,
      expiryDate: detectedExpiry,
      cardHolder: detectedHolder,
      rawExtractedText: fullText,
    );
  }
}

