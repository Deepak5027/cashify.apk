import { useState, useEffect } from 'react';
import { Card } from '../components/ui/card';
import { Label } from '../components/ui/label';
import {
  Settings as SettingsIcon,
  Moon,
  Sun,
  Shield,
  DollarSign,
  Calendar,
  Database,
  CheckCircle2,
  Bell,
  RefreshCw,
  Sparkles,
} from 'lucide-react';
import { toast } from 'sonner';
import { seedDemoData } from '../../utils/api/seed';

const glassCard = {
  background: 'rgba(14,20,35,0.75)',
  border: '1px solid rgba(255,255,255,0.07)',
  backdropFilter: 'blur(16px)',
};

export default function Settings() {
  const [currency, setCurrency] = useState(() => {
    return localStorage.getItem('financeai-currency') || 'INR';
  });

  const [dateFormat, setDateFormat] = useState(() => {
    return localStorage.getItem('financeai-date-format') || 'DD/MM/YYYY';
  });

  const [fraudSensitivity, setFraudSensitivity] = useState(() => {
    return localStorage.getItem('financeai-fraud-sens') || 'medium';
  });

  const [notificationsEnabled, setNotificationsEnabled] = useState(() => {
    return localStorage.getItem('financeai-notifications') !== 'false';
  });

  const [theme, setTheme] = useState<'dark' | 'light'>(() => {
    return (localStorage.getItem('financeai-theme') as 'dark' | 'light') || 'dark';
  });

  const [seeding, setSeeding] = useState(false);

  const [customApiUrl, setCustomApiUrl] = useState(() => {
    return localStorage.getItem('custom_api_url') || 'http://192.168.1.4:4000';
  });

  const handleSavePreferences = () => {
    localStorage.setItem('custom_api_url', customApiUrl.trim());
    localStorage.setItem('financeai-currency', currency);
    localStorage.setItem('financeai-date-format', dateFormat);
    localStorage.setItem('financeai-fraud-sens', fraudSensitivity);
    localStorage.setItem('financeai-notifications', String(notificationsEnabled));
    localStorage.setItem('financeai-theme', theme);

    const root = document.documentElement;
    if (theme === 'light') {
      root.classList.add('light');
      root.classList.remove('dark');
    } else {
      root.classList.remove('light');
      root.classList.add('dark');
    }

    toast.success('Preferences saved successfully');
  };

  const handleRunSeed = async () => {
    setSeeding(true);
    try {
      await seedDemoData();
      toast.success('Realistic demo dataset successfully loaded!');
    } catch (err: any) {
      toast.error('Failed to populate demo data: ' + (err.message || 'Server error'));
    } finally {
      setSeeding(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400">
            <SettingsIcon className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold" style={{ color: '#e8edf5' }}>
              Settings & Preferences
            </h1>
            <p className="text-sm text-gray-400 mt-0.5">
              Customize currency display, anomaly scoring sensitivity, and system settings
            </p>
          </div>
        </div>
      </div>

      {/* Currency & Localization */}
      <div className="rounded-2xl p-6 space-y-4" style={glassCard}>
        <div className="flex items-center gap-2 pb-2 border-b border-white/5">
          <DollarSign className="w-4 h-4 text-emerald-400" />
          <h2 className="font-semibold text-sm text-white">Currency & Display</h2>
        </div>

        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <Label className="text-xs text-gray-400 mb-1.5 block">Display Currency</Label>
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
              className="w-full px-3 py-2 rounded-xl bg-white/5 border border-white/10 text-sm text-white focus:outline-none focus:border-blue-500"
            >
              <option value="INR" className="bg-slate-900 text-white">₹ INR - Indian Rupee</option>
              <option value="USD" className="bg-slate-900 text-white">$ USD - US Dollar</option>
              <option value="EUR" className="bg-slate-900 text-white">€ EUR - Euro</option>
              <option value="GBP" className="bg-slate-900 text-white">£ GBP - British Pound</option>
            </select>
          </div>

          <div>
            <Label className="text-xs text-gray-400 mb-1.5 block">Date Format</Label>
            <select
              value={dateFormat}
              onChange={(e) => setDateFormat(e.target.value)}
              className="w-full px-3 py-2 rounded-xl bg-white/5 border border-white/10 text-sm text-white focus:outline-none focus:border-blue-500"
            >
              <option value="DD/MM/YYYY" className="bg-slate-900 text-white">DD/MM/YYYY (e.g. 15/08/2026)</option>
              <option value="MM/DD/YYYY" className="bg-slate-900 text-white">MM/DD/YYYY (e.g. 08/15/2026)</option>
              <option value="YYYY-MM-DD" className="bg-slate-900 text-white">YYYY-MM-DD (ISO standard)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Security & Anomaly Detection */}
      <div className="rounded-2xl p-6 space-y-4" style={glassCard}>
        <div className="flex items-center gap-2 pb-2 border-b border-white/5">
          <Shield className="w-4 h-4 text-purple-400" />
          <h2 className="font-semibold text-sm text-white">Anomaly & Fraud Scoring Engine</h2>
        </div>

        <div>
          <Label className="text-xs text-gray-400 mb-1.5 block">Anomaly Detection Sensitivity</Label>
          <div className="grid grid-cols-3 gap-3">
            {[
              { id: 'low', label: 'Conservative', sub: 'Flags only >3 std dev anomalies' },
              { id: 'medium', label: 'Balanced', sub: 'Default multi-factor heuristic' },
              { id: 'high', label: 'Aggressive', sub: 'Flags minor category deviations' },
            ].map((lvl) => (
              <button
                key={lvl.id}
                type="button"
                onClick={() => setFraudSensitivity(lvl.id)}
                className={`p-3 rounded-xl text-left border transition-all cursor-pointer ${
                  fraudSensitivity === lvl.id
                    ? 'bg-purple-500/20 border-purple-500/50 text-white'
                    : 'bg-white/5 border-white/5 text-gray-400 hover:bg-white/10'
                }`}
              >
                <div className="font-semibold text-xs text-white mb-0.5">{lvl.label}</div>
                <div className="text-[10px] text-gray-400 leading-snug">{lvl.sub}</div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Demo Data Management for Viva / Defense */}
      <div className="rounded-2xl p-6 space-y-4" style={glassCard}>
        <div className="flex items-center justify-between pb-2 border-b border-white/5">
          <div className="flex items-center gap-2">
            <Database className="w-4 h-4 text-blue-400" />
            <h2 className="font-semibold text-sm text-white">Demonstration & Presentation Mode</h2>
          </div>
          <span className="text-[10px] px-2 py-0.5 rounded-full bg-blue-500/20 text-blue-400 font-semibold">
            Viva Ready
          </span>
        </div>

        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="space-y-1">
            <p className="text-sm font-medium text-white">Populate Realistic Demo Data</p>
            <p className="text-xs text-gray-400 max-w-lg">
              Inserts transactions across 90 days, varied budget limits, savings goals, and sample suspicious transactions for a live presentation.
            </p>
          </div>
          <button
            onClick={handleRunSeed}
            disabled={seeding}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-all cursor-pointer disabled:opacity-50 flex-shrink-0"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${seeding ? 'animate-spin' : ''}`} />
            <span>{seeding ? 'Seeding Data...' : 'Seed Demo Data'}</span>
          </button>
        </div>
      </div>

      {/* Backend API Server Settings (Remote Server) */}
      <div className="rounded-2xl p-6 space-y-4" style={glassCard}>
        <div className="flex items-center justify-between pb-2 border-b border-white/5">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-emerald-400" />
            <h2 className="font-semibold text-sm text-white">Backend Server & Database Connection</h2>
          </div>
          <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 font-semibold">
            Live Host
          </span>
        </div>

        <div className="space-y-3">
          <Label className="text-xs text-gray-400 block">Backend Server Base URL (Node.js API & Database)</Label>
          <input
            type="text"
            value={customApiUrl}
            onChange={(e) => setCustomApiUrl(e.target.value)}
            placeholder="http://localhost:4000"
            className="w-full px-3 py-2 rounded-xl text-xs text-white bg-white/5 border border-white/10 focus:outline-none focus:border-emerald-500 font-mono"
          />
          <p className="text-[11px] text-gray-400">
            Enables your web application to communicate directly with your custom Node.js server and database, or any cloud domain.
          </p>
        </div>
      </div>

      {/* Save Button */}
      <div className="flex justify-end">
        <button
          onClick={handleSavePreferences}
          className="flex items-center gap-2 px-6 py-2.5 rounded-xl text-xs font-bold bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white shadow-lg shadow-blue-500/20 transition-all cursor-pointer"
        >
          <CheckCircle2 className="w-4 h-4" />
          <span>Save Preferences</span>
        </button>
      </div>
    </div>
  );
}
