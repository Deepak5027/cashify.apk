import { PrismaClient } from '@prisma/client';

let dbUrl = process.env.DATABASE_URL || "postgresql://postgres.wmfbbapborfpcixxxiab:cashifydeepak@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true";

// Automatically use the verified IPv4 Supabase Pooler host when deployed on IPv4-only environments like Render
if (dbUrl.includes('db.wmfbbapborfpcixxxiab.supabase.co')) {
  dbUrl = "postgresql://postgres.wmfbbapborfpcixxxiab:cashifydeepak@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true";
}

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: dbUrl,
    },
  },
});

export default prisma;
