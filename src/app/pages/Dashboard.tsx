import { weeklyData, categorySpending, transactions as mockTransactions, budgets as mockBudgets } from "../data/mockData";
import { useState, useEffect, useCallback } from "react";
import {
  ArrowUpRight,
  ArrowDownRight,
  TrendingUp,
  AlertTriangle,
  ShoppingCart,
  Plus,
  Sparkles,
  Bot,
  Briefcase,
  GraduationCap,
  Home,
  Users,
  Target,
  Trophy,
  Shield,
  Zap,
  Bell,
  Mic,
  Scan,
  Receipt,
  CreditCard,
  PieChart,
  BarChart3,
  Calendar,
  CheckCircle2,
  Clock,
  DollarSign,
  Flame,
  Star,
  RefreshCw,
  LogOut,
  Wallet,
  Package,
  FileText,
  Lightbulb,
  Coffee,
  Smartphone,
  Plane,
  BookOpen,
  ShoppingBag,
  Activity,
  Download,
} from "lucide-react";
import { Link } from "react-router";
import { Button } from "../components/ui/button";
import { transactionsAPI, budgetsAPI, aiAPI, goalsAPI, billsAPI, activitiesAPI } from "../../services/api";
import { toast } from "sonner";
import { seedDemoData } from "../../utils/api/seed";
import { useAuth } from "../contexts/AuthContext";
import { useRole } from "../contexts/RoleContext";
import { useLanguage } from "../../contexts/LanguageContext";
import { LanguageSelector } from "../components/LanguageSelector";
import { exportFinancialReportPDF } from "../../utils/exportUtils";

// ─── Shared helpers ──────────────────────────────────────────────────────────

const glassCard = (accent = "rgba(255,255,255,0.07)") => ({
  background: "rgba(14,20,35,0.75)",
  border: `1px solid ${accent}`,
  backdropFilter: "blur(16px)",
});

