import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';
import '../services/statement_pdf_service.dart';

class InvoiceProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();
  final StatementPdfService _pdfService = StatementPdfService();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _error;
  String? _lastGeneratedPath;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastGeneratedPath => _lastGeneratedPath;

  double get totalInvoiced => _invoices.fold(0.0, (sum, inv) => sum + (inv.totalAmount > 0 ? inv.totalAmount : inv.calculatedTotal));
  double get totalCollected => _invoices.where((inv) => inv.status.toLowerCase() == 'paid').fold(0.0, (sum, inv) => sum + (inv.totalAmount > 0 ? inv.totalAmount : inv.calculatedTotal));
  double get totalReceivable => _invoices.where((inv) => inv.status.toLowerCase() != 'paid').fold(0.0, (sum, inv) => sum + (inv.totalAmount > 0 ? inv.totalAmount : inv.calculatedTotal));

  InvoiceProvider() {
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Local SQLite cache first
      final local = await _offline.getLocalInvoices();
      if (local.isNotEmpty) {
        _invoices = local;
        notifyListeners();
      }

      // 2. Fetch fresh from backend
      final fresh = await _api.getInvoices();
      _invoices = fresh;
      await _offline.saveLocalInvoices(_invoices);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInvoice(Map<String, dynamic> data) async {
    try {
      final created = await _api.createInvoice(data);
      _invoices.insert(0, created);
      await _offline.saveLocalInvoices(_invoices);
      notifyListeners();
      return true;
    } catch (e) {
      final mock = InvoiceModel.fromJson({
        'id': DateTime.now().millisecondsSinceEpoch,
        ...data,
      });
      _invoices.insert(0, mock);
      await _offline.saveLocalInvoices(_invoices);
      await _offline.queueRequest(
        url: '${ApiService.baseUrl}/api/invoices',
        method: 'POST',
        body: data,
      );
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateStatus(int id, String newStatus) async {
    final idx = _invoices.indexWhere((inv) => inv.id == id);
    if (idx != -1) {
      final current = _invoices[idx];
      _invoices[idx] = InvoiceModel(
        id: current.id,
        invoiceNo: current.invoiceNo,
        clientName: current.clientName,
        clientEmail: current.clientEmail,
        clientPhone: current.clientPhone,
        upiId: current.upiId,
        issueDate: current.issueDate,
        dueDate: current.dueDate,
        status: newStatus,
        taxRate: current.taxRate,
        notes: current.notes,
        items: current.items,
        totalAmount: current.totalAmount,
      );
      await _offline.saveLocalInvoices(_invoices);
      notifyListeners();
    }

    try {
      final updated = await _api.updateInvoice(id, {'status': newStatus});
      if (idx != -1) {
        _invoices[idx] = updated;
        await _offline.saveLocalInvoices(_invoices);
        notifyListeners();
      }
      return true;
    } catch (e) {
      await _offline.queueRequest(
        url: '${ApiService.baseUrl}/api/invoices/$id',
        method: 'PUT',
        body: {'status': newStatus},
      );
      return true;
    }
  }

  Future<bool> deleteInvoice(int id) async {
    _invoices.removeWhere((inv) => inv.id == id);
    await _offline.saveLocalInvoices(_invoices);
    notifyListeners();

    try {
      await _api.deleteInvoice(id);
      return true;
    } catch (e) {
      await _offline.queueRequest(
        url: '${ApiService.baseUrl}/api/invoices/$id',
        method: 'DELETE',
      );
      return true;
    }
  }

  Future<String> generateAndSaveStatement({
    required String userName,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) async {
    final html = _pdfService.buildFinancialStatementHtml(
      userName: userName,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      transactions: transactions,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
    );
    final filename = 'Statement_${DateTime.now().millisecondsSinceEpoch}.html';
    final file = await _pdfService.saveHtmlDocument(filename, html);
    _lastGeneratedPath = file.path;
    notifyListeners();
    return file.path;
  }

  Future<String> generateAndSaveReimbursementSlip({
    required String employeeName,
    required String purpose,
    required String department,
    required String currency,
    required List<TransactionModel> claimItems,
  }) async {
    final html = _pdfService.buildReimbursementSlipHtml(
      employeeName: employeeName,
      purpose: purpose,
      department: department,
      currency: currency,
      claimItems: claimItems,
    );
    final filename = 'Reimbursement_Claim_${DateTime.now().millisecondsSinceEpoch}.html';
    final file = await _pdfService.saveHtmlDocument(filename, html);
    _lastGeneratedPath = file.path;
    notifyListeners();
    return file.path;
  }
}
