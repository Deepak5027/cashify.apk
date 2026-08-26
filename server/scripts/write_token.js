import prisma from '../src/prismaClient.js';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';
import fs from 'fs';

dotenv.config();

async function main() {
  const email = 'testuser+local@example.com';
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    console.error('User not found');
    process.exit(1);
  }
  const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'dev-secret', { expiresIn: '7d' });
  fs.writeFileSync('./.test_token', token);
  console.log('Wrote token to server/.test_token');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
