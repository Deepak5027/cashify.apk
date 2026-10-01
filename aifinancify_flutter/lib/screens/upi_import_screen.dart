import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';

class ParsedUpiItem {
  String id;
  String merchant;
  double amount;
  String type; // expense or income
  String category;
  String upiRef;
  DateTime date;
  bool selected;

  ParsedUpiItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.type,
    required this.category,
    required this.upiRef,
    required this.date,
    this.selected = true,
  });
}

class UpiImportScreen extends StatefulWidget {
  const UpiImportScreen({super.key});

  @override
  State<UpiImportScreen> createState() => _UpiImportScreenState();
}

class _UpiImportScreenState extends State<UpiImportScreen> {
  final TextEditingController _smsController = TextEditingController();
  List<ParsedUpiItem> _parsedList = [];
  bool _isImporting = false;

  final String _sampleUpiSms = """Paid ₹450.00 to SWIGGY via UPI Ref 423456789012 from SBI A/c XX1234 on 28-08-2026.
Rs.1250.00 debited from HDFC A/C XX5678 to amazon@apl on 27-08-2026. UPI Ref 423456789013.
Received ₹15,000.00 from TechCorp Solutions on GPay to A/c XX9012. UPI Ref 423456789023 on 26-08-2026.
Paid ₹750 to Star Bazaar using PhonePe UPI Ref 423456789019 on 25-08-2026.""";

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Transport',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Salary',
    'Investment',
    'Other',
  ];

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  void _loadSample() {
    _smsController.text = _sampleUpiSms;
    _parseMessages();
  }

  void _parseMessages() {
    final text = _smsController.text.trim();
    if (text.isEmpty) {
      setState(() => _parsedList = []);
      return;
    }

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final List<ParsedUpiItem> results = [];
    int idx = 0;

    for (var line in lines) {
      final amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(line);

      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr) ?? 0.0;

        final isIncome = RegExp(r'\b(received|credited|deposit|salary)\b', caseSensitive: false).hasMatch(line);
        final type = isIncome ? 'income' : 'expense';

        // Extract UPI Ref
        final refRegex = RegExp(r'(?:ref|rrn|upi\s*ref|txn)[\s#:]*([0-9a-zA-Z]+)', caseSensitive: false);
        final refMatch = refRegex.firstMatch(line);
        final upiRef = refMatch != null ? refMatch.group(1)! : "UPI-${1000 + idx}";

        // Extract Merchant
        String merchant = "UPI Payment";
        final lower = line.toLowerCase();
        if (lower.contains('to ')) {
          merchant = line.split(RegExp(r'to ', caseSensitive: false)).last.split(RegExp(r'[\.\n,]|\bvia\b|\bon\b|\bfrom\b')).first.trim();
        } else if (lower.contains('from ')) {
          merchant = line.split(RegExp(r'from ', caseSensitive: false)).last.split(RegExp(r'[\.\n,]|\bon\b|\bto\b|\bvia\b')).first.trim();
        } else if (lower.contains('at ')) {
          merchant = line.split(RegExp(r'at ', caseSensitive: false)).last.split(RegExp(r'[\.\n,]|\bon\b')).first.trim();
        }

        merchant = merchant.replaceAll(RegExp(r'[@A-Z0-9_\.]+$'), '').trim();
        if (merchant.isEmpty || merchant.length < 2) merchant = isIncome ? "UPI Inward Credit" : "UPI Merchant";

        results.add(ParsedUpiItem(
          id: "upi_${DateTime.now().millisecondsSinceEpoch}_$idx",
          merchant: merchant,
          amount: amount,
          type: type,
          category: _inferCategory(merchant, isIncome),
          upiRef: upiRef,
          date: DateTime.now().subtract(Duration(days: idx)),
          selected: true,
        ));
        idx++;
      }
    }

    setState(() {
      _parsedList = results;
    });
  }

  String _inferCategory(String name, bool isIncome) {
    if (isIncome) return 'Salary';
    final n = name.toLowerCase();
    if (n.contains('swiggy') || n.contains('zomato') || n.contains('food') || n.contains('cafe') || n.contains('restaurant')) return 'Food & Dining';
    if (n.contains('blinkit') || n.contains('zepto') || n.contains('grocer') || n.contains('mart') || n.contains('bazaar')) return 'Groceries';
    if (n.contains('amazon') || n.contains('flipkart') || n.contains('myntra') || n.contains('shop')) return 'Shopping';
    if (n.contains('uber') || n.contains('ola') || n.contains('petrol') || n.contains('fuel') || n.contains('rapido')) return 'Transport';
    return 'Other';
  }

  void _toggleSelectAll() {
    final allSelected = _parsedList.every((i) => i.selected);
    setState(() {
      for (var item in _parsedList) {
        item.selected = !allSelected;
      }
    });
  }

  Future<void> _importSelected() async {
    final selectedItems = _parsedList.where((i) => i.selected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one transaction to import"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final rawList = selectedItems.map((item) => {
            'description': item.merchant,
            'merchant': item.merchant,
            'amount': item.amount,
            'type': item.type,
            'category': item.category,
            'paymentMode': 'UPI',
            'date': item.date.toIso8601String(),
          }).toList();

      final count = await context.read<TransactionProvider>().importBatch(rawList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imported $count UPI transactions successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;
    final selectedCount = _parsedList.where((i) => i.selected).length;
    final selectedTotal = _parsedList.where((i) => i.selected).fold<double>(0.0, (s, i) => s + (i.type == 'expense' ? i.amount : 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phonelink_ring, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("UPI SMS Importer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  Text("Bank SMS Batch Parser", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF818CF8)),
            label: const Text("Load Sample", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _loadSample,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Paste Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Paste Bank / UPI SMS Notifications", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            if (_smsController.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _smsController.clear();
                                  setState(() => _parsedList = []);
                                },
                                child: const Text("Clear", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _smsController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: "Paste debit/credit SMS from SBI, HDFC, ICICI, Axis, Google Pay, PhonePe, Paytm...",
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                          ),
                          onChanged: (_) => _parseMessages(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text("Extract & Parse Transactions"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _parseMessages,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Parsed List Section
                  if (_parsedList.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Extracted Transactions (${_parsedList.length})",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: _toggleSelectAll,
                          child: Row(
                            children: [
                              Icon(
                                _parsedList.every((i) => i.selected) ? Icons.check_box : Icons.check_box_outline_blank,
                                color: const Color(0xFF818CF8),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text("Select All", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._parsedList.map((item) => _buildTransactionCard(item, currency)),
                  ],
                ],
              ),
            ),

            // Bottom Import Action Bar
            if (_parsedList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  border: Border(top: BorderSide(color: Color(0xFF1F2937))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$selectedCount of ${_parsedList.length} selected", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          Text(
                            "Total: $currency${selectedTotal.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: _isImporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download_done_rounded, size: 18),
                      label: Text(_isImporting ? "Importing..." : "Import Selected ($selectedCount)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isImporting ? null : _importSelected,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ParsedUpiItem item, String currency) {
    final isIncome = item.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.selected ? const Color(0xFF6366F1) : const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            activeColor: const Color(0xFF6366F1),
            onChanged: (val) => setState(() => item.selected = val ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.merchant,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${isIncome ? '+' : '-'}$currency${item.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isIncome ? "CREDIT" : "DEBIT",
                        style: TextStyle(color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Ref: ${item.upiRef}",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category Selector
                DropdownButton<String>(
                  value: _categories.contains(item.category) ? item.category : 'Other',
                  dropdownColor: const Color(0xFF1E293B),
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11.5, fontWeight: FontWeight.w600),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => item.category = val ?? 'Other'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 16),
            onPressed: () => setState(() => _parsedList.removeWhere((i) => i.id == item.id)),
          ),
        ],
      ),
    );
  }
}
