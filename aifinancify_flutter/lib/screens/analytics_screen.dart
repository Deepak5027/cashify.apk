import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/transaction.dart';

class AnalyticsScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const AnalyticsScreen({super.key, this.onMenuPressed});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    final transactions = txProvider.transactions;
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;
    final categoryBreakdown = txProvider.categoryBreakdown;

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
        title: const Text(
          "Financial Analytics",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.indigoAccent),
            tooltip: "Export Summary",
            onPressed: () => _showExportSummaryDialog(context, totalIncome, totalExpense, netSavings, savingsRate, currency),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      body: txProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () => txProvider.fetchTransactions(),
              color: const Color(0xFF6366F1),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: "Net Savings",
                          value: "$currency${netSavings.toStringAsFixed(0)}",
                          subtitle: "${savingsRate.toStringAsFixed(1)}% savings rate",
                          isPositive: netSavings >= 0,
                          icon: Icons.savings_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: "Total Spent",
                          value: "$currency${totalExpense.toStringAsFixed(0)}",
                          subtitle: "${transactions.where((t) => t.type == 'expense').length} expenses",
                          isPositive: false,
                          icon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Income vs Expense Comparison Card
                  _buildSectionCard(
                    title: "Income vs Expense Overview",
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2 + 100,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      if (val == 0) return const Text("Income", style: TextStyle(color: Colors.greenAccent, fontSize: 12));
                                      if (val == 1) return const Text("Expense", style: TextStyle(color: Colors.redAccent, fontSize: 12));
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totalIncome > 0 ? totalIncome : 10,
                                      color: Colors.greenAccent,
                                      width: 32,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: totalExpense > 0 ? totalExpense : 10,
                                      color: Colors.redAccent,
                                      width: 32,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem("Income ($currency${totalIncome.toStringAsFixed(0)})", Colors.greenAccent),
                            const SizedBox(width: 20),
                            _buildLegendItem("Expense ($currency${totalExpense.toStringAsFixed(0)})", Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Breakdown Chart & List
                  _buildSectionCard(
                    title: "Expense Breakdown by Category",
                    child: categoryBreakdown.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                "No expense transactions logged yet.",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 40,
                                    sections: _generatePieSections(categoryBreakdown, totalExpense),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...categoryBreakdown.entries.map((entry) {
                                final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(entry.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        "${percent.toStringAsFixed(1)}%",
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "$currency${entry.value.toStringAsFixed(0)}",
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Health Score Card
                  _buildSectionCard(
                    title: "Financial Health Assessment",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (savingsRate >= 20 ? Colors.greenAccent : Colors.amberAccent).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                savingsRate >= 20 ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: savingsRate >= 20 ? Colors.greenAccent : Colors.amberAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    savingsRate >= 30
                                        ? "Excellent Savings Rate"
                                        : savingsRate >= 15
                                            ? "Healthy Savings Pace"
                                            : "Budget Optimization Recommended",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    savingsRate >= 20
                                        ? "You are saving more than 20% of your earnings. Keep it up!"
                                        : "Aim to allocate at least 20% of monthly income towards savings goals.",
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(icon, color: isPositive ? Colors.greenAccent : Colors.redAccent, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, double> categoryBreakdown, double total) {
    if (total == 0) return [];
    return categoryBreakdown.entries.map((e) {
      final val = e.value;
      final percent = (val / total) * 100;
      return PieChartSectionData(
        value: val,
        title: percent > 8 ? "${percent.toStringAsFixed(0)}%" : "",
        color: _getCategoryColor(e.key),
        radius: 36,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('dining') || cat.contains('grocer')) return Colors.orangeAccent;
    if (cat.contains('shop') || cat.contains('cloth') || cat.contains('amazon')) return Colors.purpleAccent;
    if (cat.contains('bill') || cat.contains('utilit') || cat.contains('rent')) return Colors.blueAccent;
    if (cat.contains('trans') || cat.contains('fuel') || cat.contains('cab')) return Colors.amberAccent;
    if (cat.contains('health') || cat.contains('med')) return Colors.tealAccent;
    if (cat.contains('entertain') || cat.contains('movie')) return Colors.pinkAccent;
    return Colors.indigoAccent;
  }

  void _showExportSummaryDialog(
    BuildContext context,
    double income,
    double expense,
    double savings,
    double rate,
    String currency,
  ) {
    final transactions = context.read<TransactionProvider>().transactions;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
        title: Row(
          children: const [
            Icon(Icons.analytics_outlined, color: Color(0xFF818CF8), size: 22),
            SizedBox(width: 8),
            Text("Monthly Financial Summary", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Total Income", "+$currency${income.toStringAsFixed(2)}", const Color(0xFF10B981)),
                  const SizedBox(height: 6),
                  _buildSummaryRow("Total Expenses", "-$currency${expense.toStringAsFixed(2)}", const Color(0xFFEF4444)),
                  const Divider(color: Color(0xFF334155), height: 16),
                  _buildSummaryRow("Net Savings", "$currency${savings.toStringAsFixed(2)}", Colors.white),
                  const SizedBox(height: 6),
                  _buildSummaryRow("Savings Rate", "${rate.toStringAsFixed(1)}%", const Color(0xFF818CF8)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _generateAndDownloadCsv(context, transactions, income, expense, savings, rate, currency);
            },
            icon: const Icon(Icons.download, size: 16, color: Colors.white),
            label: const Text("Download CSV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        Text(value, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _generateAndDownloadCsv(
    BuildContext context,
    List<TransactionModel> txs,
    double income,
    double expense,
    double savings,
    double rate,
    String currency,
  ) async {
    try {
      final StringBuffer csv = StringBuffer();
      csv.writeln("=== AiFinancify Financial Report ===");
      csv.writeln("Generated On,${DateTime.now().toIso8601String()}");
      csv.writeln("Total Income,$currency${income.toStringAsFixed(2)}");
      csv.writeln("Total Expense,$currency${expense.toStringAsFixed(2)}");
      csv.writeln("Net Savings,$currency${savings.toStringAsFixed(2)}");
      csv.writeln("Savings Rate,${rate.toStringAsFixed(1)}%");
      csv.writeln("");
      csv.writeln("ID,Date,Description,Category,Type,Amount,Payment Mode,Risk Score");

      for (var t in txs) {
        csv.writeln("${t.id ?? ''},${t.date.toIso8601String().split('T')[0]},\"${t.description ?? ''}\",\"${t.category}\",${t.type},${t.amount},\"${t.paymentMode}\",${t.riskScore}");
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/AiFinancify_Financial_Report.csv");
      await file.writeAsString(csv.toString());

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
                    Text("Report Downloaded Successfully", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                      Text("Total Rows Exported: ${txs.length} transactions", style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
