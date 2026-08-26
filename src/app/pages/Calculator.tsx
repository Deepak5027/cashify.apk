import { useState, useCallback } from "react";
import { useTranslation } from "react-i18next";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Button } from "../components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Progress } from "../components/ui/progress";
import {
  Calculator as CalcIcon, TrendingUp, Wallet, PiggyBank, Percent,
  Calendar, IndianRupee, Target, BarChart3, AlertCircle, CheckCircle2,
} from "lucide-react";
import {
  PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis,
  Tooltip, CartesianGrid, LineChart, Line, Area, AreaChart,
} from "recharts";

// ─── Safe Math Parser ──────────────────────────────────────────────────────────
// No eval() — hand-written recursive descent parser for +, -, *, /, %, ()

class MathParser {
  private pos = 0;
  private expr = "";

  parse(expression: string): number {
    this.expr = expression.replace(/\s+/g, "").replace(/×/g, "*").replace(/÷/g, "/");
    this.pos = 0;
    if (!this.expr) return 0;
    const result = this.parseAddSub();
    if (this.pos !== this.expr.length) throw new Error("Unexpected character");
    return result;
  }

  private parseAddSub(): number {
    let left = this.parseMulDiv();
    while (this.pos < this.expr.length) {
      const op = this.expr[this.pos];
      if (op !== "+" && op !== "-") break;
      this.pos++;
      const right = this.parseMulDiv();
      left = op === "+" ? left + right : left - right;
    }
    return left;
  }

  private parseMulDiv(): number {
    let left = this.parseUnary();
    while (this.pos < this.expr.length) {
      const op = this.expr[this.pos];
      if (op !== "*" && op !== "/" && op !== "%") break;
      this.pos++;
      const right = this.parseUnary();
      if (op === "*") left = left * right;
      else if (op === "/") {
        if (right === 0) throw new Error("Division by zero");
        left = left / right;
      } else {
        left = left % right;
      }
    }
    return left;
  }

  private parseUnary(): number {
    if (this.pos < this.expr.length && this.expr[this.pos] === "-") {
      this.pos++;
      return -this.parsePrimary();
    }
    if (this.pos < this.expr.length && this.expr[this.pos] === "+") {
      this.pos++;
    }
    return this.parsePrimary();
  }

  private parsePrimary(): number {
    if (this.pos < this.expr.length && this.expr[this.pos] === "(") {
      this.pos++;
      const val = this.parseAddSub();
      if (this.pos >= this.expr.length || this.expr[this.pos] !== ")")
        throw new Error("Missing closing parenthesis");
      this.pos++;
      return val;
    }
    const start = this.pos;
    if (this.pos < this.expr.length && (this.expr[this.pos] === "." || /\d/.test(this.expr[this.pos]))) {
      while (this.pos < this.expr.length && /[\d.]/.test(this.expr[this.pos])) this.pos++;
      const numStr = this.expr.slice(start, this.pos);
      const num = parseFloat(numStr);
      if (isNaN(num)) throw new Error("Invalid number");
      return num;
    }
    throw new Error("Unexpected character: " + this.expr[this.pos]);
  }
}

const mathParser = new MathParser();

function safeCalc(expr: string): { result: number | null; error: string | null } {
  try {
    if (!expr || expr === "0") return { result: 0, error: null };
    const result = mathParser.parse(expr);
    if (!isFinite(result)) return { result: null, error: "Result is infinite" };
    return { result, error: null };
  } catch (e: any) {
    return { result: null, error: e.message || "Invalid expression" };
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const fmt = (n: number, decimals = 2) =>
  new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: decimals }).format(n);

const pct = (n: number) => `${n.toFixed(1)}%`;

const CHART_COLORS = ["#10b981", "#3b82f6", "#7c3aed", "#f59e0b", "#06b6d4", "#ef4444"];

function ErrorMsg({ msg }: { msg: string }) {
  return (
    <div className="flex items-center gap-2 text-sm text-destructive">
      <AlertCircle className="w-4 h-4 flex-shrink-0" />
      {msg}
    </div>
  );
}

function ResultCard({ label, value, sub, color = "#10b981", icon: Icon }: {
  label: string; value: string; sub?: string; color?: string; icon?: any;
}) {
  return (
    <div className="rounded-2xl p-4" style={{ background: `${color}08`, border: `1px solid ${color}20` }}>
      {Icon && <Icon className="w-4 h-4 mb-2" style={{ color }} />}
      <div className="text-xs mb-1" style={{ color: "#6b7ca0" }}>{label}</div>
      <div className="text-xl font-black font-mono" style={{ color }}>{value}</div>
      {sub && <div className="text-xs mt-1" style={{ color: "#6b7ca0" }}>{sub}</div>}
    </div>
  );
}

