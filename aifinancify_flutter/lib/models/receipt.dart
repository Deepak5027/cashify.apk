class ReceiptItemModel {
  final int? id;
  final int? receiptId;
  final String name;
  final double price;
  final int quantity;

  ReceiptItemModel({
    this.id,
    this.receiptId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      receiptId: json['receiptId'] is int ? json['receiptId'] : int.tryParse(json['receiptId']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Item',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
      quantity: (json['quantity'] is int)
          ? json['quantity'] as int
          : (int.tryParse(json['quantity']?.toString() ?? '1') ?? 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (receiptId != null) 'receiptId': receiptId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

class ReceiptModel {
  final int? id;
  final String? userId;
  final double total;
  final String? merchant;
  final DateTime date;
  final List<ReceiptItemModel> items;
  final DateTime? createdAt;

  ReceiptModel({
    this.id,
    this.userId,
    required this.total,
    this.merchant,
    DateTime? date,
    List<ReceiptItemModel>? items,
    this.createdAt,
  })  : date = date ?? DateTime.now(),
        items = items ?? [];

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString()) ?? DateTime.now();
    }

    final rawItems = json['items'] as List? ?? [];
    return ReceiptModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId']?.toString(),
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : (double.tryParse(json['total']?.toString() ?? '0') ?? 0.0),
      merchant: json['merchant']?.toString() ?? 'Unknown Vendor',
      date: parseDate(json['date'] ?? json['createdAt']),
      items: rawItems.map((i) => ReceiptItemModel.fromJson(Map<String, dynamic>.from(i))).toList(),
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'total': total,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
