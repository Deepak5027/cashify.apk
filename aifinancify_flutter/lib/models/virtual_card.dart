class VirtualCardModel {
  final int? id;
  final String cardName;
  final String cardType;
  final String cardNetwork;
  final String bankName;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final double spendingLimit;
  final double currentSpend;
  final bool isFrozen;
  final bool tapToPayEnabled;
  final bool internationalTx;
  final String cardColor;
  final bool isPrimary;

  VirtualCardModel({
    this.id,
    this.cardName = 'AiFinancify Virtual Card',
    this.cardType = 'Virtual Debit',
    this.cardNetwork = 'VISA',
    this.bankName = 'Federal Bank',
    this.cardNumber = '4532 •••• •••• 8821',
    this.cardHolder = 'AIFINANCIFY MEMBER',
    this.expiryDate = '08/29',
    this.cvv = '842',
    this.spendingLimit = 50000.0,
    this.currentSpend = 0.0,
    this.isFrozen = false,
    this.tapToPayEnabled = true,
    this.internationalTx = false,
    this.cardColor = 'indigo',
    this.isPrimary = false,
  });

  double get remainingBudget => (spendingLimit - currentSpend).clamp(0.0, spendingLimit);
  double get spendPercentage => spendingLimit > 0 ? (currentSpend / spendingLimit).clamp(0.0, 1.0) : 0.0;

  factory VirtualCardModel.fromJson(Map<String, dynamic> json) {
    return VirtualCardModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      cardName: json['cardName'] ?? 'AiFinancify Virtual Card',
      cardType: json['cardType'] ?? 'Virtual Debit',
      cardNetwork: json['cardNetwork'] ?? 'VISA',
      bankName: json['bankName'] ?? 'Federal Bank',
      cardNumber: json['cardNumber'] ?? '4532 •••• •••• 8821',
      cardHolder: json['cardHolder'] ?? 'AIFINANCIFY MEMBER',
      expiryDate: json['expiryDate'] ?? '08/29',
      cvv: json['cvv'] ?? '842',
      spendingLimit: (json['spendingLimit'] is num)
          ? (json['spendingLimit'] as num).toDouble()
          : double.tryParse(json['spendingLimit']?.toString() ?? '50000') ?? 50000.0,
      currentSpend: (json['currentSpend'] is num)
          ? (json['currentSpend'] as num).toDouble()
          : double.tryParse(json['currentSpend']?.toString() ?? '0') ?? 0.0,
      isFrozen: json['isFrozen'] == true || json['isFrozen'] == 1,
      tapToPayEnabled: json['tapToPayEnabled'] != false && json['tapToPayEnabled'] != 0,
      internationalTx: json['internationalTx'] == true || json['internationalTx'] == 1,
      cardColor: json['cardColor'] ?? 'indigo',
      isPrimary: json['isPrimary'] == true || json['isPrimary'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cardName': cardName,
      'cardType': cardType,
      'cardNetwork': cardNetwork,
      'bankName': bankName,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'spendingLimit': spendingLimit,
      'currentSpend': currentSpend,
      'isFrozen': isFrozen,
      'tapToPayEnabled': tapToPayEnabled,
      'internationalTx': internationalTx,
      'cardColor': cardColor,
      'isPrimary': isPrimary,
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
      cvv: cvv ?? this.cvv,
      spendingLimit: spendingLimit ?? this.spendingLimit,
      currentSpend: currentSpend ?? this.currentSpend,
      isFrozen: isFrozen ?? this.isFrozen,
      tapToPayEnabled: tapToPayEnabled ?? this.tapToPayEnabled,
      internationalTx: internationalTx ?? this.internationalTx,
      cardColor: cardColor ?? this.cardColor,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
