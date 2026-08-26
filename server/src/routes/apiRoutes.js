import express from 'express';
import prisma from '../prismaClient.js';
import { verifyJWT } from '../middleware/authMiddleware.js';

const router = express.Router();

// Helper to log user activity
async function logActivity(userId, action, title, details = '', type = 'info') {
  try {
    await prisma.activity.create({
      data: { userId, action, title, details, type }
    });
  } catch (e) {
    console.error('Failed to log activity:', e);
  }
}

// Helper to advance recurring date
function getNextRecurringDate(baseDate, period) {
  const next = new Date(baseDate);
  if (period === 'weekly') {
    next.setDate(next.getDate() + 7);
  } else {
    // default monthly
    next.setMonth(next.getMonth() + 1);
  }
  return next;
}

// ==========================================
// TRANSACTIONS
// ==========================================
router.get('/transactions', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const now = new Date();

    // Check if any active recurring transactions are due for auto-creation
    try {
      const dueRecurring = await prisma.transaction.findMany({
        where: {
          userId,
          isRecurring: true,
          nextRecurringDate: { lte: now }
        }
      });

      for (const recTx of dueRecurring) {
        const nextDate = getNextRecurringDate(recTx.nextRecurringDate || now, recTx.recurringPeriod || 'monthly');
        // Create the spawned occurrence
        await prisma.transaction.create({
          data: {
            userId,
            amount: recTx.amount,
            description: `${recTx.description || 'Recurring'} (Auto-renewed)`,
            category: recTx.category,
            type: recTx.type || 'expense',
            paymentMode: recTx.paymentMode || 'Cash',
            date: recTx.nextRecurringDate || now,
            isRecurring: false,
            riskScore: 0,
            riskReason: 'Scheduled recurring transaction',
          }
        });
        // Advance next recurring date
        await prisma.transaction.update({
          where: { id: recTx.id },
          data: { nextRecurringDate: nextDate }
        });
        // Log activity
        await logActivity(
          userId,
          'recurring_executed',
          `Auto-renewed recurring ${recTx.type === 'income' ? 'income' : 'expense'}: ${recTx.description}`,
          `₹${recTx.amount.toFixed(2)} - next schedule: ${nextDate.toLocaleDateString()}`,
          recTx.type === 'income' ? 'income' : 'expense'
        );
      }
    } catch (recErr) {
      console.error('Error auto-processing recurring transactions:', recErr);
    }

    const transactions = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' }
    });
    res.json({ data: transactions });
  } catch (err) {
    console.error('Error fetching transactions:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch transactions' });
  }
});

router.post('/transactions', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const payload = req.body || {};

    const rawAmount = payload.amount;
    const amount = typeof rawAmount === 'number' ? rawAmount : parseFloat(rawAmount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({
        error: 'invalid_amount',
        message: 'Amount must be a valid positive number'
      });
    }

    const description = (payload.merchant || payload.description || 'Transaction').trim();
    const category = (payload.category || 'other').trim();
    const type = (payload.type || 'expense').toLowerCase() === 'income' ? 'income' : 'expense';
    const paymentMode = payload.paymentMode || payload.payment_mode || 'Cash';
    const isRecurring = Boolean(payload.isRecurring);
    const recurringPeriod = payload.recurringPeriod || (isRecurring ? 'monthly' : null);

    let txDate = new Date();
    if (payload.date) {
      const parsedDate = new Date(payload.date);
      if (!isNaN(parsedDate.getTime())) {
        txDate = parsedDate;
      }
    }

    let nextRecurringDate = null;
    if (isRecurring) {
      nextRecurringDate = getNextRecurringDate(txDate, recurringPeriod);
    }

    // Fetch recent transactions to use as baseline for fraud scoring
    const recentTxs = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 50,
    });

    // Compute fraud risk score using rule-based signals
    const fraudResult = calculateFraudScore(
      { amount, category, date: txDate, merchant: description },
      recentTxs
    );

    const tx = await prisma.transaction.create({
      data: {
        userId,
        amount,
        description,
        category,
        type,
        paymentMode,
        isRecurring,
        recurringPeriod,
        nextRecurringDate,
        date: txDate,
        riskScore: fraudResult.riskScore,
        riskReason: fraudResult.reasons.join(' | '),
      }
    });

    await logActivity(
      userId,
      'transaction_added',
      `Recorded ${type === 'income' ? 'income' : 'expense'}: ${description}`,
      `${type === 'income' ? '+' : '-'}₹${amount.toFixed(2)} (${category})${isRecurring ? ` • Repeats ${recurringPeriod}` : ''}`,
      type
    );

    res.status(201).json(tx);
  } catch (err) {
    console.error('Error creating transaction:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create transaction' });
  }
});

