# AI Daily Cash Management

A modern, full-stack personal cash and expense management system with intelligent analytics, OCR receipt extraction, voice expense logging, statistical time-series budgeting forecasts, and heuristic fraud detection.

---

## 🌟 Key Features

- 🔐 **Authentication & Security**: Custom JWT-based authentication with bcrypt password hashing and optional Google OAuth integration.
- 💰 **Transaction Management**: Record income and expenses, filter by category, search by merchant, paginate large sets, and tag notes.
- 📊 **Dynamic Analytics Dashboard**: Interactive category breakdown, 6-month historical trends, cash flow distribution, and monthly summaries using Recharts.
- 🎯 **Smart Budgeting & Goals**: Set category budget limits with real-time progress indicators, track multi-tier savings targets, and estimate time-to-goal.
- 🛡️ **Anomaly & Fraud Detection**: Heuristic anomaly analysis detecting unusual amounts (z-score variance), high-risk merchants, and abnormal transaction timing.
- 📸 **Receipt Scanner (OCR)**: Browser-based image text recognition powered by Tesseract.js to automatically parse merchant, total amount, and dates.
- 🎙️ **Voice Entry**: Real-time natural speech recognition with regex-driven entity extraction for quick hands-free expense entry.
- 📈 **Predictive Time-Series Budgeting**: Explainable statistical time-series forecasting (weighted moving average and exponential trend estimation) with confidence intervals.
- 📑 **Data Export**: One-click CSV and formatted PDF reports generated client-side via jsPDF.
- 🌓 **Modern UI / Dark Mode**: Clean interface built with Tailwind CSS, Radix UI primitives, Lucide icons, and responsive desktop/mobile layouts.

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS, Radix UI, Lucide React
- **Visualizations**: Recharts
- **OCR Engine**: Tesseract.js
- **Speech Parsing**: Web Speech API
- **Document Export**: jsPDF + autotable styling

### Backend
- **Runtime**: Node.js + Express (ES Modules)
- **ORM**: Prisma ORM (v4/v5 client)
- **Database**: SQLite (`prisma/dev.db` - zero external database setup required)
- **Authentication**: JWT (`jsonwebtoken`) + `bcrypt`
- **CORS & Middleware**: `cors`, `cookie-parser`, `express-session`

---

## 🚀 Quick Start & Installation

### Prerequisites
- **Node.js**: v18.0.0 or higher
- **npm** (or **pnpm** / **yarn**)

---

### Step 1: Clone and Install Dependencies

```bash
# Clone the repository
git clone <your-repository-url>
cd Aidailycashmanagement-main

# Install frontend dependencies
npm install

# Install server dependencies
cd server
npm install
cd ..
```

---

### Step 2: Configure Environment Variables

1. **Frontend**: Create `.env` in the root folder:
   ```env
   VITE_API_BASE=http://localhost:4000
   ```

2. **Backend**: Create `server/.env` in the `server/` folder:
   ```env
   DATABASE_URL="file:./prisma/dev.db"
   JWT_SECRET="your-super-secret-jwt-key"
   FRONTEND_URL="http://localhost:5174"
   BACKEND_URL="http://localhost:4000"
   NODE_ENV="development"
   ```

---

### Step 3: Initialize the SQLite Database

From the `server` directory, run Prisma migrations to generate the local SQLite database schema:

```bash
cd server
npx prisma migrate dev --name init
npx prisma generate
```

*(Optional)* Populate realistic demo data for presentation or defense:
```bash
node prisma/seed.js
```
```bash
cd ..
```

---

### Step 4: Run the Application

You can run both the frontend and backend in separate terminals:

**Terminal 1 — Backend API:**
```bash
cd server
npm run dev
# Server running at http://localhost:4000
```

**Terminal 2 — Frontend App:**
```bash
npm run dev
# Frontend running at http://localhost:5174
```

Open [http://localhost:5174](http://localhost:5174) in your browser.

---

## 📁 Project Structure

```
├── server/
│   ├── prisma/
│   │   ├── schema.prisma        # Prisma data models (User, Transaction, Budget, Goal, etc.)
│   │   └── seed.js              # Realistic demo data populator
│   ├── src/
│   │   ├── middleware/          # JWT authentication and request validation
│   │   ├── routes/
│   │   │   ├── apiRoutes.js     # CRUD endpoints (transactions, budgets, goals, etc.)
│   │   │   └── authRoutes.js    # Login, signup, token validation endpoints
│   │   ├── index.js             # Express app entry point & CORS configuration
│   │   └── prismaClient.js      # Shared Prisma client instance
│   └── package.json
│
├── src/
│   ├── app/
│   │   ├── components/          # Reusable UI components, ErrorBoundary, Navbars
│   │   ├── pages/               # Routed pages (Dashboard, Transactions, Budget, etc.)
│   │   └── routes.tsx           # React Router route definitions
│   ├── services/
│   │   ├── api.ts               # Typed client API services
│   │   ├── aiAssistant.ts       # Natural language expense parsing & rule engine
│   │   ├── fraudDetection.ts    # Multi-factor anomaly scoring logic
│   │   └── mlPredictions.ts     # Statistical time-series forecasting service
│   ├── styles/                  # Global CSS and Tailwind directives
│   └── main.tsx                 # React application root
├── package.json
└── README.md
```

---

## 🧪 Testing & Verification

- **Frontend Typecheck**:
  ```bash
  npm run typecheck
  ```
- **Frontend Production Build**:
  ```bash
  npm run build
  ```
- **Unit Tests** (Fraud scoring & ML prediction fallback):
  ```bash
  npx vitest run
  ```

---

## 📜 License
This project is developed for educational purposes as an academic final-year project.
