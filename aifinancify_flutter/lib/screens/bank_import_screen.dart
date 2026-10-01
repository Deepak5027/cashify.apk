import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';

class BankImportScreen extends StatefulWidget {
  const BankImportScreen({super.key});

  @override
  State<BankImportScreen> createState() => _BankImportScreenState();
}

class _BankImportScreenState extends State<BankImportScreen> {
  final TextEditingController _csvController = TextEditingController();
  String _selectedPreset = 'Generic CSV';
  List<Map<String, dynamic>> _parsedTransactions = [];
  Set<int> _selectedIndices = {};
  bool _isImporting = false;

  final String _sampleGenericCsv = """Date,Description,Amount,Type,Category
2026-08-20,STARBUCKS COFFEE,-250.00,Debit,Food & Dining
2026-08-21,WHOLE FOODS / DMART,-1840.00,Debit,Groceries
2026-08-22,SALARY DIRECT DEPOSIT,45000.00,Credit,Salary
2026-08-23,SHELL GAS STATION,-650.00,Debit,Transport
2026-08-24,NETFLIX SUBSCRIPTION,-499.00,Debit,Entertainment
2026-08-25,AMAZON ONLINE SHOPPING,-2499.00,Debit,Shopping""";

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    setState(() {
      _csvController.text = _sampleGenericCsv;
    });
    _parseCsv();
  }

  void _parseCsv() {
    final text = _csvController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedTransactions = [];
        _selectedIndices.clear();
      });
      return;
    }

    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1) return;

    final List<Map<String, dynamic>> list = [];
    int startIdx = 0;
    if (RegExp(r'^(date|desc|amount|type|txn|sl)', caseSensitive: false).hasMatch(lines[0])) {
      startIdx = 1;
    }

    for (int i = startIdx; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',').map((p) => p.trim().replaceAll('"', '')).toList();
      if (parts.length >= 3) {
        final dateStr = parts[0];
        final desc = parts[1];
        final rawAmtStr = parts[2].replaceAll(RegExp(r'[^\d.-]'), '');
        final rawAmt = double.tryParse(rawAmtStr) ?? 0.0;
        final isNegative = parts[2].contains('-') || rawAmt < 0;
        final amount = rawAmt.abs();
        
        String type = 'expense';
        if (parts.length > 3) {
          final t = parts[3].toLowerCase();
          if (t.contains('credit') || t.contains('income') || t.contains('payment') || t.contains('deposit')) {
            type = 'income';
          }
        } else if (!isNegative && rawAmt > 0 && (desc.toLowerCase().contains('salary') || desc.toLowerCase().contains('refund'))) {
          type = 'income';
        }

        final category = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : _inferCategory(desc);

        list.add({
          'date': dateStr,
          'description': desc,
          'merchant': desc,
          'amount': amount,
          'type': type,
          'category': category,
          'paymentMode': 'Bank Transfer',
        });
      }
    }

    setState(() {
      _parsedTransactions = list;
      _selectedIndices = List.generate(list.length, (i) => i).toSet();
    });
  }

  String _inferCategory(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('starbucks') || d.contains('coffee') || d.contains('swiggy') || d.contains('zomato') || d.contains('cafe') || d.contains('restaurant')) return 'Food & Dining';
    if (d.contains('food') || d.contains('grocery') || d.contains('dmart') || d.contains('zepto') || d.contains('blinkit') || d.contains('market') || d.contains('walmart')) return 'Groceries';
    if (d.contains('netflix') || d.contains('spotify') || d.contains('movie') || d.contains('prime') || d.contains('hotstar')) return 'Entertainment';
    if (d.contains('salary') || d.contains('payroll') || d.contains('deposit') || d.contains('stipend')) return 'Salary';
    if (d.contains('uber') || d.contains('fuel') || d.contains('gas') || d.contains('petrol') || d.contains('ola') || d.contains('rapido')) return 'Transport';
    if (d.contains('amazon') || d.contains('flipkart') || d.contains('myntra') || d.contains('store')) return 'Shopping';
    if (d.contains('electricity') || d.contains('water') || d.contains('bill') || d.contains('recharge') || d.contains('wifi')) return 'Bills & Utilities';
    return 'General';
  }

  Future<void> _handleBatchImport() async {
    if (_selectedIndices.isEmpty) return;

    final selectedItems = _selectedIndices.map((idx) => _parsedTransactions[idx]).toList();
    setState(() => _isImporting = true);

    try {
      final count = await context.read<TransactionProvider>().importBatch(selectedItems);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("Successfully imported $count transactions into database!"),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Import error: $e"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    final double totalSelectedExpense = _selectedIndices
        .map((i) => _parsedTransactions[i])
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (s, t) => s + (t['amount'] as double));

    final double totalSelectedIncome = _selectedIndices
        .map((i) => _parsedTransactions[i])
        .where((t) => t['type'] == 'income')
        .fold(0.0, (s, t) => s + (t['amount'] as double));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bank Statement CSV Import",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        children: [
          // Format Guidelines Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF818CF8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "CSV Format & Guidelines",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "• Standard format: Date, Description, Amount, Type, Category\n• Negative amounts or 'Debit' represent expenses.\n• Positive amounts or 'Credit/Salary' represent income.",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preset selector
          Row(
            children: [
              const Text("Bank Preset: ", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPreset,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: ['Generic CSV', 'HDFC Bank', 'SBI Bank', 'ICICI Bank', 'Chase Bank']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPreset = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF312E81),
                  foregroundColor: const Color(0xFFA5B4FC),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loadSampleData,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text("Load Sample", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CSV input area
          const Text("Paste Statement CSV Content", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _csvController,
            maxLines: 6,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: "Date,Description,Amount,Type,Category\n2026-08-20,Store,-250.00,Debit,Shopping",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
            ),
            onChanged: (_) => _parseCsv(),
          ),
          const SizedBox(height: 16),

          // Parsed preview table
          if (_parsedTransactions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Extracted Rows (${_selectedIndices.length}/${_parsedTransactions.length})",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedIndices.length == _parsedTransactions.length) {
                          _selectedIndices.clear();
                        } else {
                          _selectedIndices = List.generate(_parsedTransactions.length, (i) => i).toSet();
                        }
                      });
                    },
                    icon: Icon(
                      _selectedIndices.length == _parsedTransactions.length ? Icons.clear_all : Icons.select_all,
                      size: 16,
                      color: const Color(0xFF818CF8),
                    ),
                    label: Text(
                      _selectedIndices.length == _parsedTransactions.length ? "Deselect All" : "Select All",
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rows list
            ..._parsedTransactions.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;
              final isSelected = _selectedIndices.contains(idx);
              final isIncome = t['type'] == 'income';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF6366F1),
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIndices.add(idx);
                          } else {
                            _selectedIndices.remove(idx);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['description'] ?? 'Transaction',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                "${t['date']}",
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${t['category']}",
                                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${isIncome ? '+' : '-'}$currency${(t['amount'] as double).toStringAsFixed(2)}",
                      style: TextStyle(
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Import Action Button (Explicit High-Contrast Styling)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: _isImporting || _selectedIndices.isEmpty ? null : _handleBatchImport,
                icon: _isImporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                label: Text(
                  _isImporting ? "Importing..." : "Import ${_selectedIndices.length} Selected Transactions",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card UNDER the Import Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SELECTED BATCH SUMMARY",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward, color: Color(0xFFEF4444), size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text("Total Expenses", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                        ],
                      ),
                      Text(
                        "$currency${totalSelectedExpense.toStringAsFixed(2)}",
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text("Total Income", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                        ],
                      ),
                      Text(
                        "$currency${totalSelectedIncome.toStringAsFixed(2)}",
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