router.put('/transactions/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid transaction ID' });
    }

    const existing = await prisma.transaction.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Transaction not found' });
    }

    const payload = req.body || {};
    const updateData = {};

    if (payload.amount !== undefined) {
      const amount = typeof payload.amount === 'number' ? payload.amount : parseFloat(payload.amount);
      if (isNaN(amount) || amount <= 0) {
        return res.status(400).json({ error: 'invalid_amount', message: 'Amount must be a valid positive number' });
      }
      updateData.amount = amount;
    }

    if (payload.merchant !== undefined || payload.description !== undefined) {
      updateData.description = (payload.merchant || payload.description || '').trim();
    }

    if (payload.category !== undefined) {
      updateData.category = (payload.category || 'other').trim();
    }

    if (payload.date !== undefined) {
      const parsedDate = new Date(payload.date);
      if (isNaN(parsedDate.getTime())) {
        return res.status(400).json({ error: 'invalid_date', message: 'Invalid date format' });
      }
      updateData.date = parsedDate;
    }

    const updated = await prisma.transaction.update({
      where: { id },
      data: updateData
    });

    res.json(updated);
  } catch (err) {
    console.error('Error updating transaction:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update transaction' });
  }
});

router.delete('/transactions/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid transaction ID' });
    }

    const existing = await prisma.transaction.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Transaction not found' });
    }

    await prisma.transaction.delete({ where: { id } });
    res.json({ success: true, message: 'Transaction deleted' });
  } catch (err) {
    console.error('Error deleting transaction:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to delete transaction' });
  }
});

// ==========================================
// BUDGETS
// ==========================================
router.get('/budgets', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const budgets = await prisma.budget.findMany({ where: { userId } });
    res.json({ data: budgets });
  } catch (err) {
    console.error('Error fetching budgets:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch budgets' });
  }
});

router.post('/budgets', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const payload = req.body || {};

    const name = (payload.name || payload.category || '').trim();
    if (!name) {
      return res.status(400).json({ error: 'missing_name', message: 'Budget category name is required' });
    }

    const rawLimit = payload.limit !== undefined ? payload.limit : payload.amount;
    const limit = typeof rawLimit === 'number' ? rawLimit : parseFloat(rawLimit);
    if (isNaN(limit) || limit <= 0) {
      return res.status(400).json({ error: 'invalid_limit', message: 'Budget limit must be a positive number' });
    }

    // Check duplicate category for this user
    const existing = await prisma.budget.findFirst({
      where: { userId, name: { equals: name } }
    });
    if (existing) {
      return res.status(409).json({ error: 'duplicate_budget', message: `Budget for '${name}' already exists` });
    }

    const budget = await prisma.budget.create({
      data: {
        userId,
        name,
        limit,
        period: payload.period || 'monthly',
      }
    });

    res.status(201).json(budget);
  } catch (err) {
    console.error('Error creating budget:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create budget' });
  }
});

router.put('/budgets/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid budget ID' });
    }

    const existing = await prisma.budget.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Budget not found' });
    }

    const payload = req.body || {};
    const data = {};

    if (payload.name !== undefined || payload.category !== undefined) {
      const name = (payload.name || payload.category || '').trim();
      if (!name) return res.status(400).json({ error: 'invalid_name', message: 'Name cannot be empty' });
      data.name = name;
    }

    if (payload.limit !== undefined || payload.amount !== undefined) {
      const rawLimit = payload.limit !== undefined ? payload.limit : payload.amount;
      const limit = typeof rawLimit === 'number' ? rawLimit : parseFloat(rawLimit);
      if (isNaN(limit) || limit <= 0) {
        return res.status(400).json({ error: 'invalid_limit', message: 'Budget limit must be a positive number' });
      }
      data.limit = limit;
    }

    if (payload.period !== undefined) {
      data.period = payload.period;
    }

    const updated = await prisma.budget.update({ where: { id }, data });
    res.json(updated);
  } catch (err) {
    console.error('Error updating budget:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update budget' });
  }
});

router.delete('/budgets/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid budget ID' });
    }

    const existing = await prisma.budget.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Budget not found' });
    }

    await prisma.budget.delete({ where: { id } });
    res.json({ success: true, message: 'Budget deleted' });
  } catch (err) {
    console.error('Error deleting budget:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to delete budget' });
  }
});

