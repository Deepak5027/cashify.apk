const fs = require('fs');
const path = require('path');

function generateMobileHtmlReport(summaryData, testResults, outputPath) {
  const total = summaryData.total || testResults.length;
  const passed = summaryData.passed || testResults.filter(t => t.status === 'PASSED').length;
  const failed = summaryData.failed || testResults.filter(t => t.status === 'FAILED').length;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : '0';
  const duration = summaryData.duration || 0;

  const categories = {};
  testResults.forEach(test => {
    const cat = test.category || 'Mobile General';
    if (!categories[cat]) categories[cat] = { total: 0, passed: 0, failed: 0 };
    categories[cat].total++;
    if (test.status === 'PASSED') categories[cat].passed++;
    else categories[cat].failed++;
  });

  const catRows = Object.entries(categories).map(([name, s]) => `
    <tr>
      <td style="font-weight: 600; color: #E2E8F0;">${name}</td>
      <td><span class="badge badge-tot">${s.total}</span></td>
      <td><span class="badge badge-pass">${s.passed}</span></td>
      <td><span class="badge ${s.failed > 0 ? 'badge-fail' : 'badge-neutral'}">${s.failed}</span></td>
      <td>${((s.passed / s.total) * 100).toFixed(0)}%</td>
    </tr>
  `).join('');

  const tcRows = testResults.slice(0, 250).map(t => `
    <tr>
      <td><code>${t.id}</code></td>
      <td>${t.category}</td>
      <td>${t.name}</td>
      <td><span class="badge ${t.status === 'PASSED' ? 'badge-pass' : 'badge-fail'}">${t.status}</span></td>
      <td>${t.duration}ms</td>
    </tr>
  `).join('');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Aidailycash Mobile Appium Test Execution Report</title>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0A0D14;
      --card: #131A26;
      --border: #1E293B;
      --cyan: #06B6D4;
      --green: #10B981;
      --red: #EF4444;
      --text: #F8FAFC;
      --muted: #94A3B8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
    body { background: var(--bg); color: var(--text); padding: 32px 20px; }
    .container { max-width: 1280px; margin: 0 auto; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); padding-bottom: 24px; margin-bottom: 30px; }
    .header h1 { font-size: 26px; font-weight: 700; background: linear-gradient(135deg, #38BDF8, #A855F7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 30px; }
    .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
    .card-title { font-size: 12px; text-transform: uppercase; color: var(--muted); font-weight: 600; margin-bottom: 6px; }
    .card-value { font-size: 28px; font-weight: 700; }
    .card.pass { border-top: 3px solid var(--green); }
    .card.fail { border-top: 3px solid var(--red); }
    .card.info { border-top: 3px solid var(--cyan); }
    .box { background: var(--card); border: 1px solid var(--border); border-radius: 10px; overflow: hidden; margin-bottom: 30px; }
    table { width: 100%; border-collapse: collapse; font-size: 14px; text-align: left; }
    th { background: #0F172A; padding: 12px 16px; color: var(--muted); font-size: 12px; text-transform: uppercase; }
    td { padding: 11px 16px; border-bottom: 1px solid var(--border); }
    tr:last-child td { border-bottom: none; }
    .badge { display: inline-block; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
    .badge-pass { background: rgba(16, 185, 129, 0.15); color: #34D399; }
    .badge-fail { background: rgba(239, 68, 68, 0.15); color: #F87171; }
    .badge-tot { background: rgba(56, 189, 248, 0.15); color: #38BDF8; }
    .badge-neutral { background: rgba(148, 163, 184, 0.15); color: #94A3B8; }
    code { font-family: 'JetBrains Mono', monospace; font-size: 11px; color: #38BDF8; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <h1>Aidailycash Mobile Appium Suite</h1>
        <p style="color: var(--muted); margin-top: 4px;">Android Automated Test Execution Report (1,111 Cases)</p>
      </div>
      <div style="text-align: right; color: var(--muted); font-size: 13px;">
        <div><strong>Runner:</strong> Appium / UiAutomator2</div>
        <div><strong>Platform:</strong> Android (API 29+)</div>
        <div><strong>Timestamp:</strong> ${new Date().toISOString()}</div>
      </div>
    </div>

    <div class="grid">
      <div class="card info">
        <div class="card-title">Total Tests</div>
        <div class="card-value" style="color: #38BDF8;">${total}</div>
      </div>
      <div class="card pass">
        <div class="card-title">Passed Tests</div>
        <div class="card-value" style="color: #34D399;">${passed}</div>
      </div>
      <div class="card fail">
        <div class="card-title">Failed Tests</div>
        <div class="card-value" style="color: ${failed > 0 ? '#F87171' : '#94A3B8'};">${failed}</div>
      </div>
      <div class="card info">
        <div class="card-title">Pass Rate</div>
        <div class="card-value" style="color: #A855F7;">${passRate}%</div>
      </div>
    </div>

    <h3 style="margin-bottom: 12px;">📊 Category Breakdown</h3>
    <div class="box">
      <table>
        <thead>
          <tr>
            <th>Category</th>
            <th>Total</th>
            <th>Passed</th>
            <th>Failed</th>
            <th>Pass Rate</th>
          </tr>
        </thead>
        <tbody>
          ${catRows}
        </tbody>
      </table>
    </div>

    <h3 style="margin-bottom: 12px;">🔍 Test Cases Sample (Showing 250 / ${total})</h3>
    <div class="box">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Category</th>
            <th>Test Assertion</th>
            <th>Status</th>
            <th>Duration</th>
          </tr>
        </thead>
        <tbody>
          ${tcRows}
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>`;

  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(outputPath, html, 'utf8');
  console.log(`[Mobile HTML] Report written to: ${outputPath}`);
}

module.exports = { generateMobileHtmlReport };
