
## 📈 API Baseline / Load Testing Results (k6)

### 🎯 Test Configuration
- **Virtual Users (VUs):** **100 concurrent users**
- **Test Duration:** **1 minute (continuous)**
- **Target System:** Aidailycash Backend API

---

### 📊 Performance Summary Table

| Metric | Measured Value | Target SLA / Baseline | Gate Status |
| :--- | :--- | :--- | :---: |
| **Throughput (RPS)** | **114.0 req/sec** | > 50 req/sec | ✅ **PASS** |
| **Total Requests Sent** | **6840 requests** | ~ 5,000+ requests | ✅ **PASS** |
| **Average Response Time** | **245.80 ms** | < 300 ms | ✅ **PASS** |
| **Min Response Time (Fastest)** | **48.20 ms** | Baseline (< 100ms) | ✅ **PASS** |
| **Max Response Time (Slowest)** | **1220.50 ms** | < 1,500 ms | ✅ **PASS** |
| **95th Percentile (p95)** | **420.30 ms** | < 1,500 ms SLA | ✅ **PASS** |
| **Request Failure Rate** | **0.00%** | < 5.0% threshold | ✅ **PASS** |
| **Assertions Pass Rate** | **100.0%** | > 99.0% | ✅ **PASS** |

---

### 💡 Performance Insights
- The API handled continuous traffic with an average throughput of **114.0 requests/second**.
- Response times stayed fast and well within SLA limits, with 95% of requests completed under **420.30ms**.
- Zero unexpected connection drops or server throttling occurred under 100 concurrent virtual users.
