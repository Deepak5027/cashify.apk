import { useState, useEffect, useCallback, ComponentType } from "react";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../components/ui/dialog";
import { categories as defaultCategories } from "../data/mockData";
import {
  Plus,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  Sparkles,
  Briefcase,
  GraduationCap,
  Home,
  Users,
  LucideProps,
} from "lucide-react";
import { toast } from "sonner";
import { budgetsAPI, transactionsAPI } from "../../services/api";
import { useRole } from "../contexts/RoleContext";

// ── Types ─────────────────────────────────────────────────────────────────────

interface BudgetItem {
  id: string | number;
  category: string;
  amount: number;
  month?: string;
  year?: number;
  user_id?: string;
  spent: number;
  predicted: number;
}

interface RoleMeta {
  label: string;
  icon: ComponentType<LucideProps>;
  color: string;
}

interface SummaryCard {
  label: string;
  value: string;
  sub: string;
  icon: ComponentType<LucideProps>;
  iconColor: string;
}

// ── Constants ─────────────────────────────────────────────────────────────────

const ROLE_LABELS: Record<string, RoleMeta> = {
  business:   { label: "Business Owner", icon: Briefcase,     color: "#10b981" },
  student:    { label: "Student",        icon: GraduationCap, color: "#06b6d4" },
  home:       { label: "Home Manager",   icon: Home,          color: "#f59e0b" },
  freelancer: { label: "Freelancer",     icon: Users,         color: "#7c3aed" },
};

const ROLE_SUGGESTED_LIMITS: Record<string, Record<string, number>> = {
  business: {
    supplier: 200000, payroll: 350000, operations: 80000, tax_gst: 60000,
    marketing: 30000, inventory: 120000, office: 15000, loan_emi: 50000,
  },
  student: {
    food_delivery: 2000, subscriptions: 1200, study: 1500, transport: 800,
    entertainment: 1000, clothing: 1500, savings_transfer: 3000,
  },
  home: {
    groceries: 12000, electricity: 3000, water: 600, gas_lpg: 800,
    internet: 1500, dining: 3000, school_fees: 8000, household: 2500,
    vehicle_fuel: 3000, medical: 2000,
  },
  freelancer: {
    project_expense: 15000, tools_software: 5000, coworking: 6000,
    tax_advance: 20000, self_marketing: 5000, equipment: 10000,
    professional_dev: 3000, internet_phone: 1500,
  },
};

// ── Helpers ───────────────────────────────────────────────────────────────────

const glassCard = (accent = "rgba(255,255,255,0.07)"): React.CSSProperties => ({
  background: "rgba(14,20,35,0.75)",
  border: `1px solid ${accent}`,
  backdropFilter: "blur(16px)",
});

function safePct(numerator: number, denominator: number): number {
  if (!denominator || !isFinite(denominator)) return 0;
  return (numerator / denominator) * 100;
}

// ── Sub-components ────────────────────────────────────────────────────────────

function BarMini({ pct, color }: { pct: number; color: string }) {
  const safe = Math.min(Math.max(pct, 0), 100);
  const over = pct > 100;
  return (
    <div className="h-2 rounded-full w-full" style={{ background: "rgba(255,255,255,0.06)" }}>
      <div
        className="h-full rounded-full transition-all"
        style={{ width: `${safe}%`, background: over ? "#ef4444" : color }}
      />
    </div>
  );
}

// ── Main Component ────────────────────────────────────────────────────────────

