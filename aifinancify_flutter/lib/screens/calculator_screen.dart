import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/profile_provider.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. EMI Calculator States
  final _emiLoanAmountCtrl = TextEditingController(text: '100000');
  final _emiInterestRateCtrl = TextEditingController(text: '10.5');
  final _emiTenureMonthsCtrl = TextEditingController(text: '24');
  double _calculatedEmi = 0.0;
  double _totalEmiInterest = 0.0;
  double _totalEmiPayment = 0.0;

  // 2. SIP Investment States
  final _sipMonthlyCtrl = TextEditingController(text: '5000');
  final _sipReturnCtrl = TextEditingController(text: '12');
  final _sipYearsCtrl = TextEditingController(text: '5');
  double _sipInvested = 0.0;
  double _sipReturns = 0.0;
  double _sipMaturity = 0.0;

  // 3. Emergency Fund States
  final _emgExpenseCtrl = TextEditingController(text: '25000');
  final _emgMonthsCtrl = TextEditingController(text: '6');
  double _emgTarget = 0.0;

  // 4. Tax Estimator States
  final _taxIncomeCtrl = TextEditingController(text: '800000');
  double _estimatedTax = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calculateEmi();
    _calculateSip();
    _calculateEmergency();
    _calculateTax();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emiLoanAmountCtrl.dispose();
    _emiInterestRateCtrl.dispose();
    _emiTenureMonthsCtrl.dispose();
    _sipMonthlyCtrl.dispose();
    _sipReturnCtrl.dispose();
    _sipYearsCtrl.dispose();
    _emgExpenseCtrl.dispose();
    _emgMonthsCtrl.dispose();
    _taxIncomeCtrl.dispose();
    super.dispose();
  }

  void _calculateEmi() {
    final P = double.tryParse(_emiLoanAmountCtrl.text.trim()) ?? 0.0;
    final r = (double.tryParse(_emiInterestRateCtrl.text.trim()) ?? 0.0) / (12 * 100);
    final n = double.tryParse(_emiTenureMonthsCtrl.text.trim()) ?? 0.0;

    if (P > 0 && r > 0 && n > 0) {
      final emi = (P * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
      final totalPay = emi * n;
      setState(() {
        _calculatedEmi = emi;
        _totalEmiPayment = totalPay;
        _totalEmiInterest = totalPay - P;
      });
    }
  }

  void _calculateSip() {
    final P = double.tryParse(_sipMonthlyCtrl.text.trim()) ?? 0.0;
    final i = (double.tryParse(_sipReturnCtrl.text.trim()) ?? 0.0) / (12 * 100);
    final n = (double.tryParse(_sipYearsCtrl.text.trim()) ?? 0.0) * 12;

    if (P > 0 && i > 0 && n > 0) {
      final M = P * ((pow(1 + i, n) - 1) / i) * (1 + i);
      final invested = P * n;
      setState(() {
        _sipInvested = invested;
        _sipMaturity = M;
        _sipReturns = M - invested;
      });
    }
  }

  void _calculateEmergency() {
    final exp = double.tryParse(_emgExpenseCtrl.text.trim()) ?? 0.0;
    final months = double.tryParse(_emgMonthsCtrl.text.trim()) ?? 0.0;
    setState(() {
      _emgTarget = exp * months;
    });
  }

  void _calculateTax() {
    final income = double.tryParse(_taxIncomeCtrl.text.trim()) ?? 0.0;
    // Standard Indian New Tax Regime estimation
    double tax = 0.0;
    if (income > 700000) {
      if (income <= 600000) {
        tax = (income - 300000) * 0.05;
      } else if (income <= 900000) {
        tax = 15000 + (income - 600000) * 0.10;
      } else if (income <= 1200000) {
        tax = 45000 + (income - 900000) * 0.15;
      } else if (income <= 1500000) {
        tax = 90000 + (income - 1200000) * 0.20;
      } else {
        tax = 150000 + (income - 1500000) * 0.30;
      }
    }
    setState(() {
      _estimatedTax = tax;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text("Financial Calculator Suite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: "Loan EMI"),
            Tab(text: "SIP Growth"),
            Tab(text: "Emergency Fund"),
            Tab(text: "Tax Estimator"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmiTab(currency),
          _buildSipTab(currency),
          _buildEmergencyTab(currency),
          _buildTaxTab(currency),
        ],
      ),
    );
  }

  Widget _buildEmiTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResultCard(
          title: "MONTHLY EMI PAYOUT",
          value: "$currency${_calculatedEmi.toStringAsFixed(0)}",
          rows: [
            _buildResultRow("Principal Loan Amount", "$currency${_emiLoanAmountCtrl.text}"),
            _buildResultRow("Total Interest Payable", "$currency${_totalEmiInterest.toStringAsFixed(0)}", color: Colors.amberAccent),
            _buildResultRow("Total Amount Payable", "$currency${_totalEmiPayment.toStringAsFixed(0)}", color: Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalcInput("Loan Amount ($currency)", _emiLoanAmountCtrl, _calculateEmi),
        const SizedBox(height: 12),
        _buildCalcInput("Interest Rate (% per annum)", _emiInterestRateCtrl, _calculateEmi),
        const SizedBox(height: 12),
        _buildCalcInput("Tenure (Months)", _emiTenureMonthsCtrl, _calculateEmi),
      ],
    );
  }

  Widget _buildSipTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResultCard(
          title: "ESTIMATED MATURITY WEALTH",
          value: "$currency${_sipMaturity.toStringAsFixed(0)}",
          rows: [
            _buildResultRow("Total Invested Amount", "$currency${_sipInvested.toStringAsFixed(0)}"),
            _buildResultRow("Estimated Wealth Gain", "+$currency${_sipReturns.toStringAsFixed(0)}", color: Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalcInput("Monthly Investment ($currency)", _sipMonthlyCtrl, _calculateSip),
        const SizedBox(height: 12),
        _buildCalcInput("Expected Annual Return (%)", _sipReturnCtrl, _calculateSip),
        const SizedBox(height: 12),
        _buildCalcInput("Time Horizon (Years)", _sipYearsCtrl, _calculateSip),
      ],
    );
  }

  Widget _buildEmergencyTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResultCard(
          title: "RECOMMENDED EMERGENCY FUND",
          value: "$currency${_emgTarget.toStringAsFixed(0)}",
          rows: [
            _buildResultRow("Monthly Living Expenses", "$currency${_emgExpenseCtrl.text}"),
            _buildResultRow("Runway Coverage", "${_emgMonthsCtrl.text} Months of Stability", color: Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalcInput("Monthly Essential Expenses ($currency)", _emgExpenseCtrl, _calculateEmergency),
        const SizedBox(height: 12),
        _buildCalcInput("Months of Runway Needed (3-12)", _emgMonthsCtrl, _calculateEmergency),
      ],
    );
  }

  Widget _buildTaxTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResultCard(
          title: "ESTIMATED TAX LIABILITY",
          value: "$currency${_estimatedTax.toStringAsFixed(0)}",
          rows: [
            _buildResultRow("Gross Annual Income", "$currency${_taxIncomeCtrl.text}"),
            _buildResultRow("Tax Regime", "New Simplified Slab Structure", color: Colors.indigoAccent),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalcInput("Gross Annual Income ($currency)", _taxIncomeCtrl, _calculateTax),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCalcInput(String label, TextEditingController controller, VoidCallback onChanged) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
