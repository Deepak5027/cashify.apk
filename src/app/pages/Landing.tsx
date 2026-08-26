import { Link } from "react-router";
import { useState, useEffect, useRef, useId, useCallback } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "../contexts/AuthContext";
import {
  Brain,
  Wallet,
  ArrowRight,
  Shield,
  TrendingUp,
  Scan,
  Bell,
  BarChart3,
  Mic,
  Zap,
  Target,
  Star,
  Bot,
  Sparkles,
  Activity,
  PieChart,
  CreditCard,
  Home,
  GraduationCap,
  Briefcase,
  Users,
  CheckCircle2,
  Play,
  Globe,
  Lock,
  X,
  Menu,
  ChevronRight,
  ChevronLeft,
  ArrowUpRight,
  Flame,
  Award,
  Cpu,
  Layers,
  Smartphone,
  Eye,
  Coins,
  DollarSign,
  TrendingDown,
} from "lucide-react";

// --- Types & Data ---

const userModes = [
  {
    id: "business",
    label: "Business Owner",
    icon: Briefcase,
    color: "#10b981",
    accentLight: "#34d399",
    glow: "rgba(16, 185, 129, 0.35)",
    tagline: "Profit-driven financial control & cash flow foresight",
    description:
      "Engineered for founders, retailers, and MSME owners managing complex supplier invoices, GST filing cycles, payroll, and 6-month predictive cash runways.",
    badge: "ENTERPRISE GRADE",
    features: [
      "Real-time profit & loss analytics dashboard",
      "Supplier expense tracking & invoice reconciliation",
      "Automated salary & payroll disbursement planner",
      "Dynamic GST & advance tax liability estimation",
      "Predictive 6-month business cash flow forecasting",
      "Vendor payment scheduling with penalty avoidance",
    ],
    stats: [
      { label: "Avg. Monthly Savings", value: "₹28,400", change: "+34% YoY", trend: "up" },
      { label: "Tax Filing Accuracy", value: "99.2%", change: "Zero penalties", trend: "up" },
      { label: "Admin Time Saved", value: "14 hrs/mo", change: "100% automated", trend: "up" },
    ],
  },
  {
    id: "student",
    label: "Student",
    icon: GraduationCap,
    color: "#38bdf8",
    accentLight: "#7dd3fc",
    glow: "rgba(56, 189, 248, 0.35)",
    tagline: "Smart money habits for high-impact futures",
    description:
      "Built for college and university students mastering pocket money allowances, shared flat bills, OTT subscriptions, and first milestone savings goals.",
    badge: "COLLEGE READY",
    features: [
      "Pocket money tracker with daily burn-rate limit",
      "Subscription vampire detector & renewal alerts",
      "Food delivery & hangout spend analyzer",
      "Gamified savings challenges with badge rewards",
      "Instant expense splitting & UPI settlement links",
      "Semester textbook & project budget allocator",
    ],
    stats: [
      { label: "Avg. Monthly Savings", value: "₹3,200", change: "+42% Saved", trend: "up" },
      { label: "Overspend Prevented", value: "84%", change: "Early AI alert", trend: "up" },
      { label: "Target Goals Met", value: "91%", change: "On streak", trend: "up" },
    ],
  },
  {
    id: "housewife",
    label: "Home Manager",
    icon: Home,
    color: "#f59e0b",
    accentLight: "#fbbf24",
    glow: "rgba(245, 158, 11, 0.35)",
    tagline: "Run your household finances like a Fortune 500 CFO",
    description:
      "Crafted for family portfolio leaders handling multi-store groceries, electricity & gas bill calendars, tuition schedules, and emergency reserve funds.",
    badge: "FAMILY FIRST",
    features: [
      "Smart grocery list budgeting with price estimation",
      "Multi-member household expense categorization",
      "Electricity, water & gas bill auto-reminders",
      "Long-term family emergency cushion builder",
      "School tuition & extracurricular fee timeline",
      "Festival, vacation & wedding occasion fund planner",
    ],
    stats: [
      { label: "Avg. Monthly Savings", value: "₹6,800", change: "+28% Surplus", trend: "up" },
      { label: "Bill Due Alerts", value: "100%", change: "Never miss", trend: "up" },
      { label: "Family Goals Met", value: "88%", change: "+15% YoY", trend: "up" },
    ],
  },
  {
    id: "freelancer",
    label: "Freelancer",
    icon: Users,
    color: "#a855f7",
    accentLight: "#c084fc",
    glow: "rgba(168, 85, 247, 0.35)",
    tagline: "Total financial clarity with irregular income streams",
    description:
      "Designed for independent contractors, creators, and consultants needing income-smoothing algorithms, quarterly tax countdowns, and project ROI scoring.",
    badge: "CREATOR ECONOMY",
    features: [
      "Irregular income smoothing & safe-spend envelope",
      "Client invoice status tracker & overdue nudges",
      "Advance tax estimator with quarterly countdown",
      "Client project hourly profitability scoring",
      "6-month emergency buffer AI recommendations",
      "Upskilling & software tool ROI tracker",
    ],
    stats: [
      { label: "Avg. Monthly Savings", value: "₹11,600", change: "+31% Retained", trend: "up" },
      { label: "Tax Filing Accuracy", value: "97%", change: "CA-compliant", trend: "up" },
      { label: "Income Predictability", value: "+62%", change: "ML smoothed", trend: "up" },
    ],
  },
];

const aiFeatures = [
  {
    icon: Bot,
    title: "Conversational Financial Co-Pilot",
    description:
      "Ask anything about your cash in natural language. Get instant, deeply personalized intelligence powered by real-time neural models.",
    tag: "GPT-4o Finance",
    color: "#10b981",
    glow: "rgba(16, 185, 129, 0.25)",
    metric: "< 320ms latency",
  },
  {
    icon: Activity,
    title: "Predictive Overspend Radar",
    description:
      "Proprietary time-series algorithms forecast category budget breaches 5-7 days before they happen, giving you time to course-correct.",
    tag: "Time-Series ML",
    color: "#38bdf8",
    glow: "rgba(56, 189, 248, 0.25)",
    metric: "94.8% accuracy",
  },
  {
    icon: Scan,
    title: "High-Speed OCR Intelligence",
    description:
      "Snap physical bills and paper receipts. Neural computer vision extracts merchant, amount, category, and GST lines in under 2 seconds.",
    tag: "Vision OCR",
    color: "#a855f7",
    glow: "rgba(168, 85, 247, 0.25)",
    metric: "Sub-2s scan speed",
  },
  {
    icon: Mic,
    title: "Voice Natural Language Entry",
    description:
      '"Spent 450 rupees on groceries via UPI" — speak naturally in English, Hindi, or mixed phrases. AI parses, logs, and categorizes instantly.',
    tag: "Speech-to-Intent",
    color: "#f59e0b",
    glow: "rgba(245, 158, 11, 0.25)",
    metric: "Multi-dialect support",
  },
  {
    icon: PieChart,
    title: "Behavioral Spend Clustering",
    description:
      "Unsupervised clustering models detect emotional spending triggers, late-night ordering trends, and surface high-leverage micro-saving opportunities.",
    tag: "Clustering ML",
    color: "#06b6d4",
    glow: "rgba(6, 182, 212, 0.25)",
    metric: "Weekly analytics",
  },
  {
    icon: Shield,
    title: "Real-Time Fraud & Anomaly Defense",
    description:
      "Multi-signal heuristics cross-examine suspicious merchant names, time windows, and velocity spikes to safeguard your liquidity 24/7.",
    tag: "Live Defense Core",
    color: "#ef4444",
    glow: "rgba(239, 68, 68, 0.25)",
    metric: "Zero-latency scoring",
  },
];

