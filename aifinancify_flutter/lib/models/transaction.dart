class TransactionModel {
  final int? id;
  final String? userId;
  final double amount;
  final String? description;
  final String? category;
  final String type; // 'income' or 'expense'
  final String paymentMode; // 'Cash', 'Card', 'UPI', 'Bank Transfer', etc.
  final bool isRecurring;
  final String? recurringPeriod; // 'weekly', 'monthly'
  final DateTime? nextRecurringDate;
  final DateTime date;
  final double riskScore;
  final String riskReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get merchant => description ?? 'Transaction';

  TransactionModel({
    this.id,
    this.userId,
    required this.amount,
    this.description,
    this.category,
    this.type = 'expense',
    this.paymentMode = 'Cash',
    this.isRecurring = false,
    this.recurringPeriod,
    this.nextRecurringDate,
    DateTime? date,
    this.riskScore = 0.0,
    this.riskReason = 'Normal transaction',
    this.createdAt,
    this.updatedAt,
  }) : date = date ?? DateTime.now();

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString()) ?? DateTime.now();
    }

    final cat = (json['category'] ?? '').toString().toLowerCase();
    final isIncomeCat = cat == 'salary' || cat == 'revenue' || cat == 'income' || cat == 'refund';
    final rawType = (json['type'] ?? '').toString().toLowerCase();
    final effectiveType = rawType.isNotEmpty ? rawType : (isIncomeCat ? 'income' : 'expense');

    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0),
      description: json['description']?.toString() ?? json['merchant']?.toString(),
      category: json['category']?.toString() ?? 'Other',
      type: effectiveType,
      paymentMode: json['paymentMode']?.toString() ?? json['payment_mode']?.toString() ?? 'Cash',
      isRecurring: json['isRecurring'] == true || json['is_recurring'] == true,
      recurringPeriod: json['recurringPeriod']?.toString() ?? json['recurring_period']?.toString(),
      nextRecurringDate: json['nextRecurringDate'] != null ? parseDate(json['nextRecurringDate']) : null,
      date: parseDate(json['date'] ?? json['createdAt']),
      riskScore: (json['riskScore'] is num)
          ? (json['riskScore'] as num).toDouble()
          : (double.tryParse(json['risk_score']?.toString() ?? '0') ?? 0.0),
      riskReason: json['riskReason']?.toString() ?? json['risk_reason']?.toString() ?? 'Normal transaction',
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  double get normalizedRiskScore => riskScore > 1.0 ? riskScore / 100.0 : riskScore;
  double get riskPercentage => (normalizedRiskScore * 100.0).clamp(0.0, 100.0);
  bool get isHighRisk => normalizedRiskScore >= 0.6;
  bool get isMediumRisk => normalizedRiskScore >= 0.35 && normalizedRiskScore < 0.6;
  bool get isLowRisk => normalizedRiskScore < 0.35;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
      'paymentMode': paymentMode,
      'isRecurring': isRecurring,
      if (recurringPeriod != null) 'recurringPeriod': recurringPeriod,
      if (nextRecurringDate != null) 'nextRecurringDate': nextRecurringDate!.toIso8601String(),
      'date': date.toIso8601String(),
      'riskScore': riskScore,
      'riskReason': riskReason,
    };
  }
}

typedef Transaction = TransactionModel;


