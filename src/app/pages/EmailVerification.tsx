import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card } from '../components/ui/card';
import { Label } from '../components/ui/label';
import { toast } from 'sonner';
import { TrendingUp, KeyRound, RefreshCw } from 'lucide-react';
import { authService } from '../../services/auth';

export default function EmailVerification() {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [resendLoading, setResendLoading] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || '';

  useEffect(() => {
    if (!email) {
      navigate('/signup');
    }
  }, [email, navigate]);

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();

    if (code.length !== 6) {
      toast.error('Please enter a valid 6-digit code');
      return;
    }

    setLoading(true);

    try {
      const result = await authService.verifySignupOTP(email, code);

      if (!result.success) {
        toast.error(result.error || 'Verification failed');
      } else {
        toast.success('Email verified successfully!');
        navigate('/app');
      }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setResendLoading(true);

    try {
      const result = await authService.resendVerificationEmail(email);

      if (!result.success) {
        toast.error(result.error || 'Failed to resend code');
      } else {
        toast.success('Verification code resent!');
      }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred');
    } finally {
      setResendLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md p-8">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full mb-4">
            <TrendingUp className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            FinanceAI
          </h1>
          <p className="text-gray-600 mt-2">Verify your email</p>
        </div>

        <div className="mb-6 p-4 bg-blue-50 rounded-lg">
          <p className="text-sm text-gray-700 text-center">
            We've sent a 6-digit verification code to
          </p>
          <p className="text-sm font-semibold text-gray-900 text-center mt-1">
            {email}
          </p>
        </div>

        <form onSubmit={handleVerify} className="space-y-4">
          <div>
            <Label htmlFor="code">Verification Code</Label>
            <div className="relative mt-1">
              <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                id="code"
                type="text"
                placeholder="000000"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                className="pl-10 text-center text-2xl tracking-widest font-mono"
                required
                maxLength={6}
                autoFocus
              />
            </div>
          </div>

          <Button
            type="submit"
            className="w-full bg-gradient-to-r from-blue-500 to-purple-600"
            disabled={loading || code.length !== 6}
          >
            {loading ? 'Verifying...' : 'Verify Email'}
          </Button>

          <Button
            type="button"
            variant="outline"
            className="w-full"
            onClick={handleResend}
            disabled={resendLoading}
          >
            {resendLoading ? (
              <>
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                Sending...
              </>
            ) : (
              <>
                <RefreshCw className="w-4 h-4 mr-2" />
                Resend Code
              </>
            )}
          </Button>
        </form>

        <div className="mt-6 text-center">
          <p className="text-xs text-gray-500">
            Didn't receive the code? Check your spam folder or click resend above.
          </p>
        </div>
      </Card>
    </div>
  );
}
