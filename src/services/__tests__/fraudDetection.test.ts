import { describe, it, expect } from 'vitest';
import { calculateFraudScore } from '../fraudDetection';

describe('Fraud Detection & Anomaly Scoring Engine', () => {
  it('should return low risk score for a normal transaction matching baseline', () => {
    const historicalTxs = [
      { amount: 500, category: 'groceries', date: '2026-08-10T12:00:00Z' },
      { amount: 550, category: 'groceries', date: '2026-08-11T12:00:00Z' },
      { amount: 480, category: 'groceries', date: '2026-08-12T12:00:00Z' },
      { amount: 520, category: 'groceries', date: '2026-08-13T12:00:00Z' },
    ];

    const currentTx = {
      amount: 510,
      category: 'groceries',
      date: '2026-08-14T14:30:00Z',
      merchant: 'Local Supermarket',
    };

    const result = calculateFraudScore(currentTx, historicalTxs);
    expect(result.riskScore).toBeLessThan(0.4);
    expect(result.riskLevel).toBe('low');
    expect(result.isFlagged).toBe(false);
  });

  it('should flag high risk for an extreme amount anomaly (>3 std dev)', () => {
    const historicalTxs = [
      { amount: 200, category: 'food', date: '2026-08-10T12:00:00Z' },
      { amount: 250, category: 'food', date: '2026-08-11T12:00:00Z' },
      { amount: 220, category: 'food', date: '2026-08-12T12:00:00Z' },
      { amount: 190, category: 'food', date: '2026-08-13T12:00:00Z' },
    ];

    const anomalyTx = {
      amount: 15000,
      category: 'food',
      date: '2026-08-14T15:00:00Z',
      merchant: 'Food Court',
    };

    const result = calculateFraudScore(anomalyTx, historicalTxs);
    expect(result.riskScore).toBeGreaterThanOrEqual(0.5);
    expect(result.factors.amountAnomaly).toBe(true);
    expect(result.isFlagged).toBe(true);
  });

  it('should add risk penalty for abnormal night-time transactions (e.g. 2:00 AM)', () => {
    const nightTx = {
      amount: 4500,
      category: 'shopping',
      date: '2026-08-14T02:15:00Z', // 2 AM UTC / night
      merchant: 'Online Electronics',
    };

    const result = calculateFraudScore(nightTx, []);
    expect(result.factors.timingAnomaly).toBe(true);
    expect(result.riskScore).toBeGreaterThan(0);
  });

  it('should flag velocity anomalies when 3+ transactions occur within 1 hour', () => {
    const historicalTxs = [
      { amount: 1000, category: 'shopping', date: '2026-08-14T14:05:00Z' },
      { amount: 1200, category: 'shopping', date: '2026-08-14T14:15:00Z' },
      { amount: 1100, category: 'shopping', date: '2026-08-14T14:30:00Z' },
    ];

    const rapidTx = {
      amount: 1500,
      category: 'shopping',
      date: '2026-08-14T14:40:00Z',
      merchant: 'Retail Store',
    };

    const result = calculateFraudScore(rapidTx, historicalTxs);
    expect(result.factors.velocityAnomaly).toBe(true);
    expect(result.riskScore).toBeGreaterThanOrEqual(0.3);
  });

  it('should detect suspicious merchant keywords (e.g. international wire transfer)', () => {
    const suspiciousTx = {
      amount: 8000,
      category: 'transfer',
      date: '2026-08-14T16:00:00Z',
      merchant: 'International Wire Transfer Exchange',
    };

    const result = calculateFraudScore(suspiciousTx, []);
    expect(result.factors.suspiciousMerchant).toBe(true);
    expect(result.riskScore).toBeGreaterThanOrEqual(0.25);
  });

  it('should safely handle invalid or missing transaction parameters', () => {
    const invalidTx = { amount: NaN } as any;
    const result = calculateFraudScore(invalidTx, []);
    expect(result.riskScore).toBe(0);
    expect(result.isFlagged).toBe(false);
  });
});
