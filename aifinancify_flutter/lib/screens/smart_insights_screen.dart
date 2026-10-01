import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/fraud_detection_service.dart';
import '../models/transaction.dart';
import '../state/profile_provider.dart';

import '../state/transaction_provider.dart';

class SmartInsightsScreen extends StatefulWidget {
  const SmartInsightsScreen({super.key});

  @override
  State<SmartInsightsScreen> createState() => _SmartInsightsScreenState();
}

class _SmartInsightsScreenState extends State<SmartInsightsScreen> {
  final ApiService _apiService = ApiService();

  List<Transaction> _flaggedTransactions = [];
  bool _isLoading = true;
  double _overallRiskScore = 0.0;
  int _financialHealthScore = 78;
  double _savingsRate = 20.0;
  List<double> _dayOfWeekSpending = [0, 0, 0, 0, 0, 0, 0];
  List<Map<String, dynamic>> _dynamicInsights = [];
  List<Map<String, dynamic>> _dynamicRecommendations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeData();
    });
  }

  Future<void> _analyzeData() async {
    setState(() => _isLoading = true);
    try {
      final txProvider = context.read<TransactionProvider>();
      List<Transaction> txs = txProvider.transactions;
      if (txs.isEmpty) {
        txs = await _apiService.getTransactions();
      }

      final List<Transaction> flagged = [];
      double totalRisk = 0.0;
      int count = 0;

      for (var tx in txs) {
        final analysis = FraudDetectionService.calculateFraudScore(tx, txs);
        if (analysis.isFlagged || tx.isHighRisk || tx.isMediumRisk) {
          flagged.add(tx);
          totalRisk += analysis.riskScore;
          count++;
        }
      }

      // Calculate dynamic Financial Health Score (0-100)
      final expenses = txs.where((t) => t.type.toLowerCase() == 'expense').toList();
      final income = txs.where((t) => t.type.toLowerCase() == 'income').toList();
      final totalExp = expenses.fold<double>(0.0, (s, t) => s + t.amount);
      final totalInc = income.fold<double>(0.0, (s, t) => s + t.amount);

      double savingsPct = 15.0;
      int score = 75;
      if (totalInc > 0) {
        savingsPct = ((totalInc - totalExp) / totalInc) * 100;
        if (savingsPct > 25) score += 15;
        else if (savingsPct > 15) score += 10;
        else if (savingsPct < 0) score -= 20;
      } else if (totalExp > 0) {
        score -= 10;
      }
      if (flagged.isNotEmpty) score -= (flagged.length * 5);
      score = score.clamp(30, 98);

      // Compute Day of Week Spending
      final List<double> dayTotals = [0, 0, 0, 0, 0, 0, 0];
      for (var t in expenses) {
        final weekday = t.date.weekday; // 1 = Mon, 7 = Sun
        dayTotals[weekday - 1] += t.amount;
      }

      // Generate dynamic insights
      final List<Map<String, dynamic>> insights = [];
      if (expenses.isNotEmpty) {
        final Map<String, double> catMap = {};
        for (var t in expenses) {
          final cat = t.category ?? 'Other';
          catMap[cat] = (catMap[cat] ?? 0.0) + t.amount;
        }
        final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        if (sortedCats.isNotEmpty && totalExp > 0) {
          final top = sortedCats.first;
          final pct = (top.value / totalExp) * 100;
          insights.add({
            'type': 'warning',
            'title': 'Category Concentration: ${top.key}',
            'desc': '${top.key} represents ${pct.toStringAsFixed(1)}% (₹${top.value.toStringAsFixed(0)}) of all logged expenses.',
            'action': 'Review Category',
            'icon': Icons.pie_chart,
            'color': const Color(0xFFF59E0B),
          });
        }
      }

      // Weekend spending velocity
      final weekdaySum = dayTotals[0] + dayTotals[1] + dayTotals[2] + dayTotals[3] + dayTotals[4];
      final weekendSum = dayTotals[5] + dayTotals[6];
      if (weekendSum > 0 && weekdaySum > 0) {
        final weekendDaily = weekendSum / 2.0;
        final weekdayDaily = weekdaySum / 5.0;
        if (weekendDaily > weekdayDaily * 1.25) {
          insights.add({
            'type': 'warning',
            'title': 'High Weekend Spending Velocity',
            'desc': 'Daily weekend spending is ${(weekendDaily / weekdayDaily * 100 - 100).toStringAsFixed(0)}% higher than weekday averages.',
            'action': 'Set Weekend Cap',
            'icon': Icons.trending_up,
            'color': const Color(0xFFEF4444),
          });
        }
      }

      insights.add({
        'type': 'success',
        'title': 'Predictive Cash Flow Tracker',
        'desc': totalInc > totalExp
            ? 'Positive cash flow of ₹${(totalInc - totalExp).toStringAsFixed(0)} maintained with strong surplus.'
            : 'Expense tracking active across ${txs.length} recorded transactions.',
        'action': 'Track Trends',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
      });

      // Dynamic Savings Recommendations
      final List<Map<String, dynamic>> recs = [];
      if (expenses.isNotEmpty) {
        recs.add({
          'title': 'Optimize Discretionary Spending',
          'savings': (totalExp * 0.12).toStringAsFixed(0),
          'effort': 'Low',
          'impact': 'High',
          'desc': 'Trimming ~12% across top expense categories could save ~₹${(totalExp * 0.12).toStringAsFixed(0)} monthly.',
        });
      }
      recs.add({
        'title': 'Automate Recurring Bill Schedules',
        'savings': '350',
        'effort': 'Low',
        'impact': 'Medium',
        'desc': 'Scheduling utility & recurring bill payments prevents late surcharges.',
      });

      setState(() {
        _flaggedTransactions = flagged;
        _overallRiskScore = count > 0 ? (totalRisk / count) : 0.0;
        _financialHealthScore = score;
        _savingsRate = savingsPct;
        _dayOfWeekSpending = dayTotals;
        _dynamicInsights = insights;
        _dynamicRecommendations = recs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;
    final scoreLabel = _financialHealthScore >= 80 ? 'Excellent' : _financialHealthScore >= 60 ? 'Good' : 'Needs Work';
    final scoreColor = _financialHealthScore >= 80 ? const Color(0xFF10B981) : _financialHealthScore >= 60 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

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
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Smart Insights", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  Text("Financial Health & AI Tips", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _analyzeData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    SizedBox(height: 16),
                    Text("Generating Financial Insights...", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Health Score Card
                    _buildHealthScoreCard(scoreLabel, scoreColor),
                    const SizedBox(height: 20),

                    // AI Key Insights
                    _buildKeyInsightsSection(),
                    const SizedBox(height: 20),

                    // AI Savings Opportunities
                    _buildSavingsOpportunitiesSection(currency),
                    const SizedBox(height: 20),

                    // Day of Week Behavior Heatmap / Bar Chart
                    _buildDayOfWeekHeatmap(),
                    const SizedBox(height: 20),

                    // Flagged Anomalies & Spikes Section
                    _buildAnomaliesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHealthScoreCard(String scoreLabel, Color scoreColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("FINANCIAL HEALTH SCORE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$_financialHealthScore",
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: scoreColor),
                      ),
                      const Text("/100", style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scoreColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          scoreLabel,
                          style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF818CF8), size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_financialHealthScore / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF0F172A),
              color: scoreColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          // 3 Sub metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubScore("Savings Rate", "${_savingsRate.toStringAsFixed(0)}%", Icons.savings),
              Container(width: 1, height: 28, color: const Color(0xFF334155)),
              _buildSubScore("Budget Control", "${_financialHealthScore > 70 ? '88%' : '65%'}", Icons.tune),
              Container(width: 1, height: 28, color: const Color(0xFF334155)),
              _buildSubScore("Anomaly Shield", "${(100 - (_overallRiskScore * 100)).toStringAsFixed(0)}%", Icons.verified_user),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubScore(String title, String val, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildKeyInsightsSection() {
    final insights = _dynamicInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI Financial Intelligence",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (insights.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF818CF8)),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Add more transactions to generate personalized AI intelligence.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
              ],
            ),
          )
        else
          ...insights.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildSavingsOpportunitiesSection(String currency) {
    final recommendations = _dynamicRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "AI Savings Opportunities",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "Real-Time Analysis",
              style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rec['title']!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Save $currency${rec['savings']}/mo",
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec['desc']!,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge("Effort: ${rec['effort']}", const Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      _buildBadge("Impact: ${rec['impact']}", const Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBadge(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDayOfWeekHeatmap() {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final actual = _dayOfWeekSpending;
    final maxActual = actual.reduce((a, b) => a > b ? a : b);
    final baseline = maxActual > 0 ? maxActual * 0.7 : 50.0;

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Spending Behavior Heatmap", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text("Day-of-Week Actual Breakdown", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text("Actual", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text("AI Baseline", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF334155), strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(days[idx], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (idx) {
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: actual[idx],
                        color: const Color(0xFF6366F1),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: baseline,
                        color: const Color(0xFF38BDF8),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Anomaly & Risk Shield",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        if (_flaggedTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("All Transactions Safe & Normalized", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 2),
                      Text("No abnormal spikes, late-night anomalies, or suspicious merchants found.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._flaggedTransactions.map((tx) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.merchant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(tx.riskReason.isNotEmpty ? tx.riskReason : "Unusual amount spike detected", style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      "₹${tx.amount.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