// ==========================================
// GOALS
// ==========================================
router.get('/goals', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const goals = await prisma.goal.findMany({ where: { userId } });
    res.json({ data: goals });
  } catch (err) {
    console.error('Error fetching goals:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch goals' });
  }
});

router.post('/goals', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const payload = req.body || {};

    const name = (payload.name || payload.title || '').trim();
    if (!name) {
      return res.status(400).json({ error: 'missing_name', message: 'Goal name is required' });
    }

    const rawTarget = payload.target !== undefined ? payload.target : payload.target_amount;
    const target = typeof rawTarget === 'number' ? rawTarget : parseFloat(rawTarget);
    if (isNaN(target) || target <= 0) {
      return res.status(400).json({ error: 'invalid_target', message: 'Target amount must be a positive number' });
    }

    const rawSaved = payload.saved !== undefined ? payload.saved : payload.current_amount;
    const saved = typeof rawSaved === 'number' ? rawSaved : (parseFloat(rawSaved) || 0);

    let dueDate = null;
    const dateInput = payload.dueDate || payload.deadline;
    if (dateInput) {
      const parsed = new Date(dateInput);
      if (!isNaN(parsed.getTime())) {
        dueDate = parsed;
      }
    }

    const goal = await prisma.goal.create({
      data: {
        userId,
        name,
        target,
        saved: Math.max(saved, 0),
        dueDate,
      }
    });

    res.status(201).json(goal);
  } catch (err) {
    console.error('Error creating goal:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create goal' });
  }
});

router.put('/goals/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid goal ID' });
    }

    const existing = await prisma.goal.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Goal not found' });
    }

    const payload = req.body || {};
    const data = {};

    if (payload.name !== undefined) {
      const name = payload.name.trim();
      if (!name) return res.status(400).json({ error: 'invalid_name', message: 'Goal name cannot be empty' });
      data.name = name;
    }

    if (payload.target !== undefined || payload.target_amount !== undefined) {
      const rawTarget = payload.target !== undefined ? payload.target : payload.target_amount;
      const target = typeof rawTarget === 'number' ? rawTarget : parseFloat(rawTarget);
      if (isNaN(target) || target <= 0) {
        return res.status(400).json({ error: 'invalid_target', message: 'Target must be a positive number' });
      }
      data.target = target;
    }

    if (payload.saved !== undefined || payload.current_amount !== undefined) {
      const rawSaved = payload.saved !== undefined ? payload.saved : payload.current_amount;
      const saved = typeof rawSaved === 'number' ? rawSaved : parseFloat(rawSaved);
      if (isNaN(saved) || saved < 0) {
        return res.status(400).json({ error: 'invalid_saved', message: 'Saved amount must be 0 or higher' });
      }
      data.saved = saved;
    }

    if (payload.dueDate !== undefined || payload.deadline !== undefined) {
      const dateInput = payload.dueDate || payload.deadline;
      if (dateInput) {
        const parsed = new Date(dateInput);
        if (!isNaN(parsed.getTime())) {
          data.dueDate = parsed;
        }
      } else {
        data.dueDate = null;
      }
    }

    const updated = await prisma.goal.update({ where: { id }, data });
    res.json(updated);
  } catch (err) {
    console.error('Error updating goal:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update goal' });
  }
});

router.delete('/goals/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'invalid_id', message: 'Invalid goal ID' });
    }

    const existing = await prisma.goal.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) {
      return res.status(404).json({ error: 'not_found', message: 'Goal not found' });
    }

    await prisma.goal.delete({ where: { id } });
    res.json({ success: true, message: 'Goal deleted' });
  } catch (err) {
    console.error('Error deleting goal:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to delete goal' });
  }
});

