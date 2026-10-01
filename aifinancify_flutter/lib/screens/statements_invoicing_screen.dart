import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/invoice_provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/invoice.dart';
import '../widgets/upi_qr_widget.dart';

class StatementsInvoicingScreen extends StatefulWidget {
  const StatementsInvoicingScreen({super.key});

  @override
  State<StatementsInvoicingScreen> createState() => _StatementsInvoicingScreenState();
}

class _StatementsInvoicingScreenState extends State<StatementsInvoicingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;
    final userName = profileProvider.profile?.name ?? 'AiFinancify User';

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
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Statements & Invoicing",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf, size: 18), text: "Statements (PDF)"),
            Tab(icon: Icon(Icons.qr_code_2, size: 18), text: "Invoices & QR"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatementsTab(context, txProvider, invoiceProvider, userName, currency),
          _buildInvoicesTab(context, invoiceProvider, currency),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: FINANCIAL STATEMENTS
  // ==========================================
  Widget _buildStatementsTab(
    BuildContext context,
    TransactionProvider txProvider,
    InvoiceProvider invoiceProvider,
    String userName,
    String currency,
  ) {
    final filteredTxs = txProvider.transactions.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    double income = 0;
    double expense = 0;
    for (var t in filteredTxs) {
      if (t.type.toLowerCase() == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final net = income - expense;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Range Selector
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
              const Text("Statement Period", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF818CF8)),
                      label: Text(
                        "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("to", style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF818CF8)),
                      label: Text(
                        "${_endDate.day}/${_endDate.month}/${_endDate.year}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live KPI Summary
        Row(
          children: [
            Expanded(child: _buildKpiCard("TOTAL INCOME", "$currency${income.toStringAsFixed(0)}", const Color(0xFF10B981))),
            const SizedBox(width: 10),
            Expanded(child: _buildKpiCard("TOTAL EXPENSES", "$currency${expense.toStringAsFixed(0)}", const Color(0xFFEF4444))),
            const SizedBox(width: 10),
            Expanded(child: _buildKpiCard("NET BALANCE", "$currency${net.toStringAsFixed(0)}", const Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 20),

        // Export Actions
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text("Generate & Save Official Statement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final path = await invoiceProvider.generateAndSaveStatement(
                userName: userName,
                currency: currency,
                startDate: _startDate,
                endDate: _endDate,
                transactions: filteredTxs,
                totalIncome: income,
                totalExpense: expense,
                netBalance: net,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Statement generated & saved to: $path"),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 20),

        // Transactions Audit list in statement
        Text("Statement Ledger (${filteredTxs.length} items)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...filteredTxs.take(15).map((t) {
          final isInc = t.type.toLowerCase() == 'income';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.description ?? 'Expense', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("${t.category} • ${t.paymentMode}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                Text(
                  "${isInc ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}",
                  style: TextStyle(color: isInc ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 2: CLIENT INVOICES & UPI QR CODE
  // ==========================================
  Widget _buildInvoicesTab(BuildContext context, InvoiceProvider invoiceProvider, String currency) {
    final invoices = invoiceProvider.invoices;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary KPI Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TOTAL INVOICED", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("$currency${invoiceProvider.totalInvoiced.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("COLLECTED", style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("$currency${invoiceProvider.totalCollected.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PENDING", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("$currency${invoiceProvider.totalReceivable.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Create Invoice Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Create Client Invoice with UPI QR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _showCreateInvoiceDialog(context, invoiceProvider),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Client Invoices", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text("${invoices.length} Total", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: const [
                Icon(Icons.receipt_outlined, color: Color(0xFF94A3B8), size: 40),
                SizedBox(height: 10),
                Text("No Invoices Generated Yet", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Tap '+ Create Client Invoice' to generate an itemized invoice with scan-to-pay UPI QR code.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...invoices.map((inv) => _buildInvoiceCard(context, inv, currency, invoiceProvider)),
      ],
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel inv, String currency, InvoiceProvider provider) {
    final isPaid = inv.status.toLowerCase() == 'paid';
    final total = inv.totalAmount > 0 ? inv.totalAmount : inv.calculatedTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.invoiceNo, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(inv.clientName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inv.status.toUpperCase(),
                  style: TextStyle(color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Amount: $currency${total.toStringAsFixed(2)}  (incl. ${inv.taxRate.toStringAsFixed(0)}% GST)",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.qr_code, size: 14, color: Color(0xFF818CF8)),
                label: const Text("Scan-to-Pay QR", style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showQrModal(context, inv, total, currency),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isPaid ? Icons.undo : Icons.check_circle, color: isPaid ? Colors.white60 : const Color(0xFF10B981), size: 18),
                    tooltip: isPaid ? "Mark Unpaid" : "Mark Paid",
                    onPressed: () {
                      if (inv.id != null) provider.updateStatus(inv.id!, isPaid ? 'unpaid' : 'paid');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                    tooltip: "Delete",
                    onPressed: () {
                      if (inv.id != null) provider.deleteInvoice(inv.id!);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, InvoiceModel inv, double total, String currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(inv.invoiceNo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("$currency${total.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text("Payable to: ${inv.upiId}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 20),
            UpiQrWidget(
              data: inv.upiPaymentUrl,
              size: 200,
              centerLabel: "UPI PAY",
            ),
            const SizedBox(height: 16),
            const Text(
              "Scan with Google Pay, PhonePe, Paytm, or BHIM to pay instantly",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateInvoiceDialog(BuildContext context, InvoiceProvider provider) {
    final clientCtrl = TextEditingController();
    final upiCtrl = TextEditingController(text: 'deepak@okaxis');
    final descCtrl = TextEditingController(text: 'Consulting & Development Services');
    final amtCtrl = TextEditingController(text: '15000');
    final taxCtrl = TextEditingController(text: '18');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Client Invoice", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: clientCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Client / Company Name",
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0B0F19),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: upiCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Your Receiving UPI ID (e.g. yourname@okaxis)",
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0B0F19),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Service / Item Description",
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF0B0F19),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: "Amount (₹)",
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF0B0F19),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: taxCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: "GST %",
                        labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF0B0F19),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () async {
                    final client = clientCtrl.text.trim();
                    final upi = upiCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                    final tax = double.tryParse(taxCtrl.text.trim()) ?? 18.0;

                    if (client.isNotEmpty && amt > 0) {
                      await provider.createInvoice({
                        'clientName': client,
                        'upiId': upi.isNotEmpty ? upi : 'deepak@okaxis',
                        'taxRate': tax,
                        'items': [
                          {
                            'description': desc.isNotEmpty ? desc : 'Services Rendered',
                            'quantity': 1,
                            'unitPrice': amt,
                          }
                        ],
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Generate Invoice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
