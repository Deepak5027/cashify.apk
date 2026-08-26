import { Link } from 'react-router';
import { Home, ArrowLeft, Search, Wallet } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#080c14] text-[#e8edf5] flex items-center justify-center p-6">
      <div
        className="max-w-lg w-full p-8 sm:p-12 rounded-3xl text-center space-y-6"
        style={{
          background: 'rgba(14,20,35,0.75)',
          border: '1px solid rgba(255,255,255,0.08)',
          boxShadow: '0 20px 50px rgba(0,0,0,0.5)',
          backdropFilter: 'blur(20px)',
        }}
      >
        <div className="relative inline-block">
          <div className="w-20 h-20 rounded-3xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center mx-auto shadow-inner">
            <Search className="w-10 h-10 text-blue-400" />
          </div>
          <div className="absolute -bottom-2 -right-2 px-2 py-0.5 rounded-full bg-red-500 text-white text-[10px] font-black font-mono">
            404
          </div>
        </div>

        <div className="space-y-2">
          <h1 className="text-3xl font-black tracking-tight" style={{ color: '#e8edf5' }}>
            Page Not Found
          </h1>
          <p className="text-sm text-gray-400 max-w-sm mx-auto">
            The page or feature you are trying to access doesn't exist or has moved.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
          <Link
            to="/app"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-xs font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white shadow-lg shadow-blue-500/25 transition-all"
          >
            <Home className="w-4 h-4" />
            <span>Go to Dashboard</span>
          </Link>
          <Link
            to="/app/transactions"
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-xs font-semibold bg-white/5 hover:bg-white/10 text-gray-300 border border-white/10 transition-all"
          >
            <Wallet className="w-4 h-4" />
            <span>View Transactions</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
