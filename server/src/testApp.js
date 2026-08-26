/**
 * Exports the Express app instance for testing with supertest.
 * This avoids calling app.listen() during tests.
 */
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import apiRoutes from './routes/apiRoutes.js';

dotenv.config();

const app = express();
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(cookieParser());

app.get('/health', (req, res) => res.json({ ok: true }));
app.use('/api', apiRoutes);

export default app;
