import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ml_prediction_service.dart';
import '../models/prediction_result.dart';
import '../models/transaction.dart';
import '../state/profile_provider.dart';
import 'how_it_works_screen.dart';

import '../services/offline_storage_service.dart';
import '../state/transaction_provider.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  final ApiService _apiService = ApiService();
  final MLPredictionService _mlService = MLPredictionService();

  PredictionResult? _prediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePredictions();
    });
  }

  Future<void> _calculatePredictions() async {
    setState(() => _isLoading = true);
    try {
      final txProvider = context.read<TransactionProvider>();
      if (txProvider.transactions.isEmpty) {
        await txProvider.fetchTransactions();
      }
      List<TransactionModel> txs = txProvider.transactions;
      if (txs.isEmpty) {
        final local = await OfflineStorageService().getLocalTransactions();
        if (local.isNotEmpty) txs = local;
      }
      if (txs.isEmpty) {
        txs = await _apiService.getTransactions();
      }
      final res = await _mlService.predict(txs);
      setState(() {
        _prediction = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;

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
                  colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "AI Spend Predictions",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Holt's Smoothing Forecast",
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            tooltip: "Methodology",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: "Refresh Forecast",
            onPressed: _calculatePredictions,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 16),
                    Text("Calculating ML Trend Forecast...", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ],
                ),
              )
            : _prediction == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        const Text("Failed to compute predictions", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _calculatePredictions,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                          child: const Text("Retry Calculation"),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Method Explanation Banner
                        _buildMethodBanner(),
                        const SizedBox(height: 16),

                        // 4 Key Forecast Metrics Grid
                        _buildMetricsGrid(currency),
                        const SizedBox(height: 16),

                        // Confidence & Certainty Meters
                        _buildConfidenceSection(),
                        const SizedBox(height: 20),

                        // 6-Month Projected Cash Flow Line Chart
                        _buildCashFlowChartCard(currency),
                        const SizedBox(height: 20),

                        // Monthly Income vs Expense Forecast Bar Chart
                        _buildForecastBarChartCard(currency),
                        const SizedBox(height: 20),

                        // Forecast Insights & Recommendations
                        _buildInsightsCard(),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text("Refresh Forecast"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _calculatePredictions,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.menu_book_rounded, size: 18),
                                label: const Text("How It Works"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF818CF8),
                                  side: const BorderSide(color: Color(0xFF4F46E5)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMethodBanner() {
    return Container(
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
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_graph, color: Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Statistical Forecast Model",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF475569)),
                      ),
                      child: Text(
                        "${_prediction!.dataPointsUsed} data points",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _prediction!.methodDescription.isNotEmpty
                      ? _prediction!.methodDescription
                      : "Holt's Double Linear Exponential Smoothing predicting forward cash flow trajectories.",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(String currency) {
    final risk = _prediction!.overspendingRisk;
    final riskColor = risk > 0.6 ? const Color(0xFFEF4444) : risk > 0.3 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final riskLabel = risk > 0.6 ? "High Risk" : risk > 0.3 ? "Moderate" : "Low Risk";

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        // Next Month Expense
        _buildMetricCard(
          title: "Next Month Expense",
          value: "$currency${_prediction!.nextMonthExpense.toStringAsFixed(0)}",
          subtitle: "Projected spend",
          icon: Icons.calendar_month,
          accentColor: const Color(0xFF6366F1),
        ),
        // Expected Savings
        _buildMetricCard(
          title: "Expected Savings",
          value: "$currency${_prediction!.expectedSavings.toStringAsFixed(0)}",
          subtitle: _prediction!.expectedSavings >= 0 ? "Projected surplus" : "Projected deficit",
          icon: Icons.savings_outlined,
          accentColor: _prediction!.expectedSavings >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
        // Overspending Risk
        _buildRiskMetricCard(risk, riskColor, riskLabel),
        // Recommended Budget
        _buildMetricCard(
          title: "Budget Cap",
          value: "$currency${_prediction!.budgetRecommendation.toStringAsFixed(0)}",
          subtitle: "AI recommended limit",
          icon: Icons.track_changes,
          accentColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500)),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(color: accentColor == const Color(0xFFEF4444) ? Colors.redAccent : Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildRiskMetricCard(double risk, Color riskColor, String riskLabel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overspending Risk", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500)),
              Icon(Icons.warning_amber_rounded, size: 16, color: riskColor),
            ],
          ),
          Row(
            children: [
              Text(
                "${(risk * 100).toStringAsFixed(0)}%",
                style: TextStyle(color: riskColor, fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(riskLabel, style: TextStyle(color: riskColor, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: risk.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF334155),
              color: riskColor,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection() {
    final accuracy = _prediction!.predictionAccuracy;
    final certainty = _prediction!.confidenceScore;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.speed, size: 15, color: Color(0xFF6366F1)),
                        SizedBox(width: 6),
                        Text("Forecast Confidence", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${(accuracy * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF334155),
                        color: const Color(0xFF6366F1),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text("Grows with more transaction logs", style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 75, color: const Color(0xFF334155)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.hub_outlined, size: 15, color: Color(0xFF3B82F6)),
                        SizedBox(width: 6),
                        Text("Model Certainty", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${(certainty * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: certainty.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF334155),
                        color: const Color(0xFF3B82F6),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text("Trend stability metric", style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChartCard(String currency) {
    final list = _prediction!.cashFlowForecast;
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < list.length; i++) {
      spots.add(FlSpot(i.toDouble(), list[i].amount));
    }

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
                  Text("6-Month Cash Flow Forecast", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text("Projected net balance progression", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Trend View", style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF334155), strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              list[idx].month,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "$currency${(value / 1000).toStringAsFixed(0)}k",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF6366F1),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF818CF8),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.35),
                          const Color(0xFF6366F1).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastBarChartCard(String currency) {
    final list = _prediction!.cashFlowForecast;
    if (list.isEmpty) return const SizedBox.shrink();

    final expectedExpense = _prediction!.nextMonthExpense;

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
                  Text("Monthly Forecast Breakdown", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text("Expected Income vs Expenses", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text("Income", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text("Expense", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFF334155), strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < list.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(list[idx].month, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        "$currency${(v / 1000).toStringAsFixed(0)}k",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(list.length, (idx) {
                  final projBalance = list[idx].amount;
                  final projIncome = (expectedExpense + projBalance).clamp(0.0, 9999999.0);

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: projIncome,
                        color: const Color(0xFF10B981),
                        width: 9,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expectedExpense,
                        color: const Color(0xFFF97316),
                        width: 9,
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

  Widget _buildInsightsCard() {
    final insights = _prediction!.insights;

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
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFFBBF24), size: 18),
              SizedBox(width: 8),
              Text("Forecast Insights & Recommendations", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            const Text("Record more daily expenses to generate deeper AI recommendations.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
          else
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            insight,
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
