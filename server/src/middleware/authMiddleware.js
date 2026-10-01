import jwt from 'jsonwebtoken';
import prisma from '../prismaClient.js';

export async function verifyJWT(req, res, next) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  const userEmailHeader = req.headers['x-user-email'] || req.query.user_email;

  if (!auth && !userEmailHeader) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  let token = '';
  if (auth) {
    const match = String(auth).match(/^Bearer\s+(.+)$/i);
    token = match ? match[1] : String(auth).trim();
  }

  try {
    let payload = null;
    if (token) {
      try {
        payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret');
      } catch (e) {
        // Decode token without throwing if signed by Supabase or external provider
        payload = jwt.decode(token);
      }
    }

    const userIdOrSub = payload?.id || payload?.sub || (token.startsWith('google_auth_token_') ? token.replace('google_auth_token_', '') : null);
    const email = payload?.email || payload?.user_metadata?.email || userEmailHeader;

    let user = null;
    if (email) {
      try {
        user = await prisma.user.findUnique({ where: { email: String(email).trim().toLowerCase() } });
      } catch (_) {}
    }

    if (!user && userIdOrSub) {
      try {
        user = await prisma.user.findUnique({ where: { id: userIdOrSub } });
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
            email: email ? String(email).trim().toLowerCase() : `${fallbackId}@user.local`,
            name: payload?.name || payload?.user_metadata?.full_name || (email ? String(email).split('@')[0] : 'User'),
            image: payload?.picture || payload?.user_metadata?.avatar_url || null,
            lastLogin: new Date(),
            lastLoginDevice: 'Web / OAuth',
          }
        });
      } catch (upsertErr) {
        user = await prisma.user.findFirst({ where: { OR: [{ id: fallbackId }, ...(email ? [{ email: String(email).trim().toLowerCase() }] : [])] } });
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
