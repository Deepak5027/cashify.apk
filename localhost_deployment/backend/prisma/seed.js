import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting comprehensive database seeding...');

  // 1. Create or Find Demo User
  const demoEmail = 'email@example.com';
  const hashedPassword = await bcrypt.hash('password123', 10);

  let user = await prisma.user.findUnique({
    where: { email: demoEmail }
  });

  if (!user) {
    user = await prisma.user.create({
      data: {
        email: demoEmail,
        name: 'Alex Johnson',
      }
    });
    console.log(`✅ Created demo user: ${demoEmail} (${user.id})`);
  } else {
    console.log(`ℹ️ Found existing demo user: ${demoEmail} (${user.id})`);
  }

  // Store password in KV store for demo login compatibility
  await prisma.kvStore.upsert({
    where: { key: `auth_pass_${demoEmail}` },
    update: { value: hashedPassword },
    create: { key: `auth_pass_${demoEmail}`, value: hashedPassword }
  });

  const userId = user.id;

  // 2. Clear old data for clean presentation
  await prisma.receiptItem.deleteMany();
  await prisma.receipt.deleteMany({ where: { userId } });
  await prisma.transaction.deleteMany({ where: { userId } });
  await prisma.budget.deleteMany({ where: { userId } });
  await prisma.goal.deleteMany({ where: { userId } });
  await prisma.bill.deleteMany({ where: { userId } });
  await prisma.investment.deleteMany({ where: { userId } });

  console.log('🧹 Cleaned previous user data');

  // 3. Generate Realistic Transactions over the last 90 days
  const now = new Date();
  const sampleTransactions = [];

  // Monthly Salaries
  for (let m = 0; m < 3; m++) {
    const salaryDate = new Date(now.getFullYear(), now.getMonth() - m, 1, 9, 0, 0);
    sampleTransactions.push({
      userId,
      amount: 75000.00,
      description: 'Monthly Tech Corp Salary',
      category: 'salary',
      date: salaryDate,
    });
  }

  // Normal Expenses spanning past 90 days
  const vendors = [
    { merchant: 'Whole Foods Market', category: 'groceries', min: 1200, max: 3500 },
    { merchant: 'BigBasket Fresh', category: 'groceries', min: 800, max: 2200 },
    { merchant: 'Starbucks Coffee', category: 'food', min: 280, max: 650 },
    { merchant: 'Swiggy Gourmet', category: 'food', min: 350, max: 1200 },
    { merchant: 'Zomato Dining', category: 'food', min: 600, max: 1800 },
    { merchant: 'Shell Gas Station', category: 'fuel', min: 1500, max: 3000 },
    { merchant: 'Uber Rides', category: 'transport', min: 180, max: 550 },
    { merchant: 'Amazon Shopping', category: 'shopping', min: 850, max: 4800 },
    { merchant: 'Zara Apparel', category: 'shopping', min: 2400, max: 6500 },
    { merchant: 'Netflix Subscription', category: 'entertainment', min: 649, max: 649 },
    { merchant: 'Spotify Premium', category: 'entertainment', min: 119, max: 119 },
    { merchant: 'Electricity Utility Board', category: 'bills', min: 2400, max: 3800 },
    { merchant: 'ACT Fibernet Broadband', category: 'bills', min: 1150, max: 1150 },
    { merchant: 'Apollo Pharmacy', category: 'healthcare', min: 450, max: 1600 },
  ];

  for (let d = 85; d >= 1; d -= Math.floor(Math.random() * 2) + 1) {
    const vendor = vendors[Math.floor(Math.random() * vendors.length)];
    const txDate = new Date(Date.now() - d * 24 * 60 * 60 * 1000);
    txDate.setHours(10 + Math.floor(Math.random() * 10), Math.floor(Math.random() * 60));

    const amount = Math.round((Math.random() * (vendor.max - vendor.min) + vendor.min) * 100) / 100;

    sampleTransactions.push({
      userId,
      amount,
      description: vendor.merchant,
      category: vendor.category,
      date: txDate,
    });
  }

  // 4. Add Specially Flagged Suspicious Transactions for Live Defense / Alerts Demo
  // Flagged 1: Extreme Amount Spike in Dining Category
  sampleTransactions.push({
    userId,
    amount: 28500.00,
    description: 'Luxury Club VIP Lounge',
    category: 'food',
    date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
  });

  // Flagged 2: Night-time Suspicious International Wire Transfer
  const nightDate = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000);
  nightDate.setHours(2, 45, 0); // 2:45 AM
  sampleTransactions.push({
    userId,
    amount: 14500.00,
    description: 'International Wire Transfer Exchange',
    category: 'transfer',
    date: nightDate,
  });

  for (const tx of sampleTransactions) {
    await prisma.transaction.create({ data: tx });
  }
  console.log(`✅ Seeded ${sampleTransactions.length} realistic transactions`);

  // 5. Seed Budgets
  const sampleBudgets = [
    { name: 'groceries', limit: 15000, period: 'monthly' },
    { name: 'food', limit: 12000, period: 'monthly' },
    { name: 'shopping', limit: 10000, period: 'monthly' },
    { name: 'fuel', limit: 6000, period: 'monthly' },
    { name: 'entertainment', limit: 3000, period: 'monthly' },
    { name: 'bills', limit: 8000, period: 'monthly' },
  ];

  for (const b of sampleBudgets) {
    await prisma.budget.create({ data: { ...b, userId } });
  }
  console.log(`✅ Seeded ${sampleBudgets.length} budget allocations`);

  // 6. Seed Savings Goals
  const sampleGoals = [
    {
      userId,
      name: 'Emergency Fund',
      target: 150000,
      saved: 85000,
      dueDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    },
    {
      userId,
      name: 'New MacBook Pro M3',
      target: 180000,
      saved: 120000,
      dueDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    },
    {
      userId,
      name: 'Japan Autumn Vacation',
      target: 250000,
      saved: 65000,
      dueDate: new Date(Date.now() + 240 * 24 * 60 * 60 * 1000),
    },
  ];

  for (const g of sampleGoals) {
    await prisma.goal.create({ data: g });
  }
  console.log(`✅ Seeded ${sampleGoals.length} savings goals`);

  // 7. Seed Bills & Investments
  await prisma.bill.create({
    data: {
      userId,
      name: 'Apartment Maintenance',
      amount: 4500,
      dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      paid: false,
    }
  });
  await prisma.bill.create({
    data: {
      userId,
      name: 'Car Insurance Premium',
      amount: 14200,
      dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      paid: false,
    }
  });

  await prisma.investment.create({
    data: { userId, name: 'Nifty 50 Index Mutual Fund', amount: 85000 }
  });
  await prisma.investment.create({
    data: { userId, name: 'S&P 500 US Tech ETF', amount: 45000 }
  });

  // 8. Seed Scanned Receipts
  const receipt = await prisma.receipt.create({
    data: {
      userId,
      merchant: 'Starbucks Reserve',
      total: 785.00,
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    }
  });

  const items = [
    { receiptId: receipt.id, name: 'Vanilla Sweet Cream Cold Brew', price: 395.00, quantity: 1 },
    { receiptId: receipt.id, name: 'Blueberry Cheesecake Slice', price: 390.00, quantity: 1 },
  ];

  for (const item of items) {
    await prisma.receiptItem.create({ data: item });
  }

  console.log('🎉 Database seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
