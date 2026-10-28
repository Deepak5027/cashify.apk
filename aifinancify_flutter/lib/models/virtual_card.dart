/// Digital Card Wallet Model for Financify
///
/// Complies with strict security standards:
/// - Never stores CVV, PIN, OTP, or full 16-digit PAN.
/// - Stores bank/issuer name, card nickname, cardholder name, card type, network,
///   last four digits, optional expiry date (MM/YY), and optional user notes.
class VirtualCardModel {
  final int? id;
  final String cardName;
  final String cardType;
  final String cardNetwork;
  final String bankName;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv; // Kept for backend backward-compatibility only; never displayed or requested
  final double spendingLimit;
  final double currentSpend;
  final bool isFrozen;
  final bool tapToPayEnabled;
  final bool internationalTx;
  final String cardColor;
  final bool isPrimary;
  final String notes;

  VirtualCardModel({
    this.id,
    this.cardName = 'Personal Card',
    this.cardType = 'Debit Card',
    this.cardNetwork = 'VISA',
    this.bankName = 'Bank',
    this.cardNumber = '•••• •••• •••• 0000',
    this.cardHolder = 'CARDHOLDER',
    this.expiryDate = '',
    this.cvv = '',
    this.spendingLimit = 50000.0,
    this.currentSpend = 0.0,
    this.isFrozen = false,
    this.tapToPayEnabled = true,
    this.internationalTx = false,
    this.cardColor = 'indigo',
    this.isPrimary = false,
    this.notes = '',
  });

  /// Extracts the last 4 digits safely from cardNumber
  String get lastFourDigits {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    return digits.padLeft(4, '0');
  }

  /// Clean masked number representation: •••• •••• •••• 1234
  String get maskedCardNumber => '•••• •••• •••• $lastFourDigits';

  bool get isCredit => cardType.toLowerCase().contains('credit');
  bool get isDebit => cardType.toLowerCase().contains('debit');
  bool get isPrepaid => cardType.toLowerCase().contains('prepaid');

  double get remainingBudget =>
      (spendingLimit - currentSpend).clamp(0.0, spendingLimit > 0 ? spendingLimit : 0.0);
  double get spendPercentage =>
      spendingLimit > 0 ? (currentSpend / spendingLimit).clamp(0.0, 1.0) : 0.0;

  factory VirtualCardModel.fromJson(Map<String, dynamic> json) {
    // If raw full 16-digit card number is sent from legacy, mask it immediately
    String rawNumber = json['cardNumber']?.toString() ?? '•••• •••• •••• 0000';
    final digitsOnly = rawNumber.replaceAll(RegExp(r'\D'), '');
    String safeNumber = rawNumber;
    if (digitsOnly.length >= 4) {
      final last4 = digitsOnly.substring(digitsOnly.length - 4);
      safeNumber = '•••• •••• •••• $last4';
    }

    return VirtualCardModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      cardName: json['cardName']?.toString() ?? 'Personal Card',
      cardType: json['cardType']?.toString() ?? 'Debit Card',
      cardNetwork: (json['cardNetwork']?.toString() ?? 'VISA').toUpperCase(),
      bankName: json['bankName']?.toString() ?? 'Bank',
      cardNumber: safeNumber,
      cardHolder: (json['cardHolder']?.toString() ?? 'CARDHOLDER').toUpperCase(),
      expiryDate: json['expiryDate']?.toString() ?? '',
      cvv: '', // Never store or propagate CVV
      spendingLimit: (json['spendingLimit'] is num)
          ? (json['spendingLimit'] as num).toDouble()
          : double.tryParse(json['spendingLimit']?.toString() ?? '50000') ?? 50000.0,
      currentSpend: (json['currentSpend'] is num)
          ? (json['currentSpend'] as num).toDouble()
          : double.tryParse(json['currentSpend']?.toString() ?? '0') ?? 0.0,
      isFrozen: json['isFrozen'] == true || json['isFrozen'] == 1,
      tapToPayEnabled: json['tapToPayEnabled'] != false && json['tapToPayEnabled'] != 0,
      internationalTx: json['internationalTx'] == true || json['internationalTx'] == 1,
      cardColor: json['cardColor']?.toString() ?? 'indigo',
      isPrimary: json['isPrimary'] == true || json['isPrimary'] == 1,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cardName': cardName,
      'cardType': cardType,
      'cardNetwork': cardNetwork,
      'bankName': bankName,
      'cardNumber': maskedCardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cvv': '', // Zero out CVV for safety
      'spendingLimit': spendingLimit,
      'currentSpend': currentSpend,
      'isFrozen': isFrozen,
      'tapToPayEnabled': tapToPayEnabled,
      'internationalTx': internationalTx,
      'cardColor': cardColor,
      'isPrimary': isPrimary,
      'notes': notes,
    };
  }

  VirtualCardModel copyWith({
    int? id,
    String? cardName,
    String? cardType,
    String? cardNetwork,
    String? bankName,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    double? spendingLimit,
    double? currentSpend,
    bool? isFrozen,
    bool? tapToPayEnabled,
    bool? internationalTx,
    String? cardColor,
    bool? isPrimary,
    String? notes,
  }) {
    return VirtualCardModel(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      cardType: cardType ?? this.cardType,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      bankName: bankName ?? this.bankName,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: '',
      spendingLimit: spendingLimit ?? this.spendingLimit,
      currentSpend: currentSpend ?? this.currentSpend,
      isFrozen: isFrozen ?? this.isFrozen,
      tapToPayEnabled: tapToPayEnabled ?? this.tapToPayEnabled,
      internationalTx: internationalTx ?? this.internationalTx,
      cardColor: cardColor ?? this.cardColor,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
    );
  }

  /// Validation utility to ensure card inputs adhere to security and formatting rules
  static Map<String, String> validateFields({
    required String cardName,
    required String bankName,
    required String cardHolder,
    required String lastFourDigits,
    String? expiryDate,
  }) {
    final Map<String, String> errors = {};

    if (cardName.trim().isEmpty) {
      errors['cardName'] = 'Card nickname is required';
    } else if (cardName.trim().length > 30) {
      errors['cardName'] = 'Nickname must be under 30 characters';
    }

    if (bankName.trim().isEmpty) {
      errors['bankName'] = 'Bank or issuer name is required';
    }

    if (cardHolder.trim().isEmpty) {
      errors['cardHolder'] = 'Cardholder name is required';
    }

    final cleanDigits = lastFourDigits.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length != 4) {
      errors['lastFourDigits'] = 'Last 4 digits must be exactly 4 numbers';
    }

    if (expiryDate != null && expiryDate.trim().isNotEmpty) {
      final exp = expiryDate.trim();
      final expRegex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
      if (!expRegex.hasMatch(exp)) {
        errors['expiryDate'] = 'Expiry format must be MM/YY (e.g. 12/28)';
      }
    }

    return errors;
  }
}
