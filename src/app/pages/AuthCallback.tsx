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

    async function exchangeCode() {
      try {
        const params = new URLSearchParams(window.location.search);
        const token = params.get('token');

        // Check if Supabase handled OAuth session automatically
        const { data: { session } } = await supabase.auth.getSession();
        
        if (session || token) {
          await authService.handleOAuthCallback(token || session?.access_token);
          const state = authService.getState();
          toast.success(`Welcome, ${state.user?.name || state.user?.email || 'user'}!`);
          navigate('/app', { replace: true });
          return;
        }

        toast.error('Authentication failed. No session active.');
        navigate('/login', { replace: true });
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
