import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/virtual_card.dart';
import '../models/invoice.dart';

class PendingSyncItem {
  final String id;
  final String url;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final int timestamp;

  PendingSyncItem({
    required this.id,
    required this.url,
    required this.method,
    this.body,
    this.headers,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'method': method,
      'body': body != null ? jsonEncode(body) : null,
      'headers': headers != null ? jsonEncode(headers) : null,
      'timestamp': timestamp,
    };
  }

  factory PendingSyncItem.fromMap(Map<String, dynamic> map) {
    return PendingSyncItem(
      id: map['id'],
      url: map['url'],
      method: map['method'],
      body: map['body'] != null ? (map['body'] is String ? jsonDecode(map['body']) : map['body']) : null,
      headers: map['headers'] != null ? (map['headers'] is String ? Map<String, String>.from(jsonDecode(map['headers'])) : Map<String, String>.from(map['headers'])) : null,
      timestamp: map['timestamp'],
    );
  }
}

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db;
  }

  Future<Database?> _initDB() async {
    if (kIsWeb) return null;
    try {
      final path = join(await getDatabasesPath(), 'financeai_offline.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createTables(db);
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_syncs (
        id TEXT PRIMARY KEY,
        url TEXT,
        method TEXT,
        body TEXT,
        headers TEXT,
        timestamp INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_transactions (
        id INTEGER PRIMARY KEY,
        amount REAL,
        description TEXT,
        category TEXT,
        type TEXT,
        paymentMode TEXT,
        date TEXT,
        riskScore REAL,
        riskReason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_budgets (
        id INTEGER PRIMARY KEY,
        category TEXT,
        limitAmount REAL,
        spentAmount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_goals (
        id INTEGER PRIMARY KEY,
        name TEXT,
        targetAmount REAL,
        currentAmount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_virtual_cards (
        id INTEGER PRIMARY KEY,
        cardName TEXT,
        cardType TEXT,
        cardNetwork TEXT,
        bankName TEXT,
        cardNumber TEXT,
        cardHolder TEXT,
        expiryDate TEXT,
        cvv TEXT,
        spendingLimit REAL,
        currentSpend REAL,
        isFrozen INTEGER,
        tapToPayEnabled INTEGER,
        internationalTx INTEGER,
        cardColor TEXT,
        isPrimary INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_invoices (
        id INTEGER PRIMARY KEY,
        invoiceNo TEXT,
        clientName TEXT,
        clientEmail TEXT,
        clientPhone TEXT,
        upiId TEXT,
        issueDate TEXT,
        dueDate TEXT,
        status TEXT,
        taxRate REAL,
        notes TEXT,
        items TEXT,
        totalAmount REAL
      )
    ''');
  }

  // ==========================================
  // LOCAL TRANSACTIONS CACHE
  // ==========================================
  Future<void> saveLocalTransactions(List<TransactionModel> txs) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = txs.map((t) => t.toJson()).toList();
      await prefs.setString('web_local_transactions', jsonEncode(jsonList));
      return;
    }
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('local_transactions');
    for (var tx in txs) {
      batch.insert('local_transactions', {
        'id': tx.id ?? DateTime.now().millisecondsSinceEpoch,
        'amount': tx.amount,
        'description': tx.description,
        'category': tx.category,
        'type': tx.type,
        'paymentMode': tx.paymentMode,
        'date': tx.date.toIso8601String(),
        'riskScore': tx.riskScore,
        'riskReason': tx.riskReason,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertLocalTransaction(TransactionModel tx) async {
    if (kIsWeb) {
      final list = await getLocalTransactions();
      list.removeWhere((t) => t.id == tx.id);
      list.insert(0, tx);
      await saveLocalTransactions(list);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('local_transactions', {
      'id': tx.id ?? DateTime.now().millisecondsSinceEpoch,
      'amount': tx.amount,
      'description': tx.description,
      'category': tx.category,
      'type': tx.type,
      'paymentMode': tx.paymentMode,
      'date': tx.date.toIso8601String(),
      'riskScore': tx.riskScore,
      'riskReason': tx.riskReason,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getLocalTransactions() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_local_transactions');
      if (raw == null || raw.isEmpty) return [];
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((m) => TransactionModel.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('local_transactions', orderBy: 'date DESC');
    return maps.map((m) {
      return TransactionModel(
        id: m['id'] as int?,
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        description: m['description'] as String? ?? '',
        category: m['category'] as String? ?? 'General',
        type: m['type'] as String? ?? 'expense',
        paymentMode: m['paymentMode'] as String? ?? 'UPI',
        date: m['date'] != null ? (DateTime.tryParse(m['date'] as String) ?? DateTime.now()) : DateTime.now(),
        riskScore: (m['riskScore'] as num?)?.toDouble() ?? 0.0,
        riskReason: m['riskReason'] as String? ?? 'Normal',
      );
    }).toList();
  }

  // ==========================================
  // LOCAL BUDGETS CACHE
  // ==========================================
  Future<void> saveLocalBudgets(List<BudgetModel> budgets) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = budgets.map((b) => b.toJson()).toList();
      await prefs.setString('web_local_budgets', jsonEncode(jsonList));
      return;
    }
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('local_budgets');
    for (var b in budgets) {
      batch.insert('local_budgets', {
        'id': b.id ?? DateTime.now().millisecondsSinceEpoch,
        'category': b.category,
        'limitAmount': b.limit,
        'spentAmount': b.spent,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<BudgetModel>> getLocalBudgets() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_local_budgets');
      if (raw == null || raw.isEmpty) return [];
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((m) => BudgetModel.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('local_budgets');
    return maps.map((m) {
      return BudgetModel(
        id: m['id'] as int?,
        category: m['category'] as String? ?? 'General',
        limit: (m['limitAmount'] as num?)?.toDouble() ?? 0.0,
        spent: (m['spentAmount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // ==========================================
  // LOCAL GOALS CACHE
  // ==========================================
  Future<void> saveLocalGoals(List<GoalModel> goals) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = goals.map((g) => g.toJson()).toList();
      await prefs.setString('web_local_goals', jsonEncode(jsonList));
      return;
    }
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('local_goals');
    for (var g in goals) {
      batch.insert('local_goals', {
        'id': g.id ?? DateTime.now().millisecondsSinceEpoch,
        'name': g.name,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<GoalModel>> getLocalGoals() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_local_goals');
      if (raw == null || raw.isEmpty) return [];
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((m) => GoalModel.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('local_goals');
    return maps.map((m) {
      return GoalModel(
        id: m['id'] as int?,
        name: m['name'] as String? ?? 'Savings Goal',
        targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // ==========================================
  // LOCAL VIRTUAL CARDS CACHE
  // ==========================================
  Future<void> saveLocalVirtualCard(VirtualCardModel card) async {
    await saveLocalVirtualCards([card]);
  }

  Future<void> saveLocalVirtualCards(List<VirtualCardModel> cards) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = cards.map((c) => c.toJson()).toList();
      await prefs.setString('web_local_virtual_cards', jsonEncode(jsonList));
      return;
    }
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('local_virtual_cards');
    for (var card in cards) {
      batch.insert('local_virtual_cards', {
        'id': card.id ?? DateTime.now().millisecondsSinceEpoch,
        'cardName': card.cardName,
        'cardType': card.cardType,
        'cardNetwork': card.cardNetwork,
        'bankName': card.bankName,
        'cardNumber': card.cardNumber,
        'cardHolder': card.cardHolder,
        'expiryDate': card.expiryDate,
        'cvv': card.cvv,
        'spendingLimit': card.spendingLimit,
        'currentSpend': card.currentSpend,
        'isFrozen': card.isFrozen ? 1 : 0,
        'tapToPayEnabled': card.tapToPayEnabled ? 1 : 0,
        'internationalTx': card.internationalTx ? 1 : 0,
        'cardColor': card.cardColor,
        'isPrimary': card.isPrimary ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<VirtualCardModel?> getLocalVirtualCard() async {
    final list = await getLocalVirtualCards();
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<VirtualCardModel>> getLocalVirtualCards() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_local_virtual_cards');
      if (raw == null || raw.isEmpty) return [];
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((m) => VirtualCardModel.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('local_virtual_cards');
    return maps.map((m) {
      return VirtualCardModel(
        id: m['id'] as int?,
        cardName: m['cardName'] as String? ?? 'Card',
        cardType: m['cardType'] as String? ?? 'Credit Card',
        cardNetwork: m['cardNetwork'] as String? ?? 'VISA',
        bankName: m['bankName'] as String? ?? 'Bank',
        cardNumber: m['cardNumber'] as String? ?? '•••• •••• •••• 1234',
        cardHolder: m['cardHolder'] as String? ?? 'DEEPAK R',
        expiryDate: m['expiryDate'] as String? ?? '12/28',
        cvv: m['cvv'] as String? ?? '567',
        spendingLimit: (m['spendingLimit'] as num?)?.toDouble() ?? 50000.0,
        currentSpend: (m['currentSpend'] as num?)?.toDouble() ?? 0.0,
        isFrozen: m['isFrozen'] == 1,
        tapToPayEnabled: m['tapToPayEnabled'] != 0,
        internationalTx: m['internationalTx'] == 1,
        cardColor: m['cardColor'] as String? ?? 'indigo',
        isPrimary: m['isPrimary'] == 1,
      );
    }).toList();
  }

  // ==========================================
  // LOCAL INVOICES CACHE
  // ==========================================
  Future<void> saveLocalInvoices(List<InvoiceModel> invoices) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = invoices.map((i) => i.toJson()).toList();
      await prefs.setString('web_local_invoices', jsonEncode(jsonList));
      return;
    }
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('local_invoices');
    for (var inv in invoices) {
      batch.insert('local_invoices', {
        'id': inv.id ?? DateTime.now().millisecondsSinceEpoch,
        'invoiceNo': inv.invoiceNo,
        'clientName': inv.clientName,
        'clientEmail': inv.clientEmail,
        'clientPhone': inv.clientPhone,
        'upiId': inv.upiId,
        'issueDate': inv.issueDate.toIso8601String(),
        'dueDate': inv.dueDate?.toIso8601String(),
        'status': inv.status,
        'taxRate': inv.taxRate,
        'notes': inv.notes,
        'items': jsonEncode(inv.items.map((i) => i.toJson()).toList()),
        'totalAmount': inv.totalAmount,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<InvoiceModel>> getLocalInvoices() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_local_invoices');
      if (raw == null || raw.isEmpty) return [];
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((m) => InvoiceModel.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {
        return [];
      }
    }
    final db = await database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('local_invoices', orderBy: 'issueDate DESC');
    return maps.map((m) {
      List<InvoiceItemModel> items = [];
      try {
        if (m['items'] != null) {
          final decoded = jsonDecode(m['items'] as String) as List;
          items = decoded.map((i) => InvoiceItemModel.fromJson(i)).toList();
        }
      } catch (_) {}

      return InvoiceModel(
        id: m['id'] as int?,
        invoiceNo: m['invoiceNo'] as String? ?? 'INV-001',
        clientName: m['clientName'] as String? ?? 'Client',
        clientEmail: m['clientEmail'] as String? ?? '',
        clientPhone: m['clientPhone'] as String? ?? '',
        upiId: m['upiId'] as String? ?? '',
        issueDate: m['issueDate'] != null ? (DateTime.tryParse(m['issueDate'] as String) ?? DateTime.now()) : DateTime.now(),
        dueDate: m['dueDate'] != null ? DateTime.tryParse(m['dueDate'] as String) : null,
        status: m['status'] as String? ?? 'sent',
        taxRate: (m['taxRate'] as num?)?.toDouble() ?? 18.0,
        notes: m['notes'] as String? ?? '',
        items: items,
      );
    }).toList();
  }

  // ==========================================
  // SYNC QUEUE MANAGEMENT
  // ==========================================
  Future<void> queueRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final item = PendingSyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      method: method,
      body: body,
      headers: headers,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('web_pending_syncs') ?? [];
      list.add(jsonEncode(item.toMap()));
      await prefs.setStringList('web_pending_syncs', list);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('pending_syncs', item.toMap());
  }

  Future<int> getPendingSyncCount() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('web_pending_syncs') ?? [];
      return list.length;
    }
    final db = await database;
    if (db == null) return 0;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_syncs'));
    return count ?? 0;
  }

  Future<void> processSyncQueue() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('web_pending_syncs') ?? [];
      if (list.isEmpty) return;
      final remaining = <String>[];
      for (var str in list) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          final item = PendingSyncItem.fromMap(map);
          final dio = await ApiService().getDio();
          if (item.method == 'POST') {
            await dio.post(item.url, data: item.body);
          } else if (item.method == 'PUT') {
            await dio.put(item.url, data: item.body);
          } else if (item.method == 'DELETE') {
            await dio.delete(item.url);
          }
        } catch (_) {
          remaining.add(str);
        }
      }
      await prefs.setStringList('web_pending_syncs', remaining);
      return;
    }

    final db = await database;
    if (db == null) return;
    final List<Map<String, dynamic>> maps = await db.query('pending_syncs', orderBy: 'timestamp ASC');
    if (maps.isEmpty) return;

    for (var map in maps) {
      final item = PendingSyncItem.fromMap(map);
      try {
        final dio = await ApiService().getDio();
        if (item.method == 'POST') {
          await dio.post(item.url, data: item.body);
        } else if (item.method == 'PUT') {
          await dio.put(item.url, data: item.body);
        } else if (item.method == 'DELETE') {
          await dio.delete(item.url);
        }
        await db.delete('pending_syncs', where: 'id = ?', whereArgs: [item.id]);
      } catch (e) {
        break;
      }
    }
  }
}
