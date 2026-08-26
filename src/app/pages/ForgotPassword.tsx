import { useState } from 'react';
import { useNavigate, Link } from 'react-router';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Card } from '../components/ui/card';
import { Label } from '../components/ui/label';
import { toast } from 'sonner';
import { Lock, Mail, TrendingUp, ArrowLeft, KeyRound } from 'lucide-react';
import { authService } from '../../services/auth';

type Step = 'email' | 'verify' | 'reset';

export default function ForgotPassword() {
  const [step, setStep] = useState<Step>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const result = await authService.sendPasswordResetEmail(email);

      if (!result.success) {
        toast.error(result.error || 'Failed to send reset code');
      } else {
        toast.success('Reset code sent to your email!');
        setStep('verify');
      }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();

    if (code.length !== 6) {
      toast.error('Please enter a valid 6-digit code');
      return;
    }

    setStep('reset');
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();

    if (newPassword.length < 6) {
      toast.error('Password must be at least 6 characters');
      return;
    }

    if (newPassword !== confirmPassword) {
      toast.error('Passwords do not match');
      return;
    }

    setLoading(true);

    try {
      const result = await authService.resetPassword(code, newPassword);

      if (!result.success) {
        toast.error(result.error || 'Failed to reset password');
      } else {
        toast.success('Password reset successful! Please sign in.');
        navigate('/login');
      }
    } catch (error: any) {
      toast.error(error.message || 'An error occurred');
    } finally {
      setLoading(false);
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
          <p className="text-gray-600 mt-2">
            {step === 'email' && 'Reset your password'}
            {step === 'verify' && 'Verify your email'}
            {step === 'reset' && 'Set new password'}
          </p>
        </div>

        {step === 'email' && (
          <form onSubmit={handleSendCode} className="space-y-4">
            <div>
              <Label htmlFor="email">Email Address</Label>
              <div className="relative mt-1">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <Input
                  id="email"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="pl-10"
                  required
                />
              </div>
              <p className="text-xs text-gray-500 mt-2">
                We'll send a 6-digit verification code to your email
              </p>
            </div>

            <Button
              type="submit"
              className="w-full bg-gradient-to-r from-blue-500 to-purple-600"
              disabled={loading}
            >
              {loading ? 'Sending...' : 'Send Reset Code'}
            </Button>
          </form>
        )}

        {step === 'verify' && (
          <form onSubmit={handleVerifyCode} className="space-y-4">
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
                />
              </div>
              <p className="text-xs text-gray-500 mt-2">
                Enter the 6-digit code sent to {email}
              </p>
            </div>

            <Button
              type="submit"
              className="w-full bg-gradient-to-r from-blue-500 to-purple-600"
            >
              Verify Code
            </Button>

            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={() => setStep('email')}
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
          </form>
        )}

        {step === 'reset' && (
          <form onSubmit={handleResetPassword} className="space-y-4">
            <div>
              <Label htmlFor="newPassword">New Password</Label>
              <div className="relative mt-1">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <Input
                  id="newPassword"
                  type="password"
                  placeholder="••••••••"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="pl-10"
                  required
                  minLength={6}
                />
              </div>
            </div>

            <div>
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <div className="relative mt-1">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <Input
                  id="confirmPassword"
                  type="password"
                  placeholder="••••••••"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="pl-10"
                  required
                  minLength={6}
                />
              </div>
              {confirmPassword && newPassword !== confirmPassword && (
                <p className="text-xs text-red-500 mt-1">Passwords do not match</p>
              )}
            </div>

            <Button
              type="submit"
              className="w-full bg-gradient-to-r from-blue-500 to-purple-600"
              disabled={loading || newPassword !== confirmPassword}
            >
              {loading ? 'Resetting...' : 'Reset Password'}
            </Button>

            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={() => setStep('verify')}
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
          </form>
        )}

        <div className="mt-6 text-center">
          <Link to="/login" className="text-sm text-blue-600 hover:underline inline-flex items-center">
            <ArrowLeft className="w-3 h-3 mr-1" />
            Back to Sign In
          </Link>
        </div>
      </Card>
    </div>
  );
}