// ==========================================
// INVESTMENTS & BILLS
// ==========================================
router.get('/investments', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const investments = await prisma.investment.findMany({ where: { userId } });
    res.json({ data: investments });
  } catch (err) {
    console.error('Error fetching investments:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.post('/investments', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const payload = req.body || {};
    const name = (payload.name || '').trim();
    if (!name) return res.status(400).json({ error: 'missing_name', message: 'Investment name is required' });

    const rawAmount = payload.amount !== undefined ? payload.amount : payload.value;
    const amount = typeof rawAmount === 'number' ? rawAmount : parseFloat(rawAmount);
    if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: 'invalid_amount', message: 'Amount must be positive' });

    const inv = await prisma.investment.create({
      data: { userId, name, amount }
    });
    res.status(201).json(inv);
  } catch (err) {
    console.error('Error creating investment:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.delete('/investments/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) return res.status(400).json({ error: 'invalid_id' });
    const existing = await prisma.investment.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) return res.status(404).json({ error: 'not_found' });
    await prisma.investment.delete({ where: { id } });
    res.json({ success: true });
  } catch (err) {
    console.error('Error deleting investment:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.get('/bills', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const bills = await prisma.bill.findMany({ where: { userId }, orderBy: { dueDate: 'asc' } });
    res.json({ data: bills });
  } catch (err) {
    console.error('Error fetching bills:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.post('/bills', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const payload = req.body || {};
    const name = (payload.name || '').trim();
    if (!name) return res.status(400).json({ error: 'missing_name', message: 'Bill name is required' });

    const amount = typeof payload.amount === 'number' ? payload.amount : parseFloat(payload.amount);
    if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: 'invalid_amount', message: 'Amount must be positive' });

    const b = await prisma.bill.create({
      data: {
        userId,
        name,
        amount,
        dueDate: payload.dueDate ? new Date(payload.dueDate) : null,
        paid: !!payload.paid,
      }
    });
    res.status(201).json(b);
  } catch (err) {
    console.error('Error creating bill:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.delete('/bills/:id', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) return res.status(400).json({ error: 'invalid_id' });
    const existing = await prisma.bill.findUnique({ where: { id } });
    if (!existing || existing.userId !== userId) return res.status(404).json({ error: 'not_found' });
    await prisma.bill.delete({ where: { id } });
    res.json({ success: true });
  } catch (err) {
    console.error('Error deleting bill:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

// ==========================================
// RECEIPTS & OCR STORAGE
// ==========================================
router.post('/receipts', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { items, ...receiptData } = req.body || {};

    const rawTotal = receiptData.total !== undefined ? receiptData.total : receiptData.amount;
    const total = typeof rawTotal === 'number' ? rawTotal : (parseFloat(rawTotal) || 0);

    const merchant = (receiptData.merchant || 'Unknown Merchant').trim();
    let date = new Date();
    if (receiptData.date) {
      const parsedDate = new Date(receiptData.date);
      if (!isNaN(parsedDate.getTime())) {
        date = parsedDate;
      }
    }

    const receipt = await prisma.receipt.create({
      data: {
        userId,
        total,
        merchant,
        date,
      }
    });

    if (Array.isArray(items) && items.length > 0) {
      for (const it of items) {
        const itemPrice = typeof it.price === 'number' ? it.price : (parseFloat(it.price || it.amount) || 0);
        await prisma.receiptItem.create({
          data: {
            receiptId: receipt.id,
            name: (it.name || 'Item').trim(),
            price: itemPrice,
            quantity: parseInt(it.quantity || 1, 10) || 1,
          }
        });
      }
    }

    const fullReceipt = await prisma.receipt.findUnique({
      where: { id: receipt.id },
      include: { items: true }
    });

    res.status(201).json(fullReceipt);
  } catch (err) {
    console.error('Error saving receipt:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to save receipt' });
  }
});

