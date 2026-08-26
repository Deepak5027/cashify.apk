import { useState, useEffect } from "react";
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
import { Switch } from "../components/ui/switch";
import { categories as defaultCategories } from "../data/mockData";
import {
  Plus,
  Search,
  Filter,
  ArrowUpRight,
  ArrowDownRight,
  AlertTriangle,
  Trash2,
  Briefcase,
  GraduationCap,
  Home,
  Users,
  Download,
  FileSpreadsheet,
  ChevronLeft,
  ChevronRight,
  Receipt,
  Sparkles,
  Repeat,
} from "lucide-react";
import { toast } from "sonner";
import { transactionsAPI, budgetsAPI, Budget } from "../../services/api";
import { useRole } from "../contexts/RoleContext";
import { exportTransactionsToCSV, exportFinancialReportPDF } from "../../utils/exportUtils";
import { calculateFraudScore } from "../../services/fraudDetection";

const ROLE_LABELS: Record<string, { label: string; icon: any; color: string }> = {
  business: { label: "Business Owner", icon: Briefcase, color: "#10b981" },
  student:  { label: "Student",        icon: GraduationCap, color: "#06b6d4" },
  home:     { label: "Home Manager",   icon: Home,  color: "#f59e0b" },
  freelancer: { label: "Freelancer",   icon: Users, color: "#7c3aed" },
};

const glassCard = {
  background: "rgba(14,20,35,0.75)",
  border: "1px solid rgba(255,255,255,0.07)",
  backdropFilter: "blur(16px)",
};

const ITEMS_PER_PAGE_OPTIONS = [10, 25, 50];

