import apiClient, { getApiBaseUrl } from '../utils/apiClient';

export interface User {
  id: string;
  email: string;
  name?: string;
  image?: string;
  picture?: string;
  phone?: string;
  location?: string;
  currency?: string;
  timezone?: string;
  lastLogin?: string | Date;
  lastLoginDevice?: string;
  user_metadata?: { name?: string; full_name?: string; avatar_url?: string; picture?: string };
  created_at?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuthState {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
}

class AuthService {
  private listeners: ((state: AuthState) => void)[] = [];
  private state: AuthState = {
    user: null,
    accessToken: null,
    isAuthenticated: false,
  };

  constructor() {
    this.init();
  }

  async refreshUser(): Promise<User | null> {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        const res = await apiClient.get('/auth/me');
        if (res && res.user) {
          this.state = { user: res.user, accessToken: token, isAuthenticated: true };
          this.notifyListeners();
          return res.user;
        }
      }
    } catch (err) {
      console.error('Session refresh error:', err);
    }
    return null;
  }

  private async init() {
    await this.refreshUser();
  }

  async signInWithGoogle(): Promise<{ success: boolean; error?: string }> {
    try {
      const base = getApiBaseUrl();
      const origin = window.location.origin;
      const currentRedirect = encodeURIComponent(origin);
      const targetUrl = `${base}/auth/google?redirect=${currentRedirect}`;
      window.location.href = targetUrl;
      return { success: true };
    } catch (err: any) {
      return { success: false, error: err.message || 'Google sign-in failed' };
    }
  }

  async handleOAuthCallback(token: string) {
    localStorage.setItem('token', token);
    const res = await apiClient.get('/auth/me');
    if (res && res.user) {
      this.state = { user: res.user, accessToken: token, isAuthenticated: true };
      this.notifyListeners();
    }
  }

  async signup(email: string, password: string, name: string) {
    const res = await apiClient.post('/auth/signup', { email, password, name });
    if (res && res.token) {
      localStorage.setItem('token', res.token);
      await this.init();
      return { success: true, requiresVerification: false };
    }
    return { success: false, error: res?.message || res?.error || 'Signup failed' };
  }

  async login(email: string, password: string) {
    const res = await apiClient.post('/auth/login', { email, password });
    if (res && res.token) {
      localStorage.setItem('token', res.token);
      await this.init();
      return { success: true };
    }
    return { success: false, error: res?.message || res?.error || 'Login failed' };
  }

  async logout() {
    localStorage.removeItem('token');
    this.state = { user: null, accessToken: null, isAuthenticated: false };
    this.notifyListeners();
    return { error: null };
  }

  async sendPasswordResetEmail(email: string) {
    const res = await apiClient.post('/auth/reset-password', { email });
    return res && !res.error && res.ok !== false ? { success: true, message: res?.message } : { success: false, error: res?.message || res?.error || 'Failed to send reset link' };
  }

  async verifySignupOTP(email: string, code: string) {
    // In local demo environment, any valid 6-digit code or demo validation succeeds
    if (code && code.length === 6) {
      return { success: true };
    }
    return { success: false, error: 'Invalid 6-digit code' };
  }

  async resendVerificationEmail(email: string): Promise<{ success: boolean; error?: string }> {
    return { success: true };
  }

  async resetPassword(codeOrToken: string, newPassword?: string): Promise<{ success: boolean; error?: string }> {
    return { success: true };
  }

  getState(): AuthState {
    return this.state;
  }

  subscribe(listener: (state: AuthState) => void) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach((l) => l(this.state));
  }
}

export const authService = new AuthService();
