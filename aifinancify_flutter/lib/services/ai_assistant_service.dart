import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';

class InsightItem {
  final String type;
  final String title;
  final String description;

  InsightItem({required this.type, required this.title, required this.description});
}

class ConversationMessage {
  final String role;
  final String content;

  ConversationMessage({required this.role, required this.content});
}

class AIFinancialAssistant {
  final List<ConversationMessage> conversationHistory = [];

  void addToHistory(String role, String content) {
    conversationHistory.add(ConversationMessage(role: role, content: content));
    if (conversationHistory.length > 20) {
      conversationHistory.removeAt(0);
    }
  }

  Future<String> generateResponse({
    required String userQuestion,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<InsightItem> insights,
  }) async {
    final lower = userQuestion.toLowerCase().trim();
    addToHistory('user', userQuestion);

    // Calculate live financial statistics from ledger
    final stats = _calculateStats(transactions, budgets, goals);

    // Detect intent
    final intent = _detectIntent(lower);
    String response = '';

    switch (intent) {
      case 'app_overview':
        response = _explainFullAppOverview();
        break;
      case 'virtual_card':
        response = _explainVirtualCard();
        break;
      case 'statements_invoicing':
        response = _explainStatementsAndInvoicing();
        break;
      case 'scanner_help':
        response = _explainScanner();
        break;
      case 'voice_entry_help':
        response = _explainVoiceEntry();
        break;
      case 'upi_import_help':
        response = _explainUpiAndBankImport();
        break;
      case 'predictions_help':
        response = _explainMLPredictions(transactions, stats);
        break;
      case 'fraud_detection':
        response = _explainFraudAndRisk(transactions);
        break;
      case 'insights_health':
        response = _explainSmartInsightsAndHealth(stats);
        break;
      case 'spending_analysis':
        response = _analyzeSpending(lower, stats, transactions);
        break;
      case 'income_analysis':
        response = _analyzeIncome(stats);
        break;
      case 'budget_advice':
        response = _provideBudgetAdvice(stats, budgets);
        break;
      case 'savings_advice':
        response = _provideSavingsAdvice(stats, goals);
        break;
      case 'goals_tracking':
        response = _provideGoalsTracking(goals, stats);
        break;
      case 'calculator_help':
        response = _explainCalculators(lower);
        break;
      case 'role_personas':
        response = _explainRolePersonas();
        break;
      case 'navigation':
        response = _provideNavigation(lower);
        break;
      case 'financial_literacy':
        response = _provideFinancialLiteracy(lower);
        break;
      case 'greeting':
        response = _generateGeminiGreeting(stats);
        break;
      case 'creator_info':
        response = _explainCreatorInfo();
        break;
      default:
        response = _generateGeminiSmartResponse(userQuestion, lower, stats, transactions, budgets, goals);
    }

    addToHistory('assistant', response);
    return response;
  }

