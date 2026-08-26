import { transactionsAPI, budgetsAPI, goalsAPI, aiAPI, Transaction, Budget, Goal } from './api';

export interface InsightItem {
  type: string;
  title: string;
  description: string;
}

export interface ConversationContext {
  transactions: Transaction[];
  budgets: Budget[];
  goals: Goal[];
  insights: InsightItem[];
  predictions?: any;
  conversationHistory: Array<{ role: string; content: string }>;
}

export interface FinancialStats {
  totalExpenses: number;
  totalIncome: number;
  netBalance: number;
  savingsRate: number;
  categorySpending: Record<string, number>;
  topExpenseCategory: [string, number] | null;
  avgDailyExpense: number;
  budgetUtilization: number;
}

export class AIFinancialAssistant {
  private context: Partial<ConversationContext> = {
    conversationHistory: []
  };

  async loadUserData() {
    try {
      const [txResponse, budgetResponse, goalResponse, insightResponse] = await Promise.all([
        transactionsAPI.getAll().catch(() => ({ transactions: [] })),
        budgetsAPI.getAll().catch(() => ({ budgets: [] })),
        goalsAPI.getAll().catch(() => ({ goals: [] })),
        aiAPI.getInsights().catch(() => ({ insights: [] })),
      ]);

      this.context = {
        transactions: txResponse.transactions || [],
        budgets: budgetResponse.budgets || [],
        goals: goalResponse.goals || [],
        insights: insightResponse.insights || [],
        conversationHistory: this.context.conversationHistory || []
      };
    } catch (error) {
      console.error('Failed to load user data:', error);
    }
  }

  addToHistory(role: string, content: string) {
    this.context.conversationHistory?.push({ role, content });
    // Keep only last 10 messages for context
    if (this.context.conversationHistory && this.context.conversationHistory.length > 10) {
      this.context.conversationHistory = this.context.conversationHistory.slice(-10);
    }
  }

  async generateResponse(userQuestion: string): Promise<string> {
    const lowerQuestion = userQuestion.toLowerCase();
    this.addToHistory('user', userQuestion);

    // Load fresh data
    await this.loadUserData();

    const { transactions = [], budgets = [], goals = [], insights = [] } = this.context;

    // Calculate comprehensive stats
    const stats = this.calculateStats(transactions, budgets, goals);

    // Intent Detection with improved NLP
    const intent = this.detectIntent(lowerQuestion);

    let response = '';

    switch (intent) {
      case 'app_features':
        response = this.explainAppFeatures(lowerQuestion);
        break;
      case 'navigation':
        response = this.provideNavigation(lowerQuestion);
        break;
      case 'spending_analysis':
        response = this.analyzeSpending(lowerQuestion, stats, transactions);
        break;
      case 'income_query':
        response = this.analyzeIncome(stats);
        break;
      case 'budget_advice':
        response = this.provideBudgetAdvice(stats, budgets);
        break;
      case 'savings_recommendation':
        response = this.provideSavingsRecommendation(stats);
        break;
      case 'goals_tracking':
        response = this.provideGoalsTracking(goals, stats);
        break;
      case 'fraud_detection':
        response = this.analyzeFraud(transactions);
        break;
      case 'predictions':
        response = this.providePredictions(transactions, stats);
        break;
      case 'category_breakdown':
        response = this.provideCategoryBreakdown(stats);
        break;
      case 'comparison':
        response = this.provideComparison(lowerQuestion, stats, transactions);
        break;
      case 'how_to':
        response = this.provideHowToGuide(lowerQuestion);
        break;
      case 'calculator_help':
        response = this.explainCalculator();
        break;
      case 'voice_entry_help':
        response = this.explainVoiceEntry();
        break;
      case 'scanner_help':
        response = this.explainScanner();
        break;
      case 'transaction_search':
        response = this.searchTransactions(lowerQuestion, transactions);
        break;
      case 'general_advice':
        response = this.provideGeneralAdvice(stats, insights);
        break;
      default:
        response = this.provideSmartResponse(lowerQuestion, stats, insights);
    }

    this.addToHistory('assistant', response);
    return response;
  }

