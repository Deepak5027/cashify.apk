export function getApiBaseUrl(): string {
  if (typeof window === 'undefined') return 'https://financeai-api-ba5p.onrender.com';
  const customUrl = localStorage.getItem('custom_api_url');
  if (customUrl) return customUrl.replace(/\/$/, '');

  const envUrl = (import.meta as any).env?.VITE_API_BASE;
  if (envUrl) return envUrl.replace(/\/$/, '');

  return 'https://financeai-api-ba5p.onrender.com';
}

function getToken() {
  try { return localStorage.getItem('token'); } catch (e) { return null; }
}

async function request(path: string, opts: any = {}) {
  const headers: Record<string,string> = { 'Content-Type': 'application/json' };
  const token = getToken();
  if (token) headers['Authorization'] = 'Bearer ' + token;

  const base = getApiBaseUrl();
  let res: Response;
  try {
    res = await fetch((base || '') + path, {
      headers,
      ...opts,
      body: opts.body ? JSON.stringify(opts.body) : undefined,
      credentials: 'include',
    });
  } catch (netErr: any) {
    return {
      ok: false,
      error: netErr?.message || 'Network request failed. Please check if the server is running on port 4000.',
      message: netErr?.message || 'Network request failed',
      status: 0,
    };
  }

  const text = await res.text();
  let parsed: any;
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch (e) {
    parsed = { raw: text };
  }

  if (!res.ok) {
    const errorMsg =
      parsed?.message ||
      parsed?.error ||
      (typeof parsed === 'string' ? parsed : '') ||
      `HTTP ${res.status}: ${res.statusText || 'Request failed'}`;

    return {
      ...parsed,
      error: errorMsg,
      message: errorMsg,
      status: res.status,
      ok: false,
    };
  }
  return parsed;
}

export default {
  getApiBaseUrl,
  get: (path: string) => request(path, { method: 'GET' }),
  post: (path: string, body?: any) => request(path, { method: 'POST', body }),
  put: (path: string, body?: any) => request(path, { method: 'PUT', body }),
  del: (path: string) => request(path, { method: 'DELETE' }),
  delete: (path: string) => request(path, { method: 'DELETE' }),
};
