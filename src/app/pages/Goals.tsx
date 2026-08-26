import { useState, useEffect } from "react";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog";
import {
  Target,
  TrendingUp,
  Plus,
  Trophy,
  Zap,
  Calendar,
  DollarSign,
  Flame,
  Star,
  Sparkles,
  Briefcase,
  GraduationCap,
  Home,
  Users,
} from "lucide-react";
import { toast } from "sonner";
import { goalsAPI } from "../../services/api";
import confetti from "canvas-confetti";
import { useRole } from "../contexts/RoleContext";

interface Goal {
  id: string | number;
  name: string;
  target_amount: number;
  current_amount: number;
  deadline: string;
  category: string;
}

const ROLE_LABELS: Record<string, { label: string; icon: any; color: string }> = {
  business:   { label: "Business Owner", icon: Briefcase,      color: "#10b981" },
  student:    { label: "Student",        icon: GraduationCap,  color: "#06b6d4" },
  home:       { label: "Home Manager",   icon: Home,           color: "#f59e0b" },
  freelancer: { label: "Freelancer",     icon: Users,          color: "#7c3aed" },
};

const ROLE_CATEGORIES: Record<string, { id: string; label: string; emoji: string }[]> = {
  business: [
    { id: "expansion", label: "Business Expansion", emoji: "🏢" },
    { id: "emergency", label: "Emergency Reserve", emoji: "🛡️" },
    { id: "tax_fund", label: "Tax Payment Fund", emoji: "📋" },
    { id: "equipment", label: "Equipment / Tech", emoji: "💻" },
    { id: "marketing", label: "Marketing Budget", emoji: "📣" },
    { id: "custom",    label: "Custom Goal", emoji: "🎯" },
  ],
  student: [
    { id: "tech",      label: "Laptop / Phone", emoji: "💻" },
    { id: "travel",    label: "Trip / Vacation", emoji: "✈️" },
    { id: "emergency", label: "Emergency Fund", emoji: "🛡️" },
    { id: "education", label: "Course / Certification", emoji: "📚" },
    { id: "gadget",    label: "Gadget / Accessories", emoji: "🎧" },
    { id: "custom",    label: "Custom Goal", emoji: "🎯" },
  ],
  home: [
    { id: "vacation",  label: "Family Vacation", emoji: "🏖️" },
    { id: "renovation",label: "Home Renovation", emoji: "🏠" },
    { id: "emergency", label: "Emergency Fund", emoji: "🛡️" },
    { id: "education", label: "Children Education", emoji: "📚" },
    { id: "vehicle",   label: "Vehicle Purchase", emoji: "🚗" },
    { id: "custom",    label: "Custom Goal", emoji: "🎯" },
  ],
  freelancer: [
    { id: "tax_fund",  label: "Tax Reserve", emoji: "📋" },
    { id: "equipment", label: "Equipment / Studio", emoji: "🎬" },
    { id: "travel",    label: "Business Travel", emoji: "✈️" },
    { id: "education", label: "Skill Development", emoji: "📚" },
    { id: "emergency", label: "Income Buffer", emoji: "🛡️" },
    { id: "custom",    label: "Custom Goal", emoji: "🎯" },
  ],
};

const DEFAULT_CATEGORIES = [
  { id: "savings",   label: "Savings",   emoji: "🏦" },
  { id: "travel",    label: "Travel",    emoji: "✈️" },
  { id: "tech",      label: "Tech",      emoji: "💻" },
  { id: "home",      label: "Home",      emoji: "🏠" },
  { id: "car",       label: "Car",       emoji: "🚗" },
  { id: "education", label: "Education", emoji: "📚" },
  { id: "health",    label: "Health",    emoji: "💪" },
  { id: "custom",    label: "Custom",    emoji: "🎯" },
];

const glassCard = (accent = "rgba(255,255,255,0.07)") => ({
  background: "rgba(14,20,35,0.75)",
  border: `1px solid ${accent}`,
  backdropFilter: "blur(16px)",
});

