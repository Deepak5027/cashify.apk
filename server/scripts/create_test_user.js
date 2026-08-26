import prisma from '../src/prismaClient.js';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';

dotenv.config();

async function main() {
  const email = 'testuser+local@example.com';
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    user = await prisma.user.create({ data: { email, name: 'Local Test User' } });
    console.log('Created user:', user.id);
  } else {
    console.log('Found existing user:', user.id);
  }
  const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'dev-secret', { expiresIn: '7d' });
  console.log('TOKEN:', token);
  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
