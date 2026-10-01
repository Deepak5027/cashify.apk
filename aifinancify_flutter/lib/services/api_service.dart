import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/receipt.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';
import '../models/virtual_card.dart';
import '../models/invoice.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Default server URLs - connects seamlessly to cloud and local backends
  static const String defaultLocalUrl = "http://localhost:4000";
  static const String defaultAdbUrl = "http://127.0.0.1:4000";
  static const String defaultCloudUrl = "https://financeai-api-ba5p.onrender.com";
  static const String defaultLanUrl = "http://10.34.0.116:4000";
  static const String defaultEmulatorUrl = "http://10.0.2.2:4000";

  static String _baseUrl = defaultLocalUrl;
  static String get baseUrl => _baseUrl;

  Dio? _dioInstance;

  Future<Dio> getDio() async {
    if (_dioInstance != null) return _dioInstance!;

    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('custom_server_url') ?? (kIsWeb ? defaultLocalUrl : defaultCloudUrl);

    _dioInstance = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final p = await SharedPreferences.getInstance();
          final token = p.getString('auth_token');
          final userEmail = p.getString('user_email');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (userEmail != null) {
            options.headers['x-user-email'] = userEmail;
          }
          return handler.next(options);
        },
      ));

    return _dioInstance!;
  }

  Future<void> updateBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_server_url', _baseUrl);
    _dioInstance = null; // Recreate with new URL
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _dioInstance = null;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _dioInstance = null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString('custom_server_url');
    final candidates = [
      custom,
      if (kIsWeb) defaultLocalUrl,
      if (kIsWeb) defaultAdbUrl,
      if (!kIsWeb) defaultCloudUrl,
      if (!kIsWeb) defaultLocalUrl,
      if (!kIsWeb) defaultAdbUrl,
      "http://10.0.2.2:4000",
      "http://127.0.0.1:4000",
      "http://localhost:4000",
      defaultCloudUrl,
    ].whereType<String>().toSet().toList();

    Exception? lastError;

    for (var url in candidates) {
      try {
        final Dio dio = Dio(BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ));
        final res = await dio.post('/auth/login', data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        });
        if (res.data != null && res.data['token'] != null) {
          await updateBaseUrl(url);
          await saveToken(res.data['token']);
          await prefs.setString('user_email', email.trim().toLowerCase());
          if (res.data['user'] != null) {
            await prefs.setString('user_name', res.data['user']['name'] ?? 'User');
          }
          return Map<String, dynamic>.from(res.data);
        }
      } catch (e) {
        lastError = Exception('Login failed: $e');
        continue;
      }
    }
    throw lastError ?? Exception('Unable to reach server. Please check your network.');
  }

  Future<Map<String, dynamic>> signup(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString('custom_server_url');
    final candidates = [
      custom,
      if (kIsWeb) defaultLocalUrl,
      if (kIsWeb) defaultAdbUrl,
      if (!kIsWeb) defaultCloudUrl,
      if (!kIsWeb) defaultLocalUrl,
      if (!kIsWeb) defaultAdbUrl,
      "http://10.0.2.2:4000",
      "http://127.0.0.1:4000",
      "http://localhost:4000",
      defaultCloudUrl,
    ].whereType<String>().toSet().toList();

    Exception? lastError;

    for (var url in candidates) {
      try {
        final Dio dio = Dio(BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ));
        final res = await dio.post('/auth/signup', data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'name': name.trim(),
        });
        if (res.data != null && res.data['token'] != null) {
          await updateBaseUrl(url);
          await saveToken(res.data['token']);
          await prefs.setString('user_email', email.trim().toLowerCase());
          await prefs.setString('user_name', name);
          return Map<String, dynamic>.from(res.data);
        }
      } catch (e) {
        lastError = Exception('Registration failed: $e');
        continue;
      }
    }
    throw lastError ?? Exception('Unable to reach server. Please check your network.');
  }

  Future<Map<String, dynamic>?> verifyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      if (token.startsWith('google_auth_token_')) {
        final email = prefs.getString('user_email') ?? 'google.user@example.com';
        final name = prefs.getString('user_name') ?? 'Google User';
        return {
          'user': {
            'email': email,
            'name': name,
          }
        };
      }

      final dio = await getDio();
      final res = await dio.get('/auth/me');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        return {
          'user': {
            'email': prefs.getString('user_email') ?? 'User',
            'name': prefs.getString('user_name') ?? 'User',
          }
        };
      }
      return null;
    }
  }

  // ==========================================
  // TRANSACTIONS CRUD
  // ==========================================
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/transactions');
      final raw = res.data is Map ? (res.data['data'] ?? res.data['transactions']) : res.data;
      if (raw is List) {
        return raw.map((t) => TransactionModel.fromJson(Map<String, dynamic>.from(t))).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel tx) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/transactions', data: tx.toJson());
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return TransactionModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<TransactionModel> updateTransaction(int id, Map<String, dynamic> updates) async {
    try {
      final dio = await getDio();
      final res = await dio.put('/api/transactions/$id', data: updates);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return TransactionModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final dio = await getDio();
      await dio.delete('/api/transactions/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // ==========================================
  // BUDGETS CRUD
  // ==========================================
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/budgets');
      final raw = res.data is Map ? (res.data['data'] ?? res.data['budgets']) : res.data;
      if (raw is List) {
        return raw.map((b) => BudgetModel.fromJson(Map<String, dynamic>.from(b))).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/budgets', data: budget.toJson());
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return BudgetModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  Future<BudgetModel> updateBudget(int id, Map<String, dynamic> updates) async {
    try {
      final dio = await getDio();
      final res = await dio.put('/api/budgets/$id', data: updates);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return BudgetModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      final dio = await getDio();
      await dio.delete('/api/budgets/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  // ==========================================
  // GOALS CRUD
  // ==========================================
  Future<List<GoalModel>> getGoals() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/goals');
      final raw = res.data is Map ? (res.data['data'] ?? res.data['goals']) : res.data;
      if (raw is List) {
        return raw.map((g) => GoalModel.fromJson(Map<String, dynamic>.from(g))).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/goals', data: goal.toJson());
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return GoalModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<GoalModel> updateGoal(int id, Map<String, dynamic> updates) async {
    try {
      final dio = await getDio();
      final res = await dio.put('/api/goals/$id', data: updates);
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return GoalModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      final dio = await getDio();
      await dio.delete('/api/goals/$id');
      return true;
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // ==========================================
  // RECEIPTS (OCR)
  // ==========================================
  Future<List<ReceiptModel>> getReceipts() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/receipts');
      final raw = res.data is Map ? (res.data['data'] ?? res.data['receipts']) : res.data;
      if (raw is List) {
        return raw.map((r) => ReceiptModel.fromJson(Map<String, dynamic>.from(r))).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ReceiptModel> saveReceipt(ReceiptModel receipt) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/receipts', data: receipt.toJson());
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return ReceiptModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  // ==========================================
  // BULK CSV & UPI IMPORT
  // ==========================================
  Future<int> importTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/import-csv', data: {
        'transactions': transactions,
      });
      return res.data['imported'] ?? (res.data['data'] as List?)?.length ?? transactions.length;
    } catch (e) {
      // Fallback: insert one by one
      int count = 0;
      for (var t in transactions) {
        try {
          await createTransaction(TransactionModel.fromJson(t));
          count++;
        } catch (_) {}
      }
      return count;
    }
  }

  // ==========================================
  // AI & ANALYTICS ENDPOINTS
  // ==========================================
  Future<List<dynamic>> getAIInsights() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/ai/insights');
      return res.data['insights'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAIAnalytics() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/ai/analytics');
      return Map<String, dynamic>.from(res.data['analytics'] ?? {});
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> getAIPredictions() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/ai/predict');
      return res.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeFraud(Map<String, dynamic> txData) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/ai/analyzeFraud', data: {'transaction': txData});
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      return {'riskScore': 0.0, 'riskReason': 'Offline assessment'};
    }
  }

  // ==========================================
  // ADMIN STATS & ACTIVITIES
  // ==========================================
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/admin/stats');
      return Map<String, dynamic>.from(res.data['stats'] ?? res.data);
    } catch (e) {
      return {};
    }
  }

  Future<List<ActivityModel>> getActivities() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/activities');
      final raw = res.data is Map ? (res.data['data'] ?? res.data['activities']) : res.data;
      if (raw is List) {
        return raw.map((a) => ActivityModel.fromJson(Map<String, dynamic>.from(a))).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // USER PROFILE
  // ==========================================
  Future<UserProfileModel?> getProfile() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/profile');
      if (res.data['user'] != null) {
        return UserProfileModel.fromJson(Map<String, dynamic>.from(res.data['user']));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final dio = await getDio();
      final res = await dio.put('/api/profile', data: updates);
      return res.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ==========================================
  // OFFLINE SYNC REQUEST
  // ==========================================
  Future<bool> syncOfflineRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final dio = await getDio();
      final options = Options(
        method: method,
        headers: headers != null ? Map<String, dynamic>.from(headers) : null,
      );
      final res = await dio.request(url, data: body, options: options);
      return (res.statusCode ?? 500) < 300;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // DEMO DATA SEEDING
  // ==========================================
  Future<bool> seedDemoData() async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/seed-demo-data');
      return res.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to seed demo data: $e');
    }
  }

  // ==========================================
  // VIRTUAL & REAL CARDS WALLET
  // ==========================================
  Future<List<VirtualCardModel>> getVirtualCards() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/virtual-cards');
      if (res.data != null && res.data['data'] is List) {
        return (res.data['data'] as List)
            .map((c) => VirtualCardModel.fromJson(c))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<VirtualCardModel> getVirtualCard() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/virtual-card');
      if (res.data != null && res.data['data'] != null) {
        return VirtualCardModel.fromJson(res.data['data']);
      }
      return VirtualCardModel();
    } catch (e) {
      return VirtualCardModel();
    }
  }

  Future<VirtualCardModel> createVirtualCard(Map<String, dynamic> cardData) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/virtual-card', data: cardData);
      if (res.data != null && res.data['data'] != null) {
        return VirtualCardModel.fromJson(res.data['data']);
      }
      return VirtualCardModel.fromJson(cardData);
    } catch (e) {
      throw Exception('Failed to create card: $e');
    }
  }

  Future<VirtualCardModel> updateVirtualCard(Map<String, dynamic> updates, {int? id}) async {
    try {
      final dio = await getDio();
      final url = id != null ? '/api/virtual-card/$id' : '/api/virtual-card';
      final res = await dio.put(url, data: updates);
      if (res.data != null && res.data['data'] != null) {
        return VirtualCardModel.fromJson(res.data['data']);
      }
      return VirtualCardModel.fromJson(updates);
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  Future<bool> deleteVirtualCard(int id) async {
    try {
      final dio = await getDio();
      final res = await dio.delete('/api/virtual-card/$id');
      return res.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  // ==========================================
  // 📄 INVOICING & PAYMENT QR
  // ==========================================
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final dio = await getDio();
      final res = await dio.get('/api/invoices');
      if (res.data != null && res.data['data'] is List) {
        return (res.data['data'] as List)
            .map((item) => InvoiceModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    try {
      final dio = await getDio();
      final res = await dio.post('/api/invoices', data: data);
      return InvoiceModel.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<InvoiceModel> updateInvoice(int id, Map<String, dynamic> data) async {
    try {
      final dio = await getDio();
      final res = await dio.put('/api/invoices/$id', data: data);
      return InvoiceModel.fromJson(res.data['data']);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<bool> deleteInvoice(int id) async {
    try {
      final dio = await getDio();
      final res = await dio.delete('/api/invoices/$id');
      return res.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }
}




