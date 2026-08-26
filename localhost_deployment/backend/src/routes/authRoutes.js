import express from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import prisma from '../prismaClient.js';

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

async function setPasswordHash(email, password) {
  const hashed = await bcrypt.hash(password, 10);
  await prisma.kvStore.upsert({
    where: { key: `auth_pass_${email}` },
    update: { value: hashed },
    create: { key: `auth_pass_${email}`, value: hashed },
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

router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));

router.get('/google/callback', passport.authenticate('google', { failureRedirect: '/auth/failure' }), (req, res) => {
  const user = req.user;
  const token = signToken(user);
  const redirectUrl = `${FRONTEND_URL}/auth/callback?token=${encodeURIComponent(token)}`;
  res.redirect(redirectUrl);
});

router.get('/failure', (req, res) => res.status(401).json({ error: 'oauth_failure' }));

// Return current user from JWT in Authorization header
router.get('/me', async (req, res) => {
  const auth = req.headers.authorization || '';
  const match = auth.match(/^Bearer (.+)$/);
  if (!match) return res.status(401).json({ error: 'no_token' });
  const token = match[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    // payload has id and email
    const user = await prisma.user.findUnique({ where: { id: payload.id } });
    if (!user) return res.status(404).json({ error: 'user_not_found' });
    
    // Normalize picture property from image
    const userWithMeta = {
      ...user,
      picture: user.image || payload.picture || null,
    };
    res.json({ user: userWithMeta });
  } catch (err) {
    res.status(401).json({ error: 'invalid_token' });
  }
});

export default router;

