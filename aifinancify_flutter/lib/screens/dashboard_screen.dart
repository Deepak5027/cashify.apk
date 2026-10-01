import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/transaction_provider.dart';
import '../state/budget_provider.dart';
import '../state/goal_provider.dart';
import '../state/profile_provider.dart';
import '../state/auth_provider.dart';
import '../state/virtual_card_provider.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DashboardScreen({super.key, this.onMenuPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _refreshAll() async {
    final txProvider = context.read<TransactionProvider>();
    await txProvider.fetchTransactions();
    if (mounted) {
      context.read<BudgetProvider>().fetchBudgets(txProvider.transactions);
      context.read<GoalProvider>().fetchGoals();
      context.read<ProfileProvider>().fetchProfile();
      context.read<VirtualCardProvider>().fetchVirtualCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final currency = profileProvider.currency;

    final transactions = txProvider.transactions;
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final balance = txProvider.totalBalance;
    final flaggedTxs = txProvider.flaggedTransactions;
    final budgets = budgetProvider.budgets;
    final categoryBreakdown = txProvider.categoryBreakdown;

    final userName = profileProvider.profile?.name ?? authUser?['name'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          tooltip: "Open Menu",
          onPressed: () {
            if (widget.onMenuPressed != null) {
              widget.onMenuPressed!();
            } else {
              Scaffold.maybeOf(context)?.openDrawer();
            }
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Hi, $userName 👋", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Welcome to AiFinancify", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (flaggedTxs.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            tooltip: "Fraud & Risk Alerts",
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: "User Profile",
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: "Settings",
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => Navigator.pushNamed(context, '/chatbot'),
        icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        label: const Text("AI Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: txProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () async => _refreshAll(),
              color: const Color(0xFF6366F1),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total Balance Hero Card
                  _buildBalanceCard(balance, totalIncome, totalExpense, currency),
                  const SizedBox(height: 16),

                  // Virtual Spend Card Glance Banner
                  _buildVirtualCardBanner(currency),
                  const SizedBox(height: 16),

                  // Fraud Alert Banner if any flagged transactions exist
                  if (flaggedTxs.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/alerts'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${flaggedTxs.length} Suspicious Transactions Flagged",
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const Text("Tap to review in Fraud Alert Center", style: TextStyle(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quick Action Hub Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Smart Financial Tools", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text("12 Modules", style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActionGrid(),
                  const SizedBox(height: 20),

                  // Spending Breakdown Pie Chart
                  if (categoryBreakdown.isNotEmpty) ...[
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
                              const Text("Monthly Spending Breakdown", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/analytics'),
                                child: const Text("Full Analytics →", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: _generatePieSections(categoryBreakdown, totalExpense),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Monthly Budget Progress Summary
                  if (budgets.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Budget Trackers", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/budget'),
                          child: const Text("Manage →", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...budgets.take(3).map((b) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b.category, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text("$currency${b.spent.toStringAsFixed(0)} / $currency${b.limit.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: b.limit > 0 ? (b.spent / b.limit).clamp(0.0, 1.0) : 0.0,
                                  backgroundColor: const Color(0xFF0F172A),
                                  valueColor: AlwaysStoppedAnimation<Color>(b.isOverBudget ? Colors.redAccent : const Color(0xFF6366F1)),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Transactions", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/transactions'),
                        child: const Text("View All →", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Center(
                        child: Text("No transactions recorded yet. Tap Scan OCR, Voice In, or UPI Import to start!", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12), textAlign: TextAlign.center),
                      ),
                    )
                  else
                    ...transactions.take(5).map((t) {
                      final isIncome = t.type == 'income';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                                color: isIncome ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description ?? 'Transaction', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text("${t.category} • ${t.paymentMode}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              "${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}",
                              style: TextStyle(color: isIncome ? const Color(0xFF10B981) : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL NET BALANCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(
            "$currency${balance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_downward, size: 14, color: Color(0xFF34D399)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Income", style: TextStyle(fontSize: 11, color: Colors.white70)),
                        Text("$currency${income.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_upward, size: 14, color: Color(0xFFF87171)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Expenses", style: TextStyle(fontSize: 11, color: Colors.white70)),
                        Text("$currency${expense.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualCardBanner(String currency) {
    final card = context.watch<VirtualCardProvider>().card;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/virtual-card'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.credit_card, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.cardNumber,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: card.isFrozen ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.isFrozen ? "FROZEN" : "ACTIVE",
                          style: TextStyle(color: card.isFrozen ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Monthly Cap: $currency${card.currentSpend.toStringAsFixed(0)} / $currency${card.spendingLimit.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF818CF8), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _buildActionItem(Icons.credit_card, "Virtual Card", '/virtual-card', Colors.indigoAccent),
        _buildActionItem(Icons.picture_as_pdf, "Statements", '/statements', Colors.amberAccent),
        _buildActionItem(Icons.camera_alt, "Scan OCR", '/scanner', Colors.blueAccent),
        _buildActionItem(Icons.mic, "Voice In", '/voice-entry', Colors.purpleAccent),
        _buildActionItem(Icons.message, "UPI Import", '/upi-import', Colors.greenAccent),
        _buildActionItem(Icons.file_upload, "Bank CSV", '/bank-import', Colors.tealAccent),
        _buildActionItem(Icons.chat_bubble, "AI Chat", '/chatbot', Colors.cyanAccent),
        _buildActionItem(Icons.online_prediction, "Predict", '/predictions', Colors.tealAccent),
        _buildActionItem(Icons.insights, "Insights", '/insights', Colors.deepPurpleAccent),
        _buildActionItem(Icons.calculate, "EMI Calc", '/calculator', Colors.deepOrangeAccent),
        _buildActionItem(Icons.security, "Fraud Alert", '/alerts', Colors.redAccent),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, String routeName, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, double> categoryBreakdown, double total) {
    if (total == 0) return [];
    return categoryBreakdown.entries.map((e) {
      final val = e.value;
      final percent = (val / total) * 100;
      return PieChartSectionData(
        value: val,
        title: percent > 10 ? "${percent.toStringAsFixed(0)}%" : "",
        color: _getCategoryColor(e.key),
        radius: 30,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('dining') || cat.contains('grocer')) return Colors.orangeAccent;
    if (cat.contains('shop') || cat.contains('cloth')) return Colors.purpleAccent;
    if (cat.contains('bill') || cat.contains('rent')) return Colors.blueAccent;
    if (cat.contains('trans') || cat.contains('fuel')) return Colors.amberAccent;
    return Colors.indigoAccent;
  }
}