router.get('/receipts', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const receipts = await prisma.receipt.findMany({
      where: { userId },
      include: { items: true },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ data: receipts });
  } catch (err) {
    console.error('Error fetching receipts:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

// ==========================================
// AI / ANOMALY DETECTION ENDPOINTS
// ==========================================
/**
 * Rule-based fraud scorer. Returns { riskScore, reasons, isFlagged }.
 * Signals used:
 *   1. Z-score deviation from the user's per-category spending average
 *   2. Unusual time of day (11 PM – 5 AM)
 *   3. High transaction velocity (>= 3 transactions in the same 1-hour window)
 *   4. Suspicious merchant keyword heuristics
 */
export function calculateFraudScore(transaction, historicalTxs = []) {
  if (!transaction || typeof transaction.amount !== 'number') {
    return { riskScore: 0, reasons: ['Normal transaction'], isFlagged: false };
  }

  let score = 0;
  const reasons = [];
  const amount = Math.abs(transaction.amount);
  const category = (transaction.category || '').toLowerCase();

  // Signal 1: Amount anomaly — Z-score against category average
  const sameCategoryTxs = historicalTxs.filter(
    t => (t.category || '').toLowerCase() === category && typeof t.amount === 'number'
  );
  const amounts = sameCategoryTxs.map(t => Math.abs(t.amount));

  if (amounts.length >= 3) {
    const avgAmount = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const stdDev = Math.sqrt(
      amounts.reduce((sum, a) => sum + Math.pow(a - avgAmount, 2), 0) / amounts.length
    ) || 1;
    const zScore = (amount - avgAmount) / stdDev;

    if (zScore > 3.0) {
      score += 0.5;
      reasons.push(`Amount (Rs.${amount}) is extreme outlier — more than 3 std deviations above your ${transaction.category || 'general'} average (Rs.${Math.round(avgAmount)})`);
    } else if (zScore > 2.0) {
      score += 0.35;
      reasons.push(`Amount is significantly above your typical ${transaction.category || 'general'} spending (Z-score: ${zScore.toFixed(1)})`);
    } else if (zScore > 1.5) {
      score += 0.2;
      reasons.push(`Amount slightly above your usual ${transaction.category || 'general'} category range`);
    }
  } else if (amount >= 25000) {
    score += 0.3;
    reasons.push(`High-value transaction (Rs.${amount}) with insufficient history to compare`);
  }

  // Signal 2: Unusual time of day — transactions between 11 PM and 5 AM
  const txDate = transaction.date ? new Date(transaction.date) : new Date();
  if (!isNaN(txDate.getTime())) {
    const localHour = txDate.getHours();
    const utcHour = txDate.getUTCHours();
    const isNight = (localHour >= 23 || localHour <= 4) || (utcHour >= 23 || utcHour <= 4);
    if (isNight) {
      score += 0.2;
      reasons.push(`Transaction occurred at an unusual hour (${txDate.toLocaleTimeString()} — typical fraud window)`);
    }
  }

  // Signal 3: High velocity — 3 or more transactions within the same 1-hour window
  if (historicalTxs.length > 0 && !isNaN(txDate.getTime())) {
    const recentCluster = historicalTxs.filter(t => {
      if (!t.date) return false;
      const d = new Date(t.date);
      if (isNaN(d.getTime())) return false;
      return Math.abs(txDate.getTime() - d.getTime()) <= 60 * 60 * 1000;
    });
    if (recentCluster.length >= 3) {
      score += 0.3;
      reasons.push(`Rapid transaction burst: ${recentCluster.length} transactions within the last hour`);
    }
  }

  // Signal 4: Suspicious merchant keyword heuristics
  const merchantStr = String(transaction.merchant || transaction.description || '').toLowerCase();
  const suspiciousKeywords = ['international', 'foreign', 'unknown exchange', 'wire transfer', 'crypto exchange', 'offshore'];
  const matchedKeyword = suspiciousKeywords.find(kw => merchantStr.includes(kw));
  if (matchedKeyword) {
    score += 0.25;
    reasons.push(`Merchant description matches high-risk keyword: "${matchedKeyword}"`);
  }

  const riskScore = Math.min(Math.round(score * 100) / 100, 1.0);
  const isFlagged = riskScore >= 0.5;

  if (reasons.length === 0) {
    reasons.push('Normal transaction — no anomalies detected');
  }

  return { riskScore, reasons, isFlagged };
}

router.post('/ai/analyzeFraud', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { transaction } = req.body || {};

    if (!transaction || typeof transaction !== 'object') {
      return res.status(400).json({ error: 'invalid_transaction', message: 'Transaction object is required' });
    }

    const txs = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 50
    });

    const result = calculateFraudScore(transaction, txs);
    const status = result.riskScore >= 0.7 ? 'suspicious' : result.riskScore >= 0.4 ? 'warning' : 'normal';

    res.json({
      risk_score: result.riskScore,
      status,
      is_flagged: result.isFlagged,
      reasons: result.reasons,
      factors: {
        amount_anomaly: result.riskScore >= 0.35,
        timing_anomaly: result.riskScore >= 0.2,
      }
    });
  } catch (err) {
    console.error('Error analyzing fraud:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to analyze transaction risk' });
  }
});

