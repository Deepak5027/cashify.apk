import http from 'k6/http';
import { check, sleep } from 'k6';

// 1. Define Baseline Load Test Options (100 Virtual Users for 1 Minute)
export const options = {
  vus: 100,
  duration: '1m',
  thresholds: {
    // Failure rate under 5%
    'http_req_failed': ['rate<0.05'],
    // 95% of requests must complete under 1.5 seconds (1500ms)
    'http_req_duration': ['p(95)<1500'],
  },
};

export default function () {
  const baseUrl = (__ENV.BACKEND_URL || 'http://127.0.0.1:5000').replace(/\/+$/, '');

  // Endpoints to exercise under normal concurrent load
  const endpoints = [
    '/api/health',
    '/api/dashboard/summary',
    '/api/transactions',
    '/api/budgets',
    '/api/cards'
  ];

  const targetPath = endpoints[Math.floor(Math.random() * endpoints.length)];
  const url = `${baseUrl}${targetPath}`;

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'k6-Baseline-LoadTester/1.0',
    },
    tags: { name: targetPath },
  };

  const res = http.get(url, params);

  // Assertions
  check(res, {
    'status is 200 or 401 (handled)': (r) => r.status === 200 || r.status === 401,
    'response time < 1500ms': (r) => r.timings.duration < 1500,
  });

  // Short user think-time between requests (100ms - 300ms)
  sleep(0.1 + Math.random() * 0.2);
}