export default function Transactions() {
  const { role, roleCategories } = useRole();
  const [transactions, setTransactions] = useState<any[]>([]);
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [filterCategory, setFilterCategory] = useState("all");
  const [filterType, setFilterType] = useState("all");
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Form state & validation errors
  const [newTransaction, setNewTransaction] = useState({
    merchant: "",
    amount: "",
    category: "",
    type: "expense",
    paymentMode: "UPI",
    isRecurring: false,
    recurringPeriod: "monthly",
    date: new Date().toISOString().split("T")[0],
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  // Use role-specific categories if a role is selected, otherwise fall back to defaults
  const activeCategories = roleCategories.length > 0 ? roleCategories : defaultCategories;
  const roleMeta = role ? ROLE_LABELS[role] : null;

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    try {
      const [txResponse, budgetResponse] = await Promise.all([
        transactionsAPI.getAll(),
        budgetsAPI.getAll().catch(() => ({ budgets: [] })),
      ]);
      const rawList = txResponse.transactions || txResponse.data || [];
      setTransactions(rawList);
      setBudgets(budgetResponse.budgets || []);
    } catch (error: any) {
      console.error("Failed to load transactions:", error);
      toast.error("Failed to load transactions");
    } finally {
      setLoading(false);
    }
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};
    if (!newTransaction.merchant.trim()) {
      errors.merchant = "Merchant / description is required";
    }
    const amt = parseFloat(newTransaction.amount);
    if (!newTransaction.amount || isNaN(amt) || amt <= 0) {
      errors.amount = "Enter a valid amount greater than 0";
    }
    if (!newTransaction.category) {
      errors.category = "Please select a category";
    }
    if (!newTransaction.paymentMode) {
      errors.paymentMode = "Please select a payment mode";
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleAddTransaction = async () => {
    if (!validateForm()) {
      toast.error("Please correct the errors before submitting");
      return;
    }

    setSubmitting(true);
    try {
      const amountVal = parseFloat(newTransaction.amount);
      const transactionData = {
        merchant: newTransaction.merchant.trim(),
        amount: amountVal,
        category: newTransaction.category,
        type: newTransaction.type as 'income' | 'expense',
        payment_mode: newTransaction.paymentMode,
        isRecurring: newTransaction.isRecurring,
        recurringPeriod: newTransaction.isRecurring ? newTransaction.recurringPeriod : undefined,
        date: newTransaction.date ? new Date(newTransaction.date).toISOString() : new Date().toISOString(),
      };

      // Client-side real-time budget overrun check
      if (transactionData.type === 'expense') {
        const catTarget = (transactionData.category || '').toLowerCase();
        const matchedBudget = budgets.find(b =>
          (b.category || b.name || '').toLowerCase() === catTarget
        );

        if (matchedBudget) {
          const limit = matchedBudget.limit || matchedBudget.amount || 0;
          const currentSpent = transactions
            .filter(t => t.type === 'expense' && (t.category || '').toLowerCase() === catTarget)
            .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
          const projectedSpent = currentSpent + amountVal;

          if (limit > 0 && projectedSpent > limit) {
            toast.warning(
              `🚨 Budget Exceeded: Spending on "${transactionData.category}" has reached ₹${projectedSpent.toFixed(2)}, exceeding your limit of ₹${limit.toFixed(2)}!`,
              { duration: 6500 }
            );
          } else if (limit > 0 && projectedSpent >= limit * 0.85) {
            toast.info(
              `⚠️ Budget Alert: Spending on "${transactionData.category}" is approaching limit (₹${projectedSpent.toFixed(2)} / ₹${limit.toFixed(2)}).`,
              { duration: 4500 }
            );
          }
        }
      }

      const created = await transactionsAPI.create(transactionData);
      setTransactions([created, ...transactions]);

      setIsAddDialogOpen(false);
      setNewTransaction({
        merchant: "",
        amount: "",
        category: "",
        type: "expense",
        paymentMode: "UPI",
        isRecurring: false,
        recurringPeriod: "monthly",
        date: new Date().toISOString().split("T")[0],
      });
      setFormErrors({});
      toast.success(
        transactionData.isRecurring
          ? `Recurring transaction scheduled (${transactionData.recurringPeriod})`
          : "Transaction recorded successfully"
      );
    } catch (error: any) {
      console.error("Failed to add transaction:", error);
      toast.error(error.message || "Failed to add transaction");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteTransaction = async (id: number | string) => {
    try {
      await transactionsAPI.delete(id);
      setTransactions(transactions.filter((t) => t.id !== id));
      toast.success("Transaction deleted");
    } catch (error: any) {
      console.error("Failed to delete transaction:", error);
      toast.error("Failed to delete transaction");
    }
  };

  // Filtering
  const filteredTransactions = transactions.filter((t) => {
    if (!t) return false;
    const merchantName = t.merchant || t.description || "Unknown";
    const matchesSearch = merchantName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = filterCategory === "all" || t.category === filterCategory;
    const matchesType = filterType === "all" || t.type === filterType;
    return matchesSearch && matchesCategory && matchesType;
  });

  // Reset page when filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, filterCategory, filterType, pageSize]);

  // Pagination slicing
  const totalPages = Math.max(Math.ceil(filteredTransactions.length / pageSize), 1);
  const paginatedTransactions = filteredTransactions.slice(
    (currentPage - 1) * pageSize,
    currentPage * pageSize
  );

  const totalExpenses = filteredTransactions
    .filter((t) => t.type === "expense")
    .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

  const totalIncome = filteredTransactions
    .filter((t) => t.type === "income")
    .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

  const handleExportCSV = () => {
    try {
      exportTransactionsToCSV(filteredTransactions, `transactions_${new Date().toISOString().slice(0, 10)}.csv`);
      toast.success("CSV export downloaded");
    } catch (err: any) {
      toast.error(err.message || "Failed to export CSV");
    }
  };

  const handleExportPDF = () => {
    try {
      exportFinancialReportPDF(filteredTransactions, {
        totalIncome,
        totalExpense: totalExpenses,
        netSavings: totalIncome - totalExpenses,
        savingsRate: totalIncome > 0 ? Math.round(((totalIncome - totalExpenses) / totalIncome) * 100) : 0,
      });
      toast.success("PDF report generated");
    } catch (err: any) {
      toast.error(err.message || "Failed to generate PDF");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl sm:text-3xl font-bold" style={{ color: "#e8edf5" }}>
              Transactions
            </h1>
            {roleMeta && (
              <span
                className="flex items-center gap-1 text-xs px-2.5 py-1 rounded-full font-medium"
                style={{ background: `${roleMeta.color}18`, color: roleMeta.color }}
              >
                <roleMeta.icon className="w-3.5 h-3.5" />
                {roleMeta.label}
              </span>
            )}
          </div>
          <p className="text-sm mt-1" style={{ color: "#6b7ca0" }}>
            Track, filter, export and manage your cash flow history
          </p>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {/* Export CSV */}
          <button
            onClick={handleExportCSV}
            disabled={filteredTransactions.length === 0}
            className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer disabled:opacity-50"
            style={{
              background: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.1)",
              color: "#e8edf5",
            }}
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-400" />
            <span>CSV</span>
          </button>

          {/* Export PDF */}
          <button
            onClick={handleExportPDF}
            disabled={filteredTransactions.length === 0}
            className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer disabled:opacity-50"
            style={{
              background: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.1)",
              color: "#e8edf5",
            }}
          >
            <Download className="w-4 h-4 text-blue-400" />
            <span>PDF Report</span>
          </button>

          {/* Add Transaction Dialog */}
          <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
            <DialogTrigger asChild>
              <button
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all cursor-pointer shadow-lg"
                style={{
                  background: "linear-gradient(135deg, #3b82f6, #6366f1)",
                  color: "#ffffff",
                  boxShadow: "0 0 20px rgba(59,130,246,0.3)",
                }}
              >
                <Plus className="w-4 h-4" />
                <span>Add Transaction</span>
              </button>
            </DialogTrigger>
            <DialogContent
              className="sm:max-w-[480px]"
              style={{
                background: "#0e1423",
                border: "1px solid rgba(255,255,255,0.1)",
                color: "#e8edf5",
              }}
            >
              <DialogHeader>
                <DialogTitle className="text-lg font-bold">Record Transaction</DialogTitle>
                <DialogDescription style={{ color: "#6b7ca0" }}>
                  Enter the transaction details below.
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4 py-3">
                {/* Type Selection */}
                <div>
                  <Label className="text-xs text-gray-400 mb-1.5 block">Transaction Type</Label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setNewTransaction({ ...newTransaction, type: "expense" })}
                      className={`py-2 px-3 rounded-lg text-xs font-bold transition-all ${
                        newTransaction.type === "expense"
                          ? "bg-red-500/20 text-red-400 border border-red-500/40"
                          : "bg-white/5 text-gray-400 border border-white/5"
                      }`}
                    >
                      Expense
                    </button>
                    <button
                      type="button"
                      onClick={() => setNewTransaction({ ...newTransaction, type: "income" })}
                      className={`py-2 px-3 rounded-lg text-xs font-bold transition-all ${
                        newTransaction.type === "income"
                          ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/40"
                          : "bg-white/5 text-gray-400 border border-white/5"
                      }`}
                    >
                      Income
                    </button>
                  </div>
                </div>

                {/* Merchant */}
                <div>
                  <Label htmlFor="merchant" className="text-xs text-gray-400 mb-1 block">
                    Merchant / Description <span className="text-red-400">*</span>
                  </Label>
                  <Input
                    id="merchant"
                    placeholder="e.g. Starbucks, Salary, Amazon"
                    value={newTransaction.merchant}
                    onChange={(e) => {
                      setNewTransaction({ ...newTransaction, merchant: e.target.value });
                      if (formErrors.merchant) setFormErrors({ ...formErrors, merchant: "" });
                    }}
                    className={formErrors.merchant ? "border-red-500" : ""}
                    style={{ background: "rgba(255,255,255,0.05)", borderColor: formErrors.merchant ? "#ef4444" : "rgba(255,255,255,0.1)" }}
                  />
                  {formErrors.merchant && (
                    <p className="text-xs text-red-400 mt-1">{formErrors.merchant}</p>
                  )}
                </div>

                {/* Amount & Date */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label htmlFor="amount" className="text-xs text-gray-400 mb-1 block">
                      Amount (₹) <span className="text-red-400">*</span>
                    </Label>
                    <Input
                      id="amount"
                      type="number"
                      step="0.01"
                      placeholder="0.00"
                      value={newTransaction.amount}
                      onChange={(e) => {
                        setNewTransaction({ ...newTransaction, amount: e.target.value });
                        if (formErrors.amount) setFormErrors({ ...formErrors, amount: "" });
                      }}
                      style={{ background: "rgba(255,255,255,0.05)", borderColor: formErrors.amount ? "#ef4444" : "rgba(255,255,255,0.1)" }}
                    />
                    {formErrors.amount && (
                      <p className="text-xs text-red-400 mt-1">{formErrors.amount}</p>
                    )}
                  </div>
                  <div>
                    <Label htmlFor="date" className="text-xs text-gray-400 mb-1 block">
                      Date
                    </Label>
                    <Input
                      id="date"
                      type="date"
                      value={newTransaction.date}
                      onChange={(e) => setNewTransaction({ ...newTransaction, date: e.target.value })}
                      style={{ background: "rgba(255,255,255,0.05)", borderColor: "rgba(255,255,255,0.1)" }}
                    />
                  </div>
                </div>

                {/* Category & Payment Mode */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label className="text-xs text-gray-400 mb-1 block">
                      Category <span className="text-red-400">*</span>
                    </Label>
                    <Select
                      value={newTransaction.category}
                      onValueChange={(val) => {
                        setNewTransaction({ ...newTransaction, category: val });
                        if (formErrors.category) setFormErrors({ ...formErrors, category: "" });
                      }}
                    >
                      <SelectTrigger style={{ background: "rgba(255,255,255,0.05)", borderColor: formErrors.category ? "#ef4444" : "rgba(255,255,255,0.1)" }}>
                        <SelectValue placeholder="Select Category" />
                      </SelectTrigger>
                      <SelectContent style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
                        {activeCategories.map((cat) => (
                          <SelectItem key={cat.id} value={cat.id}>
                            {cat.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {formErrors.category && (
                      <p className="text-xs text-red-400 mt-1">{formErrors.category}</p>
                    )}
                  </div>
                  <div>
                    <Label className="text-xs text-gray-400 mb-1 block">
                      Payment Mode
                    </Label>
                    <Select
                      value={newTransaction.paymentMode}
                      onValueChange={(val) => setNewTransaction({ ...newTransaction, paymentMode: val })}
                    >
                      <SelectTrigger style={{ background: "rgba(255,255,255,0.05)", borderColor: "rgba(255,255,255,0.1)" }}>
                        <SelectValue placeholder="Payment Mode" />
                      </SelectTrigger>
                      <SelectContent style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
                        <SelectItem value="UPI">UPI</SelectItem>
                        <SelectItem value="Card">Card</SelectItem>
                        <SelectItem value="NetBanking">Net Banking</SelectItem>
                        <SelectItem value="Cash">Cash</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                {/* Recurring Schedule */}
                <div className="p-3 rounded-xl border border-white/10 bg-white/5 space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Repeat className="w-4 h-4 text-indigo-400" />
                      <div>
                        <p className="text-xs font-semibold text-white">Recurring Transaction</p>
                        <p className="text-[10px] text-gray-400">Auto-schedules next occurrence</p>
                      </div>
                    </div>
                    <Switch
                      checked={newTransaction.isRecurring}
                      onCheckedChange={(checked) => setNewTransaction({ ...newTransaction, isRecurring: checked })}
                    />
                  </div>
                  {newTransaction.isRecurring && (
                    <div className="pt-2 border-t border-white/5 flex items-center justify-between gap-3">
                      <Label className="text-xs text-gray-400">Frequency</Label>
                      <Select
                        value={newTransaction.recurringPeriod}
                        onValueChange={(val) => setNewTransaction({ ...newTransaction, recurringPeriod: val })}
                      >
                        <SelectTrigger className="w-32 h-8 text-xs" style={{ background: "rgba(255,255,255,0.08)" }}>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
                          <SelectItem value="weekly">Weekly</SelectItem>
                          <SelectItem value="monthly">Monthly</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  )}
                </div>
              </div>

              <DialogFooter className="gap-2">
                <button
                  type="button"
                  onClick={() => setIsAddDialogOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold bg-white/5 hover:bg-white/10 text-gray-300"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={submitting}
                  onClick={handleAddTransaction}
                  className="px-4 py-2 rounded-xl text-xs font-semibold bg-blue-600 hover:bg-blue-500 text-white disabled:opacity-50"
                >
                  {submitting ? "Saving..." : "Save Transaction"}
                </button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="rounded-2xl p-4" style={glassCard}>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Search by merchant or description..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9"
              style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", color: "#e8edf5" }}
            />
          </div>
          <Select value={filterCategory} onValueChange={setFilterCategory}>
            <SelectTrigger style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", color: "#e8edf5" }}>
              <Filter className="w-4 h-4 mr-2 text-gray-400" />
              <SelectValue placeholder="Category" />
            </SelectTrigger>
            <SelectContent style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
              <SelectItem value="all">All Categories</SelectItem>
              {activeCategories.map((cat) => (
                <SelectItem key={cat.id} value={cat.id}>{cat.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={filterType} onValueChange={setFilterType}>
            <SelectTrigger style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.08)", color: "#e8edf5" }}>
              <Filter className="w-4 h-4 mr-2 text-gray-400" />
              <SelectValue placeholder="Type" />
            </SelectTrigger>
            <SelectContent style={{ background: "#0e1423", border: "1px solid rgba(255,255,255,0.1)" }}>
              <SelectItem value="all">All Types</SelectItem>
              <SelectItem value="expense">Expense Only</SelectItem>
              <SelectItem value="income">Income Only</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Summary Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[
          { label: "Total Filtered Records", value: filteredTransactions.length, color: "#e8edf5" },
          { label: "Total Expenses", value: `₹${totalExpenses.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, color: "#ef4444" },
          { label: "Total Income", value: `₹${totalIncome.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, color: "#10b981" },
        ].map((s) => (
          <div key={s.label} className="rounded-2xl p-4" style={glassCard}>
            <p className="text-xs mb-1" style={{ color: "#6b7ca0" }}>{s.label}</p>
            <p className="text-xl font-bold font-mono" style={{ color: s.color }}>
              {s.value}
            </p>
          </div>
        ))}
      </div>

      {/* Transactions Table & List */}
      <div className="rounded-2xl p-6" style={glassCard}>
        {loading ? (
          /* Loading Skeleton */
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex items-center justify-between p-4 rounded-xl bg-white/5 animate-pulse">
                <div className="flex items-center gap-4 flex-1">
                  <div className="w-10 h-10 rounded-xl bg-white/10" />
                  <div className="space-y-2 flex-1 max-w-sm">
                    <div className="h-4 bg-white/10 rounded w-3/4" />
                    <div className="h-3 bg-white/5 rounded w-1/2" />
                  </div>
                </div>
                <div className="h-6 w-20 bg-white/10 rounded" />
              </div>
            ))}
          </div>
        ) : filteredTransactions.length === 0 ? (
          /* Empty State */
          <div className="text-center py-16 space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center mx-auto text-gray-400">
              <Receipt className="w-7 h-7" />
            </div>
            <p className="text-base font-semibold" style={{ color: "#e8edf5" }}>
              {transactions.length === 0 ? "No transactions recorded yet" : "No matching transactions found"}
            </p>
            <p className="text-xs max-w-sm mx-auto" style={{ color: "#6b7ca0" }}>
              {transactions.length === 0
                ? "Start adding your daily expenses, salary, or scan a receipt to unlock real-time financial tracking."
                : "Try clearing search filters or checking for typos."}
            </p>
            {transactions.length === 0 ? (
              <button
                onClick={() => setIsAddDialogOpen(true)}
                className="mt-2 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold bg-blue-600 text-white hover:bg-blue-500 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                Add First Transaction
              </button>
            ) : (
              <button
                onClick={() => {
                  setSearchQuery("");
                  setFilterCategory("all");
                  setFilterType("all");
                }}
                className="mt-2 px-3 py-1.5 rounded-lg text-xs bg-white/10 hover:bg-white/15 text-gray-300 cursor-pointer"
              >
                Reset Filters
              </button>
            )}
          </div>
        ) : (
          /* Transactions List */
          <div className="space-y-3">
            {paginatedTransactions.map((transaction) => {
              const catObj = activeCategories.find((c) => c.id === transaction.category);
              const catName = catObj?.name || transaction.category || "General";
              const catColor = catObj?.color || "#3b82f6";
              const isIncome = transaction.type === "income";

              // Risk evaluation
              const riskAnalysis = calculateFraudScore(transaction, transactions);
              const isRisk = riskAnalysis.isFlagged || (transaction.risk_score || 0) >= 0.5;

              return (
                <div
                  key={transaction.id}
                  className="flex items-center justify-between p-4 rounded-xl transition-all hover:bg-white/[0.04]"
                  style={{
                    background: isRisk ? "rgba(239,68,68,0.05)" : "rgba(255,255,255,0.02)",
                    border: isRisk ? "1px solid rgba(239,68,68,0.25)" : "1px solid rgba(255,255,255,0.04)",
                  }}
                >
                  <div className="flex items-center gap-4 flex-1 min-w-0">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{
                        background: isIncome ? "rgba(16,185,129,0.12)" : "rgba(239,68,68,0.08)",
                      }}
                    >
                      {isIncome ? (
                        <ArrowUpRight className="w-5 h-5 text-emerald-400" />
                      ) : (
                        <ArrowDownRight className="w-5 h-5 text-red-400" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5 flex-wrap">
                        <p className="font-medium truncate text-sm" style={{ color: "#e8edf5" }}>
                          {transaction.merchant || transaction.description || "Transaction"}
                        </p>
                        {(transaction.isRecurring || transaction.is_recurring) && (
                          <span
                            className="flex items-center gap-1 text-[10px] px-2 py-0.5 rounded-full flex-shrink-0 font-medium bg-indigo-500/20 text-indigo-300 border border-indigo-500/30"
                          >
                            <Repeat className="w-3 h-3" />
                            {transaction.recurringPeriod || transaction.recurring_period || 'Recurring'}
                          </span>
                        )}
                        {isRisk && (
                          <span
                            className="flex items-center gap-1 text-[10px] px-2 py-0.5 rounded-full flex-shrink-0 font-semibold"
                            style={{ background: "rgba(239,68,68,0.15)", color: "#ef4444" }}
                          >
                            <AlertTriangle className="w-3 h-3" /> Flagged ({Math.round((transaction.risk_score || riskAnalysis.riskScore) * 100)}%)
                          </span>
                        )}
                      </div>
                      <div className="flex flex-wrap gap-2 text-xs" style={{ color: "#6b7ca0" }}>
                        <span className="flex items-center gap-1">
                          <span className="w-2 h-2 rounded-full inline-block" style={{ background: catColor }} />
                          {catName}
                        </span>
                        <span>•</span>
                        <span>{transaction.payment_mode || transaction.paymentMode || "Cash"}</span>
                        <span>•</span>
                        <span>
                          {new Date(transaction.date).toLocaleDateString("en-IN", {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 flex-shrink-0">
                    <div className="text-right">
                      <p
                        className="font-bold font-mono text-sm sm:text-base"
                        style={{
                          color: isIncome ? "#10b981" : "#e8edf5",
                        }}
                      >
                        {isIncome ? "+" : "-"}₹{Number(transaction.amount).toFixed(2)}
                      </p>
                    </div>
                    <button
                      onClick={() => handleDeleteTransaction(transaction.id)}
                      className="w-8 h-8 rounded-lg flex items-center justify-center transition-all hover:bg-red-500/20 cursor-pointer"
                      style={{ background: "rgba(239,68,68,0.08)" }}
                      title="Delete Transaction"
                    >
                      <Trash2 className="w-3.5 h-3.5 text-red-400" />
                    </button>
                  </div>
                </div>
              );
            })}

            {/* Pagination Controls */}
            {filteredTransactions.length > 0 && (
              <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4 border-t border-white/5">
                <div className="flex items-center gap-2 text-xs text-gray-400">
                  <span>Showing {(currentPage - 1) * pageSize + 1} - {Math.min(currentPage * pageSize, filteredTransactions.length)} of {filteredTransactions.length}</span>
                  <span>•</span>
                  <div className="flex items-center gap-1">
                    <span>Per page:</span>
                    <select
                      value={pageSize}
                      onChange={(e) => setPageSize(Number(e.target.value))}
                      className="bg-white/5 border border-white/10 rounded px-1.5 py-0.5 text-xs text-gray-300"
                    >
                      {ITEMS_PER_PAGE_OPTIONS.map((opt) => (
                        <option key={opt} value={opt} className="bg-slate-900 text-white">
                          {opt}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="flex items-center gap-1">
                  <button
                    onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
                    disabled={currentPage === 1}
                    className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-gray-300 disabled:opacity-30 cursor-pointer"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>

                  <span className="px-3 py-1 text-xs text-gray-300">
                    Page {currentPage} of {totalPages}
                  </span>

                  <button
                    onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
                    disabled={currentPage >= totalPages}
                    className="p-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-gray-300 disabled:opacity-30 cursor-pointer"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
