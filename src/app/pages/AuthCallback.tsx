import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router';
import { toast } from 'sonner';
import { authService } from '../../services/auth';

/**
 * Handles the OAuth redirect from Google (and any other provider).
 * Supabase appends a code + state to the URL. Calling getSession()
 * here triggers the PKCE exchange and establishes a full session.
 * onAuthStateChange in AuthService fires automatically, updating global auth state.
 */
export default function AuthCallback() {
  const navigate = useNavigate();
  const handled = useRef(false);

  useEffect(() => {
    if (handled.current) return;
    handled.current = true;

    async function exchangeCode() {
      try {
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token');
        if (!token) {
          toast.error('Authentication failed. No token received.');
          navigate('/login', { replace: true });
          return;
        }

        await authService.handleOAuthCallback(token);
        const state = authService.getState();
        toast.success(`Welcome, ${state.user?.name || state.user?.email || 'user'}!`);
        navigate('/app', { replace: true });
      } catch (err: any) {
        console.error('Unexpected callback error:', err);
        toast.error('Something went wrong. Please try again.');
        navigate('/login', { replace: true });
      }
    }

    exchangeCode();
  }, [navigate]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
      <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
      <p className="text-gray-600 text-sm font-medium">Completing sign-in…</p>
    </div>
  );
}