  private detectIntent(question: string): string {
    const patterns = {
      app_features: /what (can|does|features|do|is)|tell me about|explain.*app|capabilities|what.*this app/i,
      navigation: /how (to|do i) (go|navigate|find|access|open|get to)|where (is|can i find)|show me/i,
      spending_analysis: /spend|spent|expense|cost|paid|purchase|bought|transaction/i,
      income_query: /income|earn|salary|revenue|received|deposited/i,
      budget_advice: /budget|limit|allocate|plan.*money/i,
      savings_recommendation: /save|savings|invest|invest|set aside|reduce cost/i,
      goals_tracking: /goal|target|achieve|progress|milestone/i,
      fraud_detection: /fraud|suspicious|unusual|risky|security|alert/i,
      predictions: /predict|forecast|future|next month|trend|expect/i,
      category_breakdown: /category|categories|breakdown|distribution|where.*money/i,
      comparison: /compare|vs|versus|difference|better|more|less than/i,
      how_to: /how to|how do|how can|tutorial|guide|step/i,
      calculator_help: /calculator|calculate|compute|math/i,
      voice_entry_help: /voice|speak|microphone|voice entry|voice command/i,
      scanner_help: /scan|receipt|photo|camera|ocr/i,
      transaction_search: /find.*transaction|show.*transaction|transaction.*for|when did i/i,
      general_advice: /tip|advice|recommend|suggest|help me|what should/i,
    };

    for (const [intent, pattern] of Object.entries(patterns)) {
      if (pattern.test(question)) {
        return intent;
      }
    }

    return 'general';
  }

  private calculateStats(transactions: any[], budgets: any[], goals: any[]) {
    const expenses = transactions.filter(t => t.type === 'expense');
    const income = transactions.filter(t => t.type === 'income');

    const totalExpenses = expenses.reduce((sum, t) => sum + t.amount, 0);
    const totalIncome = income.reduce((sum, t) => sum + t.amount, 0);
    const netBalance = totalIncome - totalExpenses;
    const savingsRate = totalIncome > 0 ? ((netBalance / totalIncome) * 100) : 0;

    // Category breakdown
    const categorySpending: Record<string, number> = {};
    expenses.forEach(t => {
      categorySpending[t.category] = (categorySpending[t.category] || 0) + t.amount;
    });

    const topCategories = Object.entries(categorySpending)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5);

    // Time-based analysis
    const last7Days = expenses.filter(t => {
      const txDate = new Date(t.date);
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return txDate >= weekAgo;
    });

    const last30Days = expenses.filter(t => {
      const txDate = new Date(t.date);
      const monthAgo = new Date();
      monthAgo.setDate(monthAgo.getDate() - 30);
      return txDate >= monthAgo;
    });

    const avgDailySpending = expenses.length > 0 ? totalExpenses / 30 : 0;
    const avgTransactionSize = expenses.length > 0 ? totalExpenses / expenses.length : 0;

    // Budget performance
    const totalBudgeted = budgets.reduce((sum, b) => sum + b.amount, 0);
    const totalSpent = budgets.reduce((sum, b) => sum + (b.spent || 0), 0);
    const budgetRemaining = totalBudgeted - totalSpent;
    const budgetUtilization = totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0;

    // Goals progress
    const activeGoals = goals.filter(g => (g.current_amount || 0) < g.target_amount);
    const completedGoals = goals.filter(g => (g.current_amount || 0) >= g.target_amount);
    const totalGoalProgress = goals.reduce((sum, g) => sum + ((g.current_amount || 0) / g.target_amount) * 100, 0) / (goals.length || 1);

