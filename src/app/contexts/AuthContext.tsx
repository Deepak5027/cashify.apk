import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { authService, User, AuthState } from '../../services/auth';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isAuthenticated: boolean;
  signUp: (email: string, password: string, name: string) => Promise<{ success: boolean; error?: string; requiresVerification?: boolean }>;
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signInWithGoogle: () => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<{ error?: any } | void>;
  refreshUser: () => Promise<User | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [authState, setAuthState] = useState<AuthState>(authService.getState());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Subscribe to all auth state changes (includes OAuth callback session)
    const unsubscribe = authService.subscribe((state) => {
      setAuthState(state);
      setLoading(false);
    });

    // Initial loading done — state was already hydrated by authService.init()
    const t = setTimeout(() => setLoading(false), 300);

    return () => {
      unsubscribe();
      clearTimeout(t);
    };
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user: authState.user,
        loading,
        isAuthenticated: authState.isAuthenticated,
        signUp: (email, password, name) => authService.signup(email, password, name),
        signIn: (email, password) => authService.login(email, password),
        signInWithGoogle: () => authService.signInWithGoogle(),
        signOut: async () => { await authService.logout(); },
        refreshUser: () => authService.refreshUser(),
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
