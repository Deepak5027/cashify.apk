import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

class StatementPdfService {
  static final StatementPdfService _instance = StatementPdfService._internal();
  factory StatementPdfService() => _instance;
  StatementPdfService._internal();

  /// 1. Generate Styled Financial Statement Document
  String buildFinancialStatementHtml({
    required String userName,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) {
    final startStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    // Group categories
    final Map<String, double> catMap = {};
    for (var tx in transactions.where((t) => t.type.toLowerCase() == 'expense')) {
      final cat = tx.category ?? 'General';
      catMap[cat] = (catMap[cat] ?? 0.0) + tx.amount;
    }

    final catRows = catMap.entries.map((e) {
      final pct = totalExpense > 0 ? (e.value / totalExpense) * 100 : 0.0;
      return '''
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0; font-weight: 500;">${e.key}</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0; text-align: right; font-weight: 600;">$currency${e.value.toStringAsFixed(2)}</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0; text-align: right; color: #64748B;">${pct.toStringAsFixed(1)}%</td>
      </tr>
      ''';
    }).join('\n');

    final txRows = transactions.take(40).map((t) {
      final isInc = t.type.toLowerCase() == 'income';
      final sign = isInc ? '+' : '-';
      final color = isInc ? '#10B981' : '#EF4444';
      final dStr = "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
      return '''
      <tr>
        <td style="padding: 8px 10px; border-bottom: 1px solid #F1F5F9; font-size: 12px; color: #64748B;">$dStr</td>
        <td style="padding: 8px 10px; border-bottom: 1px solid #F1F5F9; font-size: 13px; font-weight: 500;">${t.description ?? 'Transaction'}</td>
        <td style="padding: 8px 10px; border-bottom: 1px solid #F1F5F9; font-size: 12px; color: #475569;">${t.category}</td>
        <td style="padding: 8px 10px; border-bottom: 1px solid #F1F5F9; font-size: 12px; color: #64748B;">${t.paymentMode}</td>
        <td style="padding: 8px 10px; border-bottom: 1px solid #F1F5F9; font-size: 13px; font-weight: bold; text-align: right; color: $color;">
          $sign$currency${t.amount.toStringAsFixed(2)}
        </td>
      </tr>
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>AiFinancify Statement - $userName</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 28px; color: #0F172A; background: #FFF; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #6366F1; padding-bottom: 16px; margin-bottom: 24px; }
    .logo { font-size: 22px; font-weight: 900; color: #6366F1; }
    .meta { text-align: right; font-size: 12px; color: #64748B; }
    .kpi-row { display: flex; gap: 16px; margin-bottom: 24px; }
    .kpi-card { flex: 1; padding: 14px; background: #F8FAFC; border-radius: 10px; border: 1px solid #E2E8F0; }
    .kpi-title { font-size: 11px; text-transform: uppercase; color: #64748B; font-weight: bold; }
    .kpi-val { font-size: 20px; font-weight: bold; margin-top: 4px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 13px; }
    th { background: #F1F5F9; padding: 10px; text-align: left; font-size: 11px; text-transform: uppercase; color: #475569; }
    .footer { margin-top: 30px; text-align: center; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; padding-top: 14px; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="logo">AiFinancify</div>
      <div style="font-size: 14px; color: #475569; font-weight: 600;">Official Financial Statement</div>
    </div>
    <div class="meta">
      <div><strong>Account:</strong> $userName</div>
      <div><strong>Period:</strong> $startStr to $endStr</div>
      <div><strong>Generated:</strong> ${DateTime.now().toIso8601String().split('T').first}</div>
    </div>
  </div>

  <div class="kpi-row">
    <div class="kpi-card">
      <div class="kpi-title">Total Income</div>
      <div class="kpi-val" style="color: #10B981;">$currency${totalIncome.toStringAsFixed(2)}</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">Total Expenses</div>
      <div class="kpi-val" style="color: #EF4444;">$currency${totalExpense.toStringAsFixed(2)}</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">Net Balance</div>
      <div class="kpi-val" style="color: #6366F1;">$currency${netBalance.toStringAsFixed(2)}</div>
    </div>
  </div>

  <h3 style="font-size: 14px; margin-bottom: 8px; color: #1E293B;">Spending Breakdown by Category</h3>
  <table>
    <thead>
      <tr>
        <th>Category</th>
        <th style="text-align: right;">Amount Spent</th>
        <th style="text-align: right;">Share (%)</th>
      </tr>
    </thead>
    <tbody>
      $catRows
    </tbody>
  </table>

  <h3 style="font-size: 14px; margin-bottom: 8px; color: #1E293B;">Transaction Audit Ledger</h3>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Description</th>
        <th>Category</th>
        <th>Payment Mode</th>
        <th style="text-align: right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      $txRows
    </tbody>
  </table>

  <div class="footer">
    AiFinancify Automated Tax & Audit Ledger • Encrypted Verification ID: AIF-${DateTime.now().millisecondsSinceEpoch}
  </div>
</body>
</html>
''';
  }

  /// 2. Generate Official Expense Reimbursement Slip
  String buildReimbursementSlipHtml({
    required String employeeName,
    required String purpose,
    required String department,
    required String currency,
    required List<TransactionModel> claimItems,
  }) {
    final double totalClaim = claimItems.fold(0.0, (sum, t) => sum + t.amount);

    final itemRows = claimItems.map((t) {
      final dStr = "${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}";
      return '''
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0;">$dStr</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0; font-weight: 500;">${t.description ?? 'Expense'}</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0;">${t.category}</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0;">${t.paymentMode}</td>
        <td style="padding: 10px; border-bottom: 1px solid #E2E8F0; font-weight: bold; text-align: right;">$currency${t.amount.toStringAsFixed(2)}</td>
      </tr>
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Reimbursement Claim - $employeeName</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 30px; color: #0F172A; }
    .header { border-bottom: 2px solid #3B82F6; padding-bottom: 16px; margin-bottom: 20px; display: flex; justify-content: space-between; }
    .title { font-size: 20px; font-weight: bold; color: #1E293B; }
    .meta-box { background: #F8FAFC; border: 1px solid #CBD5E1; padding: 14px; border-radius: 8px; margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th { background: #F1F5F9; padding: 10px; text-align: left; font-size: 11px; text-transform: uppercase; }
    .total-box { text-align: right; font-size: 16px; font-weight: bold; margin-bottom: 30px; color: #1E293B; }
    .signatures { display: flex; justify-content: space-between; margin-top: 40px; padding-top: 20px; }
    .sig-line { width: 200px; border-top: 1px solid #64748B; text-align: center; font-size: 12px; color: #475569; padding-top: 6px; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="title">EXPENSE REIMBURSEMENT CLAIM</div>
      <div style="font-size: 12px; color: #64748B;">Claim Ref: #EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}</div>
    </div>
    <div style="text-align: right; font-size: 12px; color: #475569;">
      <strong>AiFinancify Corporate Suite</strong><br>
      Date: ${DateTime.now().toIso8601String().split('T').first}
    </div>
  </div>

  <div class="meta-box">
    <div><strong>Claimant:</strong> $employeeName</div>
    <div><strong>Department:</strong> $department</div>
    <div><strong>Business Purpose:</strong> $purpose</div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Description / Merchant</th>
        <th>Category</th>
        <th>Mode</th>
        <th style="text-align: right;">Amount Claimed</th>
      </tr>
    </thead>
    <tbody>
      $itemRows
    </tbody>
  </table>

  <div class="total-box">
    Total Reimbursement Requested: <span style="color: #2563EB;">$currency${totalClaim.toStringAsFixed(2)}</span>
  </div>

  <div class="signatures">
    <div class="sig-line">Employee Signature</div>
    <div class="sig-line">Approving Manager Signature</div>
  </div>
</body>
</html>
''';
  }

  /// 3. Save generated document to device file system
  Future<File> saveHtmlDocument(String filename, String htmlContent) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    return await file.writeAsString(htmlContent);
  }
}
