import 'dart:math';
import '../models/transaction.dart';

class FraudAnalysisResult {
  final double riskScore;
  final bool isFlagged;
  final String riskLevel; // 'low' | 'medium' | 'high'
  final List<String> reasons;
  final Map<String, bool> factors;

  FraudAnalysisResult({
    required this.riskScore,
    required this.isFlagged,
    required this.riskLevel,
    required this.reasons,
    required this.factors,
  });
}

class FraudDetectionService {
  static FraudAnalysisResult calculateFraudScore(
    Transaction transaction,
    List<Transaction> historicalTransactions,
  ) {
    double score = 0.0;
    final List<String> reasons = [];
    final Map<String, bool> factors = {
      'amountAnomaly': false,
      'timingAnomaly': false,
      'velocityAnomaly': false,
      'suspiciousMerchant': false,
    };

    final amount = transaction.amount.abs();
    final category = (transaction.category ?? '').toLowerCase();

    // 1. Amount Anomaly (Z-Score)
    final categoryHistory = historicalTransactions.where(
      (t) => (t.category ?? '').toLowerCase() == category
    ).toList();

    if (categoryHistory.length >= 3) {
      final amounts = categoryHistory.map((t) => t.amount.abs()).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.fold<double>(0.0, (sum, a) => sum + pow(a - mean, 2)) / amounts.length;
      final stdDev = sqrt(variance) == 0.0 ? 1.0 : sqrt(variance);

      final zScore = (amount - mean) / stdDev;

      if (zScore > 3.0) {
        score += 0.5;
        factors['amountAnomaly'] = true;
        reasons.add("Amount (Rs.${amount.toStringAsFixed(0)}) is extreme anomaly (>3 std dev) compared to category average (Rs.${mean.toStringAsFixed(0)})");
      } else if (zScore > 2.0) {
        score += 0.35;
        factors['amountAnomaly'] = true;
        reasons.add('Amount is significantly higher than typical spending in "${transaction.category}"');
      } else if (zScore > 1.5) {
        score += 0.2;
        factors['amountAnomaly'] = true;
        reasons.add('Amount exceeds typical variance for category');
      }
    } else if (amount >= 25000) {
      score += 0.3;
      factors['amountAnomaly'] = true;
      reasons.add('High-value transaction (Rs.${amount.toStringAsFixed(0)}) without sufficient baseline history');
    }

    // 2. Timing Anomaly (Suspicious night-time hours 11:00 PM to 4:59 AM)
    try {
      final txDate = transaction.date;
      final localHour = txDate.hour;
      final utcHour = txDate.toUtc().hour;
      final isNight = (localHour >= 23 || localHour <= 4) || (utcHour >= 23 || utcHour <= 4);
      if (isNight) {
        score += 0.2;
        factors['timingAnomaly'] = true;
        reasons.add('Transaction occurred during unusual night-time hours');
      }
    } catch (_) {
      // If date check fails, ignore timing check
    }

    // 3. Velocity Anomaly (>= 3 transactions within a 1-hour window)
    try {
      final txDate = transaction.date;
      final recentCluster = historicalTransactions.where((t) {
        try {
          final d = t.date;
          final diffMs = (txDate.difference(d)).inMilliseconds.abs();
          return diffMs <= 60 * 60 * 1000;
        } catch (_) {
          return false;
        }
      }).toList();

      if (recentCluster.length >= 3) {
        score += 0.3;
        factors['velocityAnomaly'] = true;
        reasons.add('High transaction frequency: ${recentCluster.length} transactions executed within 1 hour');
      }
    } catch (_) {}

    // 4. Merchant Keyword Heuristics
    final merchant = transaction.merchant.toLowerCase();
    final suspiciousKeywords = ['international', 'foreign', 'unknown exchange', 'wire transfer', 'crypto exchange', 'offshore'];
    if (suspiciousKeywords.any((kw) => merchant.contains(kw))) {
      score += 0.25;
      factors['suspiciousMerchant'] = true;
      reasons.add('Merchant keyword matches high-risk security heuristics');
    }

    final normalizedScore = min((score * 100).round() / 100, 1.0);
    final String riskLevel = normalizedScore >= 0.7 ? 'high' : normalizedScore >= 0.4 ? 'medium' : 'low';
    final isFlagged = normalizedScore >= 0.5;

    if (reasons.isEmpty) {
      reasons.add('Transaction within normal parameters');
    }

    return FraudAnalysisResult(
      riskScore: normalizedScore,
      isFlagged: isFlagged,
      riskLevel: riskLevel,
      reasons: reasons,
      factors: factors,
    );
  }
}
