import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/budget.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const BudgetScreen({super.key, this.onMenuPressed});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final txProvider = context.read<TransactionProvider>();
    await txProvider.fetchTransactions();
    if (mounted) {
      context.read<BudgetProvider>().fetchBudgets(txProvider.transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    final budgets = budgetProvider.budgets;
    final totalLimit = budgetProvider.totalBudgetLimit;
    final totalSpent = budgetProvider.totalBudgetSpent;
    final overallPercent = totalLimit > 0 ? (totalSpent / totalLimit) * 100 : 0.0;

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
            "Monthly Budget Planner",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            tooltip: "How Budget Works",
            onPressed: () => _showHowItWorksModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showAddEditBudgetDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Set Budget", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: const Color(0xFF6366F1),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Overall Budget Health Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "TOTAL MONTHLY SPENDING",
                              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (overallPercent > 90 ? Colors.redAccent : Colors.greenAccent).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${overallPercent.toStringAsFixed(0)}% Consumed",
                                style: TextStyle(
                                  color: overallPercent > 90 ? Colors.redAccent : Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "$currency${totalSpent.toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "/ $currency${totalLimit.toStringAsFixed(0)} limit",
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallPercent > 90
                                  ? Colors.redAccent
                                  : overallPercent > 75
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Explanatory Banner with tap to learn how math works
                  GestureDetector(
                    onTap: () => _showHowItWorksModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "How Budget & AI Forecast Work",
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "AI calculates end-of-month spend based on daily run-rate. Tap to see the live formulas.",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Color(0xFF818CF8), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Text(
                    "Category Budgets (${budgets.length})",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Budget Cards List
                  if (budgets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.pie_chart_outline, size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text("No budgets set yet", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Tap 'Set Budget' below to track spending limits.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...budgets.map((b) => _buildBudgetCard(context, b, currency, budgetProvider)),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetModel b,
    String currency,
    BudgetProvider provider,
  ) {
    final percent = b.percentageUsed;
    final isOver = b.isOverBudget;
    final progressColor = isOver
        ? Colors.redAccent
        : percent >= 75
            ? Colors.amberAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver ? Colors.redAccent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.category_outlined, color: progressColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    b.category,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                    onPressed: () => _showAddEditBudgetDialog(context, existing: b),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => _confirmDelete(context, b, provider),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spent: $currency${b.spent.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "Limit: $currency${b.limit.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: b.limit > 0 ? (b.spent / b.limit).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOver ? "Over budget by $currency${(b.spent - b.limit).toStringAsFixed(0)}" : "Remaining: $currency${b.remaining.toStringAsFixed(0)}",
                style: TextStyle(color: isOver ? Colors.redAccent : const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              if (b.predicted > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 11),
                      const SizedBox(width: 4),
                      Text(
                        "AI Forecast: $currency${b.predicted.toStringAsFixed(0)}",
                        style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 10, fontWeight: FontWeight.bold),
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

  void _showHowItWorksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calculate_outlined, color: Color(0xFF818CF8), size: 24),
                SizedBox(width: 10),
                Text("How Monthly Budget & AI Work", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationStep("1. Set Budget (Limit)", "The monthly limit you specify for each category (e.g. ₹10,000 for Food)."),
            _buildExplanationStep("2. Current Spent", "Sum of all actual expense transactions logged in this category for the active calendar month."),
            _buildExplanationStep("3. AI Predicted Spend", "Calculated as: (Spent so far ÷ Days elapsed) × Total days in month. If you spent ₹2,000 in 5 days, AI projects ₹12,000 by month-end."),
            _buildExplanationStep("4. Remaining Balance", "Set Budget Limit − Current Spent. Turns green if safe, amber if near limit, and red if exceeded."),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Got It", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationStep(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetModel b, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Budget?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to remove the budget for '${b.category}'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (b.id != null) {
                await provider.deleteBudget(b.id!);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showAddEditBudgetDialog(BuildContext context, {BudgetModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final limitCtrl = TextEditingController(text: existing != null ? existing.limit.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? "Set Category Budget" : "Edit Budget Limit",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: catCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Category Name (e.g. Food, Groceries)",
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.category, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Enter category name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Monthly Limit Amount",
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || double.tryParse(val) == null ? "Enter valid limit" : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final cat = catCtrl.text.trim();
                    final limit = double.parse(limitCtrl.text.trim());

                    Navigator.pop(ctx);
                    if (existing == null) {
                      await context.read<BudgetProvider>().addBudget(BudgetModel(category: cat, limit: limit));
                    } else {
                      await context.read<BudgetProvider>().updateBudget(existing.id!, {'name': cat, 'limit': limit});
                    }
                  },
                  child: Text(existing == null ? "Save Budget" : "Update Limit", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