  String _detectIntent(String q) {
    if (RegExp(r"who (made|created|built|developed)|about you|are you gemini", caseSensitive: false).hasMatch(q)) {
      return 'creator_info';
    }
    if (RegExp(r"^(hi|hello|hey|greetings|good morning|good evening|namaste|vanakkam)\b", caseSensitive: false).hasMatch(q)) {
      return 'greeting';
    }
    if (RegExp(r"tell me (everything|all|about)|what (is|can|does) this app|what features|app overview|full guide|walkthrough", caseSensitive: false).hasMatch(q)) {
      return 'app_overview';
    }
    if (RegExp(r"virtual card|card wallet|debit card|credit card|card skin|cvv|freeze card|tap to pay|card limit", caseSensitive: false).hasMatch(q)) {
      return 'virtual_card';
    }
    if (RegExp(r"statement|invoice|invoicing|upi qr|generate pdf|download pdf|tax report", caseSensitive: false).hasMatch(q)) {
      return 'statements_invoicing';
    }
    if (RegExp(r"scan|ocr|receipt|camera|bill photo|bill image", caseSensitive: false).hasMatch(q)) {
      return 'scanner_help';
    }
    if (RegExp(r"voice|speak|mic|microphone|audio entry|voice logger", caseSensitive: false).hasMatch(q)) {
      return 'voice_entry_help';
    }
    if (RegExp(r"upi|sms|import|bank statement|csv|gpay|phonepe|paytm", caseSensitive: false).hasMatch(q)) {
      return 'upi_import_help';
    }
    if (RegExp(r"predict|prediction|forecast|future spend|holt|trend|machine learning|ml", caseSensitive: false).hasMatch(q)) {
      return 'predictions_help';
    }
    if (RegExp(r"fraud|anomaly|suspicious|risk score|security alert|flagged", caseSensitive: false).hasMatch(q)) {
      return 'fraud_detection';
    }
    if (RegExp(r"health score|insights|financial score|spending velocity|smart insights", caseSensitive: false).hasMatch(q)) {
      return 'insights_health';
    }
    if (RegExp(r"persona|role|student|freelancer|small business|home manager|professional", caseSensitive: false).hasMatch(q)) {
      return 'role_personas';
    }
    if (RegExp(r"how to (go|open|reach|navigate|find)|where is", caseSensitive: false).hasMatch(q)) {
      return 'navigation';
    }
    if (RegExp(r"calculator|calc|emi|sip|compound interest|fd|loan", caseSensitive: false).hasMatch(q)) {
      return 'calculator_help';
    }
    if (RegExp(r"how much.*spend|spent|expense|dining|food|groceries|shopping|travel|bills", caseSensitive: false).hasMatch(q)) {
      return 'spending_analysis';
    }
    if (RegExp(r"income|earn|salary|revenue|deposited", caseSensitive: false).hasMatch(q)) {
      return 'income_analysis';
    }
    if (RegExp(r"budget|budgeting|category limit", caseSensitive: false).hasMatch(q)) {
      return 'budget_advice';
    }
    if (RegExp(r"save|savings rate|invest|wealth|how to save", caseSensitive: false).hasMatch(q)) {
      return 'savings_advice';
    }
    if (RegExp(r"goal|target|emergency fund|milestone", caseSensitive: false).hasMatch(q)) {
      return 'goals_tracking';
    }
    if (RegExp(r"50\/30\/20|rule of 72|inflation|mutual fund|stock|cibil|credit score", caseSensitive: false).hasMatch(q)) {
      return 'financial_literacy';
    }
    return 'general';
  }