router.get('/ai/insights', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const transactions = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 100
    });

    const totalSpent = transactions
      .filter(t => {
        const cat = (t.category || '').toLowerCase();
        return !(cat === 'salary' || cat === 'revenue' || cat === 'income' || cat === 'refund');
      })
      .reduce((s, t) => s + t.amount, 0);

    const insights = [];
    if (totalSpent > 10000) {
      insights.push({
        type: 'warning',
        title: 'High Spending Alert',
        description: `Total expenses reached ₹${totalSpent.toLocaleString()} across recent activity.`
      });
    }

    const avgDaily = transactions.length > 0 ? totalSpent / 30 : 0;
    if (avgDaily > 500) {
      insights.push({
        type: 'savings_opportunity',
        title: 'Daily Spending Optimization',
        description: `Trimming discretionary daily spending by ₹100 could save ₹3,000 monthly.`
      });
    }

    res.json({ insights });
  } catch (err) {
    console.error('Error generating insights:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.get('/ai/analytics', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const transactions = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' }
    });

    if (!transactions || transactions.length === 0) {
      return res.json({
        analytics: {
          categoryTotals: {},
          monthlyData: {},
          totalTransactions: 0,
          total_income: 0,
          total_expense: 0,
          net_savings: 0,
          savings_rate: 0,
          financial_health_score: 75
        }
      });
    }

    const categoryTotals = {};
    const monthlyData = {};

    let totalIncome = 0;
    let totalExpense = 0;

    transactions.forEach(t => {
      const cat = (t.category || '').toLowerCase();
      const isIncome = cat === 'salary' || cat === 'revenue' || cat === 'income' || cat === 'refund';
      const type = isIncome ? 'income' : 'expense';

      if (type === 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        const categoryKey = t.category || 'Other';
        categoryTotals[categoryKey] = (categoryTotals[categoryKey] || 0) + t.amount;
      }

      const month = new Date(t.date).toISOString().slice(0, 7);
      if (!monthlyData[month]) monthlyData[month] = { income: 0, expense: 0 };
      monthlyData[month][type] += t.amount;
    });

    const netSavings = totalIncome - totalExpense;
    const savingsRate = totalIncome > 0 ? Math.round((netSavings / totalIncome) * 100) : 0;
    const financialHealthScore = Math.min(Math.max(50 + savingsRate, 20), 100);

    res.json({
      analytics: {
        categoryTotals,
        monthlyData,
        totalTransactions: transactions.length,
        total_income: totalIncome,
        total_expense: totalExpense,
        net_savings: netSavings,
        savings_rate: savingsRate,
        financial_health_score: financialHealthScore
      }
    });
  } catch (err) {
    console.error('Error generating analytics:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.get('/ai/predict', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const transactions = await prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 120,
    });

    const isIncome = (t) => {
      const cat = (t.category || '').toLowerCase();
      return t.type === 'income' || cat === 'salary' || cat === 'revenue' || cat === 'income' || cat === 'refund';
    };

    const expenses = transactions.filter((t) => !isIncome(t));
    const incomes = transactions.filter(isIncome);
    const totalExpense = expenses.reduce((s, t) => s + t.amount, 0);
    const totalIncome = incomes.reduce((s, t) => s + t.amount, 0);
    const avgMonthlyExpense = expenses.length > 0 ? totalExpense / Math.max(1, Math.ceil(expenses.length / 30)) * 30 : 0;
    const nextMonthExpense = Math.round(avgMonthlyExpense || 0);
    const expectedSavings = Math.round(totalIncome - nextMonthExpense);

    const cashFlowForecast = Array.from({ length: 6 }, (_, i) => ({
      month: new Date(Date.now() + (i + 1) * 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 7),
      expense: Math.round(nextMonthExpense * (1 + i * 0.02)),
      income: Math.round(totalIncome / Math.max(incomes.length, 1)),
    }));

    res.json({
      data: {
        nextMonthExpense,
        expectedSavings,
        budgetRecommendation: Math.round(nextMonthExpense * 1.1),
        overspendingRisk: totalExpense > totalIncome ? 0.7 : 0.2,
        confidenceScore: transactions.length >= 10 ? 0.85 : 0.6,
        cashFlowForecast,
        insights: [
          expectedSavings >= 0
            ? 'Spending trend suggests positive savings next month.'
            : 'Expenses may exceed income — review discretionary spending.',
        ],
      },
    });
  } catch (err) {
    console.error('Error generating predictions:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to generate predictions' });
  }
});

router.post('/seed-demo-data', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const now = new Date();

    const existingCount = await prisma.transaction.count({ where: { userId } });
    if (existingCount > 0) {
      return res.json({ message: 'Demo data already exists', seeded: false, transactions: existingCount });
    }

    const sampleTransactions = [
      { amount: 75000, description: 'Monthly Salary', category: 'salary', type: 'income', date: new Date(now.getFullYear(), now.getMonth(), 1) },
      { amount: 2400, description: 'Whole Foods Market', category: 'groceries', type: 'expense', date: new Date(now.getTime() - 2 * 86400000) },
      { amount: 650, description: 'Starbucks Coffee', category: 'food', type: 'expense', date: new Date(now.getTime() - 3 * 86400000) },
      { amount: 3200, description: 'Amazon Shopping', category: 'shopping', type: 'expense', date: new Date(now.getTime() - 5 * 86400000) },
      { amount: 1800, description: 'Uber Rides', category: 'transport', type: 'expense', date: new Date(now.getTime() - 7 * 86400000) },
    ];

    for (const tx of sampleTransactions) {
      await prisma.transaction.create({
        data: { userId, ...tx, paymentMode: 'UPI', riskScore: 0, riskReason: 'Normal transaction' },
      });
    }

    await prisma.budget.createMany({
      data: [
        { userId, name: 'groceries', limit: 8000, period: 'monthly' },
        { userId, name: 'food', limit: 4000, period: 'monthly' },
        { userId, name: 'shopping', limit: 6000, period: 'monthly' },
      ],
    });

    await prisma.goal.createMany({
      data: [
        { userId, name: 'Emergency Fund', target: 100000, saved: 25000, dueDate: new Date(now.getFullYear(), 11, 31) },
        { userId, name: 'Vacation', target: 50000, saved: 12000, dueDate: new Date(now.getFullYear(), 8, 30) },
      ],
    });

    res.json({ message: 'Demo data seeded successfully', seeded: true, transactions: sampleTransactions.length });
  } catch (err) {
    console.error('Error seeding demo data:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to seed demo data' });
  }
});