function formatTimeAgo(dateInput?: string | Date | null): string {
  if (!dateInput) return "Just now";
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return "Recently";
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return "Just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function ActivityFeed({ activities, color }: { activities: any[]; color: string }) {
  return (
    <div className="rounded-2xl p-5" style={glassCard()}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ background: `${color}15` }}>
            <Activity className="w-4 h-4" style={{ color }} />
          </div>
          <div>
            <h3 className="font-bold text-sm text-white">Recent Activity</h3>
            <p className="text-[11px]" style={{ color: "#6b7ca0" }}>Real-time chronological log of records & changes</p>
          </div>
        </div>
        <span className="flex items-center gap-1.5 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" /> Live Sync
        </span>
      </div>

      {activities.length === 0 ? (
        <p className="text-xs text-center py-6" style={{ color: "#6b7ca0" }}>No recent activity yet. Add transactions or budgets to see live updates.</p>
      ) : (
        <div className="space-y-2.5">
          {activities.slice(0, 10).map((act, i) => {
            const isIncome = act.type === 'income';
            const isExpense = act.type === 'expense';
            const isBudget = act.type === 'budget';
            const isGoal = act.type === 'goal';

            return (
              <div key={act.id || i} className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/[0.04] hover:bg-white/[0.04] transition-all">
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${
                    isIncome ? 'bg-emerald-500/15 text-emerald-400' :
                    isExpense ? 'bg-red-500/15 text-red-400' :
                    isBudget ? 'bg-amber-500/15 text-amber-400' :
                    isGoal ? 'bg-purple-500/15 text-purple-400' :
                    'bg-indigo-500/15 text-indigo-400'
                  }`}>
                    {isIncome ? <ArrowUpRight className="w-4 h-4" /> :
                     isExpense ? <ArrowDownRight className="w-4 h-4" /> :
                     isBudget ? <PieChart className="w-4 h-4" /> :
                     isGoal ? <Target className="w-4 h-4" /> :
                     <Sparkles className="w-4 h-4" />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold text-white truncate">{act.title}</p>
                    {act.details && (
                      <p className="text-[11px] truncate mt-0.5" style={{ color: "#94a3b8" }}>{act.details}</p>
                    )}
                  </div>
                </div>
                <span className="text-[10px] font-mono flex-shrink-0 ml-3" style={{ color: "#6b7ca0" }}>
                  {formatTimeAgo(act.createdAt)}
                </span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function Ring({ value, color, size = 80 }: { value: number; color: string; size?: number }) {
  const r = size * 0.38;
  const circ = 2 * Math.PI * r;
  const offset = circ - (Math.min(value, 100) / 100) * circ;
  return (
    <div className="relative flex-shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={size * 0.1} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={size * 0.1}
          strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"
          style={{ filter: `drop-shadow(0 0 6px ${color}80)` }} />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span className="font-black text-sm" style={{ color, fontFamily: "monospace" }}>{value}</span>
      </div>
    </div>
  );
}

function BarMini({ values, color, labels }: { values: number[]; color: string; labels: string[] }) {
  const max = Math.max(...values, 1);
  return (
    <div className="flex items-end gap-1 h-20 w-full">
      {values.map((v, i) => (
        <div key={i} className="flex flex-col items-center gap-1 flex-1">
          <div className="w-full rounded-t-sm" style={{
            height: `${(v / max) * 64}px`,
            background: `linear-gradient(to top, ${color}, ${color}88)`,
            minHeight: 4,
          }} />
          <span style={{ fontSize: 9, color: "#6b7ca0" }}>{labels[i]}</span>
        </div>
      ))}
    </div>
  );
}

function LineMini({ values, color }: { values: number[]; color: string }) {
  const W = 200, H = 60, pad = 8;
  const max = Math.max(...values, 1);
  const iW = W - pad * 2;
  const step = iW / (values.length - 1);
  const pts = values.map((v, i) => `${pad + i * step},${H - pad - ((v / max) * (H - pad * 2))}`).join(" ");
  const area = `${pad},${H - pad} ${pts} ${pad + (values.length - 1) * step},${H - pad}`;
  return (
    <svg viewBox={`0 0 ${W} ${H}`} width="100%" height={H} preserveAspectRatio="none">
      <polygon points={area} fill={color} fillOpacity={0.12} />
      <polyline points={pts} fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function AICard({ color, advice }: { color: string; advice: string[] }) {
  return (
    <div className="rounded-2xl p-5" style={{ background: `${color}08`, border: `1px solid ${color}20` }}>
      <div className="flex items-center gap-2 mb-3">
        <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ background: `${color}18` }}>
          <Sparkles className="w-4 h-4" style={{ color }} />
        </div>
        <span className="font-semibold text-sm" style={{ color }}>AI Financial Advisor</span>
        <Link to="/app/chatbot" className="ml-auto text-xs px-2 py-1 rounded-lg flex items-center gap-1"
          style={{ background: `${color}12`, color, border: `1px solid ${color}20` }}>
          <Bot className="w-3 h-3" /> Chat
        </Link>
      </div>
      <div className="space-y-2">
        {advice.map((a, i) => (
          <div key={i} className="flex items-start gap-2 text-sm" style={{ color: "#94a3b8" }}>
            <Lightbulb className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" style={{ color }} />
            {a}
          </div>
        ))}
      </div>
    </div>
  );
}

function QuickActions({ color }: { color: string }) {
  return (
    <div className="flex gap-2 flex-wrap">
      {[
        { icon: Plus, label: "Add", to: "/app/transactions" },
        { icon: Mic, label: "Voice", to: "/app/voice" },
        { icon: Scan, label: "Scan", to: "/app/scanner" },
        { icon: Bot, label: "AI Chat", to: "/app/chatbot" },
      ].map((a) => (
        <Link key={a.label} to={a.to}
          className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium transition-all"
          style={{ background: `${color}10`, border: `1px solid ${color}20`, color }}>
          <a.icon className="w-3.5 h-3.5" />
          {a.label}
        </Link>
      ))}
    </div>
  );
}

function HealthScoreBadge({ score, color }: { score: number; color: string }) {
  const label = score >= 80 ? "Excellent" : score >= 60 ? "Good" : "Needs Work";
  return (
    <div className="rounded-2xl p-4 flex items-center gap-4" style={glassCard()}>
      <Ring value={score} color={color} size={72} />
      <div>
        <div className="text-xs mb-0.5" style={{ color: "#6b7ca0" }}>Health Score</div>
        <div className="text-xl font-black" style={{ color: "#e8edf5" }}>{score}<span className="text-sm font-normal">/100</span></div>
        <div className="text-xs font-medium" style={{ color }}>{label}</div>
      </div>
    </div>
  );
}

function StatCard({ label, value, change, up, icon: Icon, color }: {
  label: string; value: string; change: string; up: boolean; icon: any; color: string;
}) {
  return (
    <div className="rounded-2xl p-4" style={glassCard()}>
      <div className="flex items-start justify-between mb-2">
        <span className="text-xs" style={{ color: "#6b7ca0" }}>{label}</span>
        <div className="w-7 h-7 rounded-lg flex items-center justify-center" style={{ background: `${color}15` }}>
          <Icon className="w-3.5 h-3.5" style={{ color }} />
        </div>
      </div>
      <div className="text-xl font-black mb-1" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{value}</div>
      <div className="text-xs font-medium flex items-center gap-1" style={{ color: up ? "#10b981" : "#f59e0b" }}>
        {up ? <ArrowUpRight className="w-3 h-3" /> : <ArrowDownRight className="w-3 h-3" />}
        {change}
      </div>
    </div>
  );
}

// ─── Role Selector ────────────────────────────────────────────────────────────

const ROLES = [
  {
    id: "business",
    label: "Business Owner",
    icon: Briefcase,
    color: "#10b981",
    glow: "rgba(16,185,129,0.25)",
    description: "Track revenue, manage suppliers, analyze profit & loss, and get AI business insights.",
    tags: ["Cash Flow", "Tax/GST", "Payroll"],
  },
  {
    id: "student",
    label: "Student",
    icon: GraduationCap,
    color: "#06b6d4",
    glow: "rgba(6,182,212,0.25)",
    description: "Manage pocket money, track subscriptions, food spending, and build saving habits.",
    tags: ["Pocket Money", "Subscriptions", "Goals"],
  },
  {
    id: "home",
    label: "Home Manager",
    icon: Home,
    color: "#f59e0b",
    glow: "rgba(245,158,11,0.25)",
    description: "Plan grocery budgets, manage household bills, track utilities, and save for family goals.",
    tags: ["Groceries", "Utilities", "Family Goals"],
  },
  {
    id: "freelancer",
    label: "Freelancer",
    icon: Users,
    color: "#7c3aed",
    glow: "rgba(124,58,237,0.25)",
    description: "Track client payments, manage invoices, estimate taxes, and predict income flow.",
    tags: ["Invoices", "Tax Estimate", "Income Forecast"],
  },
];

function RoleSelector({ onSelect }: { onSelect: (role: string) => void }) {
  const [hovered, setHovered] = useState<string | null>(null);
  const [selected, setSelected] = useState<string | null>(null);

  const handleSelect = (id: string) => {
    setSelected(id);
    setTimeout(() => onSelect(id), 400);
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center overflow-auto py-8 px-4"
      style={{ background: "linear-gradient(135deg, #080c14 0%, #0d1220 50%, #080c14 100%)" }}>
      {/* Ambient orbs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute rounded-full blur-3xl opacity-20"
          style={{ width: 500, height: 500, top: -150, left: -150,
            background: "radial-gradient(circle, #10b981, transparent 70%)" }} />
        <div className="absolute rounded-full blur-3xl opacity-15"
          style={{ width: 400, height: 400, bottom: 0, right: -100,
            background: "radial-gradient(circle, #7c3aed, transparent 70%)" }} />
      </div>

      {/* Logo */}
      <div className="flex items-center gap-2 mb-8">
        <div className="w-9 h-9 rounded-xl flex items-center justify-center"
          style={{ background: "linear-gradient(135deg, #10b981, #3b82f6)" }}>
          <Wallet className="w-5 h-5 text-white" />
        </div>
        <span className="text-xl font-bold" style={{ color: "#e8edf5" }}>
          Finance<span style={{ color: "#10b981" }}>AI</span>
        </span>
      </div>

      <div className="text-center mb-10 relative z-10">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-sm font-medium mb-4"
          style={{ background: "rgba(16,185,129,0.1)", border: "1px solid rgba(16,185,129,0.25)", color: "#10b981" }}>
          <Sparkles className="w-4 h-4" /> Personalized AI Experience
        </div>
        <h1 className="font-black mb-3"
          style={{ fontSize: "clamp(1.75rem, 5vw, 3rem)", color: "#e8edf5", letterSpacing: "-0.03em" }}>
          Choose Your Financial Lifestyle
        </h1>
        <p style={{ color: "#6b7ca0", fontSize: "1rem", maxWidth: 480, margin: "0 auto" }}>
          Personalize your AI financial assistant experience. Your dashboard will be fully customized for your life.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 w-full max-w-5xl relative z-10">
        {ROLES.map((role) => {
          const Icon = role.icon;
          const isHovered = hovered === role.id;
          const isSelected = selected === role.id;
          return (
            <button
              key={role.id}
              onClick={() => handleSelect(role.id)}
              onMouseEnter={() => setHovered(role.id)}
              onMouseLeave={() => setHovered(null)}
              className="text-left rounded-3xl p-6 transition-all duration-300 flex flex-col gap-4"
              style={{
                background: isSelected
                  ? `${role.color}15`
                  : isHovered
                  ? `${role.color}10`
                  : "rgba(14,20,35,0.7)",
                border: `1px solid ${isHovered || isSelected ? role.color + "50" : "rgba(255,255,255,0.07)"}`,
                backdropFilter: "blur(16px)",
                boxShadow: isHovered || isSelected ? `0 0 40px ${role.glow}, 0 8px 32px rgba(0,0,0,0.4)` : "0 4px 24px rgba(0,0,0,0.3)",
                transform: isHovered ? "translateY(-4px) scale(1.01)" : isSelected ? "scale(0.98)" : "none",
                cursor: "pointer",
              }}
            >
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center"
                style={{
                  background: isHovered || isSelected ? `${role.color}20` : "rgba(255,255,255,0.05)",
                  border: `1px solid ${isHovered || isSelected ? role.color + "40" : "rgba(255,255,255,0.08)"}`,
                  boxShadow: isHovered ? `0 0 20px ${role.glow}` : "none",
                  transition: "all 0.3s",
                }}>
                <Icon className="w-7 h-7" style={{ color: isHovered || isSelected ? role.color : "#6b7ca0" }} />
              </div>

              <div>
                <h3 className="font-bold text-base mb-1.5" style={{ color: "#e8edf5" }}>{role.label}</h3>
                <p className="text-sm leading-relaxed" style={{ color: "#6b7ca0" }}>{role.description}</p>
              </div>

              <div className="flex flex-wrap gap-1.5 mt-auto">
                {role.tags.map((tag) => (
                  <span key={tag} className="text-xs px-2 py-0.5 rounded-full"
                    style={{ background: `${role.color}12`, color: role.color, border: `1px solid ${role.color}25` }}>
                    {tag}
                  </span>
                ))}
              </div>

              <div className="flex items-center gap-2 font-semibold text-sm mt-1"
                style={{ color: isHovered || isSelected ? role.color : "#3d4f6b" }}>
                {isSelected ? (
                  <><CheckCircle2 className="w-4 h-4" /> Setting up...</>
                ) : (
                  <><ArrowUpRight className="w-4 h-4" /> Select this mode</>
                )}
              </div>
            </button>
          );
        })}
      </div>

      <p className="mt-8 text-xs relative z-10" style={{ color: "#3d4f6b" }}>
        You can change your mode anytime from the profile settings
      </p>
    </div>
  );
}

// ─── Helpers for calculations ──────────────────────────────────────────────────

function getMonthlyData(transactions: any[], type: "income" | "expense" | "both") {
  const data = Array(12).fill(0);
  const currentYear = new Date().getFullYear();
  transactions.forEach(t => {
    const d = new Date(t.date);
    if (d.getFullYear() === currentYear) {
      const month = d.getMonth();
      if (type === "both") {
        data[month] += t.type === "income" ? t.amount : -t.amount;
      } else if (t.type === type) {
        data[month] += t.amount;
      }
    }
  });
  return data;
}

function getWeeklyData(transactions: any[]) {
  const data = Array(7).fill(0);
  const today = new Date();
  const dayOfWeek = today.getDay();
  const monday = new Date(today);
  monday.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
  monday.setHours(0,0,0,0);

  transactions.forEach(t => {
    const d = new Date(t.date);
    if (d >= monday && t.type === "expense") {
      const day = d.getDay();
      const idx = day === 0 ? 6 : day - 1;
      data[idx] += t.amount;
    }
  });
  return data;
}

// ─── Business Dashboard ───────────────────────────────────────────────────────

interface DashboardProps {
  user: any;
  onReset: () => void;
  transactions: any[];
  budgets: any[];
  goals: any[];
  bills: any[];
}

function BusinessDashboard({ user, onReset, transactions, budgets, goals, bills }: DashboardProps) {
  const C = "#10b981";
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  // Monthly stats
  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();
  const monthlyTxs = transactions.filter(t => {
    const d = new Date(t.date);
    return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  });

  const todayStr = new Date().toDateString();
  const todayTxs = transactions.filter(t => new Date(t.date).toDateString() === todayStr);

  const todayRevenue = todayTxs.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const monthlyIncome = monthlyTxs.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const monthlyExpense = monthlyTxs.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  const monthlyProfit = monthlyIncome - monthlyExpense;

  const taxGST = Math.round(monthlyIncome * 0.18); // 18% GST estimate
  
  const revenueData = getMonthlyData(transactions, "income");
  const cashFlow = getMonthlyData(transactions, "both");

  const suppliers = bills.slice(0, 4).map((b) => ({
    name: b.name,
    due: b.dueDate ? new Date(b.dueDate).toLocaleDateString("en-IN", { month: "short", day: "numeric" }) : "No deadline",
    amount: "₹" + b.amount.toLocaleString(),
    status: b.paid ? "paid" : (new Date(b.dueDate) < new Date() ? "overdue" : "due"),
  }));

  const salaries = transactions
    .filter(t => t.type === "expense" && (t.category === "salary" || t.category === "payroll" || (t.merchant && t.merchant.toLowerCase().includes("salary"))))
    .slice(0, 4)
    .map(t => ({
      role: t.merchant || "Contractor",
      salary: "₹" + t.amount.toLocaleString(),
      status: "paid",
    }));

  const finalSalaries = salaries.length > 0 ? salaries : [
    { role: "Operations Lead", salary: "₹95,000", status: "paid" },
    { role: "Sales Manager", salary: "₹72,000", status: "paid" },
    { role: "Developer (Contract)", salary: "₹60,000", status: "pending" },
  ];

  return (
    <div className="space-y-5 max-w-7xl" style={{ fontFamily: "'Inter', sans-serif" }}>
      {/* Header */}
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="w-6 h-6 rounded-lg flex items-center justify-center" style={{ background: `${C}18` }}>
              <Briefcase className="w-3.5 h-3.5" style={{ color: C }} />
            </div>
            <span className="text-xs font-medium" style={{ color: C }}>Business Owner Mode</span>
            <button onClick={onReset} className="ml-2 text-xs px-2 py-0.5 rounded-lg flex items-center gap-1"
              style={{ color: "#6b7ca0", border: "1px solid rgba(255,255,255,0.08)" }}>
              <RefreshCw className="w-3 h-3" /> Switch
            </button>
          </div>
          <h1 className="text-2xl font-black" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>
            Business Command Center
          </h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>
            {new Date().toLocaleDateString("en-IN", { weekday: "long", month: "long", day: "numeric" })}
          </p>
        </div>
        <QuickActions color={C} />
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <StatCard label="Today's Revenue" value={`₹${todayRevenue.toLocaleString()}`} change="+14.2% vs yesterday" up icon={TrendingUp} color={C} />
        <StatCard label="Monthly Profit" value={`₹${monthlyProfit.toLocaleString()}`} change="+6.8% vs last month" up icon={DollarSign} color="#3b82f6" />
        <StatCard label="Operational Cost" value={`₹${monthlyExpense.toLocaleString()}`} change="+12% this month" up={false} icon={ShoppingCart} color="#f59e0b" />
        <StatCard label="Tax/GST Est" value={`₹${taxGST.toLocaleString()}`} change="18% GST Estimate" up={false} icon={FileText} color="#ef4444" />
      </div>

      <div className="grid lg:grid-cols-3 gap-5">
        {/* Health + AI */}
        <div className="space-y-4">
          <HealthScoreBadge score={transactions.length > 0 ? 85 : 50} color={C} />
          <AICard color={C} advice={[
            `Your operational costs stand at ₹${monthlyExpense.toLocaleString()} this month. Check transactions list for details.`,
            "GST/Tax estimate is computed dynamically based on your registered income cashflows.",
            transactions.length > 0 ? "Cash flow looks active. Consider tracking suppliers using the Bills section." : "Database is empty. Add a few transactions or bills to generate customized AI advice.",
          ]} />
        </div>

        {/* Revenue chart */}
        <div className="lg:col-span-2 rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold" style={{ color: "#e8edf5" }}>Monthly Revenue (₹)</h3>
            <span className="text-xs px-2 py-1 rounded-lg" style={{ background: `${C}12`, color: C }}>YTD Trend</span>
          </div>
          <BarMini values={revenueData} color={C} labels={months} />
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-5">
        {/* Supplier tracker */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#e8edf5" }}>
              <Package className="w-4 h-4" style={{ color: C }} /> Supplier Payments (Bills)
            </h3>
          </div>
          <div className="space-y-3">
            {suppliers.length === 0 ? (
              <div className="text-center py-6 text-sm text-gray-500">No active bills registered</div>
            ) : (
              suppliers.map((s, idx) => (
                <div key={idx} className="flex items-center justify-between p-3 rounded-xl"
                  style={{ background: "rgba(255,255,255,0.03)" }}>
                  <div>
                    <div className="text-sm font-medium" style={{ color: "#e8edf5" }}>{s.name}</div>
                    <div className="text-xs" style={{ color: "#6b7ca0" }}>Due: {s.due}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{s.amount}</div>
                    <span className="text-xs px-2 py-0.5 rounded-full"
                      style={{
                        background: s.status === "overdue" ? "rgba(239,68,68,0.12)" : s.status === "due" ? "rgba(245,158,11,0.12)" : "rgba(16,185,129,0.12)",
                        color: s.status === "overdue" ? "#ef4444" : s.status === "due" ? "#f59e0b" : "#10b981",
                      }}>{s.status}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Staff salaries */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#e8edf5" }}>
              <Users className="w-4 h-4" style={{ color: "#3b82f6" }} /> Staff Salaries
            </h3>
            <span className="text-xs" style={{ color: "#6b7ca0" }}>Recent Payroll</span>
          </div>
          <div className="space-y-3">
            {finalSalaries.map((s, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 rounded-xl"
                style={{ background: "rgba(255,255,255,0.03)" }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl flex items-center justify-center"
                    style={{ background: s.status === "paid" ? "rgba(16,185,129,0.12)" : "rgba(245,158,11,0.12)" }}>
                    {s.status === "paid"
                      ? <CheckCircle2 className="w-4 h-4" style={{ color: "#10b981" }} />
                      : <Clock className="w-4 h-4" style={{ color: "#f59e0b" }} />}
                  </div>
                  <span className="text-sm" style={{ color: "#94a3b8" }}>{s.role}</span>
                </div>
                <span className="text-sm font-bold" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{s.salary}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Cash flow + Tax */}
      <div className="grid lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 rounded-2xl p-6" style={glassCard()}>
          <h3 className="font-bold mb-4" style={{ color: "#e8edf5" }}>Net Cash Flow Trend</h3>
          <LineMini values={cashFlow} color={C} />
          <div className="flex justify-between mt-2">
            {["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"].map((m, i) => (
              <span key={i} style={{ fontSize: 9, color: "#6b7ca0" }}>{m}</span>
            ))}
          </div>
        </div>
        <div className="rounded-2xl p-6 flex flex-col gap-4" style={{ background: "rgba(239,68,68,0.06)", border: "1px solid rgba(239,68,68,0.18)" }}>
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5" style={{ color: "#ef4444" }} />
            <h3 className="font-bold" style={{ color: "#fca5a5" }}>Tax Breakdown</h3>
          </div>
          {[
            { label: "Gross Income", value: `₹${monthlyIncome.toLocaleString()}` },
            { label: "Operational Expenses", value: `₹${monthlyExpense.toLocaleString()}` },
            { label: "Net GST Liability", value: `₹${Math.round(monthlyIncome * 0.18).toLocaleString()}` },
            { label: "Estimated Tax (30%)", value: `₹${Math.max(0, Math.round(monthlyProfit * 0.3)).toLocaleString()}` },
          ].map((row) => (
            <div key={row.label} className="flex justify-between items-center">
              <span className="text-xs" style={{ color: "#6b7ca0" }}>{row.label}</span>
              <span className="text-sm font-bold" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{row.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Student Dashboard ────────────────────────────────────────────────────────

function StudentDashboard({ user, onReset, transactions, budgets, goals, bills }: DashboardProps) {
  const C = "#06b6d4";
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  // Balance calculation
  const totalIncome = transactions.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  const balance = totalIncome - totalExpense;

  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();
  
  const monthlyExpenses = transactions.filter(t => {
    const d = new Date(t.date);
    return t.type === "expense" && d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  });

  const foodSpend = monthlyExpenses.filter(t => t.category === "food").reduce((s, t) => s + t.amount, 0);
  const subCost = bills.filter(b => b.category === "subscription" || b.name.toLowerCase().includes("netflix") || b.name.toLowerCase().includes("spotify")).reduce((s, b) => s + b.amount, 0);

  const monthlySavings = goals.reduce((s, g) => s + (g.current_amount || 0), 0);

  const weekSpend = getWeeklyData(transactions);

  const subItems = bills.slice(0, 4).map(b => ({
    name: b.name,
    cost: "₹" + b.amount.toLocaleString(),
    active: !b.paid,
  }));

  const renderedSubscriptions = subItems.length > 0 ? subItems : [
    { name: "Netflix", cost: "₹649/mo", active: true },
    { name: "Spotify", cost: "₹119/mo", active: true },
  ];

  const renderedGoals = goals.slice(0, 3).map(g => ({
    name: g.name,
    current: g.current_amount || 0,
    target: g.target_amount || 1,
    color: C,
  }));

  return (
    <div className="space-y-5 max-w-7xl" style={{ fontFamily: "'Inter', sans-serif" }}>
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="w-6 h-6 rounded-lg flex items-center justify-center" style={{ background: `${C}18` }}>
              <GraduationCap className="w-3.5 h-3.5" style={{ color: C }} />
            </div>
            <span className="text-xs font-medium" style={{ color: C }}>Student Mode</span>
            <button onClick={onReset} className="ml-2 text-xs px-2 py-0.5 rounded-lg flex items-center gap-1"
              style={{ color: "#6b7ca0", border: "1px solid rgba(255,255,255,0.08)" }}>
              <RefreshCw className="w-3 h-3" /> Switch
            </button>
          </div>
          <h1 className="text-2xl font-black" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>
            Hey {user?.name?.split(" ")[0] || "User"} 👋 Pocket Money Left
          </h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>
            {new Date().toLocaleDateString("en-IN", { weekday: "long", month: "long", day: "numeric" })}
          </p>
        </div>
        <QuickActions color={C} />
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Account Balance" value={`₹${balance.toLocaleString()}`} change="Current Pocket Money" up={balance >= 0} icon={Wallet} color={C} />
        <StatCard label="Food Delivery" value={`₹${foodSpend.toLocaleString()}`} change="Spending on food" up={false} icon={ShoppingBag} color="#ef4444" />
        <StatCard label="Subscriptions" value={`₹${subCost.toLocaleString()}`} change="Monthly services cost" up={false} icon={Smartphone} color="#7c3aed" />
        <StatCard label="Saved In Goals" value={`₹${monthlySavings.toLocaleString()}`} change="Total savings progress" up icon={Target} color="#10b981" />
      </div>

      <div className="grid lg:grid-cols-3 gap-5">
        <div className="space-y-4">
          <HealthScoreBadge score={balance > 500 ? 82 : 45} color={C} />
          <AICard color={C} advice={[
            `You spent ₹${foodSpend.toLocaleString()} on food categories this month. Try tracking expenses using scanner OCR!`,
            "Active subscriptions list compiles your recurring utility/service bills.",
            "Set target amounts in the Savings page to update goals progress on your dashboard.",
          ]} />
        </div>

        <div className="lg:col-span-2 rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold" style={{ color: "#e8edf5" }}>Weekly Spending (₹)</h3>
            <span className="text-xs px-2 py-1 rounded-lg" style={{ background: `${C}12`, color: C }}>This Week</span>
          </div>
          <BarMini values={weekSpend} color={C} labels={days} />
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-5">
        {/* Subscriptions */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#e8edf5" }}>
              <Smartphone className="w-4 h-4" style={{ color: C }} /> Subscriptions List
            </h3>
          </div>
          <div className="space-y-3">
            {renderedSubscriptions.map((s, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 rounded-xl"
                style={{ background: "rgba(255,255,255,0.03)" }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center"
                    style={{ background: s.active ? `${C}15` : "rgba(255,255,255,0.05)" }}>
                    <Smartphone className="w-4 h-4" style={{ color: s.active ? C : "#3d4f6b" }} />
                  </div>
                  <span className="text-sm font-medium" style={{ color: s.active ? "#e8edf5" : "#3d4f6b" }}>{s.name}</span>
                </div>
                <div className="text-right">
                  <div className="text-xs font-bold" style={{ color: s.active ? "#e8edf5" : "#3d4f6b", fontFamily: "monospace" }}>{s.cost}</div>
                  <div className="text-xs" style={{ color: s.active ? C : "#ef4444" }}>{s.active ? "Active" : "Unused"}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Goals */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#10b981" }} >
              <Target className="w-4 h-4" style={{ color: "#10b981" }} /> Savings Goals
            </h3>
            <Link to="/app/goals" className="text-xs" style={{ color: C }}>Manage →</Link>
          </div>
          <div className="space-y-4">
            {renderedGoals.length === 0 ? (
              <div className="text-center py-6 text-sm text-gray-500">No goals found</div>
            ) : (
              renderedGoals.map((g, idx) => {
                const pct = Math.round((g.current / g.target) * 100);
                return (
                  <div key={idx}>
                    <div className="flex justify-between mb-1.5">
                      <span className="text-sm font-medium" style={{ color: "#94a3b8" }}>{g.name}</span>
                      <span className="text-xs font-bold" style={{ color: g.color, fontFamily: "monospace" }}>
                        ₹{g.current.toLocaleString()} / ₹{g.target.toLocaleString()}
                      </span>
                    </div>
                    <div className="h-2 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }}>
                      <div className="h-full rounded-full transition-all" style={{ width: `${Math.min(pct, 100)}%`, background: g.color }} />
                    </div>
                    <div className="text-xs mt-1" style={{ color: "#6b7ca0" }}>{pct}% complete</div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Home Manager Dashboard ───────────────────────────────────────────────────

function HomeDashboard({ user, onReset, transactions, budgets, goals, bills }: DashboardProps) {
  const C = "#f59e0b";

  // Balance calculation
  const totalIncome = transactions.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  const balance = totalIncome - totalExpense;

  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();

  const monthlyExpenses = transactions.filter(t => {
    const d = new Date(t.date);
    return t.type === "expense" && d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  });

  const grocerySpend = monthlyExpenses.filter(t => t.category === "groceries").reduce((s, t) => s + t.amount, 0);
  const billCosts = bills.filter(b => !b.paid).reduce((s, b) => s + b.amount, 0);
  const savedAmt = goals.reduce((s, g) => s + (g.current_amount || 0), 0);

  const groceryData = getMonthlyData(transactions.filter(t => t.category === "groceries"), "expense");

  const renderedBills = bills.slice(0, 4).map((b) => ({
    name: b.name,
    due: b.dueDate ? new Date(b.dueDate).toLocaleDateString("en-IN", { month: "short", day: "numeric" }) : "No deadline",
    amount: "₹" + b.amount.toLocaleString(),
    urgent: !b.paid && (b.dueDate ? (new Date(b.dueDate).getTime() - Date.now()) < 3 * 24 * 60 * 60 * 1000 : false),
    paid: b.paid,
  }));

  const finalBills = renderedBills.length > 0 ? renderedBills : [
    { name: "Electricity Board", due: "Jun 5", amount: "₹2,840", urgent: true, paid: false },
    { name: "Water Supply", due: "Jun 10", amount: "₹480", urgent: false, paid: false },
  ];

  const familyGoals = goals.slice(0, 3).map((g) => ({
    name: g.name,
    current: g.current_amount || 0,
    target: g.target_amount || 1,
    color: C,
  }));

  return (
    <div className="space-y-5 max-w-7xl" style={{ fontFamily: "'Inter', sans-serif" }}>
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="w-6 h-6 rounded-lg flex items-center justify-center" style={{ background: `${C}18` }}>
              <Home className="w-3.5 h-3.5" style={{ color: C }} />
            </div>
            <span className="text-xs font-medium" style={{ color: C }}>Home Manager Mode</span>
            <button onClick={onReset} className="ml-2 text-xs px-2 py-0.5 rounded-lg flex items-center gap-1"
              style={{ color: "#6b7ca0", border: "1px solid rgba(255,255,255,0.08)" }}>
              <RefreshCw className="w-3 h-3" /> Switch
            </button>
          </div>
          <h1 className="text-2xl font-black" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>
            Family Finance Hub 🏡
          </h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>
            {new Date().toLocaleDateString("en-IN", { weekday: "long", month: "long", day: "numeric" })}
          </p>
        </div>
        <QuickActions color={C} />
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Available Household Balance" value={`₹${balance.toLocaleString()}`} change="Total household wallet" up={balance >= 0} icon={Wallet} color={C} />
        <StatCard label="Grocery Spend" value={`₹${grocerySpend.toLocaleString()}`} change="Spending on groceries" up={false} icon={ShoppingCart} color="#ef4444" />
        <StatCard label="Pending Bills" value={`₹${billCosts.toLocaleString()}`} change="Unpaid utilities bills" up={false} icon={Bell} color="#3b82f6" />
        <StatCard label="Total Saved" value={`₹${savedAmt.toLocaleString()}`} change="Family savings goals" up icon={Target} color="#10b981" />
      </div>

      <div className="grid lg:grid-cols-3 gap-5">
        <div className="space-y-4">
          <HealthScoreBadge score={balance > 2000 ? 76 : 58} color={C} />
          <AICard color={C} advice={[
            `Monthly grocery bill is at ₹${grocerySpend.toLocaleString()}. Optimize via bulk ordering or tracking bills.`,
            `Total pending utility bill payment needed: ₹${billCosts.toLocaleString()}.`,
            "Add bills in the Bills page to set auto reminders on your command center.",
          ]} />
        </div>

        <div className="lg:col-span-2 rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold" style={{ color: "#e8edf5" }}>Grocery Spending Trends (₹)</h3>
            <span className="text-xs px-2 py-1 rounded-lg" style={{ background: `${C}12`, color: C }}>Current Year</span>
          </div>
          <BarMini values={groceryData} color={C} labels={["J","F","M","A","M","J","J","A","S","O","N","D"]} />
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-5">
        {/* Bill reminders */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#e8edf5" }}>
              <Bell className="w-4 h-4" style={{ color: C }} /> Utility Bills & Reminders
            </h3>
          </div>
          <div className="space-y-3">
            {finalBills.map((b, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 rounded-xl"
                style={{ background: b.urgent ? "rgba(239,68,68,0.05)" : "rgba(255,255,255,0.03)", border: b.urgent ? "1px solid rgba(239,68,68,0.15)" : "none" }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl flex items-center justify-center"
                    style={{ background: b.urgent ? "rgba(239,68,68,0.12)" : `${C}12` }}>
                    <Zap className="w-4 h-4" style={{ color: b.urgent ? "#ef4444" : C }} />
                  </div>
                  <div>
                    <div className="text-sm font-medium" style={{ color: "#e8edf5" }}>{b.name}</div>
                    <div className="text-xs" style={{ color: b.urgent ? "#f87171" : "#6b7ca0" }}>Due: {b.due}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{b.amount}</div>
                  <span className="text-xs" style={{ color: b.paid ? "#10b981" : "#ef4444" }}>{b.paid ? "Paid" : "Pending"}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Family goals */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#10b981" }} >
              <Target className="w-4 h-4" style={{ color: "#10b981" }} /> Family Savings Goals
            </h3>
          </div>
          <div className="space-y-4">
            {familyGoals.length === 0 ? (
              <div className="text-center py-6 text-sm text-gray-500">No family goals configured</div>
            ) : (
              familyGoals.map((g, idx) => {
                const pct = Math.round((g.current / g.target) * 100);
                return (
                  <div key={idx}>
                    <div className="flex justify-between mb-1.5">
                      <span className="text-sm font-medium" style={{ color: "#94a3b8" }}>{g.name}</span>
                      <span className="text-xs font-bold" style={{ color: g.color, fontFamily: "monospace" }}>{pct}%</span>
                    </div>
                    <div className="h-2.5 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }}>
                      <div className="h-full rounded-full" style={{ width: `${Math.min(pct, 100)}%`, background: g.color }} />
                    </div>
                    <div className="flex justify-between text-xs mt-1" style={{ color: "#6b7ca0" }}>
                      <span>₹{g.current.toLocaleString()}</span>
                      <span>₹{g.target.toLocaleString()}</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Freelancer Dashboard ─────────────────────────────────────────────────────

function FreelancerDashboard({ user, onReset, transactions, budgets, goals, bills }: DashboardProps) {
  const C = "#7c3aed";

  // Balance calculation
  const totalIncome = transactions.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions.filter(t => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  
  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();
  const monthlyTxs = transactions.filter(t => {
    const d = new Date(t.date);
    return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  });

  const monthEarned = monthlyTxs.filter(t => t.type === "income").reduce((s, t) => s + t.amount, 0);
  const pendingInvoices = bills.filter(b => !b.paid).reduce((s, b) => s + b.amount, 0);
  
  const taxEstimate = Math.round(monthEarned * 0.1); // 10% TDS/tax estimate

  const earningsData = getMonthlyData(transactions, "income");

  const clients = bills.slice(0, 4).map((b) => ({
    name: b.name,
    pending: "₹" + b.amount.toLocaleString(),
    status: b.paid ? "paid" : "invoiced",
    days: b.dueDate ? new Date(b.dueDate).toLocaleDateString("en-IN", { month: "short", day: "numeric" }) : "No deadline",
  }));

  const finalClients = clients.length > 0 ? clients : [
    { name: "TechNova Solutions", pending: "₹45,000", status: "due", days: "2 days" },
    { name: "DesignCraft Agency", pending: "₹28,500", status: "overdue", days: "5 days ago" },
  ];

  const projects = transactions
    .filter(t => t.type === "income" && t.category === "freelance")
    .slice(0, 4)
    .map(t => ({
      name: t.merchant || "Freelance Project",
      revenue: "₹" + t.amount.toLocaleString(),
      status: "completed",
    }));

  const finalProjects = projects.length > 0 ? projects : [
    { name: "Brand Identity Project", revenue: "₹1,20,000", status: "active" },
    { name: "UX Audit Consultant", revenue: "₹38,000", status: "completed" },
  ];

  return (
    <div className="space-y-5 max-w-7xl" style={{ fontFamily: "'Inter', sans-serif" }}>
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="w-6 h-6 rounded-lg flex items-center justify-center" style={{ background: `${C}18` }}>
              <Users className="w-3.5 h-3.5" style={{ color: C }} />
            </div>
            <span className="text-xs font-medium" style={{ color: C }}>Freelancer Mode</span>
            <button onClick={onReset} className="ml-2 text-xs px-2 py-0.5 rounded-lg flex items-center gap-1"
              style={{ color: "#6b7ca0", border: "1px solid rgba(255,255,255,0.08)" }}>
              <RefreshCw className="w-3 h-3" /> Switch
            </button>
          </div>
          <h1 className="text-2xl font-black" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>
            Creative Finance Studio 🎨
          </h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>
            {new Date().toLocaleDateString("en-IN", { weekday: "long", month: "long", day: "numeric" })}
          </p>
        </div>
        <QuickActions color={C} />
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="This Month Earned" value={`₹${monthEarned.toLocaleString()}`} change="+12% vs last month" up icon={TrendingUp} color={C} />
        <StatCard label="Pending Invoices" value={`₹${pendingInvoices.toLocaleString()}`} change="Pending bills/invoices" up={false} icon={Receipt} color="#ef4444" />
        <StatCard label="Account Balance" value={`₹${(totalIncome - totalExpense).toLocaleString()}`} change="Total available money" up={(totalIncome - totalExpense) >= 0} icon={Activity} color="#10b981" />
        <StatCard label="Tax Estimate (10%)" value={`₹${taxEstimate.toLocaleString()}`} change="TDS Tax Estimate" up={false} icon={FileText} color="#f59e0b" />
      </div>

      <div className="grid lg:grid-cols-3 gap-5">
        <div className="space-y-4">
          <HealthScoreBadge score={totalIncome - totalExpense > 0 ? 80 : 55} color={C} />
          <AICard color={C} advice={[
            `You earned ₹${monthEarned.toLocaleString()} this month from registered freelance and salary cash flows.`,
            `Estimated TDS / withholding tax stand at ₹${taxEstimate.toLocaleString()}.`,
            "Track unpaid client invoices in the Bills page to monitor outstanding dues.",
          ]} />
        </div>

        <div className="lg:col-span-2 rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold" style={{ color: "#e8edf5" }}>Monthly Earnings (₹)</h3>
            <span className="text-xs px-2 py-1 rounded-lg" style={{ background: `${C}12`, color: C }}>Earnings Trend</span>
          </div>
          <BarMini values={earningsData} color={C} labels={["J","F","M","A","M","J","J","A","S","O","N","D"]} />
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-5">
        {/* Client payment tracker */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#e8edf5" }}>
              <CreditCard className="w-4 h-4" style={{ color: C }} /> Invoices & Client Dues
            </h3>
          </div>
          <div className="space-y-3">
            {finalClients.map((c, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 rounded-xl"
                style={{ background: "rgba(255,255,255,0.03)" }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl flex items-center justify-center"
                    style={{ background: c.status === "paid" ? "rgba(16,185,129,0.12)" : "rgba(239,68,68,0.12)" }}>
                    {c.status === "paid"
                      ? <CheckCircle2 className="w-4 h-4" style={{ color: "#10b981" }} />
                      : <Clock className="w-4 h-4" style={{ color: C }} />}
                  </div>
                  <div>
                    <div className="text-sm font-medium" style={{ color: "#e8edf5" }}>{c.name}</div>
                    <div className="text-xs" style={{ color: "#6b7ca0" }}>{c.days}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{c.pending}</div>
                  <span className="text-xs capitalize" style={{ color: c.status === "paid" ? "#10b981" : C }}>{c.status}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Projects */}
        <div className="rounded-2xl p-6" style={glassCard()}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold flex items-center gap-2" style={{ color: "#3b82f6" }}>
              <BarChart3 className="w-4 h-4" style={{ color: "#3b82f6" }} /> Project Dues
            </h3>
          </div>
          <div className="space-y-3">
            {finalProjects.map((p, idx) => (
              <div key={idx} className="p-3 rounded-xl" style={{ background: "rgba(255,255,255,0.03)" }}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium truncate" style={{ color: "#e8edf5" }}>{p.name}</span>
                  <span className="text-sm font-bold ml-2 flex-shrink-0" style={{ color: "#e8edf5", fontFamily: "monospace" }}>{p.revenue}</span>
                </div>
                <span className="text-xs px-2 py-0.5 rounded-full"
                  style={{ background: p.status === "active" ? `${C}12` : "rgba(16,185,129,0.12)", color: p.status === "active" ? C : "#10b981" }}>
                  {p.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Main Dashboard ───────────────────────────────────────────────────────────

export default function Dashboard() {
  const { user } = useAuth();
  const { role, setRole, clearRole } = useRole();
  const { changeLanguage, languagePreferenceSet } = useLanguage();

  const [transactions, setTransactions] = useState<any[]>([]);
  const [budgets, setBudgets] = useState<any[]>([]);
  const [goals, setGoals] = useState<any[]>([]);
  const [bills, setBills] = useState<any[]>([]);
  const [activities, setActivities] = useState<any[]>([]);
  const [loadingData, setLoadingData] = useState(true);
  const [seeding, setSeeding] = useState(false);
  const [exportingPDF, setExportingPDF] = useState(false);
  const [demoMode, setDemoMode] = useState(() => {
    const val = localStorage.getItem("demoMode");
    return val === null ? true : val === "true"; // Default to Demo Mode so they see data instantly
  });

  const loadData = useCallback(async (showLoading = true) => {
    if (demoMode) {
      if (showLoading) setLoadingData(true);
      const mockTxs = (mockTransactions || []).map((t: any) => ({
        ...t,
        merchant: t.merchant || t.description || "Unknown",
        type: t.type || "expense",
      }));

      // Budgets schema expects { category, limit, spent }
      const mockBgs = (mockBudgets || []).map((b: any) => ({
        id: b.category,
        category: b.category,
        limit: b.limit || 500,
        spent: b.spent || 0,
        amount: b.limit || 500,
        name: b.category,
        period: "monthly",
      }));

      const mockGoalsList = [
        { id: 1, name: "Emergency Fund", target_amount: 10000, current_amount: 2500, target: 10000, saved: 2500, deadline: "2026-10-15", dueDate: "2026-10-15" },
        { id: 2, name: "New Laptop", target_amount: 1500, current_amount: 750, target: 1500, saved: 750, deadline: "2026-12-01", dueDate: "2026-12-01" },
        { id: 3, name: "Vacation Trip", target_amount: 5000, current_amount: 1200, target: 5000, saved: 1200, deadline: "2026-08-30", dueDate: "2026-08-30" },
      ];

      const mockBillsList = [
        { id: 1, name: "Electricity bill", amount: 120, dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(), paid: false },
        { id: 2, name: "Water bill", amount: 45, dueDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000).toISOString(), paid: true },
        { id: 3, name: "Internet bill", amount: 80, dueDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(), paid: false },
      ];

      const mockActList = [
        { id: 1, title: "Added expense: Grocery Shopping", details: "-$64.50 (Groceries)", type: "expense", createdAt: new Date(Date.now() - 3 * 60 * 1000).toISOString() },
        { id: 2, title: "Received salary payout", details: "+$3,200.00 (Income)", type: "income", createdAt: new Date(Date.now() - 45 * 60 * 1000).toISOString() },
        { id: 3, title: "Created budget for Dining", details: "Limit: $350.00 / monthly", type: "budget", createdAt: new Date(Date.now() - 3 * 3600 * 1000).toISOString() },
        { id: 4, title: "Emergency Fund Goal Updated", details: "Saved: $2,500 / $10,000", type: "goal", createdAt: new Date(Date.now() - 24 * 3600 * 1000).toISOString() },
      ];

      setTransactions(mockTxs);
      setBudgets(mockBgs);
      setGoals(mockGoalsList);
      setBills(mockBillsList);
      setActivities(mockActList);
      if (showLoading) setLoadingData(false);
    } else {
      if (showLoading) setLoadingData(true);
      try {
        const [txRes, bRes, gRes, billsRes, actRes] = await Promise.all([
          transactionsAPI.getAll(),
          budgetsAPI.getAll(),
          goalsAPI.getAll(),
          billsAPI.getAll(),
          activitiesAPI.getAll().catch(() => ({ data: [] })),
        ]);
        setTransactions(txRes.transactions || []);
        setBudgets(bRes.budgets || []);
        setGoals(gRes.goals || []);
        setBills(billsRes.bills || []);
        const acts = (actRes as any)?.data || (actRes as any)?.activities || [];
        setActivities(acts);
      } catch (err) {
        console.error("Failed to load dashboard statistics:", err);
      } finally {
        if (showLoading) setLoadingData(false);
      }
    }
  }, [demoMode]);

  useEffect(() => {
    if (role && languagePreferenceSet) {
      loadData(true);

      // Requirement 5: Polling every 15 seconds so balance, transactions, and budgets update automatically across tabs/devices
      const interval = setInterval(() => {
        if (!demoMode) {
          loadData(false);
        }
      }, 15000);

      return () => clearInterval(interval);
    }
  }, [role, languagePreferenceSet, loadData, demoMode]);

  const handleSelect = (r: string) => {
    setRole(r as any);
  };

  const handleReset = () => {
    clearRole();
  };

  const handleLanguageSelect = async (lang: string) => {
    await changeLanguage(lang);
  };

  const handleSeed = async () => {
    setSeeding(true);
    try {
      await seedDemoData();
      toast.success("Demo transactions, budgets and goals seeded successfully!");
      await loadData(true);
    } catch (err) {
      toast.error("Failed to seed demo data");
    } finally {
      setSeeding(false);
    }
  };

  const handleExportPDFReport = () => {
    setExportingPDF(true);
    try {
      exportFinancialReportPDF(transactions, undefined, `monthly_financial_report_${new Date().toISOString().slice(0, 10)}.pdf`);
      toast.success("Downloaded Monthly PDF Report with AI Insights!");
    } catch (err: any) {
      toast.error(err?.message || "Failed to generate PDF");
    } finally {
      setExportingPDF(false);
    }
  };

  // Step 1: Select Role
  if (!role) {
    return <RoleSelector onSelect={handleSelect} />;
  }

  // Step 2: Select Language (only if not set yet)
  if (!languagePreferenceSet) {
    return <LanguageSelector onSelect={handleLanguageSelect} />;
  }

  if (loadingData) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-t-transparent rounded-full animate-spin mx-auto mb-4 border-blue-500" />
          <p style={{ color: "#6b7ca0" }}>Loading dashboard...</p>
        </div>
      </div>
    );
  }

  const hasData = transactions.length > 0 || budgets.length > 0 || goals.length > 0;

  // Step 3: Show Dashboard
  const props: DashboardProps = { 
    user, 
    onReset: handleReset,
    transactions,
    budgets,
    goals,
    bills
  };

  const activeRoleColor = role === "business" ? "#10b981" : role === "student" ? "#06b6d4" : role === "home" ? "#f59e0b" : "#7c3aed";

  return (
    <div className="space-y-5 pb-8">
      {/* Premium Toggle Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 p-4 rounded-2xl border border-white/10 bg-slate-900/60 backdrop-blur-md">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-indigo-400" />
            Dashboard Overview
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            Manage your financial records, budgets, and predictive cashflows.
          </p>
        </div>
        
        <div className="flex items-center gap-2 flex-wrap self-start sm:self-auto">
          {/* PDF Export Button */}
          <Button
            size="sm"
            onClick={handleExportPDFReport}
            disabled={exportingPDF}
            className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-white/5 hover:bg-white/10 text-slate-200 border border-white/10 flex items-center gap-1.5"
          >
            <Download className="w-3.5 h-3.5 text-indigo-400" />
            <span>{exportingPDF ? "Exporting..." : "Export PDF Report"}</span>
          </Button>

          <div className="flex items-center gap-1 bg-slate-950/60 p-1 rounded-xl border border-white/5">
            <Button
              size="sm"
              onClick={() => {
                localStorage.setItem("demoMode", "false");
                setDemoMode(false);
              }}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                !demoMode
                  ? "bg-indigo-600 hover:bg-indigo-700 text-white shadow-lg shadow-indigo-500/20"
                  : "bg-transparent text-slate-400 hover:text-white border-none"
              }`}
              style={!demoMode ? { background: "#4f46e5", color: "#fff" } : { background: "transparent", border: "none" }}
            >
              Real Database
            </Button>
            <Button
              size="sm"
              onClick={() => {
                localStorage.setItem("demoMode", "true");
                setDemoMode(true);
              }}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                demoMode
                  ? "bg-indigo-600 hover:bg-indigo-700 text-white shadow-lg shadow-indigo-500/20"
                  : "bg-transparent text-slate-400 hover:text-white border-none"
              }`}
              style={demoMode ? { background: "#4f46e5", color: "#fff" } : { background: "transparent", border: "none" }}
            >
              Demo Mode
            </Button>
          </div>
        </div>
      </div>

      {/* Onboarding seed data banner */}
      {!demoMode && !hasData && (
        <div className="rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-4 transition-all"
          style={{ background: "rgba(255,255,255,0.03)", border: `1px dashed ${activeRoleColor}50` }}>
          <div>
            <p className="font-bold text-sm flex items-center gap-1.5" style={{ color: activeRoleColor }}>
              <Sparkles className="w-4 h-4 animate-pulse" /> Empty SQLite Database Detected
            </p>
            <p className="text-xs mt-0.5" style={{ color: "#6b7ca0" }}>
              To view charts, transactions, and AI financial insights, you can seed your database with mock data.
            </p>
          </div>
          <Button 
            onClick={handleSeed} 
            disabled={seeding} 
            className="px-4 py-2 text-xs font-semibold rounded-xl transition-all" 
            style={{ background: activeRoleColor, color: "#fff", border: "none" }}
          >
            {seeding ? "Seeding..." : "Seed Demo Data"}
          </Button>
        </div>
      )}

      {(() => {
        switch (role) {
          case "business":   return <BusinessDashboard {...props} />;
          case "student":    return <StudentDashboard {...props} />;
          case "home":       return <HomeDashboard {...props} />;
          case "freelancer": return <FreelancerDashboard {...props} />;
          default:           return <RoleSelector onSelect={handleSelect} />;
        }
      })()}

      {/* Requirement 7: Chronological Recent Activity Feed */}
      <ActivityFeed activities={activities} color={activeRoleColor} />
    </div>
  );
}
