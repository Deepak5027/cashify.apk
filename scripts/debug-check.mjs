/**
 * Debug startup checker — verifies frontend/backend reachability.
 * Hypotheses:
 *   H1: Vite dev server not running on 5174
 *   H2: Backend not running on 4000
 *   H3: Wrong project directory (no package.json)
 *   H4: Database not initialized (backend /health ok but /auth/me fails without DB)
 */
import { existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const LOG_URL = 'http://127.0.0.1:7561/ingest/a6b51cb1-8bc9-48a5-bec1-7a3a938dc650';
const SESSION = '1565aa';

function log(hypothesisId, location, message, data) {
  fetch(LOG_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Debug-Session-Id': SESSION },
    body: JSON.stringify({ sessionId: SESSION, hypothesisId, location, message, data, timestamp: Date.now(), runId: 'startup-check' }),
  }).catch(() => {});
}

async function probe(url) {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(3000) });
    return { ok: res.ok, status: res.status };
  } catch (err) {
    return { ok: false, error: err.code || err.message };
  }
}

const hasPackage = existsSync(join(root, 'package.json'));
log('H3', 'debug-check.mjs:35', 'project directory check', { hasPackage, root });

const frontend = await probe('http://localhost:5174/');
log('H1', 'debug-check.mjs:38', 'frontend probe :5174', frontend);

const backendHealth = await probe('http://localhost:4000/health');
log('H2', 'debug-check.mjs:41', 'backend probe :4000/health', backendHealth);

console.log('Debug startup check:');
console.log('  package.json found:', hasPackage);
console.log('  frontend :5174 ->', frontend.ok ? 'OK' : frontend.error || `HTTP ${frontend.status}`);
console.log('  backend  :4000 ->', backendHealth.ok ? 'OK' : backendHealth.error || `HTTP ${backendHealth.status}`);

if (!frontend.ok) {
  console.log('\nFix: cd Aidailycashmanagement-main && npm run dev');
}
if (!backendHealth.ok) {
  console.log('\nFix: cd Aidailycashmanagement-main && npm run dev:server');
}
