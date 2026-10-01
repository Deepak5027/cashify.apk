class InvoiceItemModel {
  final int? id;
  final String description;
  final double quantity;
  final double unitPrice;

  InvoiceItemModel({
    this.id,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      description: json['description'] ?? 'Item',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unitPrice: (json['unitPrice'] is num)
          ? (json['unitPrice'] as num).toDouble()
          : double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class InvoiceModel {
  final int? id;
  final String invoiceNo;
  final String clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String upiId;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String status; // paid, unpaid, overdue
  final double taxRate; // e.g. 18.0 for 18% GST
  final String? notes;
  final List<InvoiceItemModel> items;
  final double totalAmount;

  InvoiceModel({
    this.id,
    required this.invoiceNo,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    this.upiId = 'deepak@okaxis',
    DateTime? issueDate,
    this.dueDate,
    this.status = 'unpaid',
    this.taxRate = 18.0,
    this.notes,
    this.items = const [],
    this.totalAmount = 0.0,
  }) : issueDate = issueDate ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, it) => sum + it.total);
  double get taxAmount => (subtotal * taxRate) / 100.0;
  double get calculatedTotal => subtotal + taxAmount;

  String get upiPaymentUrl {
    final amt = (totalAmount > 0 ? totalAmount : calculatedTotal).toStringAsFixed(2);
    final cleanUpi = Uri.encodeComponent(upiId.trim().isNotEmpty ? upiId.trim() : 'deepak@okaxis');
    final cleanName = Uri.encodeComponent(clientName.trim().isNotEmpty ? clientName.trim() : 'AiFinancify Client');
    final cleanNote = Uri.encodeComponent('Payment for $invoiceNo');
    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$amt&cu=INR&tn=$cleanNote';
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<InvoiceItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((it) => InvoiceItemModel.fromJson(it)).toList();
    }

    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      invoiceNo: json['invoiceNo'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      clientName: json['clientName'] ?? 'Valued Client',
      clientEmail: json['clientEmail'],
      clientPhone: json['clientPhone'],
      upiId: json['upiId'] ?? 'deepak@okaxis',
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      status: json['status'] ?? 'unpaid',
      taxRate: (json['taxRate'] is num)
          ? (json['taxRate'] as num).toDouble()
          : double.tryParse(json['taxRate']?.toString() ?? '18') ?? 18.0,
      notes: json['notes'],
      items: parsedItems,
      totalAmount: (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'invoiceNo': invoiceNo,
      'clientName': clientName,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (clientPhone != null) 'clientPhone': clientPhone,
      'upiId': upiId,
      'issueDate': issueDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'status': status,
      'taxRate': taxRate,
      if (notes != null) 'notes': notes,
      'items': items.map((it) => it.toJson()).toList(),
      'totalAmount': totalAmount > 0 ? totalAmount : calculatedTotal,
    };
  }
}
