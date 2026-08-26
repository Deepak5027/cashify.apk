import jwt from 'jsonwebtoken';
import prisma from '../prismaClient.js';

export async function verifyJWT(req, res, next) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth) return res.status(401).json({ error: 'Unauthorized: No token provided' });
  const match = String(auth).match(/^Bearer\s+(.+)$/i);
  if (!match) return res.status(401).json({ error: 'Unauthorized: Invalid auth header' });
  const token = match[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');
    // payload expected to include id
    const user = await prisma.user.findUnique({ where: { id: payload.id } });
    if (!user) return res.status(401).json({ error: 'Unauthorized: user not found' });
    req.user = user;
    req.userId = user.id;
    next();
  } catch (err) {
    console.error('JWT verify error', err);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
}
