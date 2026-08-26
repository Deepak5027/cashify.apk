export interface TransactionItem {
  id?: number | string;
  amount: number;
  category?: string;
  date?: string | Date;
  merchant?: string;
  description?: string;
  type?: 'income' | 'expense';
}

export interface FraudAnalysisResult {
  riskScore: number;
  isFlagged: boolean;
  riskLevel: 'low' | 'medium' | 'high';
  reasons: string[];
  factors: {
    amountAnomaly: boolean;
    timingAnomaly: boolean;
    velocityAnomaly: boolean;
    suspiciousMerchant: boolean;
  };
}

/**
 * Multi-factor Heuristic Fraud & Anomaly Scoring Engine
 * Analyzes deviations from category baselines, timing anomalies, high transaction velocity, and suspicious merchant flags.
 */
export function calculateFraudScore(
  transaction: TransactionItem,
  historicalTransactions: TransactionItem[] = []
): FraudAnalysisResult {
  if (!transaction || typeof transaction.amount !== 'number' || isNaN(transaction.amount)) {
    return {
      riskScore: 0,
      isFlagged: false,
      riskLevel: 'low',
      reasons: ['Valid transaction parameters not provided'],
      factors: {
        amountAnomaly: false,
        timingAnomaly: false,
        velocityAnomaly: false,
        suspiciousMerchant: false,
      }
    };
  }

  let score = 0;
  const reasons: string[] = [];
  const factors = {
    amountAnomaly: false,
    timingAnomaly: false,
    velocityAnomaly: false,
    suspiciousMerchant: false,
  };

  const amount = Math.abs(transaction.amount);
  const category = (transaction.category || '').toLowerCase();

  // 1. Baseline Statistical Amount Anomaly (Z-Score)
  const categoryHistory = historicalTransactions.filter(
    t => (t.category || '').toLowerCase() === category && typeof t.amount === 'number'
  );

  if (categoryHistory.length >= 3) {
    const amounts = categoryHistory.map(t => Math.abs(t.amount));
    const mean = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = amounts.reduce((sum, a) => sum + Math.pow(a - mean, 2), 0) / amounts.length;
    const stdDev = Math.sqrt(variance) || 1;

    const zScore = (amount - mean) / stdDev;

    if (zScore > 3.0) {
      score += 0.5;
      factors.amountAnomaly = true;
      reasons.push(`Amount (₹${amount}) is extreme anomaly (>3 std dev) compared to category average (₹${Math.round(mean)})`);
    } else if (zScore > 2.0) {
      score += 0.35;
      factors.amountAnomaly = true;
      reasons.push(`Amount is significantly higher than typical spending in "${transaction.category}"`);
    } else if (zScore > 1.5) {
      score += 0.2;
      factors.amountAnomaly = true;
      reasons.push(`Amount exceeds typical variance for category`);
    }
  } else if (amount >= 25000) {
    score += 0.3;
    factors.amountAnomaly = true;
    reasons.push(`High-value transaction (₹${amount}) without sufficient baseline history`);
  }

  // 2. Timing Anomaly (Suspicious night-time hours 11:00 PM to 4:59 AM in local or UTC)
  const txDate = transaction.date ? new Date(transaction.date) : new Date();
  if (!isNaN(txDate.getTime())) {
    const localHour = txDate.getHours();
    const utcHour = txDate.getUTCHours();
    const isNight = (localHour >= 23 || localHour <= 4) || (utcHour >= 23 || utcHour <= 4);
    if (isNight) {
      score += 0.2;
      factors.timingAnomaly = true;
      reasons.push(`Transaction occurred during unusual night-time hours`);
    }
  }

  // 3. Velocity Anomaly (>= 3 transactions within a 1-hour window)
  if (historicalTransactions.length > 0 && !isNaN(txDate.getTime())) {
    const recentCluster = historicalTransactions.filter(t => {
      if (!t.date) return false;
      const d = new Date(t.date);
      if (isNaN(d.getTime())) return false;
      const diffMs = Math.abs(txDate.getTime() - d.getTime());
      return diffMs <= 60 * 60 * 1000;
    });

    if (recentCluster.length >= 3) {
      score += 0.3;
      factors.velocityAnomaly = true;
      reasons.push(`High transaction frequency: ${recentCluster.length} transactions executed within 1 hour`);
    }
  }

  // 4. Merchant Keyword Heuristics
  const merchant = (transaction.merchant || transaction.description || '').toLowerCase();
  const suspiciousKeywords = ['international', 'foreign', 'unknown exchange', 'wire transfer', 'crypto exchange', 'offshore'];
  if (suspiciousKeywords.some(kw => merchant.includes(kw))) {
    score += 0.25;
    factors.suspiciousMerchant = true;
    reasons.push(`Merchant keyword "${merchant}" matches high-risk heuristics`);
  }

  const normalizedScore = Math.min(Math.round(score * 100) / 100, 1.0);
  const riskLevel: 'low' | 'medium' | 'high' = normalizedScore >= 0.7 ? 'high' : normalizedScore >= 0.4 ? 'medium' : 'low';
  const isFlagged = normalizedScore >= 0.5;

  if (reasons.length === 0) {
    reasons.push('Transaction within normal parameters');
  }

  return {
    riskScore: normalizedScore,
    isFlagged,
    riskLevel,
    reasons,
    factors,
  };
}
