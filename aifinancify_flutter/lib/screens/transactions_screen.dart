import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const TransactionsScreen({super.key, this.onMenuPressed});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All'; // 'All', 'income', 'expense'
  String _selectedCategory = 'All';
  String _selectedPaymentMode = 'All';

  final List<String> _categories = [
    'All',
    'Food & Dining',
    'Groceries',
    'Shopping',
    'Bills & Utilities',
    'Transport',
    'Salary',
    'Investment',
    'Health',
    'Entertainment',
    'Other'
  ];

  final List<String> _paymentModes = ['All', 'Cash', 'Card', 'UPI', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> list) {
    final query = _searchController.text.trim().toLowerCase();

    return list.where((t) {
      if (_selectedType != 'All' && t.type.toLowerCase() != _selectedType.toLowerCase()) {
        return false;
      }
      if (_selectedCategory != 'All' && !(t.category ?? '').toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }
      if (_selectedPaymentMode != 'All' && t.paymentMode.toLowerCase() != _selectedPaymentMode.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final desc = (t.description ?? '').toLowerCase();
        final cat = (t.category ?? '').toLowerCase();
        final amt = t.amount.toString();
        if (!desc.contains(query) && !cat.contains(query) && !amt.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    final filteredList = _getFilteredTransactions(txProvider.transactions);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: widget.onMenuPressed != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: "Open Menu",
                onPressed: widget.onMenuPressed,
              )
            : (Navigator.canPop(context) ? const BackButton(color: Colors.white) : null),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            "Transactions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.indigoAccent),
            tooltip: "Export CSV",
            onPressed: () => _exportCsv(context, filteredList),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showAddEditTransactionDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111827),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search merchant, category, notes...",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type toggles
                      _buildFilterChip("All Types", _selectedType == 'All', () => setState(() => _selectedType = 'All')),
                      const SizedBox(width: 8),
                      _buildFilterChip("Income", _selectedType == 'income', () => setState(() => _selectedType = 'income'), color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      _buildFilterChip("Expense", _selectedType == 'expense', () => setState(() => _selectedType = 'expense'), color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Container(height: 20, width: 1, color: Colors.white24),
                      const SizedBox(width: 12),

                      // Category Dropdown Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Count Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0B0F19),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredList.length} of ${txProvider.transactions.length} records",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (_selectedType != 'All' || _selectedCategory != 'All' || _searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = 'All';
                        _selectedCategory = 'All';
                        _searchController.clear();
                      });
                    },
                    child: const Text("Reset Filters", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                            SizedBox(height: 12),
                            Text("No transactions found", style: TextStyle(color: Colors.white54, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final t = filteredList[index];
                          return _buildTransactionCard(context, t, currency, txProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    final activeColor = color ?? const Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (color ?? Colors.white) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel t,
    String currency,
    TransactionProvider provider,
  ) {
    final isIncome = t.type.toLowerCase() == 'income';
    final amountColor = isIncome ? Colors.greenAccent : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.riskScore >= 50 ? Colors.redAccent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.greenAccent : Colors.indigoAccent).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
              color: isIncome ? Colors.greenAccent : const Color(0xFF818CF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.description ?? 'Transaction',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (t.isRecurring) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text("AUTO", style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${t.category ?? 'Other'} • ${t.paymentMode} • ${_formatDate(t.date)}",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}",
                style: TextStyle(color: amountColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAddEditTransactionDialog(context, existing: t),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white54),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, t, provider),
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }

  void _confirmDelete(BuildContext context, TransactionModel t, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Transaction?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete '${t.description}'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (t.id != null) {
                await provider.deleteTransaction(t.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction deleted successfully")),
                  );
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showAddEditTransactionDialog(BuildContext context, {TransactionModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? 'expense';
    String category = existing?.category ?? 'Food & Dining';
    String paymentMode = existing?.paymentMode ?? 'Cash';
    bool isRecurring = existing?.isRecurring ?? false;
    String recurringPeriod = existing?.recurringPeriod ?? 'monthly';
    DateTime selectedDate = existing?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? "Add New Transaction" : "Edit Transaction",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Income / Expense selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => type = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: type == 'expense' ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: type == 'expense' ? Colors.redAccent : Colors.white24),
                            ),
                            child: const Center(
                              child: Text("Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => type = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: type == 'income' ? Colors.greenAccent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: type == 'income' ? Colors.greenAccent : Colors.white24),
                            ),
                            child: const Center(
                              child: Text("Income", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDec("Amount (e.g. 500.00)", Icons.currency_rupee),
                    validator: (val) => val == null || double.tryParse(val) == null ? "Enter valid amount" : null,
                  ),
                  const SizedBox(height: 12),

                  // Description / Merchant
                  TextFormField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDec("Description / Merchant", Icons.storefront_outlined),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 12),

                  // Category & Payment Mode Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _categories.contains(category) ? category : 'Other',
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _buildInputDec("Category", Icons.category_outlined),
                          items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => category = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentModes.contains(paymentMode) ? paymentMode : 'Cash',
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: _buildInputDec("Payment", Icons.payment_outlined),
                          items: _paymentModes.where((p) => p != 'All').map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => paymentMode = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recurring switch
                  SwitchListTile(
                    title: const Text("Recurring Transaction", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text("Auto-renews $recurringPeriod", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    value: isRecurring,
                    activeColor: const Color(0xFF6366F1),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => isRecurring = val),
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final amt = double.parse(amountCtrl.text.trim());
                        final desc = descCtrl.text.trim();

                        final tx = TransactionModel(
                          id: existing?.id,
                          amount: amt,
                          description: desc,
                          category: category,
                          type: type,
                          paymentMode: paymentMode,
                          isRecurring: isRecurring,
                          recurringPeriod: isRecurring ? recurringPeriod : null,
                          date: selectedDate,
                        );

                        Navigator.pop(ctx);
                        if (existing == null) {
                          await context.read<TransactionProvider>().addTransaction(tx);
                        } else {
                          await context.read<TransactionProvider>().updateTransaction(existing.id!, tx.toJson());
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? "Transaction created!" : "Transaction updated!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(
                        existing == null ? "Save Transaction" : "Update Transaction",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white54, size: 18),
      filled: true,
      fillColor: const Color(0xFF0B0F19),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
    );
  }

  Future<void> _exportCsv(BuildContext context, List<TransactionModel> list) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln("=== AiFinancify Transactions Export ===");
      buffer.writeln("Generated On,${DateTime.now().toIso8601String()}");
      buffer.writeln("Total Transactions,${list.length}");
      buffer.writeln("");
      buffer.writeln("ID,Date,Description,Category,Type,Amount,PaymentMode,RiskScore");
      for (var t in list) {
        buffer.writeln("${t.id ?? ''},${t.date.toIso8601String().split('T')[0]},\"${t.description ?? ''}\",\"${t.category ?? ''}\",${t.type},${t.amount},\"${t.paymentMode}\",${t.riskScore}");
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/AiFinancify_Transactions_Export.csv");
      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (bctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 10),
                    Text("Transactions Exported Successfully", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SAVED FILE LOCATION:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(file.path, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Text("Total Rows Exported: ${list.length} records", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(bctx),
                    child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export error: $e"), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }
}