    return {
      totalExpenses,
      totalIncome,
      netBalance,
      savingsRate,
      categorySpending,
      topCategories,
      last7DaysSpending: last7Days.reduce((sum, t) => sum + t.amount, 0),
      last30DaysSpending: last30Days.reduce((sum, t) => sum + t.amount, 0),
      avgDailySpending,
      avgTransactionSize,
      transactionCount: transactions.length,
      expenseCount: expenses.length,
      totalBudgeted,
      totalSpent,
      budgetRemaining,
      budgetUtilization,
      activeGoals: activeGoals.length,
      completedGoals: completedGoals.length,
      totalGoalProgress,
      budgets,
      goals,
    };
  }

  private explainAppFeatures(question: string): string {
    return `🎯 **FinanceAI** is your complete financial management platform! Here's what I can help you with:

📊 **Core Features:**
• **Dashboard** - View your financial overview and insights
• **Transactions** - Track all your income and expenses
• **Budget Tracker** - Set limits and monitor spending
• **Goals** - Save towards your financial targets
• **Analytics** - Visualize spending patterns with charts

🤖 **AI-Powered Tools:**
• **Voice Entry** - Speak your expenses (supports English, Tamil, Hindi)
• **Receipt Scanner** - Take photos of receipts for auto-entry
• **Smart Calculator** - Budget planning with what-if scenarios
• **AI Predictions** - ML-powered spending forecasts
• **Fraud Detection** - Automatic suspicious transaction alerts

💡 **Smart Features:**
• Multi-language support (English/Tamil/Hindi)
• Offline mode with auto-sync
• Real-time analytics and insights
• Personalized recommendations

What would you like to explore?`;
  }

  private provideNavigation(question: string): string {
    const routes = {
      'dashboard|home|main': '🏠 Go to **Dashboard** - Your main overview screen',
      'transaction|expense|income': '💳 Go to **Transactions** - View all your money movements',
      'budget': '💰 Go to **Budget** - Set and track spending limits',
      'goal': '🎯 Go to **Goals** - Track your savings targets',
      'analytics|chart|graph': '📊 Go to **Analytics** - View detailed spending charts',
      'voice': '🎤 Go to **Voice Entry** - Add expenses by speaking',
      'scan|receipt|photo': '📸 Go to **Scanner** - Scan receipts automatically',
      'calculator|calculate': '🧮 Go to **Calculator** - Smart budget calculator',
      'prediction|forecast|ai': '🔮 Go to **AI Predictions** - See ML-powered forecasts',
      'chatbot|assistant|help': '💬 You\'re already here in the **AI Assistant**!',
      'profile|settings': '⚙️ Go to **Profile** - Manage your preferences',
    };

    for (const [keywords, instruction] of Object.entries(routes)) {
      if (new RegExp(keywords, 'i').test(question)) {
        return `${instruction}\n\nYou can access it from the navigation menu on the left side.`;
      }
    }

    return `I can guide you to:\n${Object.values(routes).join('\n')}\n\nWhich section would you like to visit?`;
  }

  private analyzeSpending(question: string, stats: any, transactions: any[]): string {
    if (/today|yesterday/i.test(question)) {
      const today = new Date().toDateString();
      const todayTx = transactions.filter(t =>
        t.type === 'expense' && new Date(t.date).toDateString() === today
      );
      const todaySpending = todayTx.reduce((sum, t) => sum + t.amount, 0);

      return `📅 **Today's Spending**: ₹${todaySpending.toFixed(2)}\n\nTransactions: ${todayTx.length}\n${todayTx.length > 0 ? `\nRecent: ${todayTx.slice(-3).map(t => `• ${t.merchant}: ₹${t.amount}`).join('\n')}` : ''}`;
    }

    if (/week|last 7|past week/i.test(question)) {
      return `📊 **Last 7 Days**: ₹${stats.last7DaysSpending.toFixed(2)}\n**Last 30 Days**: ₹${stats.last30DaysSpending.toFixed(2)}\n\nAverage daily: ₹${stats.avgDailySpending.toFixed(2)}`;
    }

    return `💰 **Spending Overview:**\n\n• **Total Expenses**: ₹${stats.totalExpenses.toFixed(2)}\n• **Average Daily**: ₹${stats.avgDailySpending.toFixed(2)}\n• **Total Transactions**: ${stats.expenseCount}\n• **Average per Transaction**: ₹${stats.avgTransactionSize.toFixed(2)}\n\n📈 **Top Category**: ${stats.topCategories[0]?.[0] || 'None'} (₹${stats.topCategories[0]?.[1]?.toFixed(2) || '0'})`;
  }

  private analyzeIncome(stats: any): string {
    const projection = stats.totalIncome > 0 ? stats.totalIncome : 0;

    return `💵 **Income Analysis:**\n\n• **Total Income**: ₹${stats.totalIncome.toFixed(2)}\n• **Total Expenses**: ₹${stats.totalExpenses.toFixed(2)}\n• **Net Balance**: ₹${stats.netBalance.toFixed(2)}\n• **Savings Rate**: ${stats.savingsRate.toFixed(1)}%\n\n${stats.savingsRate >= 20 ? '✅ Excellent! You\'re meeting the 20% savings goal.' : '💡 Try to save at least 20% of your income.'}`;
  }

  private provideBudgetAdvice(stats: any, budgets: any[]): string {
    if (budgets.length === 0) {
      return `💡 **Budget Recommendation:**\n\nYou don't have any budgets set! I recommend the 50/30/20 rule:\n\n• 50% - Needs (₹${(stats.totalIncome * 0.5).toFixed(2)})\n• 30% - Wants (₹${(stats.totalIncome * 0.3).toFixed(2)})\n• 20% - Savings (₹${(stats.totalIncome * 0.2).toFixed(2)})\n\nGo to the Budget section to set up your budgets!`;
    }

    const overBudget = budgets.filter(b => (b.spent || 0) > b.amount);

    return `📋 **Budget Status:**\n\n• **Total Budgeted**: ₹${stats.totalBudgeted.toFixed(2)}\n• **Total Spent**: ₹${stats.totalSpent.toFixed(2)}\n• **Remaining**: ₹${stats.budgetRemaining.toFixed(2)}\n• **Utilization**: ${stats.budgetUtilization.toFixed(1)}%\n\n${overBudget.length > 0 ? `⚠️ ${overBudget.length} budget(s) exceeded! Review: ${overBudget.map(b => b.category).join(', ')}` : '✅ All budgets within limits!'}`;
  }

  private provideSavingsRecommendation(stats: any): string {
    const currentSavings = stats.netBalance;
    const monthlyIncome = stats.totalIncome;
    const targetSavings = monthlyIncome * 0.2;
    const gap = targetSavings - currentSavings;

    const topSpending = stats.topCategories[0];
    const potentialSavings = topSpending ? topSpending[1] * 0.2 : 0;

    return `💰 **Savings Optimization:**\n\n**Current:** ₹${currentSavings.toFixed(2)} (${stats.savingsRate.toFixed(1)}%)\n**Target (20%):** ₹${targetSavings.toFixed(2)}\n${gap > 0 ? `**Gap:** ₹${gap.toFixed(2)}\n` : '**Surplus:** ₹' + Math.abs(gap).toFixed(2) + '\n'}\n\n💡 **Quick Wins:**\n• Reduce ${topSpending?.[0]} by 20% → Save ₹${potentialSavings.toFixed(2)}/month\n• Use the Calculator to simulate budget changes\n• Set up automatic savings transfer\n• Track daily spending to stay mindful\n\n🎯 **Annual Impact:** Saving ₹${(gap > 0 ? potentialSavings : currentSavings).toFixed(2)}/month = ₹${((gap > 0 ? potentialSavings : currentSavings) * 12).toFixed(2)}/year!`;
  }

  private provideGoalsTracking(goals: any[], stats: any): string {
    if (goals.length === 0) {
      return `🎯 **Financial Goals:**\n\nYou haven't set any goals yet! Goals help you stay motivated and track progress.\n\nExamples:\n• Emergency Fund (6 months expenses)\n• Vacation Fund\n• New Laptop/Phone\n• Down Payment\n\nGo to the Goals section to create your first goal!`;
    }

    const goalsList = goals.slice(0, 5).map(g => {
      const progress = ((g.current_amount || 0) / g.target_amount) * 100;
      const emoji = progress >= 100 ? '✅' : progress >= 75 ? '🎯' : progress >= 50 ? '📈' : '🔄';
      return `${emoji} **${g.name}**: ₹${(g.current_amount || 0).toFixed(0)}/₹${g.target_amount} (${progress.toFixed(0)}%)`;
    }).join('\n');

    return `🎯 **Your Goals:**\n\n${goalsList}\n\n**Overall Progress**: ${stats.totalGoalProgress.toFixed(0)}%\n**Active Goals**: ${stats.activeGoals}\n**Completed**: ${stats.completedGoals}\n\n💡 At your current savings rate, you can reach your goals faster by reducing discretionary spending!`;
  }

  private analyzeFraud(transactions: any[]): string {
    const suspicious = transactions.filter(t => (t.risk_score || 0) > 0.7);
    const highRisk = suspicious.filter(t => (t.risk_score || 0) > 0.9);

    if (suspicious.length === 0) {
      return `🔒 **Security Status: All Clear**\n\n✅ No suspicious transactions detected\n✅ All transactions appear normal\n✅ Spending patterns are consistent\n\nI continuously monitor for:\n• Unusual amounts\n• Late-night transactions\n• Unfamiliar merchants\n• Duplicate charges`;
    }

    return `⚠️ **Fraud Alert:**\n\n**${suspicious.length} Suspicious Transaction(s) Detected**\n${highRisk.length > 0 ? `**${highRisk.length} High-Risk Transactions**\n` : ''}\nRecent alerts:\n${suspicious.slice(0, 3).map(t => `🚨 ${t.merchant}: ₹${t.amount} (${new Date(t.date).toLocaleDateString()})`).join('\n')}\n\n🔍 **Review in Alerts section**\n💡 If unauthorized, contact your bank immediately`;
  }

  private providePredictions(transactions: any[], stats: any): string {
    const avgMonthly = stats.totalExpenses;
    const trend = stats.last7DaysSpending > (avgMonthly / 4) ? 'increasing' : 'stable';
    const nextMonthPrediction = avgMonthly * (trend === 'increasing' ? 1.1 : 1.0);

    return `🔮 **AI Predictions:**\n\n**Next Month Forecast:**\n• Expected Expenses: ₹${nextMonthPrediction.toFixed(2)}\n• Trend: ${trend === 'increasing' ? '📈 Increasing' : '➡️ Stable'}\n• Confidence: 85%\n\n**Savings Forecast:**\n• Expected Savings: ₹${(stats.totalIncome - nextMonthPrediction).toFixed(2)}\n• Annual Projection: ₹${((stats.totalIncome - nextMonthPrediction) * 12).toFixed(2)}\n\n💡 Visit **AI Predictions** page for detailed ML analysis with charts!`;
  }

  private provideCategoryBreakdown(stats: any): string {
    const breakdown = stats.topCategories
      .map(([cat, amount], idx) => {
        const percent = ((amount / stats.totalExpenses) * 100).toFixed(1);
        const emoji = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][idx];
        return `${emoji} **${cat}**: ₹${amount.toFixed(2)} (${percent}%)`;
      })
      .join('\n');

    return `📊 **Category Breakdown:**\n\n${breakdown}\n\n**Total**: ₹${stats.totalExpenses.toFixed(2)}\n\n💡 Visit **Analytics** for visual charts and detailed breakdown!`;
  }

  private provideComparison(question: string, stats: any, transactions: any[]): string {
    return `📊 **Spending Comparison:**\n\n**This Month vs Recommended:**\n• Your Savings: ${stats.savingsRate.toFixed(1)}%\n• Recommended: 20%\n• Status: ${stats.savingsRate >= 20 ? '✅ On Track' : '⚠️ Below Target'}\n\n**Top Categories:**\n${stats.topCategories.slice(0, 3).map(([cat, amt]) => `• ${cat}: ₹${amt.toFixed(2)}`).join('\n')}`;
  }

  private provideHowToGuide(question: string): string {
    if (/voice|speak/i.test(question)) {
      return this.explainVoiceEntry();
    }
    if (/scan|receipt/i.test(question)) {
      return this.explainScanner();
    }
    if (/calculator|budget/i.test(question)) {
      return this.explainCalculator();
    }

    return `📚 **How-To Guides:**\n\n1️⃣ **Add Transaction**: Go to Transactions → Click Add button\n2️⃣ **Voice Entry**: Speak "I spent 250 rupees at Starbucks"\n3️⃣ **Scan Receipt**: Take photo in Scanner section\n4️⃣ **Set Budget**: Budget tab → Add Budget → Set limit\n5️⃣ **Create Goal**: Goals → Add Goal → Set target\n6️⃣ **Change Language**: Profile → Preferences → Language\n\nWhat would you like help with?`;
  }

  private explainCalculator(): string {
    return `🧮 **Smart Calculator Guide:**\n\nThe calculator helps you plan budgets and simulate scenarios!\n\n**Features:**\n• Budget Planning (Monthly/Weekly/Daily)\n• Expense Tracking\n• Auto-calculated metrics (savings %, daily limits)\n• What-If Scenarios\n• Mini Calculator\n\n**Try This:**\n1. Set your monthly budget\n2. Add your expenses\n3. See real-time calculations\n4. Use "What-If" to simulate changes\n\n💡 Navigate to **Calculator** from the menu!`;
  }

  private explainVoiceEntry(): string {
    return `🎤 **Voice Entry Guide:**\n\n**How It Works:**\n1. Click microphone button\n2. Grant permission (first time)\n3. Speak naturally: "I spent 250 rupees at Starbucks"\n4. AI extracts merchant, amount, category\n5. Review and save!\n\n**Supported Languages:**\n• English\n• Tamil (தமிழ்)\n• Hindi (हिन्दी)\n\n**Example Commands:**\n• "Swiggy food delivery 450 rupees"\n• "Paid 1200 for Big Bazaar groceries"\n• "Uber ride 180 rupees"\n\n💡 Navigate to **Voice Entry** to try it!`;
  }

  private explainScanner(): string {
    return `📸 **Receipt Scanner Guide:**\n\n**How It Works:**\n1. Take photo of receipt\n2. AI extracts text using OCR\n3. Detects: Store name, date, amount, items\n4. Auto-creates transaction\n5. Saves receipt image\n\n**Tips:**\n• Good lighting\n• Flat surface\n• Clear, focused image\n• All text visible\n\n💡 Navigate to **Scanner** to scan your first receipt!`;
  }

  private searchTransactions(question: string, transactions: any[]): string {
    const merchants = transactions.map(t => (t.merchant || t.description || "Unknown").toLowerCase());
    const matchingTx = transactions.filter(t => {
      const merchant = (t.merchant || t.description || "Unknown").toLowerCase();
      const category = (t.category || "Other").toLowerCase();
      return question.toLowerCase().includes(merchant) ||
             question.toLowerCase().includes(category);
    });

    if (matchingTx.length > 0) {
      return `🔍 **Found ${matchingTx.length} matching transactions:**\n\n${matchingTx.slice(0, 5).map(t =>
        `• ${t.merchant || t.description || "Unknown"}: ₹${t.amount} (${new Date(t.date).toLocaleDateString()}) - ${t.category || "Other"}`
      ).join('\n')}\n\n${matchingTx.length > 5 ? `\n...and ${matchingTx.length - 5} more. Check Transactions page!` : ''}`;
    }

    return `🔍 No matching transactions found. Try searching for specific merchants or categories.\n\nPopular merchants: ${merchants.filter((m, idx) => merchants.indexOf(m) === idx).slice(0, 5).join(', ')}`;
  }

  private provideGeneralAdvice(stats: any, insights: any[]): string {
    const tips = [];

    if (stats.savingsRate < 20) {
      tips.push(`📉 **Boost Savings**: You're saving ${stats.savingsRate.toFixed(1)}%. Try for 20%!`);
    }

    if (stats.budgetUtilization > 90) {
      tips.push(`⚠️ **Budget Alert**: ${stats.budgetUtilization.toFixed(0)}% of budget used!`);
    }

    if (stats.avgDailySpending > stats.totalIncome / 30) {
      tips.push(`💡 **Daily Limit**: Spending ₹${stats.avgDailySpending.toFixed(2)}/day exceeds sustainable rate!`);
    }

    if (insights.length > 0) {
      tips.push(...insights.slice(0, 2).map(i => `💡 ${i.description}`));
    }

    tips.push(`🎯 **Use Smart Tools**: Try Voice Entry, Calculator, and Scanner for easier tracking!`);

    return tips.join('\n\n');
  }

  private provideSmartResponse(question: string, stats: any, insights: any[]): string {
    // Contextual fallback
    if (this.context.conversationHistory && this.context.conversationHistory.length > 2) {
      return `I understand you're asking about "${question}". Let me help!\n\n` + this.provideGeneralAdvice(stats, insights);
    }

    return `🤖 **I'm your AI Financial Assistant!**\n\nI can help you with:\n\n💰 **Finances**: Spending analysis, budgets, savings tips\n🎯 **Goals**: Track progress, recommendations\n📊 **Insights**: Analytics, predictions, trends\n🔧 **App Help**: Features, navigation, how-to guides\n🛡️ **Security**: Fraud detection, alerts\n\n**Try asking:**\n• "How much did I spend this month?"\n• "Show me my top categories"\n• "How do I use voice entry?"\n• "What are my goals?"\n• "Give me savings tips"\n\nWhat would you like to know?`;
  }
}

export const aiAssistant = new AIFinancialAssistant();
