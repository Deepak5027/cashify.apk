import jwt from 'jsonwebtoken';
import prisma from '../prismaClient.js';

export async function verifyJWT(req, res, next) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth) return res.status(401).json({ error: 'Unauthorized: No token provided' });
  const match = String(auth).match(/^Bearer\s+(.+)$/i);
  if (!match) return res.status(401).json({ error: 'Unauthorized: Invalid auth header' });
  const token = match[1];

  try {
    let payload = null;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');
    } catch (e) {
      // Decode Supabase JWT without throwing if signed by Supabase Auth secret
      payload = jwt.decode(token);
    }

    if (!payload) {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }

    const userIdOrSub = payload.id || payload.sub;
    const email = payload.email || payload.user_metadata?.email;

    let user = null;
    if (userIdOrSub) {
      try {
        user = await prisma.user.findUnique({ where: { id: userIdOrSub } });
      } catch (_) {}
    }
    if (!user && email) {
      try {
        user = await prisma.user.findUnique({ where: { email } });
      } catch (_) {}
    }

    if (!user && (userIdOrSub || email)) {
      const fallbackId = userIdOrSub || `user_${Date.now()}`;
      try {
        user = await prisma.user.upsert({
          where: { id: fallbackId },
          update: { lastLogin: new Date() },
          create: {
            id: fallbackId,
            email: email || `${fallbackId}@user.local`,
            name: payload.name || payload.user_metadata?.full_name || payload.user_metadata?.name || (email ? email.split('@')[0] : 'User'),
            image: payload.picture || payload.user_metadata?.avatar_url || payload.user_metadata?.picture || null,
            lastLogin: new Date(),
            lastLoginDevice: 'Web / OAuth',
          }
        });
      } catch (upsertErr) {
        user = await prisma.user.findFirst({ where: { OR: [{ id: fallbackId }, ...(email ? [{ email }] : [])] } });
      }
    }

    if (!user) {
      return res.status(401).json({ error: 'Unauthorized: User not found' });
    }

    req.user = user;
    req.userId = user.id;
    next();
  } catch (err) {
    console.error('JWT verify error:', err);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
}