function NumInput({ label, value, onChange, placeholder = "0", prefix = "₹" }: {
  label: string; value: string; onChange: (v: string) => void; placeholder?: string; prefix?: string;
}) {
  return (
    <div className="space-y-1.5">
      <Label className="text-sm">{label}</Label>
      <div className="relative">
        <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">{prefix}</span>
        <Input
          type="number"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="pl-7"
          min="0"
        />
      </div>
    </div>
  );
}

// ─── 1. Basic Calculator ───────────────────────────────────────────────────────

function BasicCalc() {
  const [display, setDisplay] = useState("0");
  const [expression, setExpression] = useState("");
  const [error, setError] = useState("");
  const [history, setHistory] = useState<Array<{ expr: string; result: string }>>([]);

  const handleBtn = (val: string) => {
    setError("");
    if (val === "C") {
      setDisplay("0");
      setExpression("");
      return;
    }
    if (val === "CE") {
      setDisplay("0");
      return;
    }
    if (val === "⌫") {
      setDisplay((d) => (d.length > 1 ? d.slice(0, -1) : "0"));
      return;
    }
    if (val === "=") {
      const expr = display.replace(/×/g, "*").replace(/÷/g, "/");
      const { result, error: err } = safeCalc(expr);
      if (err) {
        setError(err);
        return;
      }
      const resultStr = String(parseFloat((result!).toFixed(10)));
      setHistory((h) => [{ expr: display, result: resultStr }, ...h.slice(0, 9)]);
      setDisplay(resultStr);
      return;
    }
    if (val === "%") {
      const { result, error: err } = safeCalc(display);
      if (err) { setError(err); return; }
      setDisplay(String(result! / 100));
      return;
    }
    if (val === "±") {
      const { result, error: err } = safeCalc(display);
      if (err) { setError(err); return; }
      setDisplay(String(-result!));
      return;
    }
    setDisplay((d) => {
      const operators = ["+", "-", "×", "÷"];
      const last = d[d.length - 1];
      if (operators.includes(val) && operators.includes(last)) {
        return d.slice(0, -1) + val;
      }
      return d === "0" && !operators.includes(val) ? val : d + val;
    });
  };

  const buttons = [
    ["C", "CE", "%", "÷"],
    ["7", "8", "9", "×"],
    ["4", "5", "6", "-"],
    ["1", "2", "3", "+"],
    ["±", "0", ".", "="],
  ];

  const isOp = (v: string) => ["÷", "×", "-", "+", "="].includes(v);
  const isUtil = (v: string) => ["C", "CE", "%", "±"].includes(v);

  return (
    <div className="grid lg:grid-cols-2 gap-6">
      <Card>
        <CardContent className="pt-6 space-y-4">
          <div className="rounded-xl p-4 text-right" style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)" }}>
            <div className="text-xs mb-1" style={{ color: "#6b7ca0" }}>Expression</div>
            <div className="text-3xl font-black font-mono truncate" style={{ color: "#e8edf5" }}>{display}</div>
            {error && <ErrorMsg msg={error} />}
          </div>
          <div className="grid grid-cols-4 gap-2">
            {buttons.flat().map((btn, i) => (
              <Button
                key={i}
                onClick={() => handleBtn(btn)}
                variant={isOp(btn) ? "default" : isUtil(btn) ? "secondary" : "outline"}
                className="h-12 text-base font-bold"
                style={btn === "=" ? { background: "#10b981", color: "#fff" } : undefined}
              >
                {btn}
              </Button>
            ))}
            <Button variant="outline" className="h-12" onClick={() => handleBtn("⌫")}>⌫</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-sm">History</CardTitle></CardHeader>
        <CardContent>
          {history.length === 0 ? (
            <p className="text-sm text-muted-foreground">No calculations yet.</p>
          ) : (
            <div className="space-y-2">
              {history.map((h, i) => (
                <div key={i} className="flex justify-between p-2 rounded-lg text-sm" style={{ background: "rgba(255,255,255,0.03)" }}>
                  <span style={{ color: "#6b7ca0" }}>{h.expr}</span>
                  <span className="font-bold font-mono" style={{ color: "#10b981" }}>= {h.result}</span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ─── 2. Budget Calculator ──────────────────────────────────────────────────────

function BudgetCalc() {
  const { t } = useTranslation();
  const [monthly, setMonthly] = useState("");
  const [weekly, setWeekly] = useState("");
  const [daily, setDaily] = useState("");
  const [expenses, setExpenses] = useState<Array<{ name: string; category: string; amount: number }>>([]);
  const [name, setName] = useState("");
  const [category, setCategory] = useState("food");
  const [amount, setAmount] = useState("");
  const [amtError, setAmtError] = useState("");

  const totalBudget =
    (parseFloat(monthly) || 0) +
    (parseFloat(weekly) || 0) * 4 +
    (parseFloat(daily) || 0) * 30;
  const totalExp = expenses.reduce((s, e) => s + e.amount, 0);
  const remaining = totalBudget - totalExp;
  const savingsPct = totalBudget > 0 ? Math.max(0, (remaining / totalBudget) * 100) : 0;
  const expPct = totalBudget > 0 ? Math.min(100, (totalExp / totalBudget) * 100) : 0;

  const addExpense = () => {
    setAmtError("");
    const a = parseFloat(amount);
    if (!name.trim()) return;
    if (isNaN(a) || a <= 0) { setAmtError("Enter a valid positive amount"); return; }
    setExpenses((prev) => [...prev, { name: name.trim(), category, amount: a }]);
    setName("");
    setAmount("");
  };

  const catMap = expenses.reduce((acc, e) => {
    acc[e.category] = (acc[e.category] || 0) + e.amount;
    return acc;
  }, {} as Record<string, number>);
  const pieData = Object.entries(catMap).map(([k, v]) => ({ name: k, value: v }));

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Budget Setup</CardTitle></CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <NumInput label={t("monthlyBudget")} value={monthly} onChange={setMonthly} />
          <NumInput label={t("weeklyBudget")} value={weekly} onChange={setWeekly} />
          <NumInput label={t("dailyBudget")} value={daily} onChange={setDaily} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Add Expense</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 md:grid-cols-4">
            <div className="space-y-1.5">
              <Label>Expense Name</Label>
              <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Groceries" />
            </div>
            <div className="space-y-1.5">
              <Label>Category</Label>
              <Select value={category} onValueChange={setCategory}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {["food","transport","entertainment","groceries","shopping","bills","health","other"].map((c) => (
                    <SelectItem key={c} value={c}>{t(c)}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <NumInput label="Amount" value={amount} onChange={setAmount} />
            <div className="flex items-end">
              <Button onClick={addExpense} className="w-full">{t("add")}</Button>
            </div>
          </div>
          {amtError && <ErrorMsg msg={amtError} />}
          {expenses.length > 0 && (
            <div className="space-y-2 max-h-48 overflow-y-auto">
              {expenses.map((e, i) => (
                <div key={i} className="flex justify-between items-center p-2 rounded-lg text-sm" style={{ background: "rgba(255,255,255,0.03)" }}>
                  <span style={{ color: "#94a3b8" }}>{e.name} <span style={{ color: "#6b7ca0" }}>({t(e.category)})</span></span>
                  <div className="flex items-center gap-3">
                    <span className="font-bold font-mono" style={{ color: "#e8edf5" }}>{fmt(e.amount)}</span>
                    <button onClick={() => setExpenses((prev) => prev.filter((_, j) => j !== i))}
                      className="text-destructive text-xs hover:opacity-70">✕</button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <ResultCard label="Total Budget" value={fmt(totalBudget)} icon={Wallet} />
        <ResultCard label="Total Expenses" value={fmt(totalExp)} color="#ef4444" icon={TrendingUp} />
        <ResultCard label="Remaining" value={fmt(remaining)} color={remaining >= 0 ? "#10b981" : "#ef4444"} />
        <ResultCard label="Daily Limit" value={fmt(totalBudget / 30)} color="#3b82f6" icon={Calendar} />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader><CardTitle className="text-sm flex items-center gap-2"><PiggyBank className="w-4 h-4 text-primary" />Savings Rate</CardTitle></CardHeader>
          <CardContent className="space-y-2">
            <div className="text-3xl font-black" style={{ color: "#10b981" }}>{pct(savingsPct)}</div>
            <Progress value={savingsPct} className="h-3" />
            <p className="text-xs text-muted-foreground">Target: ≥ 20%</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle className="text-sm flex items-center gap-2"><Percent className="w-4 h-4 text-destructive" />Expense Rate</CardTitle></CardHeader>
          <CardContent className="space-y-2">
            <div className="text-3xl font-black" style={{ color: expPct > 80 ? "#ef4444" : "#f59e0b" }}>{pct(expPct)}</div>
            <Progress value={expPct} className="h-3" />
            {expPct > 100 && <ErrorMsg msg="Expenses exceed your total budget!" />}
          </CardContent>
        </Card>
      </div>

      {pieData.length > 0 && (
        <Card>
          <CardHeader><CardTitle>Expense Breakdown by Category</CardTitle></CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" outerRadius={90}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  dataKey="value">
                  {pieData.map((_, i) => <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />)}
                </Pie>
                <Tooltip formatter={(v: any) => fmt(v)} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ─── 3. Savings Calculator ────────────────────────────────────────────────────

function SavingsCalc() {
  const [principal, setPrincipal] = useState("");
  const [monthly, setMonthly] = useState("");
  const [rate, setRate] = useState("");
  const [years, setYears] = useState("");
  const [error, setError] = useState("");

  const compute = () => {
    const p = parseFloat(principal) || 0;
    const m = parseFloat(monthly) || 0;
    const r = (parseFloat(rate) || 0) / 100 / 12;
    const n = (parseFloat(years) || 0) * 12;
    if (n <= 0) return null;
    if (r === 0) return { total: p + m * n, interest: 0, invested: p + m * n, data: [] };
    const futureP = p * Math.pow(1 + r, n);
    const futureM = m * ((Math.pow(1 + r, n) - 1) / r);
    const total = futureP + futureM;
    const invested = p + m * n;
    const data = Array.from({ length: Math.min(parseInt(years) || 0, 30) }, (_, i) => {
      const yr = i + 1;
      const nn = yr * 12;
      const fp = p * Math.pow(1 + r, nn);
      const fm = m * ((Math.pow(1 + r, nn) - 1) / r);
      return { year: `Y${yr}`, value: Math.round(fp + fm), invested: Math.round(p + m * nn) };
    });
    return { total, interest: total - invested, invested, data };
  };

  const res = compute();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Savings Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NumInput label="Initial Principal" value={principal} onChange={setPrincipal} />
          <NumInput label="Monthly Contribution" value={monthly} onChange={setMonthly} />
          <NumInput label="Annual Interest Rate" value={rate} onChange={setRate} placeholder="8.5" prefix="%" />
          <NumInput label="Duration (Years)" value={years} onChange={setYears} placeholder="10" prefix="Yr" />
        </CardContent>
      </Card>

      {res && (
        <>
          <div className="grid gap-4 sm:grid-cols-3">
            <ResultCard label="Future Value" value={fmt(res.total)} icon={TrendingUp} />
            <ResultCard label="Total Invested" value={fmt(res.invested)} color="#3b82f6" icon={Wallet} />
            <ResultCard label="Interest Earned" value={fmt(res.interest)} color="#f59e0b" icon={PiggyBank} />
          </div>
          {res.data.length > 0 && (
            <Card>
              <CardHeader><CardTitle>Growth Projection</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={280}>
                  <AreaChart data={res.data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                    <XAxis dataKey="year" stroke="#6b7ca0" tick={{ fontSize: 11 }} />
                    <YAxis stroke="#6b7ca0" tick={{ fontSize: 11 }} tickFormatter={(v) => `₹${(v/100000).toFixed(0)}L`} />
                    <Tooltip formatter={(v: any) => fmt(v)} />
                    <Area type="monotone" dataKey="invested" fill="#3b82f620" stroke="#3b82f6" name="Invested" />
                    <Area type="monotone" dataKey="value" fill="#10b98120" stroke="#10b981" name="Total Value" />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  );
}

// ─── 4. EMI Calculator ────────────────────────────────────────────────────────

function EMICalc() {
  const [loan, setLoan] = useState("");
  const [rate, setRate] = useState("");
  const [tenure, setTenure] = useState("");
  const [tenureType, setTenureType] = useState("months");

  const compute = () => {
    const p = parseFloat(loan) || 0;
    const r = (parseFloat(rate) || 0) / 100 / 12;
    let n = parseFloat(tenure) || 0;
    if (tenureType === "years") n *= 12;
    if (p <= 0 || n <= 0) return null;
    if (r === 0) return { emi: p / n, total: p, interest: 0, principal: p };
    const emi = (p * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
    const total = emi * n;
    return { emi, total, interest: total - p, principal: p };
  };

  const res = compute();
  const pieData = res ? [
    { name: "Principal", value: res.principal },
    { name: "Interest", value: res.interest },
  ] : [];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>EMI Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NumInput label="Loan Amount" value={loan} onChange={setLoan} />
          <NumInput label="Annual Interest Rate" value={rate} onChange={setRate} prefix="%" placeholder="10.5" />
          <NumInput label="Tenure" value={tenure} onChange={setTenure} prefix={tenureType === "years" ? "Yr" : "Mo"} placeholder="24" />
          <div className="space-y-1.5">
            <Label>Tenure Type</Label>
            <Select value={tenureType} onValueChange={setTenureType}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="months">Months</SelectItem>
                <SelectItem value="years">Years</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {res && (
        <>
          <div className="grid gap-4 sm:grid-cols-3">
            <ResultCard label="Monthly EMI" value={fmt(res.emi)} icon={Calendar} />
            <ResultCard label="Total Payment" value={fmt(res.total)} color="#3b82f6" icon={Wallet} />
            <ResultCard label="Total Interest" value={fmt(res.interest)} color="#ef4444" icon={IndianRupee} />
          </div>
          <div className="grid md:grid-cols-2 gap-6">
            <Card>
              <CardHeader><CardTitle className="text-sm">Payment Breakdown</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie data={pieData} cx="50%" cy="50%" outerRadius={70} dataKey="value"
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                      <Cell fill="#10b981" />
                      <Cell fill="#ef4444" />
                    </Pie>
                    <Tooltip formatter={(v: any) => fmt(v)} />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
            <Card>
              <CardHeader><CardTitle className="text-sm">Summary</CardTitle></CardHeader>
              <CardContent className="space-y-3">
                {[
                  { label: "Principal", value: fmt(res.principal), color: "#10b981" },
                  { label: "Interest Payable", value: fmt(res.interest), color: "#ef4444" },
                  { label: "Total Payable", value: fmt(res.total), color: "#3b82f6" },
                  { label: "Interest %", value: pct((res.interest / res.total) * 100), color: "#f59e0b" },
                ].map((row) => (
                  <div key={row.label} className="flex justify-between items-center py-2 border-b border-border/30">
                    <span className="text-sm text-muted-foreground">{row.label}</span>
                    <span className="font-bold font-mono text-sm" style={{ color: row.color }}>{row.value}</span>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}

// ─── 5. Loan Calculator ───────────────────────────────────────────────────────

function LoanCalc() {
  const [amount, setAmount] = useState("");
  const [down, setDown] = useState("");
  const [rate, setRate] = useState("");
  const [years, setYears] = useState("");

  const compute = () => {
    const a = parseFloat(amount) || 0;
    const d = parseFloat(down) || 0;
    const p = Math.max(0, a - d);
    const r = (parseFloat(rate) || 0) / 100 / 12;
    const n = (parseFloat(years) || 0) * 12;
    if (p <= 0 || n <= 0) return null;
    const emi = r === 0 ? p / n : (p * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
    const total = emi * n;
    const schedule = Array.from({ length: Math.min(parseInt(years) || 0, 30) }, (_, i) => {
      const yr = i + 1;
      return {
        year: `Y${yr}`,
        principal: Math.round((p / n) * 12 * yr),
        interest: Math.round((total - p) * (yr / (parseInt(years) || 1))),
      };
    });
    return { emi, total, interest: total - p, principal: p, down: d, schedule };
  };

  const res = compute();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Loan Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NumInput label="Loan Amount" value={amount} onChange={setAmount} />
          <NumInput label="Down Payment" value={down} onChange={setDown} />
          <NumInput label="Interest Rate (Annual)" value={rate} onChange={setRate} prefix="%" placeholder="8.5" />
          <NumInput label="Loan Term (Years)" value={years} onChange={setYears} prefix="Yr" placeholder="20" />
        </CardContent>
      </Card>

      {res && (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <ResultCard label="Net Loan Amount" value={fmt(res.principal)} />
            <ResultCard label="Monthly EMI" value={fmt(res.emi)} color="#3b82f6" icon={Calendar} />
            <ResultCard label="Total Interest" value={fmt(res.interest)} color="#ef4444" />
            <ResultCard label="Total Cost" value={fmt(res.total + res.down)} color="#f59e0b" icon={Wallet} />
          </div>
          {res.schedule.length > 0 && (
            <Card>
              <CardHeader><CardTitle>Yearly Payment Schedule</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={260}>
                  <BarChart data={res.schedule}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                    <XAxis dataKey="year" stroke="#6b7ca0" tick={{ fontSize: 11 }} />
                    <YAxis stroke="#6b7ca0" tick={{ fontSize: 11 }} tickFormatter={(v) => `₹${(v/100000).toFixed(0)}L`} />
                    <Tooltip formatter={(v: any) => fmt(v)} />
                    <Bar dataKey="principal" name="Principal" fill="#10b981" />
                    <Bar dataKey="interest" name="Interest" fill="#ef4444" />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  );
}

// ─── 6. SIP Calculator ───────────────────────────────────────────────────────

function SIPCalc() {
  const [monthly, setMonthly] = useState("");
  const [rate, setRate] = useState("");
  const [years, setYears] = useState("");

  const compute = () => {
    const m = parseFloat(monthly) || 0;
    const r = (parseFloat(rate) || 0) / 100 / 12;
    const n = (parseFloat(years) || 0) * 12;
    if (m <= 0 || n <= 0) return null;
    const fv = r === 0 ? m * n : m * ((Math.pow(1 + r, n) - 1) / r) * (1 + r);
    const invested = m * n;
    const data = Array.from({ length: parseInt(years) || 0 }, (_, i) => {
      const yr = i + 1;
      const nn = yr * 12;
      const v = r === 0 ? m * nn : m * ((Math.pow(1 + r, nn) - 1) / r) * (1 + r);
      return { year: `Y${yr}`, value: Math.round(v), invested: Math.round(m * nn) };
    });
    return { fv, invested, gain: fv - invested, data };
  };

  const res = compute();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>SIP (Systematic Investment Plan) Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-3">
          <NumInput label="Monthly SIP Amount" value={monthly} onChange={setMonthly} />
          <NumInput label="Expected Annual Return" value={rate} onChange={setRate} prefix="%" placeholder="12" />
          <NumInput label="Investment Period (Years)" value={years} onChange={setYears} prefix="Yr" placeholder="15" />
        </CardContent>
      </Card>

      {res && (
        <>
          <div className="grid gap-4 sm:grid-cols-3">
            <ResultCard label="Invested Amount" value={fmt(res.invested)} color="#3b82f6" icon={Wallet} />
            <ResultCard label="Wealth Gained" value={fmt(res.gain)} color="#f59e0b" icon={TrendingUp} />
            <ResultCard label="Maturity Value" value={fmt(res.fv)} icon={PiggyBank} />
          </div>
          {res.data.length > 0 && (
            <Card>
              <CardHeader><CardTitle>SIP Growth Projection</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={260}>
                  <AreaChart data={res.data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                    <XAxis dataKey="year" stroke="#6b7ca0" tick={{ fontSize: 11 }} />
                    <YAxis stroke="#6b7ca0" tick={{ fontSize: 11 }} tickFormatter={(v) => `₹${(v/100000).toFixed(0)}L`} />
                    <Tooltip formatter={(v: any) => fmt(v)} />
                    <Area type="monotone" dataKey="invested" fill="#3b82f620" stroke="#3b82f6" name="Invested" />
                    <Area type="monotone" dataKey="value" fill="#10b98120" stroke="#10b981" name="Total Value" />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          )}
        </>
      )}
    </div>
  );
}

// ─── 7. FD Calculator ────────────────────────────────────────────────────────

function FDCalc() {
  const [principal, setPrincipal] = useState("");
  const [rate, setRate] = useState("");
  const [years, setYears] = useState("");
  const [compounding, setCompounding] = useState("4");

  const compute = () => {
    const p = parseFloat(principal) || 0;
    const r = (parseFloat(rate) || 0) / 100;
    const n = parseFloat(years) || 0;
    const freq = parseFloat(compounding);
    if (p <= 0 || n <= 0) return null;
    const maturity = p * Math.pow(1 + r / freq, freq * n);
    return { maturity, interest: maturity - p, principal: p };
  };

  const res = compute();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Fixed Deposit (FD) Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NumInput label="Principal Amount" value={principal} onChange={setPrincipal} />
          <NumInput label="Annual Interest Rate" value={rate} onChange={setRate} prefix="%" placeholder="7.5" />
          <NumInput label="Duration (Years)" value={years} onChange={setYears} prefix="Yr" placeholder="5" />
          <div className="space-y-1.5">
            <Label>Compounding Frequency</Label>
            <Select value={compounding} onValueChange={setCompounding}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="1">Annually</SelectItem>
                <SelectItem value="2">Semi-Annually</SelectItem>
                <SelectItem value="4">Quarterly</SelectItem>
                <SelectItem value="12">Monthly</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {res && (
        <div className="grid gap-4 sm:grid-cols-3">
          <ResultCard label="Principal" value={fmt(res.principal)} color="#3b82f6" icon={Wallet} />
          <ResultCard label="Interest Earned" value={fmt(res.interest)} color="#f59e0b" icon={TrendingUp} />
          <ResultCard label="Maturity Amount" value={fmt(res.maturity)} icon={PiggyBank} />
        </div>
      )}
    </div>
  );
}

// ─── 8. Percentage Calculator ─────────────────────────────────────────────────

function PercentageCalc() {
  const [a, setA] = useState("");
  const [b, setB] = useState("");
  const [mode, setMode] = useState("pct_of");

  const compute = () => {
    const va = parseFloat(a) || 0;
    const vb = parseFloat(b) || 0;
    switch (mode) {
      case "pct_of": return { result: (va / 100) * vb, label: `${va}% of ₹${vb}` };
      case "what_pct": return vb === 0 ? null : { result: (va / vb) * 100, label: `${va} is what % of ${vb}`, unit: "%" };
      case "increase": return { result: vb * (1 + va / 100), label: `₹${vb} increased by ${va}%` };
      case "decrease": return { result: vb * (1 - va / 100), label: `₹${vb} decreased by ${va}%` };
      case "change": return vb === 0 ? null : { result: ((vb - va) / va) * 100, label: "% change from A to B", unit: "%" };
      default: return null;
    }
  };

  const res = compute();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Percentage Calculator</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1.5">
            <Label>Calculation Type</Label>
            <Select value={mode} onValueChange={setMode}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="pct_of">X% of Y</SelectItem>
                <SelectItem value="what_pct">X is what % of Y?</SelectItem>
                <SelectItem value="increase">Y increased by X%</SelectItem>
                <SelectItem value="decrease">Y decreased by X%</SelectItem>
                <SelectItem value="change">% change from X to Y</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <NumInput label="Value A (X)" value={a} onChange={setA} prefix="" placeholder="20" />
            <NumInput label="Value B (Y)" value={b} onChange={setB} prefix="" placeholder="5000" />
          </div>
        </CardContent>
      </Card>

      {res && (
        <ResultCard
          label={res.label}
          value={res.unit === "%" ? `${res.result.toFixed(2)}%` : fmt(res.result)}
          icon={Percent}
        />
      )}
    </div>
  );
}

// ─── 9. Monthly Expense Forecast ──────────────────────────────────────────────

function ForecastCalc() {
  const [income, setIncome] = useState("");
  const [expenses, setExpenses] = useState({
    rent: "", food: "", transport: "", utilities: "", entertainment: "", health: "", emi: "", other: "",
  });
  const [growth, setGrowth] = useState("5");

  type ExpKey = keyof typeof expenses;
  const totalExp = Object.values(expenses).reduce((s, v) => s + (parseFloat(v) || 0), 0);
  const inc = parseFloat(income) || 0;
  const savings = inc - totalExp;
  const g = (parseFloat(growth) || 0) / 100;

  const forecastData = Array.from({ length: 6 }, (_, i) => ({
    month: ["Jul","Aug","Sep","Oct","Nov","Dec"][i],
    income: Math.round(inc * Math.pow(1 + g / 12, i + 1)),
    expenses: Math.round(totalExp * Math.pow(1 + (g * 0.6) / 12, i + 1)),
    savings: Math.round((inc - totalExp) * Math.pow(1 + g / 12, i + 1)),
  }));

  const cats = Object.entries(expenses).map(([k, v]) => ({ name: k, value: parseFloat(v) || 0 })).filter((e) => e.value > 0);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Monthly Expense Forecast</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <NumInput label="Monthly Income" value={income} onChange={setIncome} />
            <NumInput label="Income Growth Rate (Annual)" value={growth} onChange={setGrowth} prefix="%" placeholder="5" />
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {(Object.keys(expenses) as ExpKey[]).map((key) => (
              <NumInput
                key={key}
                label={key.charAt(0).toUpperCase() + key.slice(1)}
                value={expenses[key]}
                onChange={(v) => setExpenses((prev) => ({ ...prev, [key]: v }))}
              />
            ))}
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-3">
        <ResultCard label="Monthly Income" value={fmt(inc)} color="#10b981" icon={TrendingUp} />
        <ResultCard label="Total Expenses" value={fmt(totalExp)} color="#ef4444" />
        <ResultCard label="Monthly Savings" value={fmt(savings)} color={savings >= 0 ? "#3b82f6" : "#ef4444"} icon={PiggyBank} />
      </div>

      {inc > 0 && (
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader><CardTitle>6-Month Forecast</CardTitle></CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={240}>
                <LineChart data={forecastData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="month" stroke="#6b7ca0" tick={{ fontSize: 11 }} />
                  <YAxis stroke="#6b7ca0" tick={{ fontSize: 11 }} tickFormatter={(v) => `₹${(v/1000).toFixed(0)}K`} />
                  <Tooltip formatter={(v: any) => fmt(v)} />
                  <Line type="monotone" dataKey="income" stroke="#10b981" name="Income" strokeWidth={2} dot={false} />
                  <Line type="monotone" dataKey="expenses" stroke="#ef4444" name="Expenses" strokeWidth={2} dot={false} />
                  <Line type="monotone" dataKey="savings" stroke="#3b82f6" name="Savings" strokeWidth={2} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {cats.length > 0 && (
            <Card>
              <CardHeader><CardTitle>Expense Distribution</CardTitle></CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={240}>
                  <PieChart>
                    <Pie data={cats} cx="50%" cy="50%" outerRadius={80} dataKey="value"
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                      {cats.map((_, i) => <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />)}
                    </Pie>
                    <Tooltip formatter={(v: any) => fmt(v)} />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}

// ─── 10. Savings Goal Calculator ──────────────────────────────────────────────

function GoalCalc() {
  const [goal, setGoal] = useState("");
  const [current, setCurrent] = useState("");
  const [monthly, setMonthly] = useState("");
  const [rate, setRate] = useState("");

  const compute = () => {
    const g = parseFloat(goal) || 0;
    const c = parseFloat(current) || 0;
    const m = parseFloat(monthly) || 0;
    const r = (parseFloat(rate) || 0) / 100 / 12;
    const remaining = Math.max(0, g - c);
    if (remaining === 0) return { months: 0, months_no_interest: 0, total_contributions: 0, done: true };
    if (m <= 0) return null;
    let months = 0;
    let bal = c;
    while (bal < g && months < 1200) {
      bal = bal * (1 + r) + m;
      months++;
    }
    const months_no_interest = Math.ceil(remaining / m);
    return { months, months_no_interest, total_contributions: m * months, done: false, remaining };
  };

  const res = compute();
  const progressPct = goal && current ? Math.min(100, ((parseFloat(current) || 0) / (parseFloat(goal) || 1)) * 100) : 0;

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle>Savings Goal Calculator</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <NumInput label="Goal Amount (Target)" value={goal} onChange={setGoal} />
          <NumInput label="Current Savings" value={current} onChange={setCurrent} />
          <NumInput label="Monthly Contribution" value={monthly} onChange={setMonthly} />
          <NumInput label="Annual Interest Rate" value={rate} onChange={setRate} prefix="%" placeholder="6" />
        </CardContent>
      </Card>

      {goal && (
        <Card>
          <CardHeader><CardTitle className="text-sm flex items-center gap-2"><Target className="w-4 h-4 text-primary" />Progress</CardTitle></CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between text-sm mb-1">
              <span style={{ color: "#6b7ca0" }}>{fmt(parseFloat(current) || 0)} saved</span>
              <span className="font-bold" style={{ color: "#10b981" }}>{progressPct.toFixed(1)}%</span>
            </div>
            <Progress value={progressPct} className="h-4" />
            <div className="text-right text-sm" style={{ color: "#6b7ca0" }}>Goal: {fmt(parseFloat(goal) || 0)}</div>
          </CardContent>
        </Card>
      )}

      {res && !res.done && (
        <div className="grid gap-4 sm:grid-cols-3">
          <ResultCard label="Months to Goal (with interest)" value={`${res.months} months`} icon={Calendar} />
          <ResultCard label="Months (without interest)" value={`${res.months_no_interest} months`} color="#f59e0b" />
          <ResultCard label="Total Contributions" value={fmt(res.total_contributions)} color="#3b82f6" icon={Wallet} />
        </div>
      )}

      {res?.done && (
        <div className="flex items-center gap-3 p-4 rounded-2xl" style={{ background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.2)" }}>
          <CheckCircle2 className="w-6 h-6 text-primary" />
          <span className="font-semibold text-primary">Goal Already Achieved! 🎉</span>
        </div>
      )}
    </div>
  );
}

// ─── Main Component ────────────────────────────────────────────────────────────

const TABS = [
  { value: "basic", label: "Basic", icon: CalcIcon, component: BasicCalc },
  { value: "budget", label: "Budget", icon: Wallet, component: BudgetCalc },
  { value: "savings", label: "Savings", icon: PiggyBank, component: SavingsCalc },
  { value: "emi", label: "EMI", icon: Calendar, component: EMICalc },
  { value: "loan", label: "Loan", icon: IndianRupee, component: LoanCalc },
  { value: "sip", label: "SIP", icon: TrendingUp, component: SIPCalc },
  { value: "fd", label: "FD", icon: BarChart3, component: FDCalc },
  { value: "percent", label: "Percent", icon: Percent, component: PercentageCalc },
  { value: "forecast", label: "Forecast", icon: Target, component: ForecastCalc },
  { value: "goal", label: "Goal", icon: Target, component: GoalCalc },
];

export default function Calculator() {
  const [activeTab, setActiveTab] = useState("basic");
  const active = TABS.find((t) => t.value === activeTab);
  const ActiveComponent = active?.component ?? BasicCalc;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-2xl flex items-center justify-center" style={{ background: "rgba(16,185,129,0.12)", border: "1px solid rgba(16,185,129,0.2)" }}>
          <CalcIcon className="w-5 h-5" style={{ color: "#10b981" }} />
        </div>
        <div>
          <h1 className="text-2xl font-black" style={{ color: "#e8edf5", letterSpacing: "-0.02em" }}>Smart Finance Calculator</h1>
          <p className="text-sm" style={{ color: "#6b7ca0" }}>10 calculators — all values in Indian Rupees ₹</p>
        </div>
      </div>

      {/* Tab bar — scrollable on mobile */}
      <div className="overflow-x-auto -mx-4 px-4 lg:mx-0 lg:px-0">
        <div className="flex gap-1.5 min-w-max pb-1">
          {TABS.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.value;
            return (
              <button
                key={tab.value}
                onClick={() => setActiveTab(tab.value)}
                className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold transition-all whitespace-nowrap"
                style={{
                  background: isActive ? "rgba(16,185,129,0.12)" : "rgba(255,255,255,0.04)",
                  border: `1px solid ${isActive ? "rgba(16,185,129,0.3)" : "rgba(255,255,255,0.07)"}`,
                  color: isActive ? "#10b981" : "#6b7ca0",
                }}
              >
                <Icon className="w-3.5 h-3.5" />
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Calculator content */}
      <ActiveComponent />
    </div>
  );
}