const testimonials = [
  {
    name: "Riya Sharma",
    role: "Founder, PeakPulse Health • Bangalore",
    avatar: "RS",
    color: "#10b981",
    tag: "Business Mode",
    text: "FinanceAI completely redefined our cash management. The automated tax liability predictor saves me 8 hours every single month. The AI forecast models are startlingly accurate.",
    rating: 5,
    saved: "₹34,000 saved/mo",
  },
  {
    name: "Arjun Mehta",
    role: "B.Tech Final Year, IIT Bombay • Mumbai",
    avatar: "AM",
    color: "#38bdf8",
    tag: "Student Mode",
    text: "I used to exhaust my monthly allowance by the 18th. The predictive overspend radar gives me subtle nudges before I overspend on dining. It has completely changed my habits.",
    rating: 5,
    saved: "₹4,500 saved/mo",
  },
  {
    name: "Priya Nair",
    role: "Family Portfolio Manager • Chennai",
    avatar: "PN",
    color: "#f59e0b",
    tag: "Home Manager",
    text: "Managing a family of five with multiple school tuitions and grocery spikes was chaotic. FinanceAI organized our cash flows into clean crystal visibility.",
    rating: 5,
    saved: "₹12,800 saved/mo",
  },
  {
    name: "Karthik Reddy",
    role: "Product Designer & Consultant • Hyderabad",
    avatar: "KR",
    color: "#a855f7",
    tag: "Freelancer Mode",
    text: "With irregular retainer dates, budgeting was guesswork. The variable income smoothing envelope gave me immediate financial certainty and flawless quarterly tax filings.",
    rating: 5,
    saved: "₹19,200 saved/mo",
  },
];

// --- 3D Particle & Holographic Canvas ---

function HologramOrbCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;
    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    const onResize = () => {
      if (!canvas) return;
      width = canvas.width = canvas.offsetWidth;
      height = canvas.height = canvas.offsetHeight;
    };
    window.addEventListener("resize", onResize);

    // Generate 3D point cloud on sphere
    const numPoints = 140;
    const radius = Math.min(width, height) * 0.38;
    const points: { x: number; y: number; z: number; origX: number; origY: number; origZ: number }[] = [];

    for (let i = 0; i < numPoints; i++) {
      const theta = Math.acos(2 * Math.random() - 1);
      const phi = 2 * Math.PI * Math.random();
      const x = radius * Math.sin(theta) * Math.cos(phi);
      const y = radius * Math.sin(theta) * Math.sin(phi);
      const z = radius * Math.cos(theta);
      points.push({ x, y, z, origX: x, origY: y, origZ: z });
    }

    let angleX = 0;
    let angleY = 0;

    const render = () => {
      ctx.clearRect(0, 0, width, height);

      const centerX = width / 2;
      const centerY = height / 2;
      angleX += 0.004;
      angleY += 0.007;

      const cosX = Math.cos(angleX);
      const sinX = Math.sin(angleX);
      const cosY = Math.cos(angleY);
      const sinY = Math.sin(angleY);

      const projectedPoints: { px: number; py: number; pz: number; alpha: number }[] = [];

      for (let i = 0; i < points.length; i++) {
        const p = points[i];
        // Rotate around Y
        const x1 = p.origX * cosY - p.origZ * sinY;
        const z1 = p.origZ * cosY + p.origX * sinY;
        // Rotate around X
        const y1 = p.origY * cosX - z1 * sinX;
        const z2 = z1 * cosX + p.origY * sinX;

        const fov = 350;
        const scale = fov / (fov + z2 + radius);
        const px = centerX + x1 * scale;
        const py = centerY + y1 * scale;
        const alpha = Math.max(0.15, (z2 + radius) / (2 * radius));

        projectedPoints.push({ px, py, pz: z2, alpha });
      }

      // Draw connective holographic lines between nearby points
      for (let i = 0; i < projectedPoints.length; i++) {
        for (let j = i + 1; j < projectedPoints.length; j++) {
          const p1 = projectedPoints[i];
          const p2 = projectedPoints[j];
          const dx = p1.px - p2.px;
          const dy = p1.py - p2.py;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 55) {
            const lineAlpha = (1 - dist / 55) * Math.min(p1.alpha, p2.alpha) * 0.45;
            ctx.beginPath();
            ctx.moveTo(p1.px, p1.py);
            ctx.lineTo(p2.px, p2.py);
            ctx.strokeStyle = `rgba(16, 185, 129, ${lineAlpha})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();
          }
        }
      }

      // Draw particle glowing nodes
      for (let i = 0; i < projectedPoints.length; i++) {
        const p = projectedPoints[i];
        const pointSize = Math.max(1, (p.pz + radius) / (radius * 0.7));

        ctx.beginPath();
        ctx.arc(p.px, p.py, pointSize, 0, Math.PI * 2);
        ctx.fillStyle = i % 3 === 0 ? `rgba(56, 189, 248, ${p.alpha})` : `rgba(16, 185, 129, ${p.alpha})`;
        ctx.shadowBlur = 8;
        ctx.shadowColor = i % 3 === 0 ? "rgba(56, 189, 248, 0.8)" : "rgba(16, 185, 129, 0.8)";
        ctx.fill();
        ctx.shadowBlur = 0;
      }

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener("resize", onResize);
      cancelAnimationFrame(animationFrameId);
    };
  }, []);

  return <canvas ref={canvasRef} className="w-full h-full pointer-events-none opacity-80" />;
}

// --- Interactive 3D Tilt Card Component ---

function TiltCard3D({
  children,
  className = "",
  style = {},
  glowColor = "rgba(16, 185, 129, 0.3)",
  maxTilt = 14,
  depth = 28,
}: {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  glowColor?: string;
  maxTilt?: number;
  depth?: number;
}) {
  const cardRef = useRef<HTMLDivElement>(null);
  const [coords, setCoords] = useState({ x: 0, y: 0, glareX: 50, glareY: 50, isHovered: false });

  const handleMouseMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (!cardRef.current) return;
      const rect = cardRef.current.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = ((y - centerY) / centerY) * -maxTilt;
      const rotateY = ((x - centerX) / centerX) * maxTilt;
      const glareX = (x / rect.width) * 100;
      const glareY = (y / rect.height) * 100;

      setCoords({ x: rotateX, y: rotateY, glareX, glareY, isHovered: true });
    },
    [maxTilt]
  );

  const handleMouseLeave = useCallback(() => {
    setCoords({ x: 0, y: 0, glareX: 50, glareY: 50, isHovered: false });
  }, []);

  return (
    <div style={{ perspective: 1200 }} className={`transition-all duration-200 ${className}`}>
      <div
        ref={cardRef}
        onMouseMove={handleMouseMove}
        onMouseEnter={() => setCoords((prev) => ({ ...prev, isHovered: true }))}
        onMouseLeave={handleMouseLeave}
        style={{
          transform: `rotateX(${coords.x}deg) rotateY(${coords.y}deg)`,
          transformStyle: "preserve-3d",
          transition: coords.isHovered ? "transform 0.08s ease-out" : "transform 0.5s cubic-bezier(0.2, 0.8, 0.2, 1)",
          ...style,
        }}
        className="relative group rounded-3xl"
      >
        {/* Dynamic Specular Light Glare */}
        {coords.isHovered && (
          <div
            className="pointer-events-none absolute inset-0 rounded-3xl z-30 transition-opacity duration-200"
            style={{
              background: `radial-gradient(circle at ${coords.glareX}% ${coords.glareY}%, rgba(255, 255, 255, 0.16) 0%, transparent 65%)`,
            }}
          />
        )}

        {/* Ambient Halo Glow */}
        <div
          className="pointer-events-none absolute -inset-[1px] rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl -z-10"
          style={{ background: glowColor }}
        />

        {/* Inner Content with Z-Depth */}
        <div style={{ transform: `translateZ(${depth}px)`, transformStyle: "preserve-3d" }}>{children}</div>
      </div>
    </div>
  );
}

// --- Dynamic 3D Hero Stage (Phone Mockup + Holographic Orb + Floating Depth Cards) ---

function Hero3DStage() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [tilt, setTilt] = useState({ x: -4, y: 8 });

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
    const y = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
    setTilt({ x: -y * 12, y: x * 16 });
  };

  const handleMouseLeave = () => {
    setTilt({ x: -3, y: 6 });
  };

  return (
    <div
      ref={containerRef}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className="relative w-full max-w-6xl mx-auto min-h-[540px] lg:min-h-[640px] flex items-center justify-center p-4 my-8"
      style={{ perspective: 1600 }}
    >
      {/* Background Holographic 3D Particle Orb */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none -z-10 overflow-hidden">
        <div className="w-[500px] h-[500px] sm:w-[680px] sm:h-[680px] relative">
          <HologramOrbCanvas />
        </div>
      </div>

      {/* Main 3D Floating Glassmorphic Device Terminal */}
      <motion.div
        style={{
          transform: `rotateX(${tilt.x}deg) rotateY(${tilt.y}deg)`,
          transformStyle: "preserve-3d",
          transition: "transform 0.12s ease-out",
        }}
        initial={{ opacity: 0, scale: 0.9, y: 50 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
        className="relative w-full max-w-4xl rounded-[32px] border border-white/15 bg-gradient-to-b from-[#0c1322]/95 via-[#080d18]/95 to-[#050912]/95 backdrop-blur-2xl shadow-[0_40px_120px_rgba(0,0,0,0.9),0_0_80px_rgba(16,185,129,0.18)] p-6 sm:p-8 md:p-10 z-10"
      >
        {/* Edge Lighting Top Bar */}
        <div className="absolute top-0 inset-x-8 h-[1px] bg-gradient-to-r from-transparent via-emerald-400/80 to-transparent" />

        {/* Terminal Header */}
        <div className="flex items-center justify-between border-b border-white/[0.08] pb-5 mb-6">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <div className="w-3.5 h-3.5 rounded-full bg-rose-500 shadow-[0_0_10px_rgba(244,63,94,0.8)]" />
              <div className="w-3.5 h-3.5 rounded-full bg-amber-500 shadow-[0_0_10px_rgba(245,158,11,0.8)]" />
              <div className="w-3.5 h-3.5 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.8)]" />
            </div>
            <div className="hidden sm:flex items-center gap-2 pl-3 border-l border-white/10 font-mono text-xs text-slate-400">
              <Sparkles className="w-3.5 h-3.5 text-emerald-400" />
              <span>FINANCE-AI ENGINE v4.8 • LIVE TELEMETRY</span>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-mono font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 shadow-[0_0_15px_rgba(16,185,129,0.2)]">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
              ALL SYSTEMS ONLINE
            </span>
          </div>
        </div>

        {/* Main Dashboard Metric Tiles */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3.5 sm:gap-4 mb-6">
          {[
            {
              label: "Net Liquid Balance",
              val: "₹3,42,850.00",
              change: "+14.8% this mo",
              color: "text-emerald-400",
              border: "border-emerald-500/30",
              bg: "bg-emerald-500/5",
            },
            {
              label: "Monthly Verified Inflow",
              val: "₹95,000.00",
              change: "Salary + Retainer",
              color: "text-sky-400",
              border: "border-sky-500/30",
              bg: "bg-sky-500/5",
            },
            {
              label: "Current Spend Burn",
              val: "₹38,240.00",
              change: "-12.4% below limit",
              color: "text-amber-400",
              border: "border-amber-500/30",
              bg: "bg-amber-500/5",
            },
            {
              label: "Financial Health Score",
              val: "94 / 100",
              change: "Top 5% Quartile",
              color: "text-purple-400",
              border: "border-purple-500/30",
              bg: "bg-purple-500/5",
            },
          ].map((stat, i) => (
            <div
              key={stat.label}
              className={`rounded-2xl p-4 sm:p-5 border ${stat.border} ${stat.bg} backdrop-blur-md relative overflow-hidden`}
              style={{ transform: `translateZ(${18 + i * 6}px)` }}
            >
              <div className="text-[11px] sm:text-xs text-slate-400 font-medium mb-1.5">{stat.label}</div>
              <div className="text-lg sm:text-2xl font-extrabold font-mono tracking-tight text-white mb-1.5">
                {stat.val}
              </div>
              <div className={`text-[11px] font-semibold ${stat.color} flex items-center gap-1`}>
                <TrendingUp className="w-3 h-3" />
                {stat.change}
              </div>
            </div>
          ))}
        </div>

        {/* 3D Interactive Chart Visualizer & Neural Co-Pilot Advice */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
          <div
            className="md:col-span-2 rounded-2xl bg-white/[0.02] p-5 sm:p-6 border border-white/[0.08]"
            style={{ transform: "translateZ(24px)" }}
          >
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-slate-300">
                  90-Day Predictive Cash Runway
                </div>
                <div className="text-[11px] text-slate-400">Continuous time-series ML regression model</div>
              </div>
              <span className="text-xs font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-md border border-emerald-500/20">
                + ₹28,400 Projected Surplus
              </span>
            </div>

            {/* Glowing bar chart visualizer */}
            <div className="h-32 flex items-end gap-2.5 pt-2">
              {[38, 48, 42, 65, 54, 72, 58, 80, 86, 75, 92, 98].map((h, i) => (
                <div key={i} className="flex-1 flex flex-col items-center gap-1.5 h-full justify-end group">
                  <div
                    className="w-full rounded-md transition-all duration-300 relative group-hover:brightness-125"
                    style={{
                      height: `${h}%`,
                      background:
                        i >= 9
                          ? "linear-gradient(180deg, #38bdf8 0%, #0284c7 100%)"
                          : "linear-gradient(180deg, #10b981 0%, #047857 100%)",
                      boxShadow: i === 11 ? "0 0 20px rgba(56, 189, 248, 0.6)" : "none",
                    }}
                  />
                  <span className="text-[10px] font-mono text-slate-400">
                    {["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][i]}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div
            className="rounded-2xl bg-gradient-to-br from-emerald-500/15 via-[#09101d] to-sky-500/15 p-5 sm:p-6 border border-emerald-500/30 flex flex-col justify-between"
            style={{ transform: "translateZ(30px)" }}
          >
            <div>
              <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2.5">
                <Brain className="w-4 h-4" />
                Live Co-Pilot Advisory
              </div>
              <p className="text-xs sm:text-sm text-slate-200 leading-relaxed">
                "Observed a 28% drop in discretionary dining this week. You are on track to fund your
                <span className="text-emerald-400 font-bold"> Vacation Reserve </span> 18 days ahead of target."
              </p>
            </div>
            <div className="pt-4 border-t border-white/[0.08] flex items-center justify-between text-[11px] font-mono text-slate-400">
              <span>Confidence: 97.4%</span>
              <span className="text-emerald-400 font-semibold flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" /> Optimal
              </span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Floating 3D Depth Card 1: Obsidian Black Metal Debit Card (Bottom-Left) */}
      <motion.div
        animate={{ y: [-10, 10, -10], rotateZ: [-3, 3, -3] }}
        transition={{ repeat: Infinity, duration: 7, ease: "easeInOut" }}
        style={{
          transform: "translateZ(75px) translateX(-35px) translateY(45px)",
        }}
        className="hidden lg:block absolute -bottom-10 -left-8 z-30 w-80 rounded-2xl bg-gradient-to-br from-slate-900 via-[#0b1424] to-slate-950 p-6 border border-white/25 shadow-[0_25px_60px_rgba(0,0,0,0.9),0_0_35px_rgba(56,189,248,0.25)] backdrop-blur-2xl"
      >
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-emerald-400 to-sky-400 flex items-center justify-center shadow-lg">
              <Wallet className="w-4 h-4 text-slate-950 font-bold" />
            </div>
            <span className="text-xs font-extrabold tracking-wider text-white">FinanceAI Obsidian</span>
          </div>
          <span className="text-[10px] font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/30">
            CONTACTLESS
          </span>
        </div>

        {/* EMV Chip & Contactless Wave */}
        <div className="flex items-center gap-3 mb-4">
          <div className="w-9 h-7 rounded bg-gradient-to-tr from-amber-300 via-amber-400 to-yellow-500 border border-amber-200/50 shadow-inner flex items-center justify-center">
            <div className="w-7 h-5 border border-amber-600/40 rounded-sm" />
          </div>
          <Zap className="w-4 h-4 text-slate-400 rotate-45" />
        </div>

        <div className="text-xs text-slate-300 font-mono tracking-widest mb-3">•••• •••• •••• 8842</div>

        <div className="flex justify-between items-end">
          <div>
            <div className="text-[9px] uppercase tracking-wider text-slate-400">Cardholder</div>
            <div className="text-xs font-bold text-white tracking-wide">ALEX JOHNSON</div>
          </div>
          <div className="text-right">
            <div className="text-[9px] uppercase tracking-wider text-slate-400">Exp</div>
            <div className="text-xs font-mono text-slate-200">08/29</div>
          </div>
        </div>
      </motion.div>

      {/* Floating 3D Depth Card 2: Neural Fraud Shield Guard (Top-Right) */}
      <motion.div
        animate={{ y: [10, -10, 10], rotateZ: [2, -2, 2] }}
        transition={{ repeat: Infinity, duration: 6, ease: "easeInOut", delay: 0.8 }}
        style={{
          transform: "translateZ(85px) translateX(40px) translateY(-35px)",
        }}
        className="hidden lg:block absolute -top-8 -right-8 z-30 w-72 rounded-2xl bg-gradient-to-br from-slate-900/95 via-[#0c1628] to-slate-950 p-5 border border-emerald-500/30 shadow-[0_25px_60px_rgba(0,0,0,0.85),0_0_35px_rgba(16,185,129,0.3)] backdrop-blur-2xl"
      >
        <div className="flex items-center gap-3 mb-3">
          <div className="w-11 h-11 rounded-xl bg-emerald-500/15 border border-emerald-500/30 flex items-center justify-center flex-shrink-0 shadow-[0_0_15px_rgba(16,185,129,0.3)]">
            <Shield className="w-6 h-6 text-emerald-400" />
          </div>
          <div>
            <div className="text-xs font-bold text-white flex items-center gap-1.5">
              Shield Defense 24/7
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            </div>
            <div className="text-[11px] text-slate-400 font-mono">Risk Index: 0.00 (Safe)</div>
          </div>
        </div>
        <div className="pt-2.5 border-t border-white/[0.08] flex items-center justify-between text-[11px] text-slate-300">
          <span>Continuous Anomaly Scan</span>
          <span className="text-emerald-400 font-mono font-bold">100% Secure</span>
        </div>
      </motion.div>
    </div>
  );
}

// --- Main Landing Page Component ---

export default function Landing() {
  const { user, isAuthenticated } = useAuth();
  const [activeMode, setActiveMode] = useState("business");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [direction, setDirection] = useState(0);

  const handleModeChange = (newModeId: string) => {
    const currentIndex = userModes.findIndex((m) => m.id === activeMode);
    const nextIndex = userModes.findIndex((m) => m.id === newModeId);
    setDirection(nextIndex > currentIndex ? 1 : -1);
    setActiveMode(newModeId);
  };

  const activeModeDef = userModes.find((m) => m.id === activeMode) || userModes[0];
  const activeModeIndex = userModes.findIndex((m) => m.id === activeMode);

  return (
    <div
      className="min-h-screen text-slate-100 overflow-x-hidden relative selection:bg-emerald-500/30 selection:text-emerald-300 bg-[#050811]"
      style={{
        fontFamily: "'Plus Jakarta Sans', 'Outfit', sans-serif",
      }}
    >
      {/* Dynamic Background Mesh & Specular Glows */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden -z-10">
        <div
          className="absolute -top-[15%] -left-[10%] w-[700px] h-[700px] rounded-full blur-[150px] opacity-25"
          style={{ background: "radial-gradient(circle, #10b981 0%, transparent 70%)" }}
        />
        <div
          className="absolute top-[25%] -right-[15%] w-[650px] h-[650px] rounded-full blur-[170px] opacity-20"
          style={{ background: "radial-gradient(circle, #38bdf8 0%, transparent 70%)" }}
        />
        <div
          className="absolute bottom-[10%] left-[25%] w-[600px] h-[600px] rounded-full blur-[160px] opacity-15"
          style={{ background: "radial-gradient(circle, #a855f7 0%, transparent 70%)" }}
        />
        {/* High-tech dot matrix pattern */}
        <div
          className="absolute inset-0 opacity-[0.04]"
          style={{
            backgroundImage: `radial-gradient(rgba(255, 255, 255, 0.4) 1px, transparent 1px)`,
            backgroundSize: "32px 32px",
          }}
        />
      </div>

      {/* Navigation Header */}
      <header className="sticky top-0 z-50 border-b border-white/[0.08] bg-[#050811]/85 backdrop-blur-2xl transition-all">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-20">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-3 group">
              <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-emerald-500 via-teal-500 to-sky-500 p-[1.5px] shadow-[0_0_25px_rgba(16,185,129,0.4)] group-hover:scale-105 transition-transform duration-300">
                <div className="w-full h-full bg-[#060b16] rounded-2xl flex items-center justify-center">
                  <Wallet className="w-5 h-5 text-emerald-400" />
                </div>
              </div>
              <div className="flex flex-col">
                <span
                  className="text-2xl font-black tracking-tight text-white"
                  style={{ fontFamily: "'Syne', sans-serif" }}
                >
                  Finance<span className="text-emerald-400">AI</span>
                </span>
                <span className="text-[10px] font-mono tracking-widest text-slate-400 uppercase -mt-1 font-semibold">
                  Neural Wealth OS
                </span>
              </div>
            </Link>

            {/* Desktop Nav Links */}
            <nav className="hidden md:flex items-center gap-1.5 bg-white/[0.03] border border-white/[0.08] rounded-full p-1.5 px-4 backdrop-blur-xl">
              {[
                { name: "Features", href: "#features" },
                { name: "User Modes", href: "#user-modes" },
                { name: "Advanced Tools", href: "#advanced-tools" },
                { name: "Security", href: "#security" },
                { name: "Testimonials", href: "#testimonials" },
              ].map((item) => (
                <a
                  key={item.name}
                  href={item.href}
                  className="text-xs font-semibold px-4 py-2 rounded-full text-slate-300 hover:text-white hover:bg-white/[0.06] transition-all"
                >
                  {item.name}
                </a>
              ))}
            </nav>

            {/* CTA Buttons */}
            <div className="hidden md:flex items-center gap-3">
              <Link
                to="/login"
                className="text-xs font-semibold px-5 py-2.5 rounded-xl text-slate-300 hover:text-white hover:bg-white/[0.05] border border-transparent hover:border-white/10 transition-all"
              >
                Sign In
              </Link>
              <Link
                to="/signup"
                className="group relative inline-flex items-center gap-2 text-xs font-bold px-6 py-2.5 rounded-xl text-white bg-gradient-to-r from-emerald-500 via-teal-500 to-emerald-600 shadow-[0_0_25px_rgba(16,185,129,0.4)] hover:shadow-[0_0_35px_rgba(16,185,129,0.6)] hover:scale-[1.02] active:scale-[0.98] transition-all overflow-hidden"
              >
                <span className="relative z-10">Start Free Account</span>
                <ArrowRight className="w-3.5 h-3.5 relative z-10 group-hover:translate-x-0.5 transition-transform" />
              </Link>
            </div>

            {/* Mobile Menu Toggle */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2.5 rounded-xl bg-white/[0.05] border border-white/10 text-slate-300"
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              className="md:hidden border-t border-white/[0.08] bg-[#050811]/98 backdrop-blur-2xl px-6 py-6 space-y-4"
            >
              {[
                { name: "Features", href: "#features" },
                { name: "User Modes", href: "#user-modes" },
                { name: "Advanced Tools", href: "#advanced-tools" },
                { name: "Security", href: "#security" },
                { name: "Testimonials", href: "#testimonials" },
              ].map((item) => (
                <a
                  key={item.name}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="block text-sm font-medium text-slate-300 py-2 hover:text-emerald-400 transition-colors"
                >
                  {item.name}
                </a>
              ))}
              <div className="pt-4 border-t border-white/10 flex flex-col gap-3">
                <Link
                  to="/login"
                  onClick={() => setMobileMenuOpen(false)}
                  className="w-full text-center py-3 rounded-xl text-sm font-semibold border border-white/10 text-slate-200"
                >
                  Sign In
                </Link>
                <Link
                  to="/signup"
                  onClick={() => setMobileMenuOpen(false)}
                  className="w-full text-center py-3 rounded-xl text-sm font-bold bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-lg shadow-emerald-500/30"
                >
                  Start Free Account
                </Link>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </header>

      {/* Hero Section */}
      <section className="relative pt-16 pb-24 lg:pt-24 lg:pb-36 px-4">
        <div className="max-w-7xl mx-auto">
          {/* Main Hero Header */}
          <div className="text-center max-w-4xl mx-auto mb-12">
            {/* Pill Badge */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full mb-6 text-xs font-semibold tracking-wide bg-gradient-to-r from-emerald-500/10 via-sky-500/10 to-purple-500/10 border border-emerald-500/30 text-emerald-300 shadow-[0_0_25px_rgba(16,185,129,0.2)]"
            >
              <Sparkles className="w-3.5 h-3.5 text-emerald-400 animate-pulse" />
              <span>Next-Generation AI Financial Architecture</span>
              <span className="w-1 h-1 rounded-full bg-emerald-400" />
              <span className="text-slate-400 font-mono">India's #1 Platform</span>
            </motion.div>

            {/* Headline */}
            <motion.h1
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.1 }}
              className="text-4xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.08] mb-6"
              style={{ fontFamily: "'Syne', sans-serif" }}
            >
              Your Money,{" "}
              <span className="bg-gradient-to-r from-emerald-400 via-teal-300 to-sky-400 bg-clip-text text-transparent italic">
                Finally Intelligent
              </span>
            </motion.h1>

            {/* Sub-headline */}
            <motion.p
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.2 }}
              className="text-base sm:text-lg lg:text-xl text-slate-300 leading-relaxed max-w-2xl mx-auto mb-10"
            >
              FinanceAI combines real-time AI, OCR receipt scanning, voice input, fraud detection, and behavioral
              analytics — built for Indian families, students, freelancers, and businesses.
            </motion.p>

            {/* Action Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.3 }}
              className="flex flex-col sm:flex-row items-center justify-center gap-4"
            >
              <Link
                to="/signup"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-3 px-8 py-4 rounded-2xl font-bold text-sm text-white bg-gradient-to-r from-emerald-500 via-teal-500 to-emerald-600 shadow-[0_0_40px_rgba(16,185,129,0.4),0_4px_20px_rgba(0,0,0,0.5)] hover:shadow-[0_0_60px_rgba(16,185,129,0.6)] hover:scale-[1.02] active:scale-[0.98] transition-all"
              >
                <span>Start Managing Smartly</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                to="/app"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl font-semibold text-sm text-slate-200 bg-white/[0.04] hover:bg-white/[0.08] border border-white/10 hover:border-white/20 backdrop-blur-xl transition-all"
              >
                <Play className="w-4 h-4 text-emerald-400 fill-emerald-400" />
                <span>Live Demo</span>
              </Link>
            </motion.div>
          </div>

          {/* 3D Holographic Hero Stage */}
          <Hero3DStage />

          {/* Social Proof Metric Bar */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.5 }}
            className="grid grid-cols-1 sm:grid-cols-3 gap-6 max-w-4xl mx-auto mt-16 pt-10 border-t border-white/[0.08]"
          >
            {[
              { num: "50,000+", label: "Active Users", desc: "Across 42 Indian cities", color: "text-emerald-400" },
              { num: "₹2.4 Cr+", label: "Fraud Prevented", desc: "Via real-time anomaly scoring", color: "text-sky-400" },
              { num: "₹48.6 Cr+", label: "Total Savings", desc: "Automated micro-optimizations", color: "text-purple-400" },
            ].map((metric) => (
              <div
                key={metric.label}
                className="p-6 rounded-2xl bg-white/[0.02] border border-white/[0.06] text-center backdrop-blur-md hover:border-white/15 transition-colors"
              >
                <div className={`text-3xl font-extrabold font-mono tracking-tight ${metric.color} mb-1`}>
                  {metric.num}
                </div>
                <div className="text-sm font-semibold text-slate-200 mb-1">{metric.label}</div>
                <div className="text-xs text-slate-400">{metric.desc}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* User Modes Sliding Deck Carousel */}
      <section id="user-modes" className="py-24 px-4 relative border-t border-white/[0.06] bg-[#04070e]">
        <div className="max-w-7xl mx-auto">
          {/* Section Heading */}
          <div className="text-center max-w-3xl mx-auto mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide bg-purple-500/10 border border-purple-500/30 text-purple-400 mb-4">
              <Users className="w-3.5 h-3.5" />
              <span>Personalized Modes</span>
            </div>
            <h2
              className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4"
              style={{ fontFamily: "'Syne', sans-serif" }}
            >
              Built for your financial life
            </h2>
            <p className="text-slate-400 text-sm sm:text-base">
              FinanceAI adapts its intelligence to your specific situation — not a one-size-fits-all tool.
            </p>
          </div>

          {/* Interactive Sliding Tab Bar */}
          <div className="flex flex-wrap justify-center items-center gap-2 p-1.5 bg-white/[0.03] border border-white/[0.08] rounded-2xl max-w-2xl mx-auto mb-12 backdrop-blur-xl">
            {userModes.map((mode) => {
              const Icon = mode.icon;
              const isActive = activeMode === mode.id;
              return (
                <button
                  key={mode.id}
                  onClick={() => handleModeChange(mode.id)}
                  className={`relative flex-1 min-w-[120px] sm:min-w-[130px] flex items-center justify-center gap-2 py-3 px-4 rounded-xl text-xs sm:text-sm font-semibold transition-colors duration-200 z-10 ${
                    isActive ? "text-white" : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <Icon className="w-4 h-4" style={{ color: isActive ? mode.color : undefined }} />
                  <span>{mode.label}</span>
                  {isActive && (
                    <motion.div
                      layoutId="activeUserModeIndicator"
                      transition={{ type: "spring", stiffness: 380, damping: 30 }}
                      className="absolute inset-0 rounded-xl bg-white/[0.08] border border-white/15 -z-10 shadow-lg"
                      style={{
                        boxShadow: `0 0 20px ${mode.glow}`,
                      }}
                    />
                  )}
                </button>
              );
            })}
          </div>

          {/* Sliding Mode Deck Showcase Panel */}
          <div className="relative min-h-[480px]">
            <AnimatePresence mode="wait" custom={direction}>
              <motion.div
                key={activeModeDef.id}
                custom={direction}
                initial={{ opacity: 0, x: direction * 80, scale: 0.98 }}
                animate={{ opacity: 1, x: 0, scale: 1 }}
                exit={{ opacity: 0, x: -direction * 80, scale: 0.98 }}
                transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch"
              >
                {/* Left Card: Mode Details & Feature Checklist */}
                <div className="lg:col-span-7">
                  <TiltCard3D
                    glowColor={activeModeDef.glow}
                    className="h-full"
                    style={{
                      background: `linear-gradient(135deg, ${activeModeDef.color}0d 0%, rgba(10,16,28,0.95) 100%)`,
                      border: `1px solid ${activeModeDef.color}33`,
                    }}
                  >
                    <div className="p-8 sm:p-10 flex flex-col justify-between h-full">
                      <div>
                        {/* Header */}
                        <div className="flex items-center gap-4 mb-6">
                          <div
                            className="w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg"
                            style={{
                              background: `${activeModeDef.color}1a`,
                              border: `1px solid ${activeModeDef.color}4d`,
                            }}
                          >
                            <activeModeDef.icon className="w-7 h-7" style={{ color: activeModeDef.color }} />
                          </div>
                          <div>
                            <div className="text-xs font-bold uppercase tracking-wider text-slate-400">
                              {activeModeDef.badge}
                            </div>
                            <h3
                              className="text-2xl sm:text-3xl font-bold text-white"
                              style={{ fontFamily: "'Syne', sans-serif" }}
                            >
                              {activeModeDef.label} Mode
                            </h3>
                          </div>
                        </div>

                        {/* Tagline & Description */}
                        <p className="text-base font-semibold mb-3" style={{ color: activeModeDef.color }}>
                          {activeModeDef.tagline}
                        </p>
                        <p className="text-sm text-slate-300 leading-relaxed mb-8">
                          {activeModeDef.description}
                        </p>

                        {/* Features List */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-4 border-t border-white/[0.08]">
                          {activeModeDef.features.map((feature, i) => (
                            <div key={i} className="flex items-start gap-2.5">
                              <CheckCircle2
                                className="w-4 h-4 flex-shrink-0 mt-0.5"
                                style={{ color: activeModeDef.color }}
                              />
                              <span className="text-xs text-slate-200 font-medium leading-tight">
                                {feature}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Mode CTA */}
                      <div className="pt-8 mt-8 border-t border-white/[0.08] flex items-center justify-between">
                        <span className="text-xs text-slate-400 font-mono">Preset ID: #{activeModeDef.id}_v2</span>
                        <Link
                          to="/signup"
                          className="inline-flex items-center gap-2 px-6 py-3 rounded-xl text-xs font-bold text-white shadow-lg transition-transform hover:scale-105 active:scale-95"
                          style={{
                            background: `linear-gradient(135deg, ${activeModeDef.color}, ${activeModeDef.color}cc)`,
                            boxShadow: `0 0 25px ${activeModeDef.glow}`,
                          }}
                        >
                          <span>Start {activeModeDef.label} Mode</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </Link>
                      </div>
                    </div>
                  </TiltCard3D>
                </div>

                {/* Right Card: Mode Performance Stats Deck */}
                <div className="lg:col-span-5 flex flex-col justify-between gap-4">
                  {activeModeDef.stats.map((stat) => (
                    <TiltCard3D
                      key={stat.label}
                      glowColor={activeModeDef.glow}
                      className="flex-1"
                      style={{
                        background: "rgba(255, 255, 255, 0.03)",
                        border: "1px solid rgba(255, 255, 255, 0.08)",
                      }}
                    >
                      <div className="p-6 flex items-center justify-between">
                        <div>
                          <div className="text-xs font-medium text-slate-400 mb-1">{stat.label}</div>
                          <div className="text-2xl sm:text-3xl font-extrabold font-mono tracking-tight text-white">
                            {stat.value}
                          </div>
                        </div>
                        <div
                          className="text-xs font-semibold px-3 py-1.5 rounded-lg font-mono border"
                          style={{
                            color: activeModeDef.color,
                            backgroundColor: `${activeModeDef.color}15`,
                            borderColor: `${activeModeDef.color}33`,
                          }}
                        >
                          {stat.change}
                        </div>
                      </div>
                    </TiltCard3D>
                  ))}

                  {/* Mode Navigation Controls */}
                  <div className="flex items-center justify-between p-4 rounded-2xl bg-white/[0.02] border border-white/[0.06]">
                    <span className="text-xs text-slate-400 font-medium">
                      Mode {activeModeIndex + 1} of {userModes.length}
                    </span>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => {
                          const prevIndex = (activeModeIndex - 1 + userModes.length) % userModes.length;
                          handleModeChange(userModes[prevIndex].id);
                        }}
                        className="p-2 rounded-xl bg-white/[0.05] hover:bg-white/10 border border-white/10 text-slate-300 transition-colors"
                        aria-label="Previous mode"
                      >
                        <ChevronLeft className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => {
                          const nextIndex = (activeModeIndex + 1) % userModes.length;
                          handleModeChange(userModes[nextIndex].id);
                        }}
                        className="p-2 rounded-xl bg-white/[0.05] hover:bg-white/10 border border-white/10 text-slate-300 transition-colors"
                        aria-label="Next mode"
                      >
                        <ChevronRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </section>

      {/* AI Features Grid with 3D Tilt */}
      <section id="features" className="py-28 px-4 relative">
        <div className="max-w-7xl mx-auto">
          {/* Section Heading */}
          <div className="text-center max-w-3xl mx-auto mb-20">
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 mb-4">
              <Brain className="w-3.5 h-3.5" />
              <span>AI-Powered Intelligence</span>
            </div>
            <h2
              className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4"
              style={{ fontFamily: "'Syne', sans-serif" }}
            >
              Not a tracker. An AI co-pilot.
            </h2>
            <p className="text-slate-400 text-sm sm:text-base">
              Six layers of machine intelligence working 24/7 on your financial life.
            </p>
          </div>

          {/* Feature Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {aiFeatures.map((feat) => {
              const Icon = feat.icon;
              return (
                <TiltCard3D
                  key={feat.title}
                  glowColor={feat.glow}
                  style={{
                    background: "rgba(255, 255, 255, 0.02)",
                    border: "1px solid rgba(255, 255, 255, 0.07)",
                  }}
                >
                  <div className="p-8 flex flex-col justify-between h-full rounded-3xl backdrop-blur-xl">
                    <div>
                      {/* Badge and Icon */}
                      <div className="flex items-center justify-between mb-6">
                        <div
                          className="w-13 h-13 rounded-2xl flex items-center justify-center p-3 shadow-md"
                          style={{
                            background: `${feat.color}15`,
                            border: `1px solid ${feat.color}33`,
                          }}
                        >
                          <Icon className="w-6 h-6" style={{ color: feat.color }} />
                        </div>
                        <span
                          className="text-[11px] font-mono font-bold px-2.5 py-1 rounded-md border"
                          style={{
                            color: feat.color,
                            backgroundColor: `${feat.color}10`,
                            borderColor: `${feat.color}30`,
                          }}
                        >
                          {feat.tag}
                        </span>
                      </div>

                      {/* Content */}
                      <h3
                        className="text-lg font-bold text-white mb-2"
                        style={{ fontFamily: "'Syne', sans-serif" }}
                      >
                        {feat.title}
                      </h3>
                      <p className="text-xs sm:text-sm text-slate-300 leading-relaxed mb-6">
                        {feat.description}
                      </p>
                    </div>

                    {/* Metric footer */}
                    <div className="pt-4 border-t border-white/[0.06] flex items-center justify-between text-xs font-mono text-slate-400">
                      <span>Benchmark</span>
                      <span className="font-semibold" style={{ color: feat.color }}>
                        {feat.metric}
                      </span>
                    </div>
                  </div>
                </TiltCard3D>
              );
            })}
          </div>
        </div>
      </section>

      {/* Advanced Tools & Gamification Score */}
      <section id="advanced-tools" className="py-28 px-4 relative bg-[#04070e] border-t border-white/[0.06]">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Column: Tool List */}
            <div className="lg:col-span-6 space-y-8">
              <div>
                <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-semibold tracking-wide bg-sky-500/10 border border-sky-500/30 text-sky-400 mb-4">
                  <Zap className="w-3.5 h-3.5" />
                  <span>Advanced Tools</span>
                </div>
                <h2
                  className="text-3xl sm:text-4xl font-bold text-white leading-tight"
                  style={{ fontFamily: "'Syne', sans-serif" }}
                >
                  Everything a serious financial life demands
                </h2>
                <p className="text-sm sm:text-base text-slate-400 mt-3">
                  Unified under one high-performance interface with zero ads, zero spam, and instant offline PWA sync.
                </p>
              </div>

              <div className="space-y-4">
                {[
                  {
                    icon: BarChart3,
                    title: "Spending Heatmap Calendar",
                    desc: "See your entire year of spending in one glance — identify patterns instantly.",
                    color: "text-emerald-400",
                    bg: "bg-emerald-500/10 border-emerald-500/20",
                  },
                  {
                    icon: Target,
                    title: "Savings Goal Gamification",
                    desc: "Badges, streaks, and milestones turn saving from chore to achievement.",
                    color: "text-amber-400",
                    bg: "bg-amber-500/10 border-amber-500/20",
                  },
                  {
                    icon: CreditCard,
                    title: "EMI & Loan Planner",
                    desc: "Model loan scenarios, track repayments, and minimize interest costs with AI guidance.",
                    color: "text-purple-400",
                    bg: "bg-purple-500/10 border-purple-500/20",
                  },
                  {
                    icon: Globe,
                    title: "Multi-currency Support",
                    desc: "Track international expenses with live FX rates. Perfect for travelers and remote workers.",
                    color: "text-sky-400",
                    bg: "bg-sky-500/10 border-sky-500/20",
                  },
                ].map((item) => {
                  const Icon = item.icon;
                  return (
                    <div
                      key={item.title}
                      className="p-4 rounded-2xl bg-white/[0.02] border border-white/[0.06] flex items-start gap-4 hover:bg-white/[0.04] transition-colors"
                    >
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 border ${item.bg}`}>
                        <Icon className={`w-5 h-5 ${item.color}`} />
                      </div>
                      <div>
                        <h4 className="text-sm font-bold text-white mb-0.5">{item.title}</h4>
                        <p className="text-xs text-slate-300 leading-relaxed">{item.desc}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Right Column: 3D Holographic Financial Health Terminal */}
            <div className="lg:col-span-6">
              <TiltCard3D
                glowColor="rgba(56, 189, 248, 0.25)"
                style={{
                  background: "linear-gradient(135deg, rgba(56, 189, 248, 0.05) 0%, rgba(9, 14, 26, 0.95) 100%)",
                  border: "1px solid rgba(56, 189, 248, 0.2)",
                }}
              >
                <div className="p-8 rounded-3xl space-y-6">
                  {/* Gauge Header */}
                  <div className="flex items-center justify-between border-b border-white/[0.08] pb-4">
                    <div className="flex items-center gap-2">
                      <Award className="w-5 h-5 text-amber-400" />
                      <span className="text-sm font-bold text-white">Financial Health Score</span>
                    </div>
                    <span className="text-xs font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-md border border-emerald-500/30">
                      EXCELLENT
                    </span>
                  </div>

                  {/* Circular Dial & Metric Split */}
                  <div className="flex flex-col sm:flex-row items-center gap-6">
                    <div className="relative w-32 h-32 flex items-center justify-center flex-shrink-0">
                      {/* Dial Ring */}
                      <div
                        className="absolute inset-0 rounded-full p-2.5"
                        style={{
                          background: "conic-gradient(#10b981 0% 87%, rgba(255,255,255,0.08) 87% 100%)",
                        }}
                      >
                        <div className="w-full h-full rounded-full bg-[#090e1a] flex flex-col items-center justify-center">
                          <span className="text-3xl font-black font-mono text-emerald-400">87</span>
                          <span className="text-[10px] font-mono text-slate-400 uppercase">SCORE</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex-1 space-y-3 w-full">
                      {[
                        { name: "Savings Rate", val: 76, color: "bg-emerald-400" },
                        { name: "Debt-to-Income", val: 88, color: "bg-sky-400" },
                        { name: "Emergency Fund", val: 60, color: "bg-purple-400" },
                      ].map((bar) => (
                        <div key={bar.name}>
                          <div className="flex justify-between text-xs font-medium mb-1">
                            <span className="text-slate-300">{bar.name}</span>
                            <span className="font-mono text-white">{bar.val}%</span>
                          </div>
                          <div className="h-1.5 rounded-full bg-white/[0.08] overflow-hidden">
                            <div
                              className={`h-full rounded-full ${bar.color}`}
                              style={{ width: `${bar.val}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Gamification Badges */}
                  <div className="grid grid-cols-3 gap-3 pt-4 border-t border-white/[0.08]">
                    {[
                      { emoji: "🏆", title: "Saver Pro", desc: "30-day streak" },
                      { emoji: "⚡", title: "Zero Overspend", desc: "This month" },
                      { emoji: "🎯", title: "Goal Crusher", desc: "3 goals done" },
                    ].map((b) => (
                      <div
                        key={b.title}
                        className="p-3 rounded-xl bg-white/[0.03] border border-white/[0.06] text-center"
                      >
                        <div className="text-2xl mb-1">{b.emoji}</div>
                        <div className="text-xs font-bold text-white">{b.title}</div>
                        <div className="text-[10px] text-slate-400 font-mono">{b.desc}</div>
                      </div>
                    ))}
                  </div>

                  {/* Summary Box */}
                  <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/25 flex items-start gap-3">
                    <Bot className="w-5 h-5 text-emerald-400 flex-shrink-0 mt-0.5" />
                    <p className="text-xs text-emerald-200/90 leading-relaxed">
                      "This month you saved ₹18,400 — 22% more than last month. Your biggest win: cutting dining
                      by ₹3,200. Keep it up to hit your vacation goal 2 weeks early. 🎉"
                    </p>
                  </div>
                </div>
              </TiltCard3D>
            </div>
          </div>
        </div>
      </section>

      {/* Security & Compliance Section */}
      <section id="security" className="py-24 px-4 relative">
        <div className="max-w-7xl mx-auto">
          <TiltCard3D
            glowColor="rgba(16, 185, 129, 0.2)"
            style={{
              background: "linear-gradient(135deg, rgba(16, 185, 129, 0.06) 0%, rgba(9, 14, 26, 0.98) 100%)",
              border: "1px solid rgba(16, 185, 129, 0.25)",
            }}
          >
            <div className="p-10 md:p-16 text-center max-w-4xl mx-auto">
              <div className="w-16 h-16 rounded-3xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center mx-auto mb-6 shadow-[0_0_30px_rgba(16,185,129,0.3)]">
                <Shield className="w-8 h-8 text-emerald-400" />
              </div>
              <h2
                className="text-3xl sm:text-4xl font-bold text-white mb-4"
                style={{ fontFamily: "'Syne', sans-serif" }}
              >
                Bank-Grade Security
              </h2>
              <p className="text-sm sm:text-base text-slate-300 max-w-2xl mx-auto leading-relaxed mb-12">
                Your financial data is encrypted, never sold, and guarded by the same standards as leading banks.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
                {[
                  {
                    icon: Lock,
                    title: "256-bit AES Encryption",
                    desc: "All data encrypted in transit and at rest.",
                  },
                  {
                    icon: Shield,
                    title: "RBI-Compliant Architecture",
                    desc: "Built following India's data privacy standards.",
                  },
                  {
                    icon: Zap,
                    title: "24/7 Fraud Monitoring",
                    desc: "AI watches for anomalies around the clock.",
                  },
                ].map((sec) => {
                  const Icon = sec.icon;
                  return (
                    <div key={sec.title} className="p-6 rounded-2xl bg-white/[0.03] border border-white/[0.06]">
                      <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-4">
                        <Icon className="w-5 h-5 text-emerald-400" />
                      </div>
                      <h4 className="text-sm font-bold text-white mb-2">{sec.title}</h4>
                      <p className="text-xs text-slate-400 leading-relaxed">{sec.desc}</p>
                    </div>
                  );
                })}
              </div>
            </div>
          </TiltCard3D>
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className="py-24 px-4 relative bg-[#04070e] border-t border-white/[0.06]">
        <div className="max-w-7xl mx-auto">
          {/* Section Heading */}
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2
              className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4"
              style={{ fontFamily: "'Syne', sans-serif" }}
            >
              Loved by 50,000+ users
            </h2>
          </div>

          {/* Testimonials Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {testimonials.map((item) => (
              <TiltCard3D
                key={item.name}
                glowColor={`${item.color}25`}
                style={{
                  background: "rgba(255, 255, 255, 0.02)",
                  border: "1px solid rgba(255, 255, 255, 0.07)",
                }}
              >
                <div className="p-6 flex flex-col justify-between h-full rounded-3xl">
                  <div>
                    {/* Stars & Tag */}
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex gap-1 text-amber-400">
                        {Array.from({ length: item.rating }).map((_, i) => (
                          <Star key={i} className="w-3.5 h-3.5 fill-current" />
                        ))}
                      </div>
                      <span
                        className="text-[10px] font-mono font-bold px-2 py-0.5 rounded border"
                        style={{
                          color: item.color,
                          backgroundColor: `${item.color}10`,
                          borderColor: `${item.color}30`,
                        }}
                      >
                        {item.tag}
                      </span>
                    </div>

                    {/* Review text */}
                    <p className="text-xs text-slate-300 leading-relaxed mb-6 italic">"{item.text}"</p>
                  </div>

                  {/* Author footer */}
                  <div className="pt-4 border-t border-white/[0.06]">
                    <div className="flex items-center gap-3 mb-2">
                      <div
                        className="w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs font-mono"
                        style={{
                          backgroundColor: `${item.color}20`,
                          color: item.color,
                          border: `1px solid ${item.color}40`,
                        }}
                      >
                        {item.avatar}
                      </div>
                      <div>
                        <div className="text-xs font-bold text-white">{item.name}</div>
                        <div className="text-[10px] text-slate-400">{item.role}</div>
                      </div>
                    </div>
                    <div className="text-[11px] font-mono font-semibold" style={{ color: item.color }}>
                      {item.saved}
                    </div>
                  </div>
                </div>
              </TiltCard3D>
            ))}
          </div>
        </div>
      </section>

      {/* High-Impact CTA Section */}
      <section className="py-28 px-4 relative">
        <div className="max-w-4xl mx-auto">
          <TiltCard3D
            glowColor="rgba(16, 185, 129, 0.35)"
            style={{
              background:
                "linear-gradient(135deg, rgba(16, 185, 129, 0.12) 0%, rgba(56, 189, 248, 0.08) 50%, rgba(9, 14, 26, 0.98) 100%)",
              border: "1px solid rgba(16, 185, 129, 0.3)",
            }}
          >
            <div className="p-12 sm:p-16 text-center space-y-6">
              <div className="w-16 h-16 rounded-3xl bg-gradient-to-tr from-emerald-500 to-teal-400 p-[1px] mx-auto shadow-[0_0_40px_rgba(16,185,129,0.5)]">
                <div className="w-full h-full bg-[#070d18] rounded-3xl flex items-center justify-center">
                  <Sparkles className="w-8 h-8 text-emerald-400" />
                </div>
              </div>
              <h2
                className="text-3xl sm:text-5xl font-bold text-white leading-tight"
                style={{ fontFamily: "'Syne', sans-serif" }}
              >
                Ready to start managing smartly?
              </h2>
              <p className="text-sm sm:text-base text-slate-300 max-w-xl mx-auto">
                Free forever for personal use. No credit card needed.
              </p>
              <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-4">
                <Link
                  to="/signup"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-3 px-8 py-4 rounded-2xl font-bold text-sm text-white bg-gradient-to-r from-emerald-500 via-teal-500 to-emerald-600 shadow-[0_0_40px_rgba(16,185,129,0.4)] hover:shadow-[0_0_60px_rgba(16,185,129,0.6)] hover:scale-105 active:scale-95 transition-all"
                >
                  <span>Create Free Account</span>
                  <ArrowRight className="w-4 h-4" />
                </Link>
                <Link
                  to="/app"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl font-semibold text-sm text-slate-200 bg-white/[0.05] hover:bg-white/10 border border-white/10 transition-all"
                >
                  <span>Explore Dashboard</span>
                  <ArrowUpRight className="w-4 h-4 text-emerald-400" />
                </Link>
              </div>
              <div className="text-[11px] font-mono text-slate-400 pt-2">
                No credit card required • Instant setup • 100% Free Tier Available
              </div>
            </div>
          </TiltCard3D>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/[0.08] py-16 px-4 relative bg-[#03050a]">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-10 mb-12">
            <div className="md:col-span-2 space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-500 to-sky-400 flex items-center justify-center shadow-md">
                  <Wallet className="w-4 h-4 text-white" />
                </div>
                <span className="text-xl font-bold text-white" style={{ fontFamily: "'Syne', sans-serif" }}>
                  Finance<span className="text-emerald-400">AI</span>
                </span>
              </div>
              <p className="text-xs sm:text-sm text-slate-400 max-w-sm leading-relaxed">
                India's most intelligent personal finance platform — built for every financial journey.
              </p>
            </div>

            {[
              {
                title: "Product",
                links: ["Features", "User Modes", "Pricing", "Security"],
              },
              {
                title: "Company",
                links: ["About", "Blog", "Careers", "Press"],
              },
              {
                title: "Legal",
                links: ["Privacy", "Terms", "Security", "Cookies"],
              },
            ].map((col) => (
              <div key={col.title}>
                <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-mono">
                  {col.title}
                </h4>
                <ul className="space-y-2.5 text-xs text-slate-400">
                  {col.links.map((link) => (
                    <li key={link}>
                      <a href="#" className="hover:text-emerald-400 transition-colors">
                        {link}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <div className="pt-8 border-t border-white/[0.06] flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-slate-400 font-mono">
            <div>© 2026 FinanceAI. All rights reserved.</div>
            <div className="flex items-center gap-6">
              <span>Made with ♥ for Indian financial freedom</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
