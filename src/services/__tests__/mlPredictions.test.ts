import { describe, it, expect } from 'vitest';
import { MLPredictionService } from '../mlPredictions';

describe('ML & Time-Series Prediction Engine', () => {
  const service = new MLPredictionService();

  it('should generate a safe empty prediction when transactions array is empty', async () => {
    const result = await service.predict([]);
    expect(result.nextMonthExpense).toBe(0);
    expect(result.expectedSavings).toBe(0);
    expect(result.cashFlowForecast.length).toBe(6);
    expect(result.insights.length).toBeGreaterThan(0);
  });

  it('should produce a valid basic statistical prediction for small transaction history (<10)', async () => {
    const sampleTxs = [
      { amount: 1500, type: 'expense' as const, date: '2026-08-01T10:00:00Z', category: 'groceries' },
      { amount: 300, type: 'expense' as const, date: '2026-08-02T10:00:00Z', category: 'food' },
      { amount: 50000, type: 'income' as const, date: '2026-08-01T10:00:00Z', category: 'salary' },
    ];

    const result = service.generateBasicPrediction(sampleTxs);
    expect(result.nextMonthExpense).toBeGreaterThan(0);
    expect(result.expectedSavings).toBeGreaterThan(0);
    expect(result.budgetRecommendation).toBeGreaterThan(result.nextMonthExpense);
    expect(result.confidenceScore).toBeGreaterThan(0.5);
  });

  it('should run time-series trend forecasting for rich historical datasets (>=10)', async () => {
    const richTxs = [];
    for (let i = 1; i <= 30; i++) {
      const day = i < 10 ? `0${i}` : `${i}`;
      richTxs.push({
        amount: 800 + (i * 20), // Upward spending trend
        type: 'expense' as const,
        date: `2026-07-${day}T12:00:00Z`,
        category: i % 2 === 0 ? 'groceries' : 'shopping',
      });
    }
    // Add monthly income
    richTxs.push({
      amount: 60000,
      type: 'income' as const,
      date: '2026-07-01T09:00:00Z',
      category: 'salary',
    });

    const result = await service.predict(richTxs);
    expect(result.nextMonthExpense).toBeGreaterThan(0);
    expect(result.predictionAccuracy).toBeGreaterThan(0.75);
    expect(result.cashFlowForecast.length).toBe(6);
    expect(result.insights.some(msg => msg.toLowerCase().includes('trend'))).toBe(true);
  });

  it('should flag high overspending risk when total expense exceeds income', () => {
    const deficitTxs = [
      { amount: 30000, type: 'expense' as const, date: '2026-08-01T10:00:00Z', category: 'shopping' },
      { amount: 25000, type: 'expense' as const, date: '2026-08-05T10:00:00Z', category: 'electronics' },
      { amount: 20000, type: 'income' as const, date: '2026-08-01T10:00:00Z', category: 'salary' },
    ];

    const result = service.generateBasicPrediction(deficitTxs);
    expect(result.overspendingRisk).toBeGreaterThanOrEqual(0.6);
    expect(result.expectedSavings).toBeLessThan(0);
  });
});
