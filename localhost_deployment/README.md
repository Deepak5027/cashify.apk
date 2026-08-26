# 🚀 Localhost Deployment Guide

This directory (`localhost_deployment/`) contains the complete self-contained deployment package for both the **Frontend** and **Backend**.

---

## 🔗 Live Localhost Deployment Links

### 💻 1. Frontend Web Application
- **Link**: [http://localhost:5174](http://localhost:5174)
- **Description**: Production compiled React + Vite interface with 3D Landing Page, Financial Dashboard, Transactions, Voice Input, and OCR Scanner.

---

### ⚙️ 2. Backend REST API
- **Link**: [http://localhost:4000](http://localhost:4000)
- **Health Check**: [http://localhost:4000/health](http://localhost:4000/health)
- **Description**: Express.js server providing authentication (`/auth/login`, `/auth/signup`, `/auth/me`), transactions REST API (`/api/transactions`), and ML predictions.

---

### 🗄️ 3. Database GUI (Prisma Studio)
- **Link**: [http://localhost:5555](http://localhost:5555)
- **Database File**: `backend/prisma/dev.db` (SQLite)
- **Description**: Interactive database manager to view and edit `User`, `Transaction`, `Budget`, and `Goal` tables.

---

### 🛡️ 4. In-App Admin Dashboard
- **Link**: [http://localhost:5174/app/admin](http://localhost:5174/app/admin)
- **Description**: Real-time system monitoring, active user metrics, and security anomaly reports.

---

## 📂 Folder Structure

```
localhost_deployment/
├── frontend_dist/         # Compiled production frontend build
├── backend/               # Backend Express API & SQLite Database
├── server.js              # Single-port unified deployment server
├── start-all.bat          # 1-Click launcher script for Windows
└── README.md              # Deployment guide & access links
```

---

## ⚡ How to Start the Local Deployment

Double-click `start-all.bat` or run:

```bash
cd localhost_deployment
node server.js
```