export default function Goals() {
  const { role, goalTemplates } = useRole();
  const [goals, setGoals] = useState<Goal[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [addAmount, setAddAmount] = useState<Record<string, string>>({});
  const [newGoal, setNewGoal] = useState({ name: "", target: "", deadline: "", category: "" });

  const roleMeta = role ? ROLE_LABELS[role] : null;
  const accentColor = roleMeta?.color || "#10b981";
  const goalCategories = role ? (ROLE_CATEGORIES[role] || DEFAULT_CATEGORIES) : DEFAULT_CATEGORIES;

  useEffect(() => { loadGoals(); }, []);

  const loadGoals = async () => {
    try {
      const response = await goalsAPI.getAll();
      setGoals((response.goals || []) as any[]);
    } catch {
      toast.error("Failed to load goals");
    } finally {
      setLoading(false);
    }
  };

  const handleAddGoal = async () => {
    if (!newGoal.name || !newGoal.target || !newGoal.deadline) {
      toast.error("Please fill in all fields");
      return;
    }
    try {
      await goalsAPI.create({
        name: newGoal.name,
        target_amount: parseFloat(newGoal.target),
        current_amount: 0,
        deadline: new Date(newGoal.deadline).toISOString(),
        category: newGoal.category || "custom",
      });
      await loadGoals();
      setIsAddDialogOpen(false);
      setNewGoal({ name: "", target: "", deadline: "", category: "" });
      toast.success("Goal created successfully!");
    } catch {
      toast.error("Failed to create goal");
    }
  };

  const handleAddMoney = async (goalId: string | number) => {
    const amount = parseFloat(addAmount[String(goalId)] || "0");
    if (amount <= 0) { toast.error("Please enter a valid amount"); return; }

    try {
      const goal = goals.find((g) => g.id === goalId);
      if (!goal) return;
      const newAmount = goal.current_amount + amount;
      await goalsAPI.update(goalId, { current_amount: newAmount });

      if (newAmount >= goal.target_amount && goal.current_amount < goal.target_amount) {
        confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
        toast.success(`🎉 Congratulations! "${goal.name}" goal achieved!`);
      } else {
        toast.success("Progress updated!");
      }

      await loadGoals();
      setAddAmount({ ...addAmount, [String(goalId)]: "" });
    } catch {
      toast.error("Failed to update progress");
    }
  };

  const getEmoji = (cat: string) => {
    const all = [...goalCategories, ...DEFAULT_CATEGORIES];
    return all.find((c) => c.id === cat)?.emoji || "🎯";
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-t-transparent rounded-full animate-spin mx-auto mb-4"
            style={{ borderColor: `${accentColor}40`, borderTopColor: accentColor }} />
          <p style={{ color: "#6b7ca0" }}>Loading goals...</p>
        </div>
      </div>
    );
  }

  const totalSaved    = goals.reduce((s, g) => s + g.current_amount, 0);
  const totalTarget   = goals.reduce((s, g) => s + g.target_amount, 0);
  const overallPct    = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          {roleMeta && (
            <div className="flex items-center gap-1.5 mb-1">
              <roleMeta.icon className="w-3.5 h-3.5" style={{ color: accentColor }} />
              <span className="text-xs font-medium" style={{ color: accentColor }}>{roleMeta.label} · Savings Goals</span>
            </div>
          )}
          <h1 className="text-2xl font-bold" style={{ color: "#e8edf5" }}>Savings Goals</h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>Track progress and achieve your financial dreams</p>
        </div>

        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button className="flex items-center gap-2 px-4 py-2 rounded-xl font-medium"
              style={{ background: accentColor, color: "#fff", border: "none" }}>
              <Plus className="w-4 h-4" />
              New Goal
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-md" style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
            <DialogHeader>
              <DialogTitle style={{ color: "#e8edf5" }}>Create Savings Goal</DialogTitle>
              <DialogDescription style={{ color: "#6b7ca0" }}>
                {role
                  ? `Set a ${roleMeta?.label} savings goal with a target and deadline`
                  : "Set a target and deadline for your savings goal"}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              {/* Quick templates */}
              {goalTemplates.length > 0 && (
                <div>
                  <Label style={{ color: "#94a3b8" }}>Quick Templates</Label>
                  <div className="flex flex-wrap gap-2 mt-1.5">
                    {goalTemplates.map((t) => (
                      <button key={t} onClick={() => setNewGoal((p) => ({ ...p, name: t }))}
                        className="text-xs px-2.5 py-1 rounded-lg transition-all"
                        style={{
                          background: newGoal.name === t ? `${accentColor}20` : "rgba(255,255,255,0.05)",
                          border: `1px solid ${newGoal.name === t ? accentColor + "50" : "rgba(255,255,255,0.08)"}`,
                          color: newGoal.name === t ? accentColor : "#94a3b8",
                        }}>
                        {t}
                      </button>
                    ))}
                  </div>
                </div>
              )}
              <div>
                <Label style={{ color: "#94a3b8" }}>Goal Name</Label>
                <Input
                  placeholder={role === "business" ? "e.g., Business Expansion Fund" : role === "student" ? "e.g., Laptop Fund" : role === "home" ? "e.g., Family Vacation" : role === "freelancer" ? "e.g., Tax Reserve" : "e.g., New Car"}
                  value={newGoal.name}
                  onChange={(e) => setNewGoal({ ...newGoal, name: e.target.value })}
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", color: "#e8edf5" }}
                />
              </div>
              <div>
                <Label style={{ color: "#94a3b8" }}>Target Amount (₹)</Label>
                <Input
                  type="number"
                  placeholder="0"
                  value={newGoal.target}
                  onChange={(e) => setNewGoal({ ...newGoal, target: e.target.value })}
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", color: "#e8edf5" }}
                />
              </div>
              <div>
                <Label style={{ color: "#94a3b8" }}>Target Date</Label>
                <Input
                  type="date"
                  value={newGoal.deadline}
                  onChange={(e) => setNewGoal({ ...newGoal, deadline: e.target.value })}
                  style={{ background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", color: "#e8edf5" }}
                />
              </div>
              <div>
                <Label style={{ color: "#94a3b8" }}>Category</Label>
                <div className="flex flex-wrap gap-2 mt-1.5">
                  {goalCategories.map((cat) => (
                    <button key={cat.id}
                      onClick={() => setNewGoal((p) => ({ ...p, category: cat.id }))}
                      className="flex items-center gap-1.5 text-xs px-2.5 py-1.5 rounded-lg transition-all"
                      style={{
                        background: newGoal.category === cat.id ? `${accentColor}20` : "rgba(255,255,255,0.05)",
                        border: `1px solid ${newGoal.category === cat.id ? accentColor + "50" : "rgba(255,255,255,0.08)"}`,
                        color: newGoal.category === cat.id ? accentColor : "#94a3b8",
                      }}>
                      <span>{cat.emoji}</span> {cat.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}
                style={{ border: "1px solid rgba(255,255,255,0.1)", color: "#94a3b8", background: "transparent" }}>
                Cancel
              </Button>
              <Button onClick={handleAddGoal}
                style={{ background: accentColor, color: "#fff", border: "none" }}>
                Create Goal
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Overall progress hero */}
      <div className="rounded-2xl p-6"
        style={{ background: `linear-gradient(135deg, ${accentColor}18, ${accentColor}08)`, border: `1px solid ${accentColor}30` }}>
        <div className="flex items-center justify-between mb-3">
          <div>
            <h3 className="font-bold" style={{ color: "#e8edf5" }}>Overall Savings Progress</h3>
            <p className="text-sm" style={{ color: "#6b7ca0", fontFamily: "monospace" }}>
              ₹{totalSaved.toLocaleString()} of ₹{totalTarget.toLocaleString()}
            </p>
          </div>
          <div className="text-right">
            <div className="text-4xl font-black" style={{ color: accentColor, fontFamily: "monospace" }}>
              {overallPct.toFixed(0)}%
            </div>
            <div className="text-xs" style={{ color: "#6b7ca0" }}>Complete</div>
          </div>
        </div>
        <div className="h-3 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }}>
          <div className="h-full rounded-full transition-all" style={{ width: `${Math.min(overallPct, 100)}%`, background: accentColor }} />
        </div>
      </div>

      {/* Streak + Achievements */}
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="rounded-2xl p-5 flex items-center gap-4" style={glassCard()}>
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0"
            style={{ background: "rgba(245,158,11,0.12)" }}>
            <Flame className="w-7 h-7" style={{ color: "#f59e0b" }} />
          </div>
          <div>
            <p className="text-2xl font-black" style={{ color: "#e8edf5" }}>47 Days</p>
            <p style={{ color: "#f59e0b" }}>Savings Streak 🔥</p>
            <p className="text-xs" style={{ color: "#6b7ca0" }}>You're on fire! Keep it up</p>
          </div>
        </div>
        <div className="rounded-2xl p-5 flex items-center gap-4" style={glassCard()}>
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0"
            style={{ background: "rgba(245,158,11,0.12)" }}>
            <Trophy className="w-7 h-7" style={{ color: "#f59e0b" }} />
          </div>
          <div>
            <p className="text-2xl font-black" style={{ color: "#e8edf5" }}>Level 12</p>
            <p style={{ color: "#f59e0b" }}>Saver Rank 🏆</p>
            <p className="text-xs" style={{ color: "#6b7ca0" }}>850 XP to next level</p>
          </div>
        </div>
      </div>

      {/* Goals list */}
      {goals.length === 0 ? (
        <div className="rounded-2xl p-12 text-center" style={glassCard()}>
          <div className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4"
            style={{ background: `${accentColor}12` }}>
            <Target className="w-8 h-8" style={{ color: accentColor }} />
          </div>
          <p className="font-medium mb-1" style={{ color: "#e8edf5" }}>No goals yet</p>
          <p className="text-sm" style={{ color: "#6b7ca0" }}>
            {role ? `Create your first ${roleMeta?.label.toLowerCase()} savings goal above` : "Create your first savings goal to get started"}
          </p>
        </div>
      ) : (
        <div className="grid gap-4">
          {goals.map((goal) => {
            const pct = (goal.current_amount / goal.target_amount) * 100;
            const daysLeft = Math.ceil((new Date(goal.deadline).getTime() - Date.now()) / 86400000);
            const monthlyReq = daysLeft > 0 ? ((goal.target_amount - goal.current_amount) / daysLeft) * 30 : 0;

            return (
              <div key={goal.id} className="rounded-2xl p-6" style={glassCard()}>
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className="text-3xl">{getEmoji(goal.category)}</div>
                    <div>
                      <h3 className="font-bold" style={{ color: "#e8edf5" }}>{goal.name}</h3>
                      <p className="text-xs" style={{ color: "#6b7ca0", fontFamily: "monospace" }}>
                        ₹{goal.current_amount.toLocaleString()} of ₹{goal.target_amount.toLocaleString()}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-black" style={{ color: pct >= 100 ? "#10b981" : accentColor, fontFamily: "monospace" }}>
                      {pct.toFixed(0)}%
                    </div>
                    <span className="text-xs px-2 py-0.5 rounded-full"
                      style={pct >= 100
                        ? { background: "rgba(16,185,129,0.12)", color: "#10b981" }
                        : { background: `${accentColor}12`, color: accentColor }}>
                      {pct >= 100 ? "🏆 Complete" : `${daysLeft} days left`}
                    </span>
                  </div>
                </div>

                <div className="h-2.5 rounded-full mb-3" style={{ background: "rgba(255,255,255,0.06)" }}>
                  <div className="h-full rounded-full transition-all"
                    style={{ width: `${Math.min(pct, 100)}%`, background: pct >= 100 ? "#10b981" : accentColor }} />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 sm:gap-3 mb-4">
                  {[
                    { icon: DollarSign, label: "Remaining", value: `₹${Math.max(0, goal.target_amount - goal.current_amount).toLocaleString()}`, color: "#94a3b8" },
                    { icon: Calendar, label: "Per Month", value: `₹${monthlyReq.toFixed(0)}`, color: accentColor },
                    { icon: TrendingUp, label: "Progress", value: `+₹${(goal.current_amount * 0.05).toFixed(0)} this wk`, color: "#10b981" },
                  ].map((s) => (
                    <div key={s.label} className="p-3 rounded-xl text-center" style={{ background: "rgba(255,255,255,0.03)" }}>
                      <div className="flex items-center justify-center gap-1 mb-1">
                        <s.icon className="w-3.5 h-3.5" style={{ color: s.color }} />
                        <span className="text-xs" style={{ color: "#6b7ca0" }}>{s.label}</span>
                      </div>
                      <p className="text-sm font-bold" style={{ color: s.color, fontFamily: "monospace" }}>{s.value}</p>
                    </div>
                  ))}
                </div>

                {pct < 100 && (
                  <div className="flex gap-2">
                    <Input
                      type="number"
                      placeholder="Add amount (₹)"
                      value={addAmount[goal.id] || ""}
                      onChange={(e) => setAddAmount({ ...addAmount, [goal.id]: e.target.value })}
                      className="flex-1"
                      style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", color: "#e8edf5" }}
                    />
                    <Button onClick={() => handleAddMoney(goal.id)}
                      className="flex items-center gap-1.5 px-4"
                      style={{ background: accentColor, color: "#fff", border: "none" }}>
                      <Plus className="w-4 h-4" /> Add
                    </Button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* AI Savings Tips */}
      <div className="rounded-2xl p-6" style={{ background: `${accentColor}08`, border: `1px solid ${accentColor}20` }}>
        <div className="flex items-center gap-2 mb-4">
          <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ background: `${accentColor}18` }}>
            <Sparkles className="w-4 h-4" style={{ color: accentColor }} />
          </div>
          <h3 className="font-bold" style={{ color: accentColor }}>
            {role ? `AI Tips for ${roleMeta?.label}` : "AI Savings Tips"}
          </h3>
        </div>
        <ul className="space-y-2.5">
          {(role === "business"
            ? [
                "Allocate 15% of monthly revenue to a business emergency reserve — it protects operations during slow quarters.",
                "Consider SIP investments for your tax reserve to earn returns while holding funds for advance tax.",
                "Automating payroll savings can help you avoid cash flow surprises at month-end.",
              ]
            : role === "student"
            ? [
                "Cancel inactive Coursera Plus subscription and redirect ₹417/month to your Laptop Fund.",
                "Reduce weekend dining by 40% — you'll reach your Goa Trip goal 3 weeks early.",
                "Set up a weekly ₹300 auto-save on Sunday to build your emergency fund consistently.",
              ]
            : role === "home"
            ? [
                "Bulk-buying groceries monthly from a wholesale market could save ₹1,500-2,000 per month.",
                "Your electricity bill is 15% above average — scheduling AC off-peak hours could reduce it by ₹400.",
                "Consider LIC or ELSS for the children education fund to get tax benefits while saving.",
              ]
            : role === "freelancer"
            ? [
                "Set aside 30% of every client payment for advance tax — transfer automatically to avoid surprises.",
                "Your top client TechNova drives 45% of income — diversify to 5+ clients to reduce revenue risk.",
                "Raise your hourly rate by ₹500 — market analysis shows you are 18% below industry peers.",
              ]
            : [
                "You're spending 23% more on food delivery than last month. Redirecting half could add ₹1,200 to your goals.",
                "Your vacation goal is on track! Maintain current savings rate to reach it 2 weeks early.",
                "Consider setting up an auto-transfer of ₹2,000/week to accelerate your emergency fund goal.",
              ]
          ).map((tip, i) => (
            <li key={i} className="flex items-start gap-2 text-sm" style={{ color: "#94a3b8" }}>
              <Star className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" style={{ color: accentColor }} />
              {tip}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
