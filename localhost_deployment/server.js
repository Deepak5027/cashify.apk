import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import session from 'express-session';
import passport from './backend/src/auth.js';
import authRoutes from './backend/src/routes/authRoutes.js';
import apiRoutes from './backend/src/routes/apiRoutes.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors({
  origin: true,
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

// API & Auth routes
app.use('/auth', authRoutes);
app.use('/api', apiRoutes);

// Static frontend bundle serving
const distPath = path.join(__dirname, 'frontend_dist');
app.use(express.static(distPath));

app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Unified Localhost Deployment running on http://localhost:${PORT}`);
});
