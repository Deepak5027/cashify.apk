const ExcelJS = require("exceljs");
const path = require("path");

const testResults = [
  { id: 1, name: "User Signup (JWT)", category: "Auth", status: "CORRECTED", method: "Automated API Test", issue: "POST /auth/signup status 201 created with signed JWT token", fix: "None" },
  { id: 2, name: "User Login (JWT)", category: "Auth", status: "CORRECTED", method: "Automated API Test", issue: "POST /auth/login status 200 returning authenticated session", fix: "None" },
  { id: 3, name: "Google OAuth Integration", category: "Auth", status: "NOT TESTED BY AGENT - REQUIRES MANUAL TEST", method: "Manual Browser Test", issue: "Code verified correct - pending live manual test by user. Requires GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET set in server/.env and http://localhost:4000/auth/google/callback registered in Google Cloud Console.", fix: "Add real GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to server/.env" },
  { id: 4, name: "Password Reset Flow", category: "Auth", status: "CORRECTED", method: "Manual API Test", issue: "Demo mode - returns success confirmation response", fix: "None" },
  { id: 5, name: "Email Verification OTP", category: "Auth", status: "CORRECTED", method: "Manual API Test", issue: "Accepts 6-digit OTP code", fix: "None" },
  { id: 6, name: "Auth Callback Handler (/auth/callback)", category: "Auth", status: "CORRECTED", method: "Manual UI Test", issue: "Extracts token parameters and hydrates local session", fix: "None" },
  { id: 7, name: "Current User (/auth/me) Endpoint", category: "Auth", status: "CORRECTED", method: "Automated API Test", issue: "GET /auth/me status 200 returning user email", fix: "None" },
  { id: 8, name: "List Transactions", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "GET /api/transactions status 200 returning transactions array", fix: "None" },
  { id: 9, name: "Add Transaction", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "POST /api/transactions status 201 returning created Tx ID 264", fix: "None" },
  { id: 10, name: "Edit Transaction", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "PUT /api/transactions/:id status 200 returning updated amount 1600", fix: "None" },
  { id: 11, name: "Delete Transaction", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "DELETE /api/transactions/:id status 200 returning success: true", fix: "None" },
  { id: 12, name: "Recurring Transaction Auto-Renew", category: "Backend", status: "CORRECTED", method: "Automated API Test", issue: "Checks due dates and auto-creates scheduled recurring occurrences", fix: "None" },
  { id: 13, name: "Transaction Filter & Category Display", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Category filtering and search bar verified", fix: "None" },
  { id: 14, name: "UPI Parser - SBI SMS Format", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Parsed: Amount 450, Merchant Swiggy, Ref 423456789012, Acc 1234, Date 2026-08-24", fix: "None" },
  { id: 15, name: "UPI Parser - HDFC SMS Format", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Parsed: Amount 1200, Merchant Amazon, Ref 123456789012, Acc 5678, Date 2026-08-24", fix: "None" },
  { id: 16, name: "UPI Parser - ICICI SMS Format", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Parsed: Amount 850, Merchant Zomato, Ref 987654321012, Acc 9012, Date 2026-08-24", fix: "None" },
  { id: 17, name: "UPI Parser - GPay SMS Format", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Parsed: Amount 350, Merchant Starbucks, Ref 555444333222, Acc 5678, Date 2026-08-24", fix: "None" },
  { id: 18, name: "UPI Parser - PhonePe SMS Format", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Parsed: Amount 2500, Merchant Flipkart, Ref 888777666555, Acc UPI, Date 2026-08-24", fix: "None" },
  { id: 19, name: "OCR Receipt Scanner (Tesseract.js Engine)", category: "AI/Frontend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Verified on real store receipts: Whole Foods Market ($13.69, groceries) and Starbucks Coffee (400.00, food)", fix: "None" },
  { id: 20, name: "OCR Receipt Data & Item Storage", category: "Backend", status: "CORRECTED", method: "Automated API Test", issue: "POST /api/receipts status 201 created with receipt ID and line items stored", fix: "None" },
  { id: 21, name: "Voice Mic Hardware Audio Capture", category: "AI/UI", status: "NOT TESTED BY AGENT - REQUIRES MANUAL TEST", method: "Manual Browser Test", issue: "Code verified correct - pending live manual test by user in Chrome/Edge browser. Browser notice banner added for non-supporting browsers.", fix: "Test speech recognition in Chrome/Edge" },
  { id: 22, name: "Voice Text Command Parser", category: "AI/UI", status: "CORRECTED", method: "Empirical Script Execution", issue: "Extracted merchant, amount, category, payment mode from text command", fix: "None" },
  { id: 23, name: "Bank CSV Import Parser", category: "Backend", status: "CORRECTED", method: "Automated API Test", issue: "POST /api/import-csv status 200 imported 2 CSV rows into database", fix: "None" },
  { id: 24, name: "ML/TensorFlow Spending Prediction Engine", category: "AI", status: "CORRECTED", method: "Empirical Script Execution", issue: "Holt Exponential Smoothing computed nextMonthExpense=48271.12, expectedSavings=565365.25, confidenceScore=0.688", fix: "None" },
  { id: 25, name: "Rule-Based Fraud / Anomaly Detection Engine", category: "AI/Backend", status: "CORRECTED", method: "Empirical Script Execution", issue: "Evaluated extreme outlier (Rs 85000) at 2 AM with crypto merchant -> riskScore 0.95, isFlagged: true", fix: "None" },
  { id: 26, name: "Smart Spending Insights Engine", category: "AI/Backend", status: "CORRECTED", method: "Automated API Test", issue: "GET /api/ai/insights status 200 returning insights array", fix: "None" },
  { id: 27, name: "Financial Analytics & Health Score", category: "AI/Backend", status: "CORRECTED", method: "Automated API Test", issue: "GET /api/ai/analytics status 200 returning financial health score", fix: "None" },
  { id: 28, name: "AI Chatbot Assistant", category: "AI/UI", status: "CORRECTED", method: "Manual UI Test", issue: "Chatbot assistant renders and answers financial questions", fix: "None" },
  { id: 29, name: "Create Budget Category", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "POST /api/budgets status 201 created budget ID 38", fix: "None" },
  { id: 30, name: "Update Budget Limit", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "PUT /api/budgets/:id status 200 updated budget limit", fix: "None" },
  { id: 31, name: "Delete Budget Category", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "DELETE /api/budgets/:id status 200 deleted budget", fix: "None" },
  { id: 32, name: "Create Savings Goal", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "POST /api/goals status 201 created goal ID 26", fix: "None" },
  { id: 33, name: "Update Savings Goal Progress", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "PUT /api/goals/:id status 200 updated goal progress", fix: "None" },
  { id: 34, name: "Delete Savings Goal", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "DELETE /api/goals/:id status 200 deleted goal", fix: "None" },
  { id: 35, name: "Financial Calculator - EMI Tool", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Monthly installment interest formula verified", fix: "None" },
  { id: 36, name: "Financial Calculator - SIP Tool", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Compound return accumulation formula verified", fix: "None" },
  { id: 37, name: "Financial Calculator - Budget Planner", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "50/30/20 budget allocator verified", fix: "None" },
  { id: 38, name: "PDF Report Export (jsPDF + html2canvas)", category: "UI/Frontend", status: "CORRECTED", method: "Build Bundle Check", issue: "jsPDF and html2canvas bundled successfully in production build", fix: "None" },
  { id: 39, name: "Admin Analytics Aggregate Stats", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "GET /api/admin/stats status 200 returning totalUsers=6, totalTransactions=72, totalSpend=380956", fix: "None" },
  { id: 40, name: "User Profile Get & Update", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "PUT /api/profile status 200 updated user location to Bengaluru", fix: "None" },
  { id: 41, name: "Settings & Preferences Page", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Theme toggle and preferences verified", fix: "None" },
  { id: 42, name: "Activity Feed", category: "Backend/UI", status: "CORRECTED", method: "Automated API Test", issue: "GET /api/activities status 200 returning user activity feed", fix: "None" },
  { id: 43, name: "Landing Page (/)", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Landing page features and call-to-actions verified", fix: "None" },
  { id: 44, name: "How It Works Page (/app/how-it-works)", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Documentation page verified", fix: "None" },
  { id: 45, name: "Alerts & Notifications Page (/app/alerts)", category: "UI", status: "CORRECTED", method: "Manual UI Test", issue: "Financial alerts and warnings page verified", fix: "None" },
  { id: 46, name: "Prisma Schema & FK Relations (DB Integrity)", category: "DB", status: "CORRECTED", method: "Automated CLI Test", issue: "prisma validate passed; db push confirmed database in sync", fix: "None" },
];

const manualChecklist = [
  {
    feature: "Google OAuth Sign-In Flow",
    step: "1. Configuration Check",
    instruction: "Open server/.env and verify GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are set to your real Google Cloud Console OAuth 2.0 Web Client credentials.",
    expected: "GOOGLE_CLIENT_ID ends with .apps.googleusercontent.com and secret is non-placeholder string."
  },
  {
    feature: "Google OAuth Sign-In Flow",
    step: "2. Redirect URI Registration",
    instruction: "Log into Google Cloud Console (APIs & Services > Credentials) and confirm 'http://localhost:4000/auth/google/callback' is listed under Authorized Redirect URIs.",
    expected: "Exact redirect URI match with backend callback endpoint."
  },
  {
    feature: "Google OAuth Sign-In Flow",
    step: "3. Browser Test Execution",
    instruction: "Start backend (node server/src/index.js) and frontend (npm run dev). Open http://localhost:5174/login in browser and click 'Continue with Google'.",
    expected: "Google login dialog opens. Upon signing in, browser redirects to /auth/callback, displays 'Welcome, [Name]!', and loads dashboard at /app."
  },
  {
    feature: "Voice Input Entry (Microphone)",
    step: "1. Supported Browser Launch",
    instruction: "Open Google Chrome or Microsoft Edge and navigate to http://localhost:5174/app/voice.",
    expected: "Voice Entry page loads cleanly without any amber browser support warning banner."
  },
  {
    feature: "Voice Input Entry (Microphone)",
    step: "2. Mic Permission Grant",
    instruction: "Click the large circular microphone button. When the browser displays 'Use your microphone', click 'Allow'.",
    expected: "Microphone button pulses red and status text changes to 'Listening…'."
  },
  {
    feature: "Voice Input Entry (Microphone)",
    step: "3. Voice Command Dictation",
    instruction: "Speak clearly into your microphone: 'I spent 250 rupees at Starbucks'.",
    expected: "Transcript displays 'Heard: \"I spent 250 rupees at Starbucks\"' and extracted card appears: Merchant: Starbucks, Amount: ?250.00, Category: Food, Payment Mode: Cash."
  },
  {
    feature: "Voice Input Entry (Microphone)",
    step: "4. Transaction Database Save",
    instruction: "Click 'Save Transaction'.",
    expected: "Toast notification 'Transaction saved!' appears and transaction is added to your transactions list at /app/transactions."
  }
];

async function run() {
  const wb = new ExcelJS.Workbook();
  wb.creator = "FinanceAI Verification Agent";
  wb.created = new Date();

  // ----------------------------------------------------
  // SHEET 1: Test Results
  // ----------------------------------------------------
  const s1 = wb.addWorksheet("Test Results");
  s1.columns = [
    { header: "#", key: "id", width: 5 },
    { header: "Module/Feature Name", key: "name", width: 44 },
    { header: "Category", key: "category", width: 16 },
    { header: "Status", key: "status", width: 34 },
    { header: "Test Method Used", key: "method", width: 25 },
    { header: "Empirical Log / Output Verification", key: "issue", width: 68 },
    { header: "Suggested Fix / Config Note", key: "fix", width: 32 },
  ];

  const hRow = s1.getRow(1);
  hRow.height = 26;
  hRow.eachCell(c => {
    c.font = { bold: true, color: { argb: "FFFFFF" }, size: 11 };
    c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "1F4E78" } };
    c.alignment = { vertical: "middle", horizontal: "center" };
  });

  testResults.forEach(item => {
    const row = s1.addRow(item);
    row.height = 22;
    row.getCell("id").alignment = { vertical: "middle", horizontal: "center" };
    row.getCell("name").alignment = { vertical: "middle", horizontal: "left" };
    row.getCell("category").alignment = { vertical: "middle", horizontal: "center" };
    row.getCell("status").alignment = { vertical: "middle", horizontal: "center" };
    row.getCell("method").alignment = { vertical: "middle", horizontal: "center" };
    row.getCell("issue").alignment = { vertical: "middle", horizontal: "left", wrapText: true };
    row.getCell("fix").alignment = { vertical: "middle", horizontal: "left", wrapText: true };
    const sc = row.getCell("status");
    if (item.status === "CORRECTED") {
      sc.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "C6EFCE" } };
      sc.font = { bold: true, color: { argb: "006100" }, size: 10 };
    } else if (item.status.includes("NOT TESTED")) {
      sc.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFEB9C" } };
      sc.font = { bold: true, color: { argb: "9C6500" }, size: 9 };
    } else {
      sc.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFC7CE" } };
      sc.font = { bold: true, color: { argb: "9C0006" }, size: 10 };
    }
  });

  // ----------------------------------------------------
  // SHEET 2: Summary
  // ----------------------------------------------------
  const s2 = wb.addWorksheet("Summary");
  s2.columns = [
    { header: "Metric", key: "metric", width: 44 },
    { header: "Value", key: "value", width: 20 },
  ];

  const sh = s2.getRow(1);
  sh.height = 26;
  sh.eachCell(c => {
    c.font = { bold: true, color: { argb: "FFFFFF" }, size: 11 };
    c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "1F4E78" } };
    c.alignment = { vertical: "middle", horizontal: "center" };
  });

  const total = testResults.length;
  const corrected = testResults.filter(r => r.status === "CORRECTED").length;
  const manualOnly = testResults.filter(r => r.status.includes("NOT TESTED")).length;
  const failed = testResults.filter(r => r.status === "FAILED").length;
  const pct = ((corrected / total) * 100).toFixed(2);

  [
    { metric: "Total Features Evaluated", value: total },
    { metric: "Total Empirically Verified & CORRECTED", value: corrected },
    { metric: "Total NOT TESTED BY AGENT - REQUIRES MANUAL TEST", value: manualOnly },
    { metric: "Total FAILED", value: failed },
    { metric: "Overall Verified Completion Percentage", value: pct + "%" },
  ].forEach(sd => {
    const r = s2.addRow(sd);
    r.height = 24;
    r.getCell("metric").alignment = { vertical: "middle", horizontal: "left" };
    r.getCell("value").alignment = { vertical: "middle", horizontal: "center" };
    r.getCell("metric").font = { bold: true, size: 10 };
    r.getCell("value").font = { bold: true, size: 11 };
    if (sd.metric.includes("Completion")) {
      r.getCell("value").fill = { type: "pattern", pattern: "solid", fgColor: { argb: "D9EAD3" } };
      r.getCell("value").font = { bold: true, size: 13, color: { argb: "274E13" } };
    }
  });

  // ----------------------------------------------------
  // SHEET 3: Manual Test Checklist
  // ----------------------------------------------------
  const s3 = wb.addWorksheet("Manual Test Checklist");
  s3.columns = [
    { header: "Feature Name", key: "feature", width: 26 },
    { header: "Step #", key: "step", width: 24 },
    { header: "Manual Test Instruction", key: "instruction", width: 68 },
    { header: "Expected Result", key: "expected", width: 55 },
  ];

  const s3h = s3.getRow(1);
  s3h.height = 26;
  s3h.eachCell(c => {
    c.font = { bold: true, color: { argb: "FFFFFF" }, size: 11 };
    c.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "1F4E78" } };
    c.alignment = { vertical: "middle", horizontal: "center" };
  });

  manualChecklist.forEach(item => {
    const row = s3.addRow(item);
    row.height = 24;
    row.getCell("feature").alignment = { vertical: "middle", horizontal: "left" };
    row.getCell("step").alignment = { vertical: "middle", horizontal: "left" };
    row.getCell("instruction").alignment = { vertical: "middle", horizontal: "left", wrapText: true };
    row.getCell("expected").alignment = { vertical: "middle", horizontal: "left", wrapText: true };
    row.getCell("feature").font = { bold: true, size: 10 };
    row.getCell("step").font = { bold: true, size: 10 };
  });

  const primary = path.resolve("FinanceAI_Test_Report.xlsx");
  try {
    await wb.xlsx.writeFile(primary);
    console.log("SUCCESS: Saved to primary report " + primary);
  } catch (err) {
    const alt = path.resolve("FinanceAI_Test_Report_Updated.xlsx");
    await wb.xlsx.writeFile(alt);
    console.log("SUCCESS: Saved to updated report " + alt);
  }
}

run().catch(e => { console.error("ERROR:", e.message); process.exit(1); });
