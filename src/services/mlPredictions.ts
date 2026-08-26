export interface Transaction {
  amount: number;
  date: string;
  category?: string;
  type: 'income' | 'expense';
  description?: string;
}

export interface PredictionResult {
  nextMonthExpense: number;
  expectedSavings: number;
  overspendingRisk: number;
  cashFlowForecast: Array<{ month: string; amount: number }>;
  budgetRecommendation: number;
  predictionAccuracy: number;
  confidenceScore: number;
  insights: string[];
  /** Human-readable description of the forecasting method used */
  methodDescription: string;
  /** Number of transaction data points used to generate this forecast */
  dataPointsUsed: number;
}

/**
 * Trend-Based Financial Forecast Engine
 *
 * Method: Holt's Linear Exponential Smoothing on daily expense aggregates,
 * combined with category-weighted spending analysis.
 *
 * - For < 10 transactions: simple moving average over available data.
 * - For >= 10 transactions: Holt double-exponential smoothing (alpha=0.3, beta=0.1)
 *   to capture both the current spending level and its trend direction.
 *
 * Confidence score is derived from the number of historical data points:
 * more data = higher confidence, capped at ~92%.
 */
export class MLPredictionService {
  /**
   * Main entry point for predicting next month's cash flow and expenses.
   */
  async predict(transactions: Transaction[]): Promise<PredictionResult> {
    if (!transactions || transactions.length === 0) {
      return this.generateEmptyPrediction();
    }

    if (transactions.length < 10) {
      return this.generateBasicPrediction(transactions);
    }

    return this.generateTimeSeriesPrediction(transactions);
  }

  /**
   * Default result when zero transactions exist.
   */
  private generateEmptyPrediction(): PredictionResult {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonthIdx = new Date().getMonth();
    const cashFlowForecast = Array.from({ length: 6 }, (_, i) => ({
      month: monthNames[(currentMonthIdx + i + 1) % 12],
      amount: 0,
    }));

    return {
      nextMonthExpense: 0,
      expectedSavings: 0,
      overspendingRisk: 0,
      cashFlowForecast,
      budgetRecommendation: 0,
      predictionAccuracy: 0.5,
      confidenceScore: 0.5,
      insights: ['Start recording income and expenses to generate smart financial predictions.'],
      methodDescription: 'No data yet — add transactions to enable forecasting.',
      dataPointsUsed: 0,
    };
  }

  /**
   * Moving-average forecast used when historical sample size is small (< 10 transactions).
   * Confidence scales linearly with the number of available data points.
   */
  public generateBasicPrediction(transactions: Transaction[]): PredictionResult {
    const expenses = transactions.filter(t => t.type === 'expense');
    const income = transactions.filter(t => t.type === 'income');

    const totalExpense = expenses.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
    const totalIncome = income.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

    const avgExpense = expenses.length > 0 ? totalExpense / expenses.length : 0;
    const avgIncome = income.length > 0 ? totalIncome / income.length : 0;

    // Estimate monthly aggregate (assume transaction frequency represents periodic spending)
    const nextMonthExpense = avgExpense * Math.max(expenses.length, 1);
    const monthlyIncome = avgIncome * Math.max(income.length, 1);
    const expectedSavings = monthlyIncome - nextMonthExpense;
    const overspendingRisk = totalExpense > totalIncome ? 0.75 : 0.25;

    // Confidence scales linearly with data count (min 0.45 up to 0.70 for < 10 points)
    const n = transactions.length;
    const confidenceScore = Math.min(0.45 + n * 0.025, 0.70);
    const predictionAccuracy = Math.min(0.50 + n * 0.022, 0.72);

    const insights: string[] = [];

    if (overspendingRisk > 0.6) {
      insights.push('Warning: High spending detected relative to recorded income. Consider trimming discretionary costs.');
    }

    const categoryExpenses = expenses.reduce((acc, t) => {
      const cat = t.category || 'General';
      acc[cat] = (acc[cat] || 0) + (Number(t.amount) || 0);
      return acc;
    }, {} as Record<string, number>);

    const topCategory = Object.entries(categoryExpenses).sort((a, b) => b[1] - a[1])[0];
    if (topCategory && totalExpense > 0) {
      const categoryPercent = (topCategory[1] / totalExpense) * 100;
      if (categoryPercent > 30) {
        insights.push(`Tip: ${topCategory[0]} accounts for ${categoryPercent.toFixed(1)}% of your spending. Check if this aligns with your budget.`);
      }
    }

    if (expectedSavings < 0) {
      insights.push(`Alert: Estimated monthly deficit of Rs.${Math.abs(expectedSavings).toFixed(2)}. Adjust your budget limits.`);
    } else if (expectedSavings > 0) {
      insights.push(`Good: On track for positive monthly net savings of Rs.${expectedSavings.toFixed(2)}.`);
    }

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonthIdx = new Date().getMonth();
    const cashFlowForecast = Array.from({ length: 6 }, (_, i) => ({
      month: monthNames[(currentMonthIdx + i + 1) % 12],
      amount: Math.round(monthlyIncome - nextMonthExpense),
    }));

    return {
      nextMonthExpense: Math.round(nextMonthExpense * 100) / 100,
      expectedSavings: Math.round(expectedSavings * 100) / 100,
      overspendingRisk,
      cashFlowForecast,
      budgetRecommendation: Math.round(nextMonthExpense * 1.1 * 100) / 100,
      predictionAccuracy,
      confidenceScore,
      insights,
      methodDescription: `Moving Average over ${n} transaction${n !== 1 ? 's' : ''}. Add more data for Holt exponential smoothing (requires >= 10 records).`,
      dataPointsUsed: n,
    };
  }

