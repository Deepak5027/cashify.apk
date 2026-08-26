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