// ==========================================
// CSV IMPORT
// ==========================================
router.post('/import-csv', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { csvData, transactions: incomingTxs } = req.body || {};

    // Support pre-parsed transactions array (from CSV, TXT, or PDF)
    if (Array.isArray(incomingTxs) && incomingTxs.length > 0) {
      const imported = [];
      for (const row of incomingTxs) {
        const amount = Math.abs(typeof row.amount === 'number' ? row.amount : parseFloat(row.amount)) || 0;
        if (amount > 0) {
          const tx = await prisma.transaction.create({
            data: {
              userId,
              amount,
              description: (row.description || row.merchant || 'Imported Transaction').trim(),
              category: (row.category || 'other').trim(),
              type: row.type === 'income' ? 'income' : 'expense',
              date: row.date ? new Date(row.date) : new Date(),
            }
          });
          imported.push(tx);
        }
      }
      return res.json({ success: true, imported: imported.length, transactions: imported });
    }

    if (!csvData || typeof csvData !== 'string') {
      return res.status(400).json({ error: 'missing_csv', message: 'Valid CSV, TXT, or PDF statement data is required' });
    }

    const lines = csvData.trim().split(/\r?\n/).filter(line => line.trim().length > 0);
    if (lines.length <= 1) {
      return res.status(400).json({ error: 'empty_csv', message: 'Statement has no data rows' });
    }

    const headers = lines[0].split(',').map(h => h.trim().toLowerCase().replace(/^["']|["']$/g, ''));
    const imported = [];

    for (let i = 1; i < lines.length; i++) {
      const values = lines[i].split(',').map(v => v.trim().replace(/^["']|["']$/g, ''));
      const row = {};
      headers.forEach((header, idx) => {
        row[header] = values[idx] || '';
      });

      const rawAmount = row.amount || row.debit || row.withdrawal || row.cost || '0';
      const amount = Math.abs(parseFloat(rawAmount)) || 0;

      if (amount > 0) {
        const tx = await prisma.transaction.create({
          data: {
            userId,
            amount,
            description: row.merchant || row.description || row.payee || 'Imported Transaction',
            category: row.category || 'other',
            date: row.date ? new Date(row.date) : new Date(),
          }
        });
        imported.push(tx);
      }
    }

    res.json({ success: true, imported: imported.length, transactions: imported });
  } catch (err) {
    console.error('Error importing statement:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to process statement file' });
  }
});

// ==========================================
// KEY-VALUE STORE
// ==========================================
router.post('/kv', verifyJWT, async (req, res) => {
  try {
    const { key, value } = req.body || {};
    if (!key || typeof key !== 'string') {
      return res.status(400).json({ error: 'missing_key', message: 'Key is required' });
    }
    const json = typeof value === 'string' ? value : JSON.stringify(value);
    await prisma.kvStore.upsert({
      where: { key },
      update: { value: json },
      create: { key, value: json }
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Error saving KV:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

router.get('/kv/:key', verifyJWT, async (req, res) => {
  try {
    const entry = await prisma.kvStore.findUnique({ where: { key: req.params.key } });
    if (!entry) return res.status(404).json({ error: 'not_found' });
    let parsed;
    try {
      parsed = JSON.parse(entry.value);
    } catch {
      parsed = entry.value;
    }
    res.json({ data: { key: entry.key, value: parsed } });
  } catch (err) {
    console.error('Error fetching KV:', err);
    res.status(500).json({ error: 'server_error' });
  }
});

// ==========================================
// ADMIN / AGGREGATE ANALYTICS (anonymized)
// ==========================================
router.get('/admin/stats', verifyJWT, async (req, res) => {
  try {
    // Total user count
    const totalUsers = await prisma.user.count();

    // Total transactions across all users
    const allTx = await prisma.transaction.findMany({
      select: { amount: true, category: true, riskScore: true },
    });

    const totalTransactions = allTx.length;
    const totalSpend = allTx.reduce((s, t) => s + t.amount, 0);
    const avgSpendPerUser = totalUsers > 0 ? Math.round(totalSpend / totalUsers) : 0;

    // Flagged transactions (riskScore > 0.5)
    const flaggedCount = allTx.filter(t => (t.riskScore || 0) > 0.5).length;

    // Top spending categories (anonymized)
    const categoryMap = {};
    allTx.forEach(t => {
      const cat = t.category || 'Other';
      categoryMap[cat] = (categoryMap[cat] || 0) + t.amount;
    });
    const topCategories = Object.entries(categoryMap)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8)
      .map(([name, total]) => ({ name, total: Math.round(total) }));
    // Total budgets and goals
    const totalBudgets = await prisma.budget.count();
    const totalGoals = await prisma.goal.count();

    res.json({
      totalUsers,
      totalTransactions,
      totalSpend: Math.round(totalSpend),
      avgSpendPerUser,
      flaggedCount,
      topCategories,
      totalBudgets,
      totalGoals,
    });
  } catch (err) {
    console.error('Error fetching admin stats:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch admin stats' });
  }
});

// ==========================================
// USER PROFILE
// ==========================================
router.get('/profile', verifyJWT, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) return res.status(404).json({ error: 'user_not_found', message: 'User not found' });
    res.json({
      user: {
        ...user,
        picture: user.image || null,
      }
    });
  } catch (err) {
    console.error('Error fetching profile:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch profile' });
  }
});

router.put('/profile', verifyJWT, async (req, res) => {
  try {
    const { name, phone, location, currency, timezone, image } = req.body || {};
    const updated = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...(name !== undefined && { name: name.trim() }),
        ...(phone !== undefined && { phone: phone.trim() }),
        ...(location !== undefined && { location: location.trim() }),
        ...(currency !== undefined && { currency: currency.trim() }),
        ...(timezone !== undefined && { timezone: timezone.trim() }),
        ...(image !== undefined && { image }),
      }
    });

    await logActivity(
      req.userId,
      'profile_updated',
      'Profile settings updated',
      'Personal and regional preferences saved',
      'system'
    );

    res.json({
      success: true,
      user: {
        ...updated,
        picture: updated.image || null,
      }
    });
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to update profile' });
  }
});