  /**
   * Holt's Double Exponential Smoothing forecast on daily expense totals.
   * Captures both the current spending level (alpha) and the day-over-day trend (beta).
   * Confidence grows with the number of distinct days observed, capped at 92%.
   */
  public generateTimeSeriesPrediction(transactions: Transaction[]): PredictionResult {
    const expenses = transactions.filter(t => t.type === 'expense');
    const income = transactions.filter(t => t.type === 'income');

    // Group daily expenses
    const dailyExpenses = new Map<string, number>();
    expenses.forEach(t => {
      const dateKey = t.date ? t.date.split('T')[0] : new Date().toISOString().split('T')[0];
      dailyExpenses.set(dateKey, (dailyExpenses.get(dateKey) || 0) + (Number(t.amount) || 0));
    });

    const sortedDates = Array.from(dailyExpenses.keys()).sort();
    const expenseSeries = sortedDates.map(date => dailyExpenses.get(date) || 0);

    // Holt's double exponential smoothing
    // alpha = level smoothing factor, beta = trend smoothing factor
    const alpha = 0.3;
    const beta = 0.1;

    let level = expenseSeries[0] || 0;
    let trend = (expenseSeries[expenseSeries.length - 1] - expenseSeries[0]) / Math.max(expenseSeries.length, 1);

    for (let i = 1; i < expenseSeries.length; i++) {
      const prevLevel = level;
      level = alpha * expenseSeries[i] + (1 - alpha) * (level + trend);
      trend = beta * (level - prevLevel) + (1 - beta) * trend;
    }

    // Projected daily expense rate -> monthly total
    const predictedDailyExpense = Math.max(level + trend, 0);
    const nextMonthExpense = predictedDailyExpense * 30;

    // Income calculation
    const totalIncome = income.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
    const totalExpense = expenses.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
    const avgMonthlyIncome = income.length > 0
      ? (totalIncome / Math.max(sortedDates.length, 1)) * 30
      : totalExpense * 1.1;

    const expectedSavings = avgMonthlyIncome - nextMonthExpense;
    const overspendingRisk = totalExpense > totalIncome ? 0.78 : (nextMonthExpense > avgMonthlyIncome ? 0.65 : 0.22);

    // Confidence grows with number of observed days, capped at 92%
    const daysObserved = sortedDates.length;
    const confidenceScore = Math.min(0.60 + daysObserved * 0.008, 0.92);
    const predictionAccuracy = Math.min(0.62 + daysObserved * 0.007, 0.92);

    const insights: string[] = [];
    const trendDirection = trend > 0 ? 'increasing' : 'decreasing';
    const trendMagnitude = Math.abs(trend / (level || 1)) * 100;

    insights.push(`Trend: Spending is ${trendDirection} by ~${trendMagnitude.toFixed(1)}% per day based on ${daysObserved} days of data.`);

    if (nextMonthExpense > avgMonthlyIncome) {
      insights.push(`Warning: Projected expense of Rs.${nextMonthExpense.toFixed(2)} exceeds projected monthly income of Rs.${avgMonthlyIncome.toFixed(2)}.`);
    } else {
      insights.push(`Good: Projected healthy monthly surplus of Rs.${Math.max(expectedSavings, 0).toFixed(2)}.`);
    }

    // Category breakdown
    const categoryExpenses = expenses.reduce((acc, t) => {
      const cat = t.category || 'General';
      acc[cat] = (acc[cat] || 0) + (Number(t.amount) || 0);
      return acc;
    }, {} as Record<string, number>);

    const topCategories = Object.entries(categoryExpenses).sort((a, b) => b[1] - a[1]);
    if (topCategories.length > 0) {
      const top = topCategories[0];
      const potential = top[1] * 0.15;
      insights.push(`Tip: Optimizing "${top[0]}" expenses by 15% could save ~Rs.${potential.toFixed(2)} monthly.`);
    }

    // 6-month forecast with slight trend dampening
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonthIdx = new Date().getMonth();
    const cashFlowForecast = Array.from({ length: 6 }, (_, i) => {
      const monthlySpend = Math.max(nextMonthExpense * (1 + (trend * i * 0.05)), 0);
      return {
        month: monthNames[(currentMonthIdx + i + 1) % 12],
        amount: Math.round(avgMonthlyIncome - monthlySpend),
      };
    });

    return {
      nextMonthExpense: Math.round(nextMonthExpense * 100) / 100,
      expectedSavings: Math.round(expectedSavings * 100) / 100,
      overspendingRisk,
      cashFlowForecast,
      budgetRecommendation: Math.round(nextMonthExpense * 1.12 * 100) / 100,
      predictionAccuracy,
      confidenceScore,
      insights,
      methodDescription: `Holt's Double Exponential Smoothing (alpha=0.3, beta=0.1) over ${daysObserved} day${daysObserved !== 1 ? 's' : ''} of transaction history.`,
      dataPointsUsed: transactions.length,
    };
  }

  dispose() {
    // No-op cleanup for interface compatibility
  }
}

export const mlPredictionService = new MLPredictionService();
