# Deployment Guide for FinanceAI

## Quick Start

This project uses a local Express backend with SQLite (Prisma) and a Vite React frontend. Deploy the frontend to your hosting provider (Vercel, Netlify, etc.) and host the backend separately if needed.

## What's Been Set Up

- ✅ **Backend**: Express + Prisma + SQLite (server/)
- ✅ **Authentication**: Google OAuth issuing JWTs (server/src/routes/authRoutes.js)
- ✅ **API**: Converted serverless functions to Express routes (server/src/routes/apiRoutes.js)
- ✅ **Frontend**: Vite React app configured to call backend via VITE_API_BASE

## Environment Setup

Your frontend and backend need these environment variables:

- Frontend (set in your hosting provider or .env for local dev):

```env
VITE_API_BASE=http://localhost:4000
```

- Backend (server/.env):

```env
DATABASE_URL="file:./prisma/dev.db"
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
JWT_SECRET=replace-this-with-a-secure-random-string
NODE_ENV=development
```

## Testing Locally

1. Start the backend:

```bash
cd server
npm install
npm run dev
```

2. Start the frontend (from repo root):

```bash
pnpm install
pnpm run dev
# or
npm install
npm run dev
```

3. Set VITE_API_BASE to your backend URL (default: http://localhost:4000).
4. Test sign-in (Google OAuth), CRUD endpoints, and seed/CSV import routes.

## Deploy to Vercel (frontend)

1. Push code to GitHub
2. Import repository in Vercel
3. Add environment variable `VITE_API_BASE` pointing to your backend URL
4. Deploy

## Deploy Backend

Host the Express server on a node hosting service (Render, Heroku, Railway, or a VM). Ensure `server/.env` is configured and the SQLite file is writable.

## Verifying Deployment

After deployment, test these features:

1. ✅ Sign in with Google (OAuth)
2. ✅ Add a transaction (Transactions page)
3. ✅ Create budgets/goals
4. ✅ Seed demo data with the backend endpoint
5. ✅ Import CSV

## Troubleshooting

- If authentication fails: verify GOOGLE_CLIENT_ID/SECRET and JWT_SECRET
- If API calls fail: check VITE_API_BASE and backend logs

## Support

If you need help, open an issue on GitHub.