// ==========================================
// RECENT ACTIVITY FEED
// ==========================================
router.get('/activities', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    let activities = await prisma.activity.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 15,
    });

    // If no explicit activity logged yet, synthesize from recent transactions, budgets, goals
    if (activities.length === 0) {
      const recentTxs = await prisma.transaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 6,
      });
      const recentBudgets = await prisma.budget.findMany({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        take: 3,
      });
      const recentGoals = await prisma.goal.findMany({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        take: 3,
      });

      const synthetic = [
        ...recentTxs.map(t => ({
          id: `tx-${t.id}`,
          action: 'transaction_added',
          title: `Recorded ${t.type === 'income' ? 'income' : 'expense'}: ${t.description || 'Transaction'}`,
          details: `${t.type === 'income' ? '+' : '-'}₹${t.amount.toFixed(2)} (${t.category || 'general'})${t.isRecurring ? ` • ${t.recurringPeriod || 'monthly'}` : ''}`,
          type: t.type === 'income' ? 'income' : 'expense',
          createdAt: t.createdAt || t.date || new Date(),
        })),
        ...recentBudgets.map(b => ({
          id: `bg-${b.id}`,
          action: 'budget_created',
          title: `Budget set for ${b.name}`,
          details: `Limit: ₹${b.limit.toFixed(2)} / ${b.period || 'monthly'}`,
          type: 'budget',
          createdAt: b.createdAt || new Date(),
        })),
        ...recentGoals.map(g => ({
          id: `gl-${g.id}`,
          action: 'goal_created',
          title: `Savings Goal: ${g.name}`,
          details: `Target: ₹${g.target.toFixed(2)} (Saved: ₹${g.saved.toFixed(2)})`,
          type: 'goal',
          createdAt: g.createdAt || new Date(),
        }))
      ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 10);

      return res.json({ data: synthetic });
    }

    res.json({ data: activities.slice(0, 10) });
  } catch (err) {
    console.error('Error fetching activities:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to fetch activities' });
  }
});

export default router;
