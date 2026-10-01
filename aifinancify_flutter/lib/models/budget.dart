class BudgetModel {
  final int? id;
  final String? userId;
  final String category; // or name
  final double limit;
  final String period; // 'monthly', 'weekly', etc.
  final double spent;
  final double predicted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get amount => limit;

  BudgetModel({
    this.id,
    this.userId,
    required this.category,
    required this.limit,
    this.period = 'monthly',
    this.spent = 0.0,
    this.predicted = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      category: json['name']?.toString() ?? json['category']?.toString() ?? 'General',
      limit: (json['limit'] is num)
          ? (json['limit'] as num).toDouble()
          : (double.tryParse(json['limit']?.toString() ?? json['amount']?.toString() ?? '0') ?? 0.0),
      period: json['period']?.toString() ?? 'monthly',
      spent: (json['spent'] is num)
          ? (json['spent'] as num).toDouble()
          : (double.tryParse(json['spent']?.toString() ?? '0') ?? 0.0),
      predicted: (json['predicted'] is num)
          ? (json['predicted'] as num).toDouble()
          : (double.tryParse(json['predicted']?.toString() ?? '0') ?? 0.0),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'name': category,
      'category': category,
      'limit': limit,
      'period': period,
    };
  }

  double get percentageUsed => limit > 0 ? (spent / limit) * 100 : 0.0;
  bool get isOverBudget => spent > limit;
  double get remaining => limit - spent;
}

typedef Budget = BudgetModel;

