import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router';
import { toast } from 'sonner';
import { authService } from '../../services/auth';
import { supabase } from '../../utils/supabase/client';

export default function AuthCallback() {
  const navigate = useNavigate();
  const handled = useRef(false);

  useEffect(() => {
    if (handled.current) return;
    handled.current = true;

    async function handleCallback() {
      try {
        console.log('[AuthCallback] Processing OAuth callback...');
        console.log('[AuthCallback] Hash:', window.location.hash);
        console.log('[AuthCallback] Search:', window.location.search);

        // 1. Direct extract from Hash (#access_token=...)
        let accessToken: string | null = null;
        if (window.location.hash) {
          const hashParams = new URLSearchParams(window.location.hash.substring(1));
          accessToken = hashParams.get('access_token');
        }

        // 2. Direct extract from Search (?token=... or ?code=...)
        if (!accessToken && window.location.search) {
          const searchParams = new URLSearchParams(window.location.search);
          accessToken = searchParams.get('token') || searchParams.get('access_token');
        }

        // 3. Fallback: Check Supabase session
        if (!accessToken) {
          const { data: { session } } = await supabase.auth.getSession();
          accessToken = session?.access_token || null;
        }

        // 4. Wait up to 3 seconds for Supabase onAuthStateChange if token is still loading
        if (!accessToken) {
          console.log('[AuthCallback] Waiting for Supabase async session detection...');
          await new Promise<void>((resolve) => {
            const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
              if (session?.access_token) {
                accessToken = session.access_token;
                subscription.unsubscribe();
                resolve();
              }
            });
            setTimeout(() => {
              subscription.unsubscribe();
              resolve();
            }, 3000);
          });
        }

        if (accessToken) {
          console.log('[AuthCallback] Session established, syncing user...');
          const isValid = await authService.handleOAuthCallback(accessToken);
          const state = authService.getState();

          if (isValid && state.isAuthenticated && state.user) {
            console.log('[AuthCallback] Authentication verified successfully for user:', state.user.email);
            toast.success(`Welcome, ${state.user.name || state.user.email || 'User'}!`);
            navigate('/app', { replace: true });
            return;
          }
        }

        console.warn('[AuthCallback] No valid session established. Clearing token and redirecting to /login.');
        localStorage.removeItem('token');
        toast.error('Authentication failed. Please try signing in again.');
        navigate('/login', { replace: true });
      } catch (err: any) {
        console.error('[AuthCallback] Unhandled error during auth callback:', err);
        localStorage.removeItem('token');
        toast.error('Sign-in failed. Please try again.');
        navigate('/login', { replace: true });
      }
    }

    handleCallback();
  }, [navigate]);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
      <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
      <p className="text-gray-600 text-sm font-medium">Completing sign-in…</p>
    </div>
  );
}
