import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/transaction.dart';
import '../services/fraud_detection_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'All';

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

    final allTxs = txProvider.transactions;
    final highRisk = allTxs.where((t) => t.isHighRisk).toList();
    final mediumRisk = allTxs.where((t) => t.isMediumRisk).toList();
    final lowRisk = allTxs.where((t) => t.isLowRisk).toList();

    List<TransactionModel> displayList;
    if (_selectedFilter == 'High Risk') {
      displayList = highRisk;
    } else if (_selectedFilter == 'Medium Risk') {
      displayList = mediumRisk;
    } else if (_selectedFilter == 'Safe') {
      displayList = lowRisk;
    } else {
      displayList = allTxs.where((t) => t.isHighRisk || t.isMediumRisk).toList();
      if (displayList.isEmpty) {
        displayList = allTxs;
      }
    }

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
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Fraud & Risk Alert Center",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Color(0xFF818CF8)),
            tooltip: "Test Live Scanner",
            onPressed: () => _showFraudSimulatorDialog(context, allTxs),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: "Refresh Alerts",
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      body: txProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Summary Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildRiskBadgeCard(
                        "High Risk",
                        "${highRisk.length}",
                        const Color(0xFFEF4444),
                        _selectedFilter == 'High Risk',
                        () => setState(() => _selectedFilter = _selectedFilter == 'High Risk' ? 'All' : 'High Risk'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRiskBadgeCard(
                        "Medium Risk",
                        "${mediumRisk.length}",
                        const Color(0xFFF59E0B),
                        _selectedFilter == 'Medium Risk',
                        () => setState(() => _selectedFilter = _selectedFilter == 'Medium Risk' ? 'All' : 'Medium Risk'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRiskBadgeCard(
                        "Safe / Verified",
                        "${lowRisk.length}",
                        const Color(0xFF10B981),
                        _selectedFilter == 'Safe',
                        () => setState(() => _selectedFilter = _selectedFilter == 'Safe' ? 'All' : 'Safe'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Simulator Launcher Card
                GestureDetector(
                  onTap: () => _showFraudSimulatorDialog(context, allTxs),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.biotech, color: Color(0xFF818CF8), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Live Fraud Detector & Scanner",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Simulate transactions to test Z-score, velocity, and night anomaly detection in real time.",
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

                // Section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Flagged Transactions (${displayList.length})",
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedFilter != 'All')
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = 'All'),
                        child: const Text("Clear Filter", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transactions List
                if (displayList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 48),
                        SizedBox(height: 12),
                        Text(
                          "No Anomalies Detected",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "All recent transactions are within normal spending velocity and category baselines.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ...displayList.map((t) => _buildAlertItemCard(context, t, currency, txProvider)),
              ],
            ),
    );
  }

  Widget _buildRiskBadgeCard(String label, String count, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : const Color(0xFF334155), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItemCard(
    BuildContext context,
    TransactionModel tx,
    String currency,
    TransactionProvider provider,
  ) {
    final isHigh = tx.isHighRisk;
    final isMedium = tx.isMediumRisk;
    final riskColor = isHigh
        ? const Color(0xFFEF4444)
        : isMedium
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withOpacity(0.4), width: 1.2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(isHigh ? Icons.warning_amber_rounded : Icons.info_outline, size: 14, color: riskColor),
                        const SizedBox(width: 4),
                        Text(
                          "Risk ${tx.riskPercentage.toStringAsFixed(0)}%",
                          style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.category ?? 'Expense',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              Text(
                "$currency${tx.amount.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tx.description ?? 'Transaction',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Signal: ${tx.riskReason}",
            style: TextStyle(color: riskColor.withOpacity(0.95), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () async {
                  if (tx.id != null) {
                    await provider.updateTransaction(tx.id!, {
                      'status': 'normal',
                      'riskScore': 0.0,
                      'riskReason': 'Verified safe by user',
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Marked as verified safe!"),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                label: const Text("Mark Safe", style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
                onPressed: () async {
                  if (tx.id != null) {
                    await provider.deleteTransaction(tx.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reported fraud and removed transaction"),
                          backgroundColor: Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.block, size: 14, color: Color(0xFFEF4444)),
                label: const Text("Report & Remove", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFraudSimulatorDialog(BuildContext context, List<TransactionModel> history) {
    final amtCtrl = TextEditingController(text: "35000");
    final descCtrl = TextEditingController(text: "International Wire Crypto");
    String selectedCategory = "Food & Dining";
    FraudAnalysisResult? liveResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.biotech, color: Color(0xFF818CF8), size: 22),
                    SizedBox(width: 8),
                    Text("Live Transaction Risk Simulator", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Simulated Amount (₹)",
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Merchant / Description",
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Category Baseline",
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0B0F19),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Food & Dining', 'Groceries', 'Shopping', 'Transport', 'Bills & Utilities', 'Entertainment']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    onPressed: () {
                      final simulatedTx = TransactionModel(
                        amount: double.tryParse(amtCtrl.text) ?? 1000.0,
                        description: descCtrl.text,
                        category: selectedCategory,
                        date: DateTime.now(),
                      );
                      final result = FraudDetectionService.calculateFraudScore(simulatedTx, history);
                      setModalState(() => liveResult = result);
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text("Run Multi-Factor Anomaly Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (liveResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: liveResult!.riskScore >= 0.6
                            ? const Color(0xFFEF4444)
                            : liveResult!.riskScore >= 0.35
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Calculated Risk: ${(liveResult!.riskScore * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: liveResult!.riskScore >= 0.6
                                    ? const Color(0xFFEF4444)
                                    : liveResult!.riskScore >= 0.35
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Level: ${liveResult!.riskLevel.toUpperCase()}",
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...liveResult!.reasons.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ", style: TextStyle(color: Color(0xFF818CF8))),
                                  Expanded(
                                    child: Text(r, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

