/**
 * Backend API tests — Transactions, Budgets, Goals
 *
 * 10 tests covering:
 *   1-5: Transactions (auth guard, create, reject bad amount, update, delete + ownership)
 *   6-8: Budgets     (auth guard, create, delete + ownership)
 *   9-10: Goals      (create, delete + ownership)
 *
 * Uses a real JWT signed with 'dev-secret' and seeds a test user in the DB
 * before each test suite. No auth routes/files are modified.
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
import prisma from '../prismaClient.js';
import app from '../testApp.js';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

let testUserId;
let otherUserId;
let authToken;
let otherToken;

// ── Setup / Teardown ───────────────────────────────────────────────────────────
beforeAll(async () => {
  // Seed two users: testUser (ours) and otherUser (for ownership checks)
  const testUser = await prisma.user.upsert({
    where: { email: 'test-api@example.com' },
    update: {},
    create: { email: 'test-api@example.com', name: 'Test User' },
  });
  testUserId = testUser.id;
  authToken = jwt.sign({ id: testUserId, email: testUser.email }, JWT_SECRET, { expiresIn: '1h' });

  const otherUser = await prisma.user.upsert({
    where: { email: 'other-api@example.com' },
    update: {},
    create: { email: 'other-api@example.com', name: 'Other User' },
  });
  otherUserId = otherUser.id;
  otherToken = jwt.sign({ id: otherUserId, email: otherUser.email }, JWT_SECRET, { expiresIn: '1h' });
}, 30000);

afterAll(async () => {
  // Clean up test data
  if (testUserId && otherUserId) {
    await prisma.transaction.deleteMany({ where: { userId: { in: [testUserId, otherUserId] } } });
    await prisma.budget.deleteMany({ where: { userId: { in: [testUserId, otherUserId] } } });
    await prisma.goal.deleteMany({ where: { userId: { in: [testUserId, otherUserId] } } });
    await prisma.user.deleteMany({ where: { email: { in: ['test-api@example.com', 'other-api@example.com'] } } });
  }
  await prisma.$disconnect();
}, 30000);

// ══════════════════════════════════════════════════════════════════════════════
// TRANSACTIONS
// ══════════════════════════════════════════════════════════════════════════════

describe('Transactions API', () => {
  let createdTxId;

  // Test 1: Auth guard
  it('GET /api/transactions returns 401 without a token', async () => {
    const res = await request(app).get('/api/transactions');
    expect(res.status).toBe(401);
  });

  // Test 2: Create
  it('POST /api/transactions creates a transaction with valid token', async () => {
    const res = await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: 250, description: 'Groceries', category: 'food' });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.amount).toBe(250);
    expect(res.body.category).toBe('food');
    // risk score should be persisted
    expect(res.body).toHaveProperty('riskScore');
    expect(res.body).toHaveProperty('riskReason');
    createdTxId = res.body.id;
  }, 20000);

  // Test 3: Reject invalid amount
  it('POST /api/transactions rejects amount <= 0', async () => {
    const res = await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: -10, description: 'Bad' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('invalid_amount');
  }, 20000);

  // Test 4: Update own transaction
  it('PUT /api/transactions/:id updates own transaction', async () => {
    const res = await request(app)
      .put(`/api/transactions/${createdTxId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ amount: 300 });

    expect(res.status).toBe(200);
    expect(res.body.amount).toBe(300);
  }, 20000);

  // Test 5: Delete own, 404 for other user
  it('DELETE /api/transactions/:id returns 404 for another user\'s transaction', async () => {
    const res = await request(app)
      .delete(`/api/transactions/${createdTxId}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(404);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// BUDGETS
// ══════════════════════════════════════════════════════════════════════════════

describe('Budgets API', () => {
  let createdBudgetId;

  // Test 6: Auth guard
  it('GET /api/budgets returns 401 without a token', async () => {
    const res = await request(app).get('/api/budgets');
    expect(res.status).toBe(401);
  });

  // Test 7: Create
  it('POST /api/budgets creates a budget', async () => {
    const res = await request(app)
      .post('/api/budgets')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'TestFood', limit: 5000, period: 'monthly' });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.name).toBe('TestFood');
    createdBudgetId = res.body.id;
  }, 20000);

  // Test 8: Ownership check on delete
  it('DELETE /api/budgets/:id returns 404 for another user\'s budget', async () => {
    const res = await request(app)
      .delete(`/api/budgets/${createdBudgetId}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(404);
  }, 20000);
});

// ══════════════════════════════════════════════════════════════════════════════
// GOALS
// ══════════════════════════════════════════════════════════════════════════════

describe('Goals API', () => {
  let createdGoalId;

  // Test 9: Create
  it('POST /api/goals creates a goal', async () => {
    const res = await request(app)
      .post('/api/goals')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Emergency Fund', target: 50000, saved: 1000 });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.name).toBe('Emergency Fund');
    expect(res.body.target).toBe(50000);
    createdGoalId = res.body.id;
  }, 20000);

  // Test 10: Ownership check on delete
  it('DELETE /api/goals/:id returns 404 for another user\'s goal', async () => {
    const res = await request(app)
      .delete(`/api/goals/${createdGoalId}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(404);
  }, 20000);
});

// ══════════════════════════════════════════════════════════════════════════════
// VIRTUAL CARD (FEATURE 1)
// ══════════════════════════════════════════════════════════════════════════════

describe('Virtual Card API (Feature 1)', () => {
  it('GET /api/virtual-card retrieves or creates user virtual card', async () => {
    const res = await request(app)
      .get('/api/virtual-card')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(res.body.data).toHaveProperty('cardNumber');
    expect(res.body.data).toHaveProperty('spendingLimit');
    expect(res.body.data).toHaveProperty('isFrozen');
  }, 20000);

  it('PUT /api/virtual-card updates spending limit and freeze state', async () => {
    const res = await request(app)
      .put('/api/virtual-card')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ spendingLimit: 75000, isFrozen: true, cardColor: 'emerald' });

    expect(res.status).toBe(200);
    expect(res.body.data.spendingLimit).toBe(75000);
    expect(res.body.data.isFrozen).toBe(true);
    expect(res.body.data.cardColor).toBe('emerald');
  }, 20000);
});

// ══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTIONS (FEATURE 2)
// ══════════════════════════════════════════════════════════════════════════════

describe('Subscriptions API (Feature 2)', () => {
  let createdSubId;

  it('POST /api/subscriptions creates a new subscription', async () => {
    const nextDate = new Date();
    nextDate.setDate(nextDate.getDate() + 15);

    const res = await request(app)
      .post('/api/subscriptions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Netflix Premium',
        amount: 649,
        billingCycle: 'monthly',
        category: 'Entertainment',
        nextBillingDate: nextDate.toISOString(),
      });

    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.name).toBe('Netflix Premium');
    expect(res.body.data.amount).toBe(649);
    createdSubId = res.body.data.id;
  }, 20000);

  it('GET /api/subscriptions returns list including created item', async () => {
    const res = await request(app)
      .get('/api/subscriptions')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.some(s => s.name === 'Netflix Premium')).toBe(true);
  }, 20000);

  it('DELETE /api/subscriptions/:id deletes own subscription', async () => {
    const res = await request(app)
      .delete(`/api/subscriptions/${createdSubId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  }, 20000);
});

// ══════════════════════════════════════════════════════════════════════════════
// INVOICES & LIVE UPI QR (FEATURE 3)
// ══════════════════════════════════════════════════════════════════════════════

describe('Invoices & QR API (Feature 3)', () => {
  let createdInvoiceId;

  it('POST /api/invoices creates an invoice with line items and computed total', async () => {
    const res = await request(app)
      .post('/api/invoices')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        clientName: 'Acme Technologies',
        upiId: 'deepak@okaxis',
        taxRate: 18,
        items: [
          { description: 'Cloud Architecture Consulting', quantity: 2, unitPrice: 5000 },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.clientName).toBe('Acme Technologies');
    expect(res.body.data.items.length).toBe(1);
    // 10,000 + 18% tax = 11,800
    expect(res.body.data.totalAmount).toBe(11800);
    createdInvoiceId = res.body.data.id;
  }, 20000);

  it('PUT /api/invoices/:id updates invoice status to paid', async () => {
    const res = await request(app)
      .put(`/api/invoices/${createdInvoiceId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ status: 'paid' });

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('paid');
  }, 20000);

  it('DELETE /api/invoices/:id removes the invoice', async () => {
    const res = await request(app)
      .delete(`/api/invoices/${createdInvoiceId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  }, 20000);
});

