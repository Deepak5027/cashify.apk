import { Outlet, Link, useLocation, useNavigate } from "react-router";
import {
  LayoutDashboard,
  Receipt,
  Wallet,
  AlertTriangle,
  ScanLine,
  BarChart3,
  User,
  Menu,
  X,
  Mic,
  Brain,
  Target,
  Bot,
  Upload,
  Bell,
  Search,
  Sparkles,
  Calculator as CalcIcon,
  TrendingUp,
  WifiOff,
  Clock,
  Sun,
  Moon,
  Command,
  Settings as SettingsIcon,
  Shield,
  Info,
  Smartphone,
} from "lucide-react";
import { useState, useEffect, useRef, useCallback } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../contexts/AuthContext";
import { RoleProvider } from "../contexts/RoleContext";
import { LanguageSwitcher } from "../components/LanguageSwitcher";

// ─── Theme ────────────────────────────────────────────────────────────────────

function useTheme() {
  const [theme, setTheme] = useState<"dark" | "light">(() => {
    try {
      return (localStorage.getItem("financeai-theme") as "dark" | "light") || "dark";
    } catch {
      return "dark";
    }
  });

  useEffect(() => {
    const root = document.documentElement;
    if (theme === "light") {
      root.classList.add("light");
      root.classList.remove("dark");
    } else {
      root.classList.remove("light");
      root.classList.add("dark");
    }
    try {
      localStorage.setItem("financeai-theme", theme);
    } catch {}
  }, [theme]);

  const toggle = useCallback(() => setTheme((t) => (t === "dark" ? "light" : "dark")), []);
  return { theme, toggle };
}

// ─── Search ───────────────────────────────────────────────────────────────────

type SearchItem = {
  label: string;
  sub: string;
  path: string;
  icon: any;
  group: string;
};

const ALL_SEARCH_ITEMS: SearchItem[] = [
  // Pages
  { label: "Dashboard", sub: "Overview & analytics", path: "/app", icon: LayoutDashboard, group: "Pages" },
  { label: "Analytics", sub: "Charts and spending trends", path: "/app/analytics", icon: BarChart3, group: "Pages" },
  { label: "Transactions", sub: "All income and expense entries", path: "/app/transactions", icon: Receipt, group: "Pages" },
  { label: "Budget", sub: "Monthly budget planning", path: "/app/budget", icon: Wallet, group: "Pages" },
  { label: "Goals", sub: "Savings goal tracking", path: "/app/goals", icon: Target, group: "Pages" },
  { label: "Calculator", sub: "EMI, SIP, FD, loan, savings calculators", path: "/app/calculator", icon: CalcIcon, group: "Pages" },
  { label: "Voice Entry", sub: "Add expenses with voice", path: "/app/voice", icon: Mic, group: "AI Tools" },
  { label: "Receipt Scanner", sub: "OCR receipt scanning", path: "/app/scanner", icon: ScanLine, group: "AI Tools" },
  { label: "AI Insights", sub: "ML-powered financial insights", path: "/app/insights", icon: Brain, group: "AI Tools" },
  { label: "AI Predictions", sub: "Spending predictions & forecasts", path: "/app/predictions", icon: TrendingUp, group: "AI Tools" },
  { label: "AI Chatbot", sub: "Chat with your financial assistant", path: "/app/chatbot", icon: Bot, group: "AI Tools" },
  { label: "Alerts", sub: "Budget alerts and notifications", path: "/app/alerts", icon: AlertTriangle, group: "Security" },
  { label: "Bank Import", sub: "Import bank statements", path: "/app/import", icon: Upload, group: "Security" },
  { label: "UPI Import", sub: "Extract transactions from UPI SMS text", path: "/app/upi-import", icon: Smartphone, group: "Security" },
  { label: "Profile", sub: "Account settings and preferences", path: "/app/profile", icon: User, group: "Account" },
  { label: "Settings", sub: "Preferences, currency, theme & alerts", path: "/app/settings", icon: SettingsIcon, group: "Account" },
  { label: "Admin Analytics", sub: "System-wide anonymized statistics", path: "/app/admin", icon: Shield, group: "Account" },
  { label: "How Our AI Works", sub: "Plain-English explanation of forecasting & fraud detection", path: "/app/how-it-works", icon: Info, group: "AI Tools" },
  // Feature shortcuts
  { label: "Add Transaction", sub: "Quick add expense or income", path: "/app/transactions", icon: Receipt, group: "Actions" },
  { label: "SIP Calculator", sub: "Calculate SIP returns", path: "/app/calculator", icon: CalcIcon, group: "Actions" },
  { label: "EMI Calculator", sub: "Calculate loan EMI", path: "/app/calculator", icon: CalcIcon, group: "Actions" },
  { label: "Budget Overview", sub: "Current budget status", path: "/app/budget", icon: Wallet, group: "Actions" },
  { label: "Financial Health Score", sub: "See your financial score", path: "/app/analytics", icon: TrendingUp, group: "Actions" },
];

