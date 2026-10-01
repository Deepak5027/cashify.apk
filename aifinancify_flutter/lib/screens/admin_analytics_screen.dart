import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/activity.dart';
import '../state/profile_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<ActivityModel> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final statsData = await _api.getAdminStats();
      final activitiesData = await _api.getActivities();
      setState(() {
        _stats = statsData;
        _activities = activitiesData;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;

    final totalUsers = _stats['totalUsers'] ?? _stats['usersCount'] ?? 1;
    final totalTxs = _stats['totalTransactions'] ?? _stats['transactionsCount'] ?? 0;
    final totalVolume = (_stats['totalVolume'] is num)
        ? (_stats['totalVolume'] as num).toDouble()
        : double.tryParse(_stats['totalVolume']?.toString() ?? '0') ?? 0.0;
    final totalBudgets = _stats['totalBudgets'] ?? _stats['budgetsCount'] ?? 0;
    final totalGoals = _stats['totalGoals'] ?? _stats['goalsCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text("Executive Admin Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAdminData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              color: const Color(0xFF6366F1),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stat cards grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _buildAdminStatCard("Total Users", "$totalUsers", Icons.people_alt_outlined, Colors.indigoAccent),
                      _buildAdminStatCard("Platform Volume", "$currency${totalVolume.toStringAsFixed(0)}", Icons.monetization_on_outlined, Colors.greenAccent),
                      _buildAdminStatCard("Transactions", "$totalTxs", Icons.receipt_long_outlined, Colors.purpleAccent),
                      _buildAdminStatCard("Active Budgets", "$totalBudgets", Icons.pie_chart_outline, Colors.amberAccent),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // System Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("System Health & Database", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildHealthRow("Database Engine", "SQLite / Prisma ORM", Colors.greenAccent),
                        _buildHealthRow("API Server", "Express REST (Port 4000)", Colors.greenAccent),
                        _buildHealthRow("Active Goals", "$totalGoals Active", Colors.indigoAccent),
                        _buildHealthRow("ML Prediction Engine", "Rule-Based + Time Series", Colors.greenAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Activity Logs
                  const Text("Recent System Activity Feed", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  if (_activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("No audit activity logged yet.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ),
                    )
                  else
                    ..._activities.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (a.type == 'expense' ? Colors.redAccent : Colors.indigoAccent).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  a.type == 'expense' ? Icons.arrow_upward : Icons.info_outline,
                                  size: 16,
                                  color: a.type == 'expense' ? Colors.redAccent : Colors.indigoAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    if (a.details != null && a.details!.isNotEmpty)
                                      Text(a.details!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(
                                "${a.createdAt.hour}:${a.createdAt.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
