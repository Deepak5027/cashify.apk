class CashFlowForecastPoint {
  final String month;
  final double amount;

  CashFlowForecastPoint({required this.month, required this.amount});

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
    };
  }
}

class PredictionResult {
  final double nextMonthExpense;
  final double expectedSavings;
  final double overspendingRisk;
  final List<CashFlowForecastPoint> cashFlowForecast;
  final double budgetRecommendation;
  final double predictionAccuracy;
  final double confidenceScore;
  final List<String> insights;
  final String methodDescription;
  final int dataPointsUsed;

  PredictionResult({
    required this.nextMonthExpense,
    required this.expectedSavings,
    required this.overspendingRisk,
    required this.cashFlowForecast,
    required this.budgetRecommendation,
    required this.predictionAccuracy,
    required this.confidenceScore,
    required this.insights,
    required this.methodDescription,
    required this.dataPointsUsed,
  });
}
