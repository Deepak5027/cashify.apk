# Backend Process & Comprehensive Diagnostic Report

## 1. Backend Server Status & Startup Console Logs
- **Status**: Currently **RUNNING** on port `4000` (PID `21940`).
- **Console Log Output**:
```text
> ai-daily-cash-management@1.0.0 dev:server
> cd server && npm run dev

> aidaily-backend@0.1.0 dev
> nodemon src/index.js

[nodemon] 2.0.22
[nodemon] to restart at any time, enter `rs`
[nodemon] watching path(s): *.*
[nodemon] watching extensions: js,mjs,json
[nodemon] starting `node src/index.js`
Server listening on port 4000
```
- **Supabase Database Connection**: Tested & Verified directly via Prisma client connect:
```text
DATABASE_URL: PRESENT
SUPABASE_CONNECTED_SUCCESSFULLY
USER_COUNT: 2
```
No database connection errors or timeouts occurred with Supabase.

---

## 2. Crash/Failure Analysis
- **Result**: The backend is not crashing. It successfully connects to Supabase PostgreSQL over SSL (`sslmode=require&connect_timeout=30`) and serves requests on port 4000.
- **Previous Failure Reason**: When the server background task was not active or stopped, any browser request to `http://localhost:4000/auth/google` immediately threw `ERR_CONNECTION_REFUSED`.

---

## 3. Environment Variables Audit (`server/.env`)
| Variable | Value Status |
| :--- | :--- |
| `DATABASE_URL` | `postgresql://postgres:***@db.***.supabase.co:5432/postgres?sslmode=require&connect_timeout=30` (Configured Supabase PostgreSQL URL) |
| `GOOGLE_CLIENT_ID` | `***.apps.googleusercontent.com` (Configured OAuth Client ID) |
| `GOOGLE_CLIENT_SECRET` | `***` (Configured Secret Format) |
| `JWT_SECRET` | `dev-secret-please-change` |
| `BACKEND_URL` | `http://localhost:4000` |
| `FRONTEND_URL` | `http://localhost:5174` |
| `NODE_ENV` | `development` |

*All environment variables are present and actively loaded.*

---

## 4. Prisma Client Generation (`npx prisma generate`)
- Executed `npx prisma generate` in `server/`:
```text
✔ Generated Prisma Client (4.16.0 | library) to .\node_modules\@prisma\client in 148ms
```
- **Provider**: PostgreSQL (`schema.prisma` configured for Supabase).

---

## 5. Port Listening Verification (Port 4000)
Command: `netstat -ano | findstr 4000`
```text
  TCP    0.0.0.0:4000           0.0.0.0:0              LISTENING       21940
  TCP    [::]:4000              [::]:0                 LISTENING       21940
```
- Server is actively listening on all local network interfaces on port `4000`.

---

## 6. Project References to `localhost:4000` & Mobile APK Explanation

### Mobile APK vs Desktop Analysis
- **Desktop Browser**: Navigating to `http://localhost:4000` resolves to the local machine's `127.0.0.1`. When the backend server is running on the laptop, connection succeeds.
- **Mobile APK (Android Device)**: On a mobile device, `localhost` or `127.0.0.1` refers to **the phone itself**, NOT the developer laptop. Therefore, an APK configured to reach `localhost:4000` will ALWAYS fail with `ERR_CONNECTION_REFUSED` when tested on a phone until Stage 2 (deploying/hosting backend to a cloud provider like Render, Railway, or Vercel).

### Codebase Occurrences of `localhost:4000`:
1. `src/utils/apiClient.ts` (Lines 2, 18) - Frontend API client fallback base URL.
2. `server/.env` & `server/.env.example` - `BACKEND_URL=http://localhost:4000`.
3. `server/src/auth.js` (Line 5) - Default backend URL fallback.
4. `.env` (Root) (Line 1) - `VITE_API_BASE=http://localhost:4000`.
5. `README.md` & `PROJECT_FULL_SUMMARY.txt` - Documentation references.

---

## 7. Final Diagnosis & Summary

1. **Desktop `ERR_CONNECTION_REFUSED` Diagnosis**:
   - **Cause**: Occurs whenever the node backend process (`npm run dev:server`) is not running in the background on your machine.
   - **Current State**: Fixed & Verified. The backend server is currently running and listening on port 4000. Supabase DB connection is verified functional.

2. **Mobile APK `ERR_CONNECTION_REFUSED` Diagnosis**:
   - **Cause**: Structural design limit of local development. The mobile app attempts to connect to `localhost:4000` on the phone itself instead of your computer's IP or a public web address.
   - **Resolution Plan**: Expected behavior until Stage 2 (hosting the backend online on a public domain). No workaround or code change applied as instructed.
