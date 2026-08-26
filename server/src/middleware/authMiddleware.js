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
      user = await prisma.user.findUnique({ where: { id: userIdOrSub } });
    }
    if (!user && email) {
      user = await prisma.user.findUnique({ where: { email } });
    }

    if (!user && email) {
      user = await prisma.user.create({
        data: {
          id: userIdOrSub || undefined,
          email,
          name: payload.name || payload.user_metadata?.full_name || payload.user_metadata?.name || email.split('@')[0],
          image: payload.picture || payload.user_metadata?.avatar_url || payload.user_metadata?.picture || null,
          lastLogin: new Date(),
          lastLoginDevice: 'Supabase OAuth',
        }
      });
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
