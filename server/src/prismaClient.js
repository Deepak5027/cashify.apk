import { PrismaClient } from '@prisma/client';

let dbUrl = process.env.DATABASE_URL;

// Ensure SSL and proper fallback for Supabase on Cloud hosting like Render
if (!dbUrl) {
  dbUrl = "postgresql://postgres:cashifydeepak@db.wmfbbapborfpcixxxiab.supabase.co:5432/postgres?sslmode=require";
}

// If using pooler port 6543 on db.wmfbbapborfpcixxxiab.supabase.co, replace with direct port 5432 for reliable SSL connection
if (dbUrl.includes('db.wmfbbapborfpcixxxiab.supabase.co:6543')) {
  dbUrl = dbUrl.replace(':6543', ':5432').replace('&pgbouncer=true', '').replace('?pgbouncer=true', '');
}

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: dbUrl,
    },
  },
});

export default prisma;
