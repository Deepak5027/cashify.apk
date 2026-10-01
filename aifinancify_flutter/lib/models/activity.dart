class ActivityModel {
  final int? id;
  final String? userId;
  final String action;
  final String title;
  final String? details;
  final String type; // 'info', 'income', 'expense', 'warning', etc.
  final DateTime createdAt;

  ActivityModel({
    this.id,
    this.userId,
    required this.action,
    required this.title,
    this.details,
    this.type = 'info',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString(),
      action: json['action']?.toString() ?? 'activity',
      title: json['title']?.toString() ?? 'Activity',
      details: json['details']?.toString(),
      type: json['type']?.toString() ?? 'info',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'action': action,
      'title': title,
      'details': details,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
