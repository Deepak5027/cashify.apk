import React, { useState, useEffect, useCallback } from "react";
import { FileText, Receipt, QrCode, Plus, Printer, CheckCircle2, Trash2, Clock } from "lucide-react";
import { invoiceAPI, Invoice as InvoiceType, Transaction, transactionsAPI } from "../../services/api";
import { toast } from "sonner";

export default function StatementsInvoicing() {
  const [activeTab, setActiveTab] = useState<"statements" | "reimbursement" | "invoices">("statements");
  const [invoices, setInvoices] = useState<InvoiceType[]>([]);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);

  // Statement Filters
  const [startDate, setStartDate] = useState(
    new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split("T")[0]
  );
  const [endDate, setEndDate] = useState(new Date().toISOString().split("T")[0]);

  // Reimbursement States
  const [selectedTxIds, setSelectedTxIds] = useState<Set<number | string>>(new Set());
  const [employeeName, setEmployeeName] = useState("Deepak R");
  const [purpose, setPurpose] = useState("Client Onsite Meeting & Operations Travel");
  const [department, setDepartment] = useState("Engineering & Tech");

  // Invoicing Modal States
  const [isInvoiceModalOpen, setIsInvoiceModalOpen] = useState(false);
  const [selectedQrInvoice, setSelectedQrInvoice] = useState<InvoiceType | null>(null);
  const [clientName, setClientName] = useState("");
  const [upiId, setUpiId] = useState("deepak@okaxis");
  const [serviceDesc, setServiceDesc] = useState("Consulting & Development Services");
  const [amount, setAmount] = useState("15000");
  const [taxRate, setTaxRate] = useState("18");

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [invRes, txRes] = await Promise.all([
        invoiceAPI.getAll(),
        transactionsAPI.getAll(),
      ]);

      if (invRes && invRes.data) {
        const cleanInvoices = (Array.isArray(invRes.data) ? invRes.data : []).map((inv) => ({
          ...inv,
          invoiceNo: inv.invoiceNo || `INV-${new Date().getFullYear()}-0001`,
          clientName: inv.clientName || "Client",
          status: String(inv.status || "unpaid").toLowerCase(),
          taxRate: Number(inv.taxRate) || 18,
          totalAmount: Number(inv.totalAmount) || 0,
          upiId: inv.upiId || "deepak@okaxis",
          items: Array.isArray(inv.items) ? inv.items : [],
        }));
        setInvoices(cleanInvoices);
      }

      if (txRes && (txRes.data || Array.isArray(txRes))) {
        const rawList = Array.isArray(txRes) ? txRes : (txRes.data || []);
        const cleanTxs = rawList.map((t: any) => ({
          ...t,
          type: String(t.type || "expense").toLowerCase(),
          amount: Number(t.amount) || 0,
          category: t.category || "General",
          description: t.description || "Transaction",
          date: t.date || new Date().toISOString(),
        }));
        setTransactions(cleanTxs);
      }
    } catch (err) {
      console.error("Statements & Invoicing load error:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Filtered transactions for statement
  const filteredTxs = transactions.filter((t) => {
    const d = t.date ? String(t.date).split("T")[0] : "";
    return d >= startDate && d <= endDate;
  });

  const totalIncome = filteredTxs
    .filter((t) => String(t.type || "expense").toLowerCase() === "income")
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);

  const totalExpense = filteredTxs
    .filter((t) => String(t.type || "expense").toLowerCase() === "expense")
    .reduce((sum, t) => sum + Number(t.amount || 0), 0);

  const netBalance = totalIncome - totalExpense;

  // Category breakdown for statement
  const categoryMap = filteredTxs
    .filter((t) => String(t.type || "expense").toLowerCase() === "expense")
    .reduce((acc, t) => {
      const cat = t.category || "General";
      acc[cat] = (acc[cat] || 0) + Number(t.amount || 0);
      return acc;
    }, {} as Record<string, number>);

  // Reimbursement expenses
  const expenseTxs = transactions.filter((t) => String(t.type || "expense").toLowerCase() === "expense");
  const claimTxs = expenseTxs.filter((t) => selectedTxIds.has(t.id));
  const claimTotal = claimTxs.reduce((sum, t) => sum + Number(t.amount || 0), 0);

  const toggleSelectTx = (id: number | string) => {
    const next = new Set(selectedTxIds);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    setSelectedTxIds(next);
  };

  // Invoicing calculations
  const totalInvoiced = invoices.reduce((sum, inv) => sum + Number(inv.totalAmount || 0), 0);
  const totalCollected = invoices
    .filter((inv) => String(inv.status || "unpaid").toLowerCase() === "paid")
    .reduce((sum, inv) => sum + Number(inv.totalAmount || 0), 0);
  const totalPending = invoices
    .filter((inv) => String(inv.status || "unpaid").toLowerCase() !== "paid")
    .reduce((sum, inv) => sum + Number(inv.totalAmount || 0), 0);

  const handleCreateInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientName.trim() || !amount) return;

    try {
      const amt = parseFloat(amount) || 0;
      const tax = parseFloat(taxRate) || 0;
      const res = await invoiceAPI.create({
        clientName: clientName.trim(),
        upiId: upiId.trim() || "deepak@okaxis",
        taxRate: tax,
        items: [
          {
            description: serviceDesc.trim() || "Services",
            quantity: 1,
            unitPrice: amt,
          },
        ],
      });

      if (res && res.data) {
        setInvoices((prev) => [res.data, ...prev]);
        toast.success(`Invoice created in database for ${clientName}`);
        setIsInvoiceModalOpen(false);
        setClientName("");
      }
    } catch (err) {
      toast.error("Failed to create invoice");
    }
  };

  const handleToggleInvoiceStatus = async (id: number, currentStatus?: string) => {
    const current = String(currentStatus || "unpaid").toLowerCase();
    const newStatus = current === "paid" ? "unpaid" : "paid";
    try {
      await invoiceAPI.update(id, { status: newStatus });
      setInvoices((prev) =>
        prev.map((inv) => (inv.id === id ? { ...inv, status: newStatus } : inv))
      );
      toast.success(`Invoice marked as ${newStatus}`);
    } catch (err) {
      toast.error("Failed to update invoice status");
    }
  };

  const handleDeleteInvoice = async (id: number) => {
    try {
      await invoiceAPI.delete(id);
      setInvoices((prev) => prev.filter((inv) => inv.id !== id));
      toast.success("Invoice deleted");
    } catch (err) {
      toast.error("Failed to delete invoice");
    }
  };

  const printDocument = () => {
    window.print();
  };

  const generateUpiUrl = (inv: InvoiceType) => {
    const amt = Number(inv.totalAmount || 0).toFixed(2);
    const cleanUpi = encodeURIComponent(inv.upiId || "deepak@okaxis");
    const cleanName = encodeURIComponent(inv.clientName || "Client");
    const note = encodeURIComponent(`Payment for ${inv.invoiceNo}`);
    return `upi://pay?pa=${cleanUpi}&pn=${cleanName}&am=${amt}&cu=INR&tn=${note}`;
  };

  return (
    <div className="p-4 lg:p-8 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold tracking-tight text-white flex items-center gap-3">
            <div className="p-2 rounded-xl bg-gradient-to-tr from-amber-500 to-yellow-600 text-white shadow-lg">
              <FileText className="w-6 h-6" />
            </div>
            Statements & Invoicing Suite
          </h1>
          <p className="text-slate-400 text-sm mt-1">
            Generate branded PDF statements, manager reimbursement slips, and client invoices with instant scan-to-pay QR codes.
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center p-1 rounded-2xl bg-slate-900 border border-slate-800">
          <button
            onClick={() => setActiveTab("statements")}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
              activeTab === "statements" ? "bg-indigo-600 text-white shadow" : "text-slate-400 hover:text-white"
            }`}
          >
            <FileText className="w-4 h-4" /> Statements
          </button>
          <button
            onClick={() => setActiveTab("reimbursement")}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
              activeTab === "reimbursement" ? "bg-indigo-600 text-white shadow" : "text-slate-400 hover:text-white"
            }`}
          >
            <Receipt className="w-4 h-4" /> Reimburse
          </button>
          <button
            onClick={() => setActiveTab("invoices")}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
              activeTab === "invoices" ? "bg-indigo-600 text-white shadow" : "text-slate-400 hover:text-white"
            }`}
          >
            <QrCode className="w-4 h-4" /> Invoices & QR
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: FINANCIAL STATEMENTS */}
      {/* ========================================================================= */}
      {activeTab === "statements" && (
        <div className="space-y-6">
          {/* Controls Bar */}
          <div className="p-5 rounded-3xl bg-slate-900/80 border border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3 w-full sm:w-auto">
              <span className="text-xs font-bold text-slate-400 uppercase">Period:</span>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-medium focus:outline-none focus:border-indigo-500"
              />
              <span className="text-slate-500 text-xs">to</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-medium focus:outline-none focus:border-indigo-500"
              />
            </div>

            <button
              onClick={printDocument}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-lg transition"
            >
              <Printer className="w-4 h-4" /> Print / Save as PDF
            </button>
          </div>

          {/* Statement Printable Document Preview */}
          <div className="p-6 lg:p-8 rounded-3xl bg-slate-900/90 border border-slate-800 space-y-6">
            {/* Header */}
            <div className="flex justify-between items-start border-b border-slate-800 pb-6">
              <div>
                <div className="text-2xl font-black text-white tracking-wider">AiFinancify</div>
                <div className="text-xs font-semibold text-indigo-400">Official Financial Statement & Tax Summary</div>
              </div>
              <div className="text-right text-xs text-slate-400 space-y-0.5">
                <div>Period: <strong className="text-white">{startDate}</strong> to <strong className="text-white">{endDate}</strong></div>
                <div>Generated: <strong className="text-white">{new Date().toLocaleDateString()}</strong></div>
              </div>
            </div>

            {/* KPI Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800">
                <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Income</div>
                <div className="text-xl font-bold text-emerald-400 mt-1">₹{totalIncome.toLocaleString("en-IN")}</div>
              </div>
              <div className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800">
                <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Expenses</div>
                <div className="text-xl font-bold text-red-400 mt-1">₹{totalExpense.toLocaleString("en-IN")}</div>
              </div>
              <div className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800">
                <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Net Balance</div>
                <div className="text-xl font-bold text-indigo-400 mt-1">₹{netBalance.toLocaleString("en-IN")}</div>
              </div>
            </div>

            {/* Category Share Breakdown */}
            <div className="space-y-3">
              <h3 className="text-sm font-bold uppercase tracking-wider text-slate-300">Spending Breakdown by Category</h3>
              <div className="rounded-2xl border border-slate-800 overflow-hidden">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-950/80 text-slate-400 uppercase font-semibold border-b border-slate-800">
                    <tr>
                      <th className="p-3">Category</th>
                      <th className="p-3 text-right">Amount</th>
                      <th className="p-3 text-right">Share (%)</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {Object.entries(categoryMap).length === 0 ? (
                      <tr>
                        <td colSpan={3} className="p-4 text-center text-slate-500">No expenses in this period</td>
                      </tr>
                    ) : (
                      Object.entries(categoryMap).map(([cat, amt]) => {
                        const pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0;
                        return (
                          <tr key={cat} className="hover:bg-slate-800/40">
                            <td className="p-3 font-medium text-white">{cat}</td>
                            <td className="p-3 text-right font-mono font-bold text-slate-200">₹{amt.toLocaleString("en-IN")}</td>
                            <td className="p-3 text-right text-slate-400">{pct.toFixed(1)}%</td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Transaction Ledger */}
            <div className="space-y-3">
              <h3 className="text-sm font-bold uppercase tracking-wider text-slate-300">Transaction Audit Ledger ({filteredTxs.length} entries)</h3>
              <div className="rounded-2xl border border-slate-800 overflow-hidden max-h-80 overflow-y-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-950/80 text-slate-400 uppercase font-semibold border-b border-slate-800 sticky top-0">
                    <tr>
                      <th className="p-3">Date</th>
                      <th className="p-3">Description</th>
                      <th className="p-3">Category</th>
                      <th className="p-3">Mode</th>
                      <th className="p-3 text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {filteredTxs.map((t, idx) => {
                      const isInc = String(t.type || "expense").toLowerCase() === "income";
                      return (
                        <tr key={idx} className="hover:bg-slate-800/40">
                          <td className="p-3 text-slate-400 font-mono">{t.date ? String(t.date).split("T")[0] : ""}</td>
                          <td className="p-3 font-medium text-white">{t.description || "Transaction"}</td>
                          <td className="p-3 text-slate-300">{t.category || "General"}</td>
                          <td className="p-3 text-slate-400">{t.paymentMode || t.payment_mode || "Other"}</td>
                          <td className={`p-3 text-right font-mono font-bold ${isInc ? "text-emerald-400" : "text-red-400"}`}>
                            {isInc ? "+" : "-"}₹{Number(t.amount || 0).toLocaleString("en-IN")}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: EXPENSE REIMBURSEMENT SLIPS */}
      {/* ========================================================================= */}
      {activeTab === "reimbursement" && (
        <div className="space-y-6">
          {/* Metadata inputs */}
          <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 space-y-4">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider">Claim Information</h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Employee / Claimant Name</label>
                <input
                  type="text"
                  value={employeeName}
                  onChange={(e) => setEmployeeName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Department / Project Code</label>
                <input
                  type="text"
                  value={department}
                  onChange={(e) => setDepartment(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Business Purpose</label>
                <input
                  type="text"
                  value={purpose}
                  onChange={(e) => setPurpose(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs"
                />
              </div>
            </div>
          </div>

          {/* Claim Hero Banner */}
          <div className="p-6 rounded-3xl bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 border border-blue-500/40 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <div className="text-xs font-bold uppercase tracking-wider text-blue-300">Total Claim Amount</div>
              <div className="text-3xl font-black text-white mt-1">₹{claimTotal.toLocaleString("en-IN")}</div>
              <p className="text-xs text-blue-200 mt-1">{selectedTxIds.size} expense receipt(s) bundled in this claim</p>
            </div>

            <button
              disabled={selectedTxIds.size === 0}
              onClick={printDocument}
              className="flex items-center gap-2 px-5 py-3 rounded-2xl bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 text-slate-950 text-sm font-extrabold shadow-lg transition"
            >
              <Printer className="w-4 h-4" /> Print Manager Reimbursement Slip
            </button>
          </div>

          {/* Selectable Expenses Table */}
          <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 space-y-4">
            <h3 className="text-sm font-bold text-white uppercase tracking-wider">Select Expenses to Include in Claim</h3>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {expenseTxs.map((t) => {
                const isSelected = selectedTxIds.has(t.id);
                return (
                  <div
                    key={t.id}
                    onClick={() => toggleSelectTx(t.id)}
                    className={`p-3.5 rounded-2xl border cursor-pointer flex items-center justify-between transition ${
                      isSelected ? "bg-indigo-950/40 border-indigo-500" : "bg-slate-950/60 border-slate-800 hover:border-slate-700"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => toggleSelectTx(t.id)}
                        className="w-4 h-4 rounded text-indigo-600 focus:ring-0"
                      />
                      <div>
                        <div className="text-sm font-bold text-white">{t.description || "Expense"}</div>
                        <div className="text-xs text-slate-400">{t.category} • {t.date ? String(t.date).split("T")[0] : ""}</div>
                      </div>
                    </div>
                    <div className="font-mono font-bold text-white text-base">₹{Number(t.amount || 0).toLocaleString("en-IN")}</div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 3: CLIENT INVOICES & UPI QR CODE */}
      {/* ========================================================================= */}
      {activeTab === "invoices" && (
        <div className="space-y-6">
          {/* KPI Banner */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="p-5 rounded-3xl bg-slate-900/80 border border-slate-800">
              <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Invoiced</div>
              <div className="text-2xl font-black text-white mt-1">₹{totalInvoiced.toLocaleString("en-IN")}</div>
            </div>
            <div className="p-5 rounded-3xl bg-slate-900/80 border border-slate-800">
              <div className="text-[10px] font-bold uppercase tracking-wider text-emerald-400">Collected Revenue</div>
              <div className="text-2xl font-black text-emerald-400 mt-1">₹{totalCollected.toLocaleString("en-IN")}</div>
            </div>
            <div className="p-5 rounded-3xl bg-slate-900/80 border border-slate-800">
              <div className="text-[10px] font-bold uppercase tracking-wider text-amber-400">Pending Receivables</div>
              <div className="text-2xl font-black text-amber-400 mt-1">₹{totalPending.toLocaleString("en-IN")}</div>
            </div>
          </div>

          <button
            onClick={() => setIsInvoiceModalOpen(true)}
            className="w-full py-3.5 rounded-2xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold flex items-center justify-center gap-2 shadow-lg transition"
          >
            <Plus className="w-5 h-5" /> Create Client Invoice with UPI QR Code
          </button>

          {/* Invoices List */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-white">Client Invoices</h3>
              <span className="text-xs text-slate-400">{invoices.length} Total</span>
            </div>

            {invoices.length === 0 ? (
              <div className="p-12 text-center rounded-3xl bg-slate-900/60 border border-slate-800 space-y-3">
                <FileText className="w-12 h-12 text-slate-600 mx-auto" />
                <h4 className="text-base font-bold text-white">No invoices generated yet</h4>
                <p className="text-xs text-slate-400 max-w-sm mx-auto">
                  Click &quot;Create Client Invoice&quot; to generate an itemized bill with instant UPI QR code.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {invoices.map((inv) => {
                  const statusStr = String(inv.status || "unpaid").toLowerCase();
                  const isPaid = statusStr === "paid";
                  return (
                    <div
                      key={inv.id}
                      className={`p-5 rounded-3xl bg-slate-900/80 border transition-all ${
                        isPaid ? "border-emerald-500/30" : "border-slate-800 hover:border-slate-700"
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <div className="text-xs font-bold text-indigo-400 tracking-wider">{inv.invoiceNo || "INV-001"}</div>
                          <h4 className="text-base font-bold text-white mt-0.5">{inv.clientName || "Client"}</h4>
                        </div>
                        <span
                          className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full uppercase ${
                            isPaid ? "bg-emerald-500/20 text-emerald-400" : "bg-amber-500/20 text-amber-400"
                          }`}
                        >
                          {statusStr}
                        </span>
                      </div>

                      <div className="my-3 text-xs text-slate-300">
                        Amount: <strong className="text-white text-sm">₹{Number(inv.totalAmount || 0).toLocaleString("en-IN")}</strong> (incl. {inv.taxRate || 18}% GST)
                      </div>

                      <div className="pt-3 border-t border-slate-800 flex items-center justify-between">
                        <button
                          onClick={() => setSelectedQrInvoice(inv)}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-indigo-500/40 bg-indigo-500/10 text-indigo-400 text-xs font-bold hover:bg-indigo-500/20 transition"
                        >
                          <QrCode className="w-3.5 h-3.5" /> Scan-to-Pay QR
                        </button>

                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => inv.id && handleToggleInvoiceStatus(inv.id, inv.status)}
                            className={`p-1.5 rounded-lg transition ${
                              isPaid ? "text-emerald-400 hover:bg-emerald-500/10" : "text-slate-400 hover:text-emerald-400"
                            }`}
                            title={isPaid ? "Mark Unpaid" : "Mark Paid"}
                          >
                            <CheckCircle2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => inv.id && handleDeleteInvoice(inv.id)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* QR Code Scan-to-Pay Modal */}
      {selectedQrInvoice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4 shadow-2xl text-center">
            <h3 className="text-lg font-bold text-white">{selectedQrInvoice.invoiceNo}</h3>
            <div className="text-2xl font-black text-emerald-400">
              ₹{Number(selectedQrInvoice.totalAmount || 0).toLocaleString("en-IN")}
            </div>
            <p className="text-xs text-slate-400">Payable to: <strong className="text-white">{selectedQrInvoice.upiId || "deepak@okaxis"}</strong></p>

            {/* Visual QR Code Container */}
            <div className="p-4 rounded-2xl bg-white mx-auto w-52 h-52 flex flex-col items-center justify-center shadow-lg border border-slate-300">
              <img
                src={`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(
                  generateUpiUrl(selectedQrInvoice)
                )}`}
                alt="UPI QR Code"
                className="w-44 h-44 object-contain"
              />
            </div>

            <p className="text-[11px] text-slate-400">
              Scan with Google Pay, PhonePe, Paytm, or BHIM UPI to complete payment.
            </p>

            <button
              onClick={() => setSelectedQrInvoice(null)}
              className="w-full py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-bold transition"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Create Invoice Modal */}
      {isInvoiceModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4 shadow-2xl">
            <h3 className="text-lg font-bold text-white">Create Client Invoice</h3>
            <p className="text-xs text-slate-400">Generate itemized invoice with embedded payment QR code.</p>

            <form onSubmit={handleCreateInvoice} className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Client / Company Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Acme Innovations Corp"
                  value={clientName}
                  onChange={(e) => setClientName(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Receiving UPI ID</label>
                <input
                  type="text"
                  required
                  value={upiId}
                  onChange={(e) => setUpiId(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-sm font-mono focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Service Description</label>
                <input
                  type="text"
                  required
                  value={serviceDesc}
                  onChange={(e) => setServiceDesc(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-sm focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Amount (₹)</label>
                  <input
                    type="number"
                    required
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-sm font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">GST / Tax %</label>
                  <input
                    type="number"
                    value={taxRate}
                    onChange={(e) => setTaxRate(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-sm font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="flex gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setIsInvoiceModalOpen(false)}
                  className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-sm font-medium hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-bold shadow-lg"
                >
                  Generate Invoice
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