function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}

function GlobalSearch({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState(0);
  const [recentSearches, setRecentSearches] = useState<string[]>(() => {
    try { return JSON.parse(localStorage.getItem("financeai-recent-searches") || "[]"); }
    catch { return []; }
  });
  const inputRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();
  const debouncedQuery = useDebounce(query, 100);

  useEffect(() => {
    if (isOpen) {
      setQuery("");
      setSelected(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  const results = debouncedQuery.trim().length > 0
    ? ALL_SEARCH_ITEMS.filter((item) =>
        item.label.toLowerCase().includes(debouncedQuery.toLowerCase()) ||
        item.sub.toLowerCase().includes(debouncedQuery.toLowerCase()) ||
        item.group.toLowerCase().includes(debouncedQuery.toLowerCase())
      )
    : ALL_SEARCH_ITEMS.slice(0, 8);

  const grouped = results.reduce((acc, item) => {
    (acc[item.group] = acc[item.group] || []).push(item);
    return acc;
  }, {} as Record<string, SearchItem[]>);

  const flatResults = Object.values(grouped).flat();

  const navigate_to = (item: SearchItem) => {
    const searches = [item.label, ...recentSearches.filter((s) => s !== item.label)].slice(0, 5);
    setRecentSearches(searches);
    try { localStorage.setItem("financeai-recent-searches", JSON.stringify(searches)); } catch {}
    navigate(item.path);
    onClose();
  };

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (!isOpen) return;
      if (e.key === "ArrowDown") { e.preventDefault(); setSelected((s) => Math.min(s + 1, flatResults.length - 1)); }
      if (e.key === "ArrowUp") { e.preventDefault(); setSelected((s) => Math.max(s - 1, 0)); }
      if (e.key === "Enter" && flatResults[selected]) { navigate_to(flatResults[selected]); }
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [isOpen, selected, flatResults]);

  if (!isOpen) return null;

  let globalIndex = 0;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-24 px-4"
      style={{ background: "rgba(0,0,0,0.7)", backdropFilter: "blur(4px)" }}
      onClick={onClose}>
      <div className="w-full max-w-xl rounded-2xl overflow-hidden shadow-2xl"
        style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}
        onClick={(e) => e.stopPropagation()}>

        {/* Input */}
        <div className="flex items-center gap-3 px-4 py-3.5 border-b" style={{ borderColor: "rgba(255,255,255,0.07)" }}>
          <Search className="w-4 h-4 flex-shrink-0" style={{ color: "#6b7ca0" }} />
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => { setQuery(e.target.value); setSelected(0); }}
            placeholder="Search pages, features, calculators..."
            className="flex-1 bg-transparent outline-none text-sm"
            style={{ color: "#e8edf5" }}
          />
          <kbd className="text-xs px-1.5 py-0.5 rounded" style={{ background: "rgba(255,255,255,0.08)", color: "#6b7ca0" }}>ESC</kbd>
        </div>

        {/* Recent searches (when no query) */}
        {!debouncedQuery.trim() && recentSearches.length > 0 && (
          <div className="px-4 py-2 border-b" style={{ borderColor: "rgba(255,255,255,0.05)" }}>
            <div className="text-xs mb-2" style={{ color: "#3d4f6b" }}>Recent</div>
            <div className="flex flex-wrap gap-1.5">
              {recentSearches.map((s) => (
                <button key={s} onClick={() => setQuery(s)}
                  className="text-xs px-2.5 py-1 rounded-lg transition-colors"
                  style={{ background: "rgba(255,255,255,0.05)", color: "#6b7ca0", border: "1px solid rgba(255,255,255,0.07)" }}>
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Results */}
        <div className="max-h-80 overflow-y-auto py-2">
          {Object.entries(grouped).length === 0 ? (
            <div className="px-4 py-6 text-center text-sm" style={{ color: "#6b7ca0" }}>
              No results for "{debouncedQuery}"
            </div>
          ) : (
            Object.entries(grouped).map(([group, items]) => (
              <div key={group}>
                <div className="px-4 py-1.5 text-xs font-semibold uppercase tracking-widest"
                  style={{ color: "#3d4f6b" }}>{group}</div>
                {items.map((item) => {
                  const idx = globalIndex++;
                  const Icon = item.icon;
                  const isSelected = selected === idx;
                  return (
                    <button key={item.path + item.label} onClick={() => navigate_to(item)}
                      onMouseEnter={() => setSelected(idx)}
                      className="w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors"
                      style={{ background: isSelected ? "rgba(16,185,129,0.08)" : "transparent" }}>
                      <div className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0"
                        style={{ background: isSelected ? "rgba(16,185,129,0.15)" : "rgba(255,255,255,0.05)" }}>
                        <Icon className="w-3.5 h-3.5" style={{ color: isSelected ? "#10b981" : "#6b7ca0" }} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-medium truncate" style={{ color: isSelected ? "#e8edf5" : "#94a3b8" }}>
                          {item.label}
                        </div>
                        <div className="text-xs truncate" style={{ color: "#6b7ca0" }}>{item.sub}</div>
                      </div>
                      {isSelected && (
                        <kbd className="text-xs px-1.5 py-0.5 rounded flex-shrink-0"
                          style={{ background: "rgba(16,185,129,0.1)", color: "#10b981", border: "1px solid rgba(16,185,129,0.2)" }}>↵</kbd>
                      )}
                    </button>
                  );
                })}
              </div>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center gap-4 px-4 py-2.5 border-t text-xs"
          style={{ borderColor: "rgba(255,255,255,0.05)", color: "#3d4f6b" }}>
          <span><kbd style={{ color: "#6b7ca0" }}>↑↓</kbd> navigate</span>
          <span><kbd style={{ color: "#6b7ca0" }}>↵</kbd> open</span>
          <span><kbd style={{ color: "#6b7ca0" }}>ESC</kbd> close</span>
        </div>
      </div>
    </div>
  );
}

// ─── Nav data ─────────────────────────────────────────────────────────────────

const navGroups = [
  {
    label: "Overview",
    translationKey: "overview",
    items: [
      { name: "Dashboard", translationKey: "dashboard", path: "/app", icon: LayoutDashboard },
      { name: "Analytics", translationKey: "analytics", path: "/app/analytics", icon: BarChart3 },
    ],
  },
  {
    label: "Money",
    translationKey: "money",
    items: [
      { name: "Transactions", translationKey: "transactions", path: "/app/transactions", icon: Receipt },
      { name: "Budget", translationKey: "budget", path: "/app/budget", icon: Wallet },
      { name: "Goals", translationKey: "goals", path: "/app/goals", icon: Target },
      { name: "Calculator", translationKey: "calculator", path: "/app/calculator", icon: CalcIcon },
    ],
  },
  {
    label: "AI Tools",
    translationKey: "aiTools",
    items: [
      { name: "Voice Entry", translationKey: "voiceEntry", path: "/app/voice", icon: Mic },
      { name: "Receipt Scanner", translationKey: "scanner", path: "/app/scanner", icon: ScanLine },
      { name: "AI Insights", translationKey: "aiInsights", path: "/app/insights", icon: Brain },
      { name: "AI Predictions", translationKey: "aiPredictions", path: "/app/predictions", icon: TrendingUp },
      { name: "AI Chatbot", translationKey: "chatbot", path: "/app/chatbot", icon: Bot },
    ],
  },
  {
    label: "Security",
    translationKey: "security",
    items: [
      { name: "Alerts", translationKey: "alerts", path: "/app/alerts", icon: AlertTriangle },
      { name: "Bank Import", translationKey: "bankImport", path: "/app/import", icon: Upload },
      { name: "UPI Import", translationKey: "upiImport", path: "/app/upi-import", icon: Smartphone },
    ],
  },
  {
    label: "Account",
    translationKey: "account",
    items: [
      { name: "Profile", translationKey: "profile", path: "/app/profile", icon: User },
      { name: "Settings", translationKey: "settings", path: "/app/settings", icon: SettingsIcon },
    ],
  },
];

// ─── Root Layout ──────────────────────────────────────────────────────────────

export default function Root() {
  const { t } = useTranslation();
  const location = useLocation();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [lastSync, setLastSync] = useState<string>("");
  const { user } = useAuth();
  const { theme, toggle: toggleTheme } = useTheme();

  const [notifications, setNotifications] = useState([
    {
      id: "n1",
      title: "Suspicious Dining Spike Flagged",
      msg: "Anomalous ₹28,500 transaction at Luxury Lounge was flagged by AI Risk Defense.",
      time: "10m ago",
      read: false,
      link: "/app/alerts",
    },
    {
      id: "n2",
      title: "Groceries Budget Warning",
      msg: "You have reached 88% of your monthly Groceries allocation.",
      time: "2h ago",
      read: false,
      link: "/app/budget",
    },
    {
      id: "n3",
      title: "Upcoming Bill Reminder",
      msg: "Apartment Maintenance bill of ₹4,500 is due in 3 days.",
      time: "1d ago",
      read: true,
      link: "/app/alerts",
    },
  ]);

  const unreadCount = notifications.filter((n) => !n.read).length;

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);
    setLastSync(new Date().toLocaleTimeString());
    const interval = setInterval(() => {
      if (isOnline) setLastSync(new Date().toLocaleTimeString());
    }, 60000);
    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      clearInterval(interval);
    };
  }, [isOnline]);

  // Global Ctrl+K shortcut
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        setSearchOpen((prev) => !prev);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  const isActive = (path: string) =>
    path === "/app" ? location.pathname === "/app" : location.pathname.startsWith(path);

  return (
    <div className="min-h-screen" style={{ background: "#080c14" }}>
      <GlobalSearch isOpen={searchOpen} onClose={() => setSearchOpen(false)} />

      {/* Mobile Header */}
      <div
        className="lg:hidden sticky top-0 z-40 border-b px-4 h-16 flex items-center justify-between"
        style={{ background: "rgba(8,12,20,0.9)", backdropFilter: "blur(20px)", borderColor: "rgba(255,255,255,0.06)" }}
      >
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg flex items-center justify-center"
            style={{ background: "linear-gradient(135deg, #10b981, #3b82f6)" }}>
            <Wallet className="w-4 h-4 text-white" />
          </div>
          <span className="font-bold" style={{ color: "#e8edf5" }}>
            Finance<span style={{ color: "#10b981" }}>AI</span>
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => setSearchOpen(true)}
            className="p-2 rounded-lg" style={{ color: "#6b7ca0" }}>
            <Search className="w-5 h-5" />
          </button>
          <button className="p-2 rounded-lg transition-colors" style={{ color: "#6b7ca0" }}
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="lg:hidden fixed inset-0 z-30 pt-16 overflow-y-auto" style={{ background: "#080c14" }}>
          <nav className="px-4 py-4 space-y-1">
            {navGroups.map((group) => (
              <div key={group.label} className="mb-4">
                <div className="text-xs font-semibold uppercase tracking-widest px-3 mb-2"
                  style={{ color: "#3d4f6b", letterSpacing: "0.1em" }}>{t(group.translationKey)}</div>
                {group.items.map((item) => {
                  const active = isActive(item.path);
                  return (
                    <Link key={item.path} to={item.path} onClick={() => setMobileMenuOpen(false)}
                      className="flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all mb-0.5"
                      style={{
                        background: active ? "rgba(16,185,129,0.1)" : "transparent",
                        color: active ? "#10b981" : "#6b7ca0",
                        border: active ? "1px solid rgba(16,185,129,0.2)" : "1px solid transparent",
                      }}>
                      <item.icon className="w-5 h-5" />
                      <span className="font-medium text-sm">{t(item.translationKey)}</span>
                    </Link>
                  );
                })}
              </div>
            ))}
          </nav>
        </div>
      )}

      <div className="lg:flex">
        {/* Desktop Sidebar */}
        <div className="hidden lg:flex lg:flex-col lg:fixed lg:inset-y-0 lg:w-64 border-r"
          style={{ background: "#0a0f1e", borderColor: "rgba(255,255,255,0.05)" }}>

          {/* Logo */}
          <div className="flex items-center gap-2.5 px-5 h-16 border-b flex-shrink-0"
            style={{ borderColor: "rgba(255,255,255,0.05)" }}>
            <div className="w-9 h-9 rounded-xl flex items-center justify-center"
              style={{ background: "linear-gradient(135deg, #10b981, #3b82f6)" }}>
              <Wallet className="w-5 h-5 text-white" />
            </div>
            <span className="text-lg font-bold" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>
              Finance<span style={{ color: "#10b981" }}>AI</span>
            </span>
          </div>

          {/* AI Quick Action */}
          <div className="px-4 pt-4">
            <Link to="/app/chatbot"
              className="flex items-center gap-2 w-full px-3 py-2.5 rounded-xl text-sm font-medium transition-all"
              style={{ background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.2)", color: "#10b981" }}>
              <Sparkles className="w-4 h-4" />
              <span>{t('chatbot')}</span>
            </Link>
          </div>

          {/* Nav */}
          <nav className="flex-1 px-4 py-4 overflow-y-auto space-y-5">
            {navGroups.map((group) => (
              <div key={group.label}>
                <div className="text-xs font-semibold uppercase tracking-widest px-3 mb-2"
                  style={{ color: "#3d4f6b", letterSpacing: "0.1em" }}>{t(group.translationKey)}</div>
                <div className="space-y-0.5">
                  {group.items.map((item) => {
                    const active = isActive(item.path);
                    return (
                      <Link key={item.path} to={item.path}
                        className="flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all"
                        style={{
                          background: active ? "rgba(16,185,129,0.1)" : "transparent",
                          color: active ? "#10b981" : "#6b7ca0",
                          border: active ? "1px solid rgba(16,185,129,0.2)" : "1px solid transparent",
                        }}
                        onMouseEnter={(e) => {
                          if (!active) {
                            (e.currentTarget as HTMLElement).style.background = "rgba(255,255,255,0.04)";
                            (e.currentTarget as HTMLElement).style.color = "#e8edf5";
                          }
                        }}
                        onMouseLeave={(e) => {
                          if (!active) {
                            (e.currentTarget as HTMLElement).style.background = "transparent";
                            (e.currentTarget as HTMLElement).style.color = "#6b7ca0";
                          }
                        }}>
                        <item.icon className="w-4 h-4" />
                        <span className="font-medium text-sm">{t(item.translationKey)}</span>
                        {item.name === "Alerts" && (
                          <span className="ml-auto text-xs font-bold px-1.5 py-0.5 rounded-full"
                            style={{ background: "rgba(239,68,68,0.15)", color: "#ef4444" }}>2</span>
                        )}
                      </Link>
                    );
                  })}
                </div>
              </div>
            ))}
          </nav>

          {/* User Profile */}
          <div className="px-4 pb-4 border-t pt-4" style={{ borderColor: "rgba(255,255,255,0.05)" }}>
            <div className="flex items-center gap-3 px-3 py-2.5 rounded-xl"
              style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.06)" }}>
              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
                style={{ background: "linear-gradient(135deg, #10b981, #3b82f6)", color: "#fff" }}>
                {user?.name?.[0]?.toUpperCase() || "U"}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-semibold truncate" style={{ color: "#e8edf5" }}>{user?.name || "User"}</div>
                <div className="text-xs truncate" style={{ color: "#6b7ca0" }}>{user?.email || "user@email.com"}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="lg:pl-64 flex-1 min-h-screen">
          {/* Top Bar */}
          <div
            className="hidden lg:flex sticky top-0 z-30 h-16 border-b items-center justify-between px-8"
            style={{ background: "rgba(8,12,20,0.9)", backdropFilter: "blur(20px)", borderColor: "rgba(255,255,255,0.05)" }}
          >
            {/* Search trigger */}
            <button
              onClick={() => setSearchOpen(true)}
              className="flex items-center gap-2 px-3 py-2 rounded-xl w-72 text-left transition-all"
              style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)" }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLElement).style.borderColor = "rgba(16,185,129,0.3)"; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLElement).style.borderColor = "rgba(255,255,255,0.06)"; }}
            >
              <Search className="w-4 h-4 flex-shrink-0" style={{ color: "#6b7ca0" }} />
              <span className="text-sm flex-1" style={{ color: "#3d4f6b" }}>Search anything...</span>
              <div className="flex items-center gap-1">
                <kbd className="text-xs px-1.5 py-0.5 rounded flex items-center gap-0.5"
                  style={{ background: "rgba(255,255,255,0.06)", color: "#3d4f6b" }}>
                  <Command className="w-3 h-3" />K
                </kbd>
              </div>
            </button>

            <div className="flex items-center gap-2">
              {!isOnline && (
                <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium"
                  style={{ background: "rgba(239,68,68,0.1)", color: "#ef4444" }}>
                  <WifiOff className="w-3 h-3" /> Offline
                </div>
              )}
              {isOnline && lastSync && (
                <div className="flex items-center gap-1.5 text-xs" style={{ color: "#6b7ca0" }}>
                  <Clock className="w-3 h-3" /> {lastSync}
                </div>
              )}

              <LanguageSwitcher />

              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                title={`Switch to ${theme === "dark" ? "light" : "dark"} mode`}
                className="w-9 h-9 rounded-xl flex items-center justify-center transition-all"
                style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)", color: "#6b7ca0" }}
                onMouseEnter={(e) => { (e.currentTarget as HTMLElement).style.color = "#e8edf5"; }}
                onMouseLeave={(e) => { (e.currentTarget as HTMLElement).style.color = "#6b7ca0"; }}
              >
                {theme === "dark" ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </button>

              {/* Notifications Dropdown */}
              <div className="relative">
                <button
                  onClick={() => setNotifOpen(!notifOpen)}
                  className="w-9 h-9 rounded-xl flex items-center justify-center relative transition-colors"
                  style={{
                    background: notifOpen ? "rgba(16,185,129,0.15)" : "rgba(255,255,255,0.04)",
                    border: notifOpen ? "1px solid rgba(16,185,129,0.3)" : "1px solid rgba(255,255,255,0.06)",
                  }}
                >
                  <Bell className="w-4 h-4" style={{ color: notifOpen ? "#10b981" : "#6b7ca0" }} />
                  {unreadCount > 0 && (
                    <span
                      className="absolute -top-1 -right-1 w-4 h-4 rounded-full border-2 text-[9px] font-bold flex items-center justify-center animate-pulse"
                      style={{ background: "#ef4444", borderColor: "#080c14", color: "#fff" }}
                    >
                      {unreadCount}
                    </span>
                  )}
                </button>

                {notifOpen && (
                  <div
                    className="absolute right-0 mt-3 w-80 sm:w-96 rounded-2xl shadow-2xl p-4 border z-50 overflow-hidden"
                    style={{
                      background: "#0c1324",
                      borderColor: "rgba(255,255,255,0.12)",
                      boxShadow: "0 20px 50px rgba(0,0,0,0.8), 0 0 30px rgba(16,185,129,0.15)",
                    }}
                  >
                    <div className="flex items-center justify-between border-b pb-3 mb-3" style={{ borderColor: "rgba(255,255,255,0.08)" }}>
                      <div className="flex items-center gap-2">
                        <Bell className="w-4 h-4 text-emerald-400" />
                        <span className="font-bold text-sm text-white">System Notifications</span>
                      </div>
                      {unreadCount > 0 && (
                        <button
                          onClick={() => {
                            setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
                          }}
                          className="text-[11px] text-emerald-400 hover:underline font-medium"
                        >
                          Mark all as read
                        </button>
                      )}
                    </div>

                    <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
                      {notifications.map((n) => (
                        <div
                          key={n.id}
                          onClick={() => {
                            setNotifications((prev) => prev.map((item) => (item.id === n.id ? { ...item, read: true } : item)));
                            navigate(n.link);
                            setNotifOpen(false);
                          }}
                          className={`p-3 rounded-xl border transition-all cursor-pointer ${
                            n.read ? "bg-white/[0.02] border-white/[0.05]" : "bg-emerald-500/10 border-emerald-500/30"
                          }`}
                        >
                          <div className="flex items-start justify-between gap-2">
                            <span className="text-xs font-bold text-white">{n.title}</span>
                            <span className="text-[10px] text-slate-400 font-mono">{n.time}</span>
                          </div>
                          <p className="text-xs text-slate-300 mt-1 leading-relaxed">{n.msg}</p>
                        </div>
                      ))}
                    </div>

                    <div className="pt-3 mt-3 border-t text-center" style={{ borderColor: "rgba(255,255,255,0.08)" }}>
                      <Link
                        to="/app/alerts"
                        onClick={() => setNotifOpen(false)}
                        className="text-xs font-semibold text-emerald-400 hover:text-emerald-300 transition-colors"
                      >
                        View All Security Alerts →
                      </Link>
                    </div>
                  </div>
                )}
              </div>

              <Link to="/app/chatbot"
                className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-all"
                style={{ background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.2)", color: "#10b981" }}>
                <Bot className="w-4 h-4" /> AI Assistant
              </Link>
            </div>
          </div>

          <main className="p-4 lg:p-8 pb-24 lg:pb-8">
            <Outlet />
          </main>
        </div>
      </div>

      {/* Mobile Bottom Navigation Bar */}
      <div
        className="lg:hidden fixed bottom-0 left-0 right-0 z-40 border-t flex items-center justify-around px-2 py-2"
        style={{ background: "rgba(8,12,20,0.95)", backdropFilter: "blur(20px)", borderColor: "rgba(255,255,255,0.08)" }}
      >
        <Link
          to="/app"
          className={`flex flex-col items-center gap-1 p-1.5 rounded-lg text-[10px] font-medium transition-all ${
            location.pathname === "/app" ? "text-emerald-400 font-bold" : "text-gray-400 hover:text-gray-200"
          }`}
        >
          <LayoutDashboard className="w-4 h-4" />
          <span>Home</span>
        </Link>
        <Link
          to="/app/transactions"
          className={`flex flex-col items-center gap-1 p-1.5 rounded-lg text-[10px] font-medium transition-all ${
            location.pathname.startsWith("/app/transactions") ? "text-emerald-400 font-bold" : "text-gray-400 hover:text-gray-200"
          }`}
        >
          <Receipt className="w-4 h-4" />
          <span>Activity</span>
        </Link>
        <Link
          to="/app/voice"
          className="flex flex-col items-center justify-center -mt-5"
        >
          <div className="w-11 h-11 rounded-full bg-gradient-to-r from-emerald-500 to-blue-500 flex items-center justify-center text-white shadow-lg shadow-emerald-500/30">
            <Mic className="w-5 h-5" />
          </div>
          <span className="text-[10px] text-emerald-400 font-bold mt-1">Voice</span>
        </Link>
        <Link
          to="/app/analytics"
          className={`flex flex-col items-center gap-1 p-1.5 rounded-lg text-[10px] font-medium transition-all ${
            location.pathname.startsWith("/app/analytics") ? "text-emerald-400 font-bold" : "text-gray-400 hover:text-gray-200"
          }`}
        >
          <BarChart3 className="w-4 h-4" />
          <span>Analytics</span>
        </Link>
        <Link
          to="/app/settings"
          className={`flex flex-col items-center gap-1 p-1.5 rounded-lg text-[10px] font-medium transition-all ${
            location.pathname.startsWith("/app/settings") ? "text-emerald-400 font-bold" : "text-gray-400 hover:text-gray-200"
          }`}
        >
          <SettingsIcon className="w-4 h-4" />
          <span>Settings</span>
        </Link>
      </div>
    </div>
  );
}
