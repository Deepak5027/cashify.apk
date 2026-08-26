# System Architecture - AI Daily Cash Management

This document provides a technical overview of the architecture, data flow, authentication mechanisms, and AI/ML subsystems implemented in the **AI Daily Cash Management** project.

---

## 🏗️ 1. High-Level Architecture Overview

The system follows a decoupled Single Page Application (SPA) client and RESTful API backend architecture:

```mermaid
graph TD
    Client["React 18 + TypeScript + Vite SPA\n(Port 5174)"]
    API["Express.js REST API Server\n(Port 4000)"]
    AuthMiddleware["JWT Authentication Middleware"]
    ORM["Prisma ORM Client"]
    DB[("SQLite Database\n(prisma/dev.db)")]

    Client -->|HTTP / JSON Requests with Bearer JWT| API
    API --> AuthMiddleware
    AuthMiddleware -->|Validated User Context| ORM
    ORM -->|CRUD SQL Queries| DB

    subgraph Client-Side AI Engine
        OCR["Tesseract.js OCR Engine"]
        NLP["Web Speech API + Regex NLP Entity Parser"]
        ML["Time-Series Forecasting\n(Exponential Smoothing & Trend Regression)"]
        Fraud["Multi-Factor Anomaly Scoring Engine\n(Z-Score Variance + Timing + Velocity)"]
    end

    Client --- Client-Side AI Engine
```

---

## 🔒 2. Authentication & Authorization Flow

The platform implements a stateless JWT (JSON Web Token) authentication architecture:

1. **User Registration & Login**:
   - `POST /auth/signup` and `POST /auth/login` validate incoming credentials.
   - Passwords are encrypted with a 10-round salt using `bcrypt`.
   - On successful authentication, the server signs a JWT containing `{ userId, email }` with a secure server-side secret (`JWT_SECRET`).
2. **Session Persistence**:
   - The token is securely stored in browser `localStorage`.
   - All authenticated requests dispatch an `Authorization: Bearer <token>` header via `apiClient.ts`.
3. **Route Protection**:
   - Backend routes verify the token using `verifyJWT` middleware and inject `req.userId` into downstream route handlers.
   - Frontend routes are wrapped in `<ProtectedRoute>`, preventing unauthorized access to `/app/*` views and redirecting unauthenticated visitors to `/login`.

---

## 🤖 3. AI & Intelligent Subsystems Architecture

### A. Heuristic Anomaly & Fraud Scoring Engine (`fraudDetection.ts` & `/api/ai/analyzeFraud`)
- **Statistical Z-Score Anomaly**:
  $$\mu = \frac{1}{N}\sum x_i, \quad \sigma = \sqrt{\frac{1}{N}\sum (x_i - \mu)^2}, \quad Z = \frac{x_{\text{current}} - \mu}{\sigma}$$
  Transactions with $Z > 2.0$ are flagged for significant category spending deviations, and $Z > 3.0$ triggers a severe risk score boost (+0.50).
- **Temporal Night-Time Heuristic**: Detects high-value spending occurring during unusual midnight hours (11:00 PM – 5:00 AM local/UTC).
- **Velocity Clustering**: Flags rapid succession spending (3 or more transactions executed within a 60-minute window).
- **Merchant Threat Profiling**: String pattern matching for high-risk transfer, foreign exchange, or suspicious keywords.

### B. Statistical Time-Series Forecasting (`mlPredictions.ts`)
- **Holt's Linear Trend / Exponential Smoothing**: Computes level and slope updates over historical daily expense aggregates:
  $$L_t = \alpha Y_t + (1 - \alpha)(L_{t-1} + T_{t-1})$$
  $$T_t = \beta (L_t - L_{t-1}) + (1 - \beta) T_{t-1}$$
- **Forecast Horizon**: Projects 30-day upcoming monthly expense requirements, expected surplus/deficit relative to recurring income, dynamic category budget safety caps, and a 6-month interactive cash flow trajectory.
- **Explainability**: Outputs human-readable rationale without un-fitted black-box weights.

### C. Voice Expense Logging (`VoiceEntry.tsx` & `aiAssistant.ts`)
- **Speech Capture**: Captures spoken audio streams via the browser's native `webkitSpeechRecognition` / `SpeechRecognition` interface.
- **NLP Token Parsing**: Extracts numerical quantities ("spent 450", "twelve hundred"), merchant tags ("Starbucks", "Shell"), and keyword-derived category mapping via regular expression tokenization.

### D. Client-Side Receipt OCR (`Scanner.tsx`)
- **Image Processing**: Processes uploaded receipts up to 5MB using `Tesseract.js`.
- **Text Entity Parsing**: Scans OCR text blocks for total lines, dates, and itemized sub-lines, auto-populating structured transaction records with a single click.

---

## 🗄️ 4. Data Model & Database Schema

The persistence layer is managed by Prisma ORM backed by SQLite:

- **`User`**: Account identity, email, name, and timestamps.
- **`Transaction`**: Records income and expense logs with `userId`, `amount`, `category`, `description`, `date`, `payment_mode`, and `risk_score`.
- **`Budget`**: Category-specific expenditure caps, limits, and monitoring intervals.
- **`Goal`**: Financial targets with `target_amount`, `saved` balance, and target deadline dates.
- **`Bill`**: Upcoming recurring obligations with due dates and payment tracking.
- **`Receipt` & `ReceiptItem`**: Itemized OCR scans with merchant and price breakdowns.
- **`KvStore`**: Key-value pair storage for configuration and user preferences.

---

## ⚡ 5. Build, Verification & Tooling

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Bundler & Dev Server** | Vite 6 | Fast HMR development and optimized rollup production bundles |
| **Type Checker** | TypeScript (`tsc --noEmit`) | Strict compile-time safety and interface contracts |
| **Unit Testing** | Vitest | Fast test execution for mathematical algorithms and scoring logic |
| **PDF Generation** | jsPDF | Structured client-side document compilation |
| **Charts & Graphs** | Recharts (SVG-based) | Responsive, hardware-accelerated financial visualizations |
