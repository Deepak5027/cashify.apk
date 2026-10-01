import apiClient from '../utils/apiClient';
import { supabase } from '../utils/supabase/client';

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
      // 1. Prioritize active local token (custom JWT or active session token)
      const token = localStorage.getItem('token');
      if (token) {
        const res = await apiClient.get('/auth/me');
        if (res && res.user) {
          this.state = { user: res.user, accessToken: token, isAuthenticated: true };
          this.notifyListeners();
          return res.user;
        }
      }

      // 2. Fallback: Check Supabase session if no valid local token exists
      const { data: { session } } = await supabase.auth.getSession();
      if (session && session.access_token) {
        localStorage.setItem('token', session.access_token);
        const res = await apiClient.get('/auth/me');
        if (res && res.user) {
          this.state = { user: res.user, accessToken: session.access_token, isAuthenticated: true };
          this.notifyListeners();
          return res.user;
        }
      }
    } catch (err) {
      console.error('Session refresh error:', err);
    }
    this.state = { user: null, accessToken: null, isAuthenticated: false };
    this.notifyListeners();
    return null;
  }

  private async init() {
    await this.refreshUser();

    // Listen to Supabase auth state changes
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.access_token) {
        localStorage.setItem('token', session.access_token);
        await this.refreshUser();
      } else if (event === 'SIGNED_OUT') {
        const currentToken = localStorage.getItem('token');
        if (currentToken) {
          const res = await apiClient.get('/auth/me');
          if (res && res.user) return; // Local backend session is still active
        }
        localStorage.removeItem('token');
        this.state = { user: null, accessToken: null, isAuthenticated: false };
        this.notifyListeners();
      }
    });
  }

  async signInWithGoogle(): Promise<{ success: boolean; error?: string }> {
    try {
      const redirectUrl = `${window.location.origin}/auth/callback`;
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: redirectUrl,
        },
      });

      if (error || !data?.url) {
        console.log('[Auth] Using backend Express Google OAuth endpoint.');
        const baseUrl = apiClient.getApiBaseUrl();
        window.location.href = `${baseUrl}/auth/google?redirect=${encodeURIComponent(window.location.origin)}`;
        return { success: true };
      }

      return { success: true };
    } catch (err: any) {
      console.warn('[Auth] Exception during Google OAuth, redirecting to local backend auth:', err);
      const baseUrl = apiClient.getApiBaseUrl();
      window.location.href = `${baseUrl}/auth/google?redirect=${encodeURIComponent(window.location.origin)}`;
      return { success: true };
    }
  }

  async handleOAuthCallback(token?: string): Promise<boolean> {
    if (token) {
      localStorage.setItem('token', token);
    }
    const { data: { session } } = await supabase.auth.getSession();
    const activeToken = token || session?.access_token || localStorage.getItem('token');
    if (activeToken) {
      localStorage.setItem('token', activeToken);
    }
    const user = await this.refreshUser();
    return !!(user && this.state.isAuthenticated);
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
    await supabase.auth.signOut();
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