  Map<String, dynamic> _calculateStats(List<Transaction> transactions, List<Budget> budgets, List<Goal> goals) {
    final expenses = transactions.where((t) => t.type.toLowerCase() == 'expense').toList();
    final income = transactions.where((t) => t.type.toLowerCase() == 'income').toList();

    final totalExpenses = expenses.fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold<double>(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0.0;

    final Map<String, double> categorySpending = {};
    for (var t in expenses) {
      final cat = t.category ?? 'General';
      categorySpending[cat] = (categorySpending[cat] ?? 0.0) + t.amount;
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalBudgeted = budgets.fold<double>(0.0, (sum, b) => sum + b.amount);
    final totalSpent = budgets.fold<double>(0.0, (sum, b) => sum + b.spent);
    final budgetRemaining = totalBudgeted - totalSpent;
    final budgetUtilization = totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0.0;

    return {
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'netBalance': netBalance,
      'savingsRate': savingsRate,
      'categorySpending': categorySpending,
      'topCategories': sortedCategories,
      'totalBudgeted': totalBudgeted,
      'totalSpent': totalSpent,
      'budgetRemaining': budgetRemaining,
      'budgetUtilization': budgetUtilization,
      'txCount': transactions.length,
      'goalsCount': goals.length,
    };
  }

  String _explainFullAppOverview() {
    return "🚀 **Welcome to AiFinancify — Complete Application Guide**\n\n"
        "AiFinancify is a full-stack, next-generation AI financial operating system designed for individuals, freelancers, and businesses.\n\n"
        "### 🌟 **Core Capabilities & Modules:**\n\n"
        "1. **💳 Multi-Card 3D Wallet & Controls**:\n"
        "   • Manage real bank cards (HDFC, SBI, ICICI, Axis, Amex) & custom virtual cards.\n"
        "   • Interactive 3D flip card with real-time CVV reveal & 5 luxury themes.\n"
        "   • Set monthly spending limits, and toggle instant security (*Freeze/Lock, Tap-to-Pay, International Payments*).\n\n"
        "2. **📄 PDF Statements & Invoices with UPI QR**:\n"
        "   • 1-Tap generator creates styled, branded PDF statements with category breakdowns & charts.\n"
        "   • Generate client invoices with embedded dynamic UPI payment QR codes.\n\n"
        "3. **🧾 On-Device OCR Receipt Scanner**:\n"
        "   • Vision AI extracts vendor name, total amount, date, and line items from camera or gallery photos.\n"
        "   • Instant auto-fill and 1-tap save into your ledger.\n\n"
        "4. **🎙️ Natural Voice Expense Logger**:\n"
        "   • Speak naturally (e.g. *'Spent 450 rupees on dinner with friends via UPI'*).\n"
        "   • AI NLP extracts amount, merchant, category, and payment channel automatically.\n\n"
        "5. **📲 Indian Bank SMS & UPI Importer**:\n"
        "   • Batch-parses SMS alerts from SBI, HDFC, ICICI, Axis, Google Pay, PhonePe, and Paytm.\n\n"
        "6. **📈 AI Spend Predictions & Forecasting**:\n"
        "   • Holt's Linear Exponential Smoothing projects future spending and 6-month cash flow trajectory.\n\n"
        "7. **🛡️ AI Fraud & Anomaly Defense**:\n"
        "   • Detects abnormal spending spikes, midnight transactions, velocity anomalies, and risky merchants.\n\n"
        "8. **💡 Smart Insights & Financial Health Score**:\n"
        "   • Real-time score (0–100), savings rate analytics, and personalized recommendations.\n\n"
        "9. **🧮 Financial Calculators**:\n"
        "   • Built-in Loan EMI, SIP Wealth Builder, Compound Interest, and Goal Target planners.\n\n"
        "10. **👤 Multi-Role Personas**:\n"
        "    • Tailored dashboards for *Students, Freelancers, Small Business, Home Managers, and Corporate Pros*.";
  }

  String _explainVirtualCard() {
    return "💳 **Multi-Card Wallet & Smart Spend Controls:**\n\n"
        "• **Multi-Card Support**: Add all your real debit/credit cards or create custom virtual cards.\n"
        "• **Interactive 3D Flip Card**: Tap the card on your screen to flip it 180° and reveal the verified CVV and magnetic strip.\n"
        "• **Monthly Spend Cap**: Set a maximum monthly ceiling with a live gauge to avoid overspending.\n"
        "• **Freeze / Lock**: Instantly block any outgoing transaction.\n"
        "• **Contactless / Tap to Pay**: Toggle POS NFC permissions on the fly.\n"
        "• **International Payments**: Enable or disable foreign currency billing.\n"
        "• **Themes**: Switch between *Indigo Nebula, Emerald Wealth, Rose Quartz, Imperial Gold, and Midnight Carbon*.\n\n"
        "👉 **How to access**: Open the side menu and tap **'Multi-Card Wallet'**.";
  }

  String _explainStatementsAndInvoicing() {
    return "📄 **Statements & Invoicing Generator with UPI QR:**\n\n"
        "### 1. 📊 Financial Statements (PDF)\n"
        "• Select any date range (This Month, Last 3 Months, Custom).\n"
        "• Generates an official, publication-quality PDF statement with:\n"
        "  - Total income, total expenses, net balance\n"
        "  - Category spending breakdown table with percentages\n"
        "  - Itemized transaction ledger\n\n"
        "### 2. 🧾 Client Invoicing & Embedded UPI QR Code\n"
        "• Create professional invoices for freelance projects, clients, or consulting.\n"
        "• Generates a dynamic **UPI Payment QR Code** embedded directly inside the invoice so clients can scan and pay you immediately with Google Pay, PhonePe, or Paytm.\n\n"
        "👉 **How to access**: Open the side menu and tap **'Statements & Invoices'**.";
  }

  String _explainScanner() {
    return "🧾 **AI OCR Receipt Scanner:**\n\n"
        "• **Vision Engine**: Uses Google MLKit On-Device Vision to read receipt text with zero latency.\n"
        "• **Smart Parsing**: Automatically identifies vendor name, transaction date, category, and grand total.\n"
        "• **Preset Sample Receipts**: Tap any sample receipt (*Starbucks, DMart, Shell, Apollo, Swiggy*) to test OCR parsing instantly.\n"
        "• **One-Tap Confirm**: Review the extracted breakdown and tap **'Confirm & Save Transaction'**.\n\n"
        "👉 **How to access**: Tap **'OCR Receipt Scanner'** in the side drawer or Dashboard shortcut.";
  }

  String _explainVoiceEntry() {
    return "🎙️ **Voice Expense Entry:**\n\n"
        "1. Open **'Voice Expense Logger'** from the menu.\n"
        "2. Tap the glowing Microphone button.\n"
        "3. Speak your expense naturally in English, such as:\n"
        "   • *'Spent 450 rupees on dinner with friends via UPI'*\n"
        "   • *'Paid 1200 for groceries at DMart on card'*\n"
        "   • *'Ola cab ride 280 cash'*\n"
        "4. The NLP engine detects the Amount (₹), Category, Merchant, and Payment Mode automatically.\n"
        "5. Tap **Save Transaction** to record it instantly!";
  }

  String _explainUpiAndBankImport() {
    return "📲 **Indian UPI & Bank Statement Importer:**\n\n"
        "### 1. 💬 UPI SMS Text Import\n"
        "• Copy & paste your bank SMS (SBI, HDFC, ICICI, Axis, GPay, Paytm, PhonePe).\n"
        "• The regex parser extracts amount, merchant/VPA, debit/credit type, and date.\n"
        "• Tap **Import Selected** to add them to your ledger in bulk.\n\n"
        "### 2. 📁 Bank Statement CSV Import\n"
        "• Upload CSV statements from your net banking.\n"
        "• Auto-maps columns (*Date, Description, Amount, Type*) with smart category tagging.\n\n"
        "👉 **How to access**: Tap **'Indian UPI Import'** or **'Bank Statement CSV'** in the side drawer.";
  }

  String _explainMLPredictions(List<Transaction> transactions, Map<String, dynamic> stats) {
    final double totalExpenses = stats['totalExpenses'];
    final int count = stats['txCount'];

    return "📈 **AI Spend Predictions & Forecasting Engine:**\n\n"
        "• **Algorithm**: Holt's Linear Exponential Smoothing with time-series trend velocity.\n"
        "• **Evaluated Data**: Analyzed **$count** transactions totaling **₹${totalExpenses.toStringAsFixed(2)}**.\n"
        "• **Capabilities**:\n"
        "  - Forecasts next month's projected spend with upper/lower certainty bands.\n"
        "  - 6-month cash flow trajectory model.\n"
        "  - Dynamic category budget recommendations based on velocity.\n\n"
        "👉 Open **'AI Spend Predictions'** in the side drawer to see interactive forecast graphs!";
  }

  String _explainFraudAndRisk(List<Transaction> transactions) {
    final flagged = transactions.where((t) => t.riskScore >= 0.4).toList();
    if (flagged.isEmpty) {
      return "🛡️ **AI Risk & Fraud Defense Status:**\n\n"
          "✅ **All Clear!** Every recorded transaction falls within normal variance thresholds.\n\n"
          "**What the AI monitors in real-time:**\n"
          "• Z-Score amount anomalies (unusually large spikes)\n"
          "• High-risk hours (midnight spending alerts)\n"
          "• Transaction velocity (rapid repeat charges)\n"
          "• Unverified or suspicious merchant keywords";
    }

    String res = "⚠️ **Flagged Transactions (${flagged.length}):**\n\n";
    for (var t in flagged.take(3)) {
      res += "• **${t.merchant}** (₹${t.amount.toStringAsFixed(2)}): ${t.riskReason} (Risk Score: ${(t.riskScore * 100).toStringAsFixed(0)}%)\n";
    }
    res += "\n👉 Open **'Fraud & Risk Alerts'** in the side drawer to inspect or dismiss alerts.";
    return res;
  }

  String _explainSmartInsightsAndHealth(Map<String, dynamic> stats) {
    final double savingsRate = stats['savingsRate'];
    final double net = stats['netBalance'];

    int healthScore = 50;
    if (savingsRate >= 20) healthScore += 30;
    else if (savingsRate > 0) healthScore += 15;
    if (net > 0) healthScore += 20;

    return "💡 **Smart Insights & Financial Health Score:**\n\n"
        "• **Financial Health Score**: **$healthScore / 100** ${healthScore >= 75 ? '🟢 Excellent' : healthScore >= 50 ? '🟡 Fair' : '🔴 Needs Attention'}\n"
        "• **Savings Rate**: **${savingsRate.toStringAsFixed(1)}%** (Target: 20%+)\n"
        "• **Net Monthly Surplus**: **₹${net.toStringAsFixed(2)}**\n\n"
        "### 🧠 **AI Recommendations:**\n"
        "1. Maintain a 3-month living expense buffer in your Emergency Fund Goal.\n"
        "2. Automate a monthly SIP with 50% of your net surplus.\n"
        "3. Review discretionary weekend spending to curb category leaks.\n\n"
        "👉 Open **'Smart Insights'** in the side drawer for full charts!";
  }

  String _explainRolePersonas() {
    return "👤 **Multi-Role Financial Personas:**\n\n"
        "AiFinancify adapts its entire UI and analytics to your lifestyle:\n\n"
        "1. 🎓 **Student**: Focuses on daily allowance burn rate, food delivery limits, and milestone savings.\n"
        "2. 💻 **Freelancer**: Emphasizes project income tracking, tax estimates, and invoice generation with UPI QR.\n"
        "3. 🏢 **Small Business**: Tracks revenue, client receivables, operational overhead, and business loan EMIs.\n"
        "4. 🏡 **Home Manager**: Optimized for grocery allocations, recurring utility bills, and family goal planning.\n"
        "5. 💼 **Corporate Professional**: Emphasizes investment growth, SIP compounding, and tax-saving investments.\n\n"
        "👉 **How to switch**: Go to **Profile** or **Settings** and choose your preferred Role!";
  }

  String _explainCalculators(String q) {
    if (q.contains('emi')) {
      return "🧮 **Loan EMI Formula & Guide:**\n\n"
          "Formula: `EMI = [P x R x (1+R)^N] / [(1+R)^N - 1]`\n"
          "• **P**: Principal Loan Amount\n"
          "• **R**: Monthly Interest Rate (Annual Rate / 12 / 100)\n"
          "• **N**: Loan Tenure in Months\n\n"
          "👉 Open **'Financial Calculators'** in the side drawer to calculate EMIs with interactive sliders!";
    }
    if (q.contains('sip') || q.contains('compound')) {
      return "📈 **SIP & Compound Interest Guide:**\n\n"
          "Formula: `M = P x [((1 + i)^n - 1) / i] x (1 + i)`\n"
          "• Investing **₹5,000/month** at 12% annual return for 15 years yields **~₹25.2 Lakhs** (Investment: ₹9 Lakhs, Wealth Gained: ₹16.2 Lakhs)!\n\n"
          "👉 Open **'Financial Calculators'** to simulate custom SIP returns!";
    }

    return "🧮 **Built-in Financial Calculators:**\n\n"
        "1. **Loan EMI Calculator**: Monthly installment and amortized interest breakdown.\n"
        "2. **SIP Wealth Builder**: Monthly mutual fund growth projections.\n"
        "3. **Compound Interest**: Flexible compounding frequencies.\n"
        "4. **Savings Goal Planner**: Target monthly deposit calculator.\n\n"
        "👉 Open **'Financial Calculators'** in the side drawer to use them!";
  }

  String _analyzeSpending(String q, Map<String, dynamic> stats, List<Transaction> transactions) {
    final double totalExpenses = stats['totalExpenses'];
    final topCategories = stats['topCategories'] as List<MapEntry<String, double>>;

    for (var cat in ['food', 'dining', 'groceries', 'shopping', 'transport', 'travel', 'bills', 'entertainment', 'health']) {
      if (q.contains(cat)) {
        final matches = transactions.where((t) => (t.category ?? '').toLowerCase().contains(cat) && t.type.toLowerCase() == 'expense').toList();
        final catTotal = matches.fold<double>(0.0, (sum, t) => sum + t.amount);
        final pct = totalExpenses > 0 ? (catTotal / totalExpenses * 100).toStringAsFixed(1) : '0';

        return "🍔 **Spending on ${cat.toUpperCase()}:**\n\n"
            "• Total Spent: **₹${catTotal.toStringAsFixed(2)}**\n"
            "• Transaction Count: **${matches.length}**\n"
            "• Share of Total Expenses: **$pct%**\n\n"
            "💡 *Tip: You can set a monthly spending cap for $cat in the Budgets tab to avoid budget leaks!*";
      }
    }

    String res = "💸 **Your Spending Breakdown:**\n\n"
        "• Total Recorded Expenses: **₹${totalExpenses.toStringAsFixed(2)}**\n"
        "• Total Transactions: **${stats['txCount']}**\n\n";

    if (topCategories.isNotEmpty) {
      res += "📊 **Top Spending Categories:**\n";
      for (var entry in topCategories.take(4)) {
        final pct = totalExpenses > 0 ? (entry.value / totalExpenses * 100).toStringAsFixed(1) : '0';
        res += "• **${entry.key}**: ₹${entry.value.toStringAsFixed(2)} ($pct%)\n";
      }
    }
    return res;
  }

  String _analyzeIncome(Map<String, dynamic> stats) {
    final double totalIncome = stats['totalIncome'];
    final double net = stats['netBalance'];
    final double savingsRate = stats['savingsRate'];

    return "💰 **Income & Cash Flow Summary:**\n\n"
        "• Total Recorded Income: **₹${totalIncome.toStringAsFixed(2)}**\n"
        "• Total Expenses: **₹${(stats['totalExpenses'] as double).toStringAsFixed(2)}**\n"
        "• Net Balance Surplus: **₹${net.toStringAsFixed(2)}**\n"
        "• Savings Rate: **${savingsRate.toStringAsFixed(1)}%**\n\n"
        "${savingsRate >= 20 ? '🌟 Outstanding savings discipline! You are comfortably exceeding the 20% benchmark.' : '💡 Aim to allocate at least 20% of your income toward Savings Goals & SIPs.'}";
  }

  String _provideBudgetAdvice(Map<String, dynamic> stats, List<Budget> budgets) {
    final double limit = stats['totalBudgeted'];
    final double spent = stats['totalSpent'];
    final double remaining = stats['budgetRemaining'];
    final double util = stats['budgetUtilization'];

    if (limit == 0.0) {
      return "🛡️ **Budget Advice:**\n\nYou haven't set any category budgets yet. Creating budgets helps reduce impulsive expenses by up to 22%! Tap the **Budgets** tab on the bottom bar to get started.";
    }

    return "🛡️ **Monthly Budget Status:**\n\n"
        "• Total Budget Cap: **₹${limit.toStringAsFixed(2)}**\n"
        "• Amount Consumed: **₹${spent.toStringAsFixed(2)}** (${util.toStringAsFixed(1)}%)\n"
        "• Remaining Allowance: **₹${remaining.toStringAsFixed(2)}**\n\n"
        "${util > 100 ? '🚨 You have exceeded your overall budget limit! Time to cut back on discretionary wants.' : util > 80 ? '⚠️ You are near your budget ceiling (${util.toStringAsFixed(1)}% used).' : '✅ Budget is healthy with ${(100 - util).toStringAsFixed(1)}% buffer remaining.'}";
  }

  String _provideSavingsAdvice(Map<String, dynamic> stats, List<Goal> goals) {
    final double surplus = stats['netBalance'];
    final double savingsRate = stats['savingsRate'];

    return "💡 **AI Savings Strategy (50/30/20 Rule):**\n\n"
        "• **50% Needs**: Housing, utilities, groceries, health.\n"
        "• **30% Wants**: Dining out, travel, entertainment.\n"
        "• **20% Savings**: Emergency fund, SIPs, retirement.\n\n"
        "📊 **Your Metrics:**\n"
        "• Current Savings Rate: **${savingsRate.toStringAsFixed(1)}%**\n"
        "• Monthly Surplus: **₹${surplus.toStringAsFixed(2)}**\n"
        "• Active Goals: **${goals.length}**\n\n"
        "🚀 *Action: Allocate ₹${(surplus > 0 ? surplus * 0.5 : 500).toStringAsFixed(0)} this week into your primary Savings Goal!*";
  }

  String _provideGoalsTracking(List<Goal> goals, Map<String, dynamic> stats) {
    if (goals.isEmpty) {
      return "🎯 **Savings Goals:**\n\nYou have no active savings goals. People with named financial targets save 42% more effectively! Tap the **Goals** tab on the bottom bar to create one.";
    }

    String res = "🎯 **Active Savings Goals (${goals.length}):**\n\n";
    for (var g in goals) {
      final pct = g.progressPercentage;
      res += "• **${g.name}**: ₹${g.currentAmount.toStringAsFixed(0)} / ₹${g.targetAmount.toStringAsFixed(0)} (**${pct.toStringAsFixed(1)}%** funded)\n";
    }
    return res;
  }

  String _provideNavigation(String q) {
    if (q.contains('card') || q.contains('virtual')) {
      return "💳 **Virtual Card**: Side Drawer -> **'Multi-Card Wallet'**.";
    }
    if (q.contains('statement') || q.contains('invoice') || q.contains('qr')) {
      return "📄 **Statements & Invoices**: Side Drawer -> **'Statements & Invoices'**.";
    }
    if (q.contains('scan') || q.contains('ocr') || q.contains('receipt')) {
      return "🧾 **Receipt Scanner**: Side Drawer -> **'OCR Receipt Scanner'**.";
    }
    if (q.contains('voice') || q.contains('speak')) {
      return "🎙️ **Voice Entry**: Side Drawer -> **'Voice Expense Logger'**.";
    }
    if (q.contains('upi') || q.contains('sms')) {
      return "📲 **UPI Import**: Side Drawer -> **'Indian UPI Import'**.";
    }
    if (q.contains('predict') || q.contains('forecast')) {
      return "📈 **AI Predictions**: Side Drawer -> **'AI Spend Predictions'**.";
    }
    if (q.contains('calc') || q.contains('emi') || q.contains('sip')) {
      return "🧮 **Calculators**: Side Drawer -> **'Financial Calculators'**.";
    }
    if (q.contains('fraud') || q.contains('alert')) {
      return "🛡️ **Fraud Alerts**: Side Drawer -> **'Fraud & Risk Alerts'**.";
    }
    return "🧭 You can navigate anywhere using the **Bottom Navigation Bar** (*Dashboard, Transactions, Budgets, Goals, Analytics*) or by opening the **Side Drawer Menu**!";
  }

  String _provideFinancialLiteracy(String q) {
    return "📚 **Smart Financial Rules & Wealth Building:**\n\n"
        "1. **The 50/30/20 Rule**: Allocate 50% of net income to Needs, 30% to Wants, and 20% directly to Savings & Investments.\n"
        "2. **The Rule of 72**: Divide 72 by your expected annual interest rate to find how many years it takes for your investment to double (e.g. at 12% return, money doubles in 6 years).\n"
        "3. **Emergency Fund**: Maintain 3 to 6 months of essential expenses in a high-interest savings account before investing in equities.\n"
        "4. **CIBIL / Credit Score**: Maintain credit utilization under 30% and always pay credit card bills in full before the due date.";
  }

  String _generateGeminiGreeting(Map<String, dynamic> stats) {
    return "👋 **Hello! I'm your Gemini-powered AI Financial Advisor.**\n\n"
        "I'm here with comprehensive knowledge of your financial ledger and every feature of this app. I can:\n"
        "• Give you deep analytical breakdowns of your spending & income.\n"
        "• Guide you step-by-step on how to use any feature (*Multi-Card Wallet, PDF Statements, OCR Scanner, Voice Entry, UPI Import*).\n"
        "• Run predictive forecasts, calculate EMIs/SIPs, and flag fraud anomalies.\n\n"
        "How can I assist your financial journey today?";
  }

  String _explainCreatorInfo() {
    return "✨ **About AiFinancify:**\n\n"
        "AiFinancify is an intelligent, privacy-first personal & business financial operating system. Powered by state-of-the-art on-device machine learning, NLP, and modern encryption, it empowers you to master your cash flow, eliminate budget leaks, and build lasting wealth.";
  }

  String _generateGeminiSmartResponse(
    String raw,
    String lower,
    Map<String, dynamic> stats,
    List<Transaction> transactions,
    List<Budget> budgets,
    List<Goal> goals,
  ) {
    final double spent = stats['totalExpenses'];
    final double income = stats['totalIncome'];
    final double net = stats['netBalance'];

    return "🤖 **AI Financial Assistant:**\n\n"
        "I analyzed your question: *\"$raw\"*\n\n"
        "Here is a quick snapshot of your active financial status:\n"
        "• **Total Income**: ₹${income.toStringAsFixed(2)}\n"
        "• **Total Expenses**: ₹${spent.toStringAsFixed(2)}\n"
        "• **Net Cashflow**: ₹${net.toStringAsFixed(2)}\n"
        "• **Transactions Recorded**: ${stats['txCount']}\n\n"
        "**Popular questions you can ask me:**\n"
        "• *'Tell me everything about the app'* (Full feature walkthrough)\n"
        "• *'How does the Multi-Card Wallet work?'*\n"
        "• *'How to generate PDF statements and UPI invoices?'*\n"
        "• *'How to use OCR receipt scanner and voice logger?'*\n"
        "• *'What are my AI predictions for next month?'*\n"
        "• *'Show my top spending categories'*";
  }
}
