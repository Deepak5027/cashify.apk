import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/goal_provider.dart';
import '../state/profile_provider.dart';
import '../models/goal.dart';

class GoalsScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const GoalsScreen({super.key, this.onMenuPressed});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    final goals = goalProvider.goals;
    final totalTarget = goalProvider.totalTargetAmount;
    final totalSaved = goalProvider.totalSavedAmount;
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;

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
        title: const Text("Savings Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => goalProvider.fetchGoals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showAddEditGoalDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Goal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: () => goalProvider.fetchGoals(),
              color: const Color(0xFF6366F1),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Overall Savings Target Hero Banner
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("TOTAL SAVINGS TARGET", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 6),
                              Text("$currency${totalSaved.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text("Target: $currency${totalTarget.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0,
                                backgroundColor: Colors.white12,
                                color: Colors.greenAccent,
                                strokeWidth: 6,
                              ),
                            ),
                            Text(
                              "${overallProgress.toStringAsFixed(0)}%",
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Text("Active Goals (${goals.length})", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (goals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.flag_outlined, size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text("No savings goals yet", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Tap 'New Goal' below to start tracking your targets.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...goals.map((g) => _buildGoalCard(context, g, currency, goalProvider)),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel g, String currency, GoalProvider provider) {
    final progress = g.progressPercentage;
    final isDone = g.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.06),
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
                      color: (isDone ? Colors.greenAccent : const Color(0xFF6366F1)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isDone ? Icons.celebration : Icons.savings_outlined, color: isDone ? Colors.greenAccent : const Color(0xFF818CF8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      if (g.deadline != null)
                        Text(
                          "Target: ${g.deadline!.day}/${g.deadline!.month}/${g.deadline!.year}",
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                    onPressed: () => _showAddEditGoalDialog(context, existing: g),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => _confirmDelete(context, g, provider),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saved: $currency${g.currentAmount.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "Target: $currency${g.targetAmount.toStringAsFixed(0)} (${progress.toStringAsFixed(0)}%)",
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(isDone ? Colors.greenAccent : const Color(0xFF6366F1)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone ? "🎉 Goal Achieved!" : "Remaining: $currency${g.remainingAmount.toStringAsFixed(0)}",
                style: TextStyle(color: isDone ? Colors.greenAccent : Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showDepositDialog(context, g, provider),
                icon: const Icon(Icons.add, size: 14),
                label: const Text("Deposit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context, GoalModel g, GoalProvider provider) {
    final depositCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Deposit to ${g.name}", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: depositCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Deposit Amount",
            labelStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.currency_rupee, color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              final amt = double.tryParse(depositCtrl.text.trim());
              if (amt != null && amt > 0 && g.id != null) {
                Navigator.pop(ctx);
                await provider.depositToGoal(g.id!, amt);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deposited ₹$amt to ${g.name}!"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text("Add Deposit"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GoalModel g, GoalProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Goal?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to remove '${g.name}'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (g.id != null) {
                await provider.deleteGoal(g.id!);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showAddEditGoalDialog(BuildContext context, {GoalModel? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final targetCtrl = TextEditingController(text: existing != null ? existing.targetAmount.toString() : '');
    final savedCtrl = TextEditingController(text: existing != null ? existing.currentAmount.toString() : '0');

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
              Text(existing == null ? "Create Savings Goal" : "Edit Goal Target", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Goal Name (e.g. Vacation, Emergency Fund)", labelStyle: TextStyle(color: Colors.white54)),
                validator: (val) => val == null || val.trim().isEmpty ? "Enter goal name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Target Amount", labelStyle: TextStyle(color: Colors.white54)),
                validator: (val) => val == null || double.tryParse(val) == null ? "Enter valid target" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: savedCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Initial Saved Amount", labelStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameCtrl.text.trim();
                    final target = double.parse(targetCtrl.text.trim());
                    final saved = double.tryParse(savedCtrl.text.trim()) ?? 0.0;

                    Navigator.pop(ctx);
                    if (existing == null) {
                      await context.read<GoalProvider>().addGoal(GoalModel(name: name, targetAmount: target, currentAmount: saved));
                    } else {
                      await context.read<GoalProvider>().updateGoal(existing.id!, {'name': name, 'target': target, 'saved': saved});
                    }
                  },
                  child: Text(existing == null ? "Create Goal" : "Update Goal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
