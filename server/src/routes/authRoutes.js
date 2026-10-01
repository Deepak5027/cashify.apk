import express from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import prisma from '../prismaClient.js';
import { verifyJWT } from '../middleware/authMiddleware.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5174';

function signToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, name: user.name, picture: user.image },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function formatUser(user) {
  return { ...user, picture: user.image || null };
}

async function getPasswordHash(email) {
  const entry = await prisma.kvStore.findUnique({ where: { key: `auth_pass_${email}` } });
  return entry?.value || null;
}

async function setPasswordHash(email, hash) {
  const hashed = await bcrypt.hash(hash, 10);
  await prisma.kvStore.upsert({
    where: { key: `auth_pass_${email}` },
    create: { key: `auth_pass_${email}`, value: hashed },
    update: { key: `auth_pass_${email}`, value: hashed },
  });
}

router.post('/signup', async (req, res) => {
  try {
    const { email, password, name } = req.body || {};
    const trimmedEmail = (email || '').trim().toLowerCase();
    if (!trimmedEmail || !password) {
      return res.status(400).json({ error: 'missing_fields', message: 'Email and password are required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'weak_password', message: 'Password must be at least 6 characters' });
    }
    const existing = await prisma.user.findUnique({ where: { email: trimmedEmail } });
    if (existing) {
      return res.status(409).json({ error: 'email_exists', message: 'An account with this email already exists' });
    }
    const user = await prisma.user.create({
      data: {
        email: trimmedEmail,
        name: (name || trimmedEmail.split('@')[0]).trim(),
        lastLogin: new Date(),
        lastLoginDevice: 'Email signup',
      },
    });
    await setPasswordHash(trimmedEmail, password);
    const token = signToken(user);
    res.status(201).json({ token, user: formatUser(user) });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to create account' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const trimmedEmail = (email || '').trim().toLowerCase();
    if (!trimmedEmail || !password) {
      return res.status(400).json({ error: 'missing_fields', message: 'Email and password are required' });
    }
    const user = await prisma.user.findUnique({ where: { email: trimmedEmail } });
    if (!user) {
      return res.status(401).json({ error: 'invalid_credentials', message: 'Invalid email or password' });
    }
    const hash = await getPasswordHash(trimmedEmail);
    if (!hash || !(await bcrypt.compare(password, hash))) {
      return res.status(401).json({ error: 'invalid_credentials', message: 'Invalid email or password' });
    }
    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date(), lastLoginDevice: 'Email login' },
    });
    const token = signToken(updated);
    res.json({ token, user: formatUser(updated) });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'server_error', message: 'Failed to sign in' });
  }
});

router.post('/reset-password', async (req, res) => {
  const { email } = req.body || {};
  if (!email) {
    return res.status(400).json({ error: 'missing_email', message: 'Email is required' });
  }
  res.json({ success: true, message: 'If an account exists, a reset link would be sent (demo mode).' });
});

router.get('/google', (req, res, next) => {
  const redirectParam = req.query.redirect;
  const redirectBase = redirectParam || FRONTEND_URL;

  // Use real Passport Google OAuth if credentials are present
  if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET && process.env.GOOGLE_CLIENT_ID !== 'your_google_client_id') {
    const stateStr = Buffer.from(JSON.stringify({ redirectBase })).toString('base64');
    return passport.authenticate('google', { scope: ['profile', 'email'], state: stateStr })(req, res, next);
  }

  // Fallback demo/dev mode if OAuth credentials are not set
  (async () => {
    try {
      let user = await prisma.user.findFirst({ where: { email: 'google.user@financerperfect.ai' } });
      if (!user) {
        user = await prisma.user.create({
          data: {
            email: 'google.user@financerperfect.ai',
            name: 'Google Verified User',
            image: 'https://lh3.googleusercontent.com/a/default-user',
            lastLogin: new Date(),
            lastLoginDevice: 'Google OAuth Web',
          }
        });
      } else {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { lastLogin: new Date(), lastLoginDevice: 'Google OAuth Web' }
        });
      }
      const token = signToken(user);
      return res.redirect(`${redirectBase}/auth/callback?token=${encodeURIComponent(token)}`);
    } catch (err) {
      console.error('Google login error:', err);
      return res.status(500).json({ error: 'auth_failed', message: 'Database query failed', details: err?.message || String(err) });
    }
  })();
});

router.get('/google/callback', (req, res, next) => {
  passport.authenticate('google', { failureRedirect: '/auth/failure' }, (err, user) => {
    if (err || !user) {
      console.error('Google OAuth callback error:', err);
      return res.redirect(`${FRONTEND_URL}/login?error=oauth_failed`);
    }

    const token = signToken(user);

    let redirectBase = FRONTEND_URL;
    if (req.query.state) {
      try {
        const decoded = JSON.parse(Buffer.from(req.query.state, 'base64').toString('utf8'));
        if (decoded.redirectBase) redirectBase = decoded.redirectBase;
      } catch (e) {}
    }

    const redirectUrl = `${redirectBase}/auth/callback?token=${encodeURIComponent(token)}`;
    return res.redirect(redirectUrl);
  })(req, res, next);
});

router.get('/failure', (req, res) => res.status(401).json({ error: 'oauth_failure' }));

// Native mobile Google Sign-In exchange
router.post('/google/native', async (req, res) => {
  try {
    const { email, name, image } = req.body || {};
    const trimmedEmail = (email || '').trim().toLowerCase();
    if (!trimmedEmail) {
      return res.status(400).json({ error: 'missing_email', message: 'Email is required' });
    }
    
    let user = await prisma.user.findUnique({ where: { email: trimmedEmail } });
    if (!user) {
      user = await prisma.user.create({
        data: {
          name: name || trimmedEmail.split('@')[0],
          email: trimmedEmail,
          image: image || null,
          lastLogin: new Date(),
          lastLoginDevice: 'Google Mobile App',
        }
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          lastLogin: new Date(),
          lastLoginDevice: 'Google Mobile App',
          image: image || user.image
        }
      });
    }
    const token = signToken(user);
    res.json({ token, user: formatUser(user) });
  } catch (err) {
    console.error('Native Google auth error:', err);
    res.status(500).json({ error: 'server_error', message: 'Auth database query failed' });
  }
});

// Return current user from JWT token (supports both custom & Supabase JWTs)
router.get('/me', verifyJWT, (req, res) => {
  res.json({ user: formatUser(req.user) });
});

export default router;