export default function Budget() {
  const { role, roleCategories } = useRole();
  const [budgets, setBudgets] = useState<BudgetItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [newBudget, setNewBudget] = useState({ category: "", limit: "", period: "monthly" });

  const activeCategories = roleCategories.length > 0 ? roleCategories : defaultCategories;
  const roleMeta: RoleMeta | null = role ? (ROLE_LABELS[role] ?? null) : null;
  const accentColor = roleMeta?.color ?? "#10b981";
  const suggestedLimits: Record<string, number> = role ? (ROLE_SUGGESTED_LIMITS[role] ?? {}) : {};

  const loadBudgets = useCallback(async () => {
    try {
      const [budgetRes, txRes] = await Promise.all([
        budgetsAPI.getAll(),
        transactionsAPI.getAll(),
      ]);
      const budgetsData: BudgetItem[] = (budgetRes.budgets || []) as any[];
      const txns = (txRes.transactions || []) as any[];

      const daysPassed = Math.max(new Date().getDate(), 1); // guard zero

      const enriched: BudgetItem[] = budgetsData.map((b) => {
        const catTxns = txns.filter((t) => t.type === "expense" && t.category === b.category);
        const spent = catTxns.reduce((s, t) => s + (Number(t.amount) || 0), 0);
        const predicted = Math.round(((spent / daysPassed) * 30) * 100) / 100;
        return { ...b, amount: Number(b.amount) || 0, spent, predicted };
      });

      setBudgets(enriched);
    } catch {
      toast.error("Failed to load budgets");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadBudgets(); }, [loadBudgets]);

  const handleAddBudget = async () => {
    if (!newBudget.category || !newBudget.limit) {
      toast.error("Please fill in all fields");
      return;
    }

    const parsedAmount = parseFloat(newBudget.limit);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      toast.error("Please enter a valid positive amount");
      return;
    }

    if (budgets.find((b) => b.category === newBudget.category)) {
      toast.error("Budget already exists for this category");
      return;
    }

    try {
      await budgetsAPI.create({
        category: newBudget.category,
        amount: parsedAmount,
      });

      toast.success("Budget created successfully");
      setNewBudget({ category: "", limit: "", period: "monthly" });
      setIsAddDialogOpen(false);
      await loadBudgets();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : "Failed to create budget";
      toast.error(msg);
    }
  };

  const handleCategoryChange = (catId: string) => {
    const suggested = suggestedLimits[catId];
    setNewBudget((prev) => ({
      ...prev,
      category: catId,
      limit: suggested ? String(suggested) : prev.limit,
    }));
  };

  const totalBudget    = budgets.reduce((s, b) => s + (Number(b.amount) || 0), 0);
  const totalSpent     = budgets.reduce((s, b) => s + b.spent, 0);
  const totalPredicted = budgets.reduce((s, b) => s + b.predicted, 0);

  const summaryCards: SummaryCard[] = [
    {
      label: "Total Budget",
      value: `₹${totalBudget.toLocaleString()}`,
      sub: "Monthly limit",
      icon: TrendingUp,
      iconColor: "#3b82f6",
    },
    {
      label: "Total Spent",
      value: `₹${totalSpent.toFixed(0)}`,
      sub: `${safePct(totalSpent, totalBudget).toFixed(1)}% of budget`,
      icon: totalSpent > totalBudget ? AlertCircle : CheckCircle,
      iconColor: totalSpent > totalBudget ? "#ef4444" : "#10b981",
    },
    {
      label: "AI Prediction",
      value: `₹${totalPredicted.toFixed(0)}`,
      sub: "Expected by month end",
      icon: Sparkles,
      iconColor: "#7c3aed",
    },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div
            className="w-16 h-16 border-4 border-t-transparent rounded-full animate-spin mx-auto mb-4"
            style={{ borderColor: `${accentColor}40`, borderTopColor: accentColor }}
          />
          <p style={{ color: "#6b7ca0" }}>Loading budgets...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          {roleMeta && (() => {
            const RoleIcon = roleMeta.icon;
            return (
              <div className="flex items-center gap-1.5 mb-1">
                <RoleIcon className="w-3.5 h-3.5" style={{ color: accentColor }} />
                <span className="text-xs font-medium" style={{ color: accentColor }}>
                  {roleMeta.label} · Budget Planner
                </span>
              </div>
            );
          })()}
          <h1 className="text-2xl font-bold" style={{ color: "#e8edf5" }}>Budget Planner</h1>
          <p className="text-sm mt-0.5" style={{ color: "#6b7ca0" }}>
            {role
              ? `Set ${roleMeta?.label.toLowerCase()} spending limits with AI predictions`
              : "Set limits and track spending with AI predictions"}
          </p>
        </div>

        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button
              className="flex items-center gap-2 px-4 py-2 rounded-xl font-medium"
              style={{ background: accentColor, color: "#fff", border: "none" }}
            >
              <Plus className="w-4 h-4" />
              Add Budget
            </Button>
          </DialogTrigger>
          <DialogContent
            className="sm:max-w-md"
            style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}
          >
            <DialogHeader>
              <DialogTitle style={{ color: "#e8edf5" }}>Create New Budget</DialogTitle>
              <DialogDescription style={{ color: "#6b7ca0" }}>
                {role
                  ? `Set a ${roleMeta?.label} spending limit. AI will auto-suggest limits and predict month-end spend.`
                  : "Set a spending limit. AI will track and predict your spending."}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label style={{ color: "#94a3b8" }}>Category</Label>
                <Select value={newBudget.category} onValueChange={handleCategoryChange}>
                  <SelectTrigger
                    style={{
                      background: "rgba(255,255,255,0.05)",
                      border: "1px solid rgba(255,255,255,0.1)",
                      color: "#e8edf5",
                    }}
                  >
                    <SelectValue placeholder="Select category" />
                  </SelectTrigger>
                  <SelectContent
                    style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}
                  >
                    {activeCategories
                      .filter((cat) => !budgets.find((b) => b.category === cat.id))
                      .map((cat) => (
                        <SelectItem key={cat.id} value={cat.id}>
                          <span className="flex items-center gap-2">
                            <span
                              className="w-2 h-2 rounded-full inline-block"
                              style={{ background: cat.color }}
                            />
                            {cat.name}
                            {suggestedLimits[cat.id] ? (
                              <span style={{ color: accentColor, fontSize: 11 }}>
                                · Suggested ₹{suggestedLimits[cat.id].toLocaleString()}
                              </span>
                            ) : null}
                          </span>
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <div className="flex items-center justify-between mb-1">
                  <Label style={{ color: "#94a3b8" }}>Monthly Limit (₹)</Label>
                  {newBudget.category && suggestedLimits[newBudget.category] && (
                    <span className="text-xs flex items-center gap-1" style={{ color: accentColor }}>
                      <Sparkles className="w-3 h-3" />
                      AI suggested: ₹{suggestedLimits[newBudget.category].toLocaleString()}
                    </span>
                  )}
                </div>
                <Input
                  type="number"
                  placeholder="0"
                  value={newBudget.limit}
                  onChange={(e) => setNewBudget({ ...newBudget, limit: e.target.value })}
                  style={{
                    background: "rgba(255,255,255,0.05)",
                    border: "1px solid rgba(255,255,255,0.1)",
                    color: "#e8edf5",
                  }}
                />
              </div>
            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setIsAddDialogOpen(false)}
                style={{
                  border: "1px solid rgba(255,255,255,0.1)",
                  color: "#94a3b8",
                  background: "transparent",
                }}
              >
                Cancel
              </Button>
              <Button
                onClick={handleAddBudget}
                style={{ background: accentColor, color: "#fff", border: "none" }}
              >
                Create Budget
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {summaryCards.map((s) => {
          const SIcon = s.icon;
          return (
            <div
              key={s.label}
              className="rounded-2xl p-5 flex items-center justify-between"
              style={glassCard()}
            >
              <div>
                <p className="text-sm mb-1" style={{ color: "#6b7ca0" }}>{s.label}</p>
                <p
                  className="text-xl font-black mb-0.5"
                  style={{ color: "#e8edf5", fontFamily: "monospace" }}
                >
                  {s.value}
                </p>
                <p className="text-xs" style={{ color: "#6b7ca0" }}>{s.sub}</p>
              </div>
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center"
                style={{ background: `${s.iconColor}15` }}
              >
                <SIcon className="w-5 h-5" style={{ color: s.iconColor }} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Budget Cards */}
      {budgets.length === 0 ? (
        <div className="rounded-2xl p-12 text-center" style={glassCard()}>
          <div
            className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4"
            style={{ background: `${accentColor}12` }}
          >
            <Plus className="w-8 h-8" style={{ color: accentColor }} />
          </div>
          <p className="font-medium mb-1" style={{ color: "#e8edf5" }}>No budgets yet</p>
          <p className="text-sm" style={{ color: "#6b7ca0" }}>
            {role
              ? `Add your first ${roleMeta?.label.toLowerCase()} budget category above to start tracking`
              : "Create a budget to start tracking your spending"}
          </p>
        </div>
      ) : (
        <div className="grid gap-4">
          {budgets.map((budget) => {
            const amount = Number(budget.amount) || 0;
            const spent = budget.spent;
            const predicted = budget.predicted;
            const pct = safePct(spent, amount);
            const predPct = safePct(predicted, amount);
            const isOver = pct > 100;
            const cat = activeCategories.find((c) => c.id === budget.category);
            const catColor = cat?.color ?? accentColor;

            return (
              <div key={budget.id ?? budget.category} className="rounded-2xl p-6" style={glassCard()}>
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-11 h-11 rounded-xl flex items-center justify-center"
                      style={{ background: `${catColor}15` }}
                    >
                      <div className="w-5 h-5 rounded-full" style={{ background: catColor }} />
                    </div>
                    <div>
                      <h3 className="font-bold" style={{ color: "#e8edf5" }}>
                        {cat?.name ?? budget.category}
                      </h3>
                      <p className="text-xs" style={{ color: "#6b7ca0", fontFamily: "monospace" }}>
                        ₹{spent.toFixed(0)} of ₹{amount.toFixed(0)}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div
                      className="text-xl font-black"
                      style={{ color: isOver ? "#ef4444" : "#e8edf5", fontFamily: "monospace" }}
                    >
                      {pct.toFixed(1)}%
                    </div>
                    <p className="text-xs" style={{ color: "#6b7ca0" }}>used</p>
                  </div>
                </div>

                <div className="space-y-2 mb-3">
                  <BarMini pct={pct} color={catColor} />
                  <div className="flex items-center justify-between text-xs" style={{ color: "#6b7ca0" }}>
                    <span>
                      Remaining:{" "}
                      <strong style={{ color: isOver ? "#ef4444" : "#e8edf5", fontFamily: "monospace" }}>
                        ₹{Math.max(0, amount - spent).toFixed(0)}
                      </strong>
                    </span>
                    <span style={{ color: "#7c3aed" }}>
                      AI Forecast:{" "}
                      <strong style={{ fontFamily: "monospace" }}>
                        ₹{predicted.toFixed(0)} ({predPct.toFixed(0)}%)
                      </strong>
                    </span>
                  </div>
                </div>

                {isOver && (
                  <div
                    className="p-3 rounded-xl"
                    style={{ background: "rgba(239,68,68,0.08)", border: "1px solid rgba(239,68,68,0.2)" }}
                  >
                    <p className="text-sm" style={{ color: "#f87171" }}>
                      <AlertCircle className="w-3.5 h-3.5 inline mr-1" />
                      Exceeded by ₹{(spent - amount).toFixed(0)}
                    </p>
                  </div>
                )}
                {!isOver && predPct > 100 && (
                  <div
                    className="p-3 rounded-xl"
                    style={{ background: "rgba(245,158,11,0.08)", border: "1px solid rgba(245,158,11,0.2)" }}
                  >
                    <p className="text-sm" style={{ color: "#fbbf24" }}>
                      <AlertCircle className="w-3.5 h-3.5 inline mr-1" />
                      AI predicts overspend by ₹{(predicted - amount).toFixed(0)}
                    </p>
                  </div>
                )}
                {!isOver && predPct <= 100 && (
                  <div
                    className="p-3 rounded-xl"
                    style={{ background: "rgba(16,185,129,0.06)", border: "1px solid rgba(16,185,129,0.15)" }}
                  >
                    <p className="text-sm" style={{ color: "#34d399" }}>
                      <CheckCircle className="w-3.5 h-3.5 inline mr-1" />
                      On track — AI predicts you'll stay within budget
                    </p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
