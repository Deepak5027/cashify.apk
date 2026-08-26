import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import prisma from './prismaClient.js';
import passport from './auth.js';
import session from 'express-session';
import jwt from 'jsonwebtoken';

dotenv.config();

const app = express();
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile native apps, Capacitor, curl) or local network origins
    if (!origin || origin.includes('localhost') || origin.includes('192.168.') || origin.includes('10.0.2.2') || origin.includes('capacitor://')) {
      return callback(null, true);
    }
    return callback(null, true);
  },
  credentials: true,
}));
app.use(express.json());
app.use(cookieParser());
app.use(session({
  secret: process.env.JWT_SECRET || 'dev-secret',
  resave: false,
  saveUninitialized: false,
}));
app.use(passport.initialize());
app.use(passport.session());

const PORT = process.env.PORT || 4000;

app.get('/health', (req, res) => res.json({ ok: true }));

// Mount auth routes
import authRoutes from './routes/authRoutes.js';
app.use('/auth', authRoutes);

// Mount API routes converted from Supabase functions
import apiRoutes from './routes/apiRoutes.js';
app.use('/api', apiRoutes);

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
