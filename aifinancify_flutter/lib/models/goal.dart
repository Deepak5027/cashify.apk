class GoalModel {
  final int? id;
  final String? userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GoalModel({
    this.id,
    this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.category = 'General',
    this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    return GoalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      name: json['name']?.toString() ?? 'Savings Goal',
      targetAmount: (json['target'] is num)
          ? (json['target'] as num).toDouble()
          : (json['target_amount'] is num)
              ? (json['target_amount'] as num).toDouble()
              : (double.tryParse(json['target']?.toString() ?? json['target_amount']?.toString() ?? '0') ?? 0.0),
      currentAmount: (json['saved'] is num)
          ? (json['saved'] as num).toDouble()
          : (json['current_amount'] is num)
              ? (json['current_amount'] as num).toDouble()
              : (double.tryParse(json['saved']?.toString() ?? json['current_amount']?.toString() ?? '0') ?? 0.0),
      deadline: parseDate(json['dueDate'] ?? json['deadline']),
      category: json['category']?.toString() ?? 'General',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'name': name,
      'target': targetAmount,
      'target_amount': targetAmount,
      'saved': currentAmount,
      'current_amount': currentAmount,
      if (deadline != null) 'dueDate': deadline!.toIso8601String(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'category': category,
    };
  }

  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) * 100 : 0.0;
  bool get isCompleted => currentAmount >= targetAmount && targetAmount > 0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);
}

typedef Goal = GoalModel;

