import { useState, useRef } from "react";
import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Textarea } from "../components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select";
import {
  Smartphone,
  Sparkles,
  CheckCircle,
  Trash2,
  ArrowUpRight,
  ArrowDownRight,
  RefreshCw,
  Receipt,
  CheckSquare,
  Square,
  Upload,
  CreditCard,
  Building2,
  Hash,
  Filter,
} from "lucide-react";
import { toast } from "sonner";
import { transactionsAPI } from "../../services/api";
import { parseUpiMessages, ParsedUpiTransaction } from "../../utils/upiParser";
import { categories as defaultCategories } from "../data/mockData";
import { useNavigate } from "react-router";

export default function UpiImport() {
  const navigate = useNavigate();
  const [rawInput, setRawInput] = useState("");
  const [parsedItems, setParsedItems] = useState<ParsedUpiTransaction[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [importSuccess, setImportSuccess] = useState(false);
  const [importedCount, setImportedCount] = useState(0);
  const [filterType, setFilterType] = useState<"all" | "expense" | "income">("all");
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleParse = () => {
    if (!rawInput.trim()) {
      toast.error("Please paste SMS messages or upload a text file first");
      return;
    }

    const items = parseUpiMessages(rawInput);
    if (items.length === 0) {
      toast.error("No valid transaction details found in text. Check SMS format.");
      return;
    }

    setParsedItems(items);
    setImportSuccess(false);
    toast.success(`Extracted ${items.length} transaction${items.length > 1 ? "s" : ""}`);
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const text = await file.text();
      setRawInput(text);
      const items = parseUpiMessages(text);
      if (items.length > 0) {
        setParsedItems(items);
        setImportSuccess(false);
        toast.success(`Loaded '${file.name}' & extracted ${items.length} transactions`);
      } else {
        toast.warning("File loaded, but no bank SMS patterns were detected.");
      }
    } catch (err) {
      console.error("File upload error:", err);
      toast.error("Could not read uploaded text file");
    }
  };

  const handleLoadSample = () => {
    const sampleText = `Paid ₹450.00 to SWIGGY via UPI Ref 423456789012 from SBI A/c XX1234 on 24-08-2026.
Rs.1250.00 debited from HDFC A/C XX5678 to amazon@apl on 24-08-2026. UPI Ref 423456789013.
Received ₹2,500.00 from TechCorp Ltd on GPay to A/c XX9012. UPI Ref 423456789023 on 23-08-2026.
Paid ₹750 to Star Bazaar using PhonePe UPI Ref 423456789019 on 22-08-2026.`;
    setRawInput(sampleText);
    const items = parseUpiMessages(sampleText);
    setParsedItems(items);
    setImportSuccess(false);
    toast.info("Sample bank SMS loaded");
  };

  const handleToggleSelectAll = () => {
    const allSelected = parsedItems.every((item) => item.selected);
    setParsedItems((prev) => prev.map((item) => ({ ...item, selected: !allSelected })));
  };

  const handleToggleItem = (id: string) => {
    setParsedItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, selected: !item.selected } : item))
    );
  };

  const handleUpdateItem = (id: string, fields: Partial<ParsedUpiTransaction>) => {
    setParsedItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, ...fields } : item))
    );
  };

  const handleRemoveItem = (id: string) => {
    setParsedItems((prev) => prev.filter((item) => item.id !== id));
    toast.info("Transaction removed");
  };

  const handleBulkCategoryChange = (category: string) => {
    setParsedItems((prev) =>
      prev.map((item) => (item.selected ? { ...item, category } : item))
    );
    toast.info(`Updated category to '${category}'`);
  };

  const handleImportSelected = async () => {
    const selectedItems = parsedItems.filter((item) => item.selected);

    if (selectedItems.length === 0) {
      toast.error("Please select at least one transaction to save");
      return;
    }

    for (const item of selectedItems) {
      if (item.amount === '' || isNaN(Number(item.amount)) || Number(item.amount) <= 0) {
        toast.error(`Please enter a valid amount for '${item.merchant || "Transaction"}'`);
        return;
      }
    }

    setIsProcessing(true);
    let successCount = 0;

    try {
      for (const item of selectedItems) {
        const numAmount = typeof item.amount === 'number' ? item.amount : parseFloat(String(item.amount));
        const notesDetail = [
          item.upiRef ? `UPI Ref: ${item.upiRef}` : '',
          item.bankAcc ? `A/c: xx${item.bankAcc}` : '',
        ].filter(Boolean).join(' | ');

        await transactionsAPI.create({
          amount: numAmount,
          merchant: item.merchant || "UPI Transaction",
          description: item.merchant || "UPI Transaction",
          category: item.category || "shopping",
          type: item.type,
          paymentMode: "UPI",
          date: item.date || new Date().toISOString().split("T")[0],
          notes: notesDetail,
        });

        successCount++;
      }

      setImportedCount(successCount);
      setImportSuccess(true);
      setParsedItems([]);
      setRawInput("");
      toast.success(`Successfully saved ${successCount} transactions`);
    } catch (error: any) {
      console.error("UPI Import Error:", error);
      toast.error(error.message || "Failed to save transactions");
    } finally {
      setIsProcessing(false);
    }
  };

  const filteredItems = parsedItems.filter((i) => {
    if (filterType === "expense") return i.type === "expense";
    if (filterType === "income") return i.type === "income";
    return true;
  });

  const selectedCount = parsedItems.filter((i) => i.selected).length;
  const totalSelectedExpense = parsedItems
    .filter((i) => i.selected && i.type === "expense" && typeof i.amount === "number")
    .reduce((acc, i) => acc + (i.amount as number), 0);
  const totalSelectedIncome = parsedItems
    .filter((i) => i.selected && i.type === "income" && typeof i.amount === "number")
    .reduce((acc, i) => acc + (i.amount as number), 0);

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <input
        ref={fileInputRef}
        type="file"
        accept=".txt,.csv,.log"
        onChange={handleFileUpload}
        className="hidden"
      />

      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold flex items-center gap-2">
            <Smartphone className="w-8 h-8 text-blue-600" />
            UPI & Bank SMS Import
          </h1>
          <p className="text-gray-600 text-sm mt-1">
            Import transactions automatically from bank SMS notifications (GPay, PhonePe, Paytm, SBI, HDFC, ICICI, etc.)
          </p>
        </div>

        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => fileInputRef.current?.click()}
          >
            <Upload className="w-4 h-4 mr-2" />
            Upload SMS File
          </Button>
          <Button
            variant="ghost"
            onClick={handleLoadSample}
            className="text-xs text-blue-600"
          >
            Load Sample SMS
          </Button>
        </div>
      </div>

      {/* SMS Input Panel */}
      {!importSuccess && (
        <Card className="p-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <label className="font-semibold text-sm flex items-center gap-2">
                <Receipt className="w-4 h-4 text-blue-600" />
                Paste Bank SMS Notifications
              </label>
              <span className="text-xs text-gray-500">Supports GPay, PhonePe, Paytm, & Indian Banks</span>
            </div>

            <Textarea
              rows={5}
              value={rawInput}
              onChange={(e) => setRawInput(e.target.value)}
              placeholder="Paste SMS messages here e.g. 'Paid ₹450 to Swiggy via UPI from A/c XX1234 on 24 Aug...'"
              className="font-mono text-sm leading-relaxed"
            />

            <div className="flex items-center justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setRawInput("");
                  setParsedItems([]);
                }}
                disabled={!rawInput && parsedItems.length === 0}
              >
                Clear Input
              </Button>
              <Button onClick={handleParse}>
                <Sparkles className="w-4 h-4 mr-2" />
                Extract Transactions
              </Button>
            </div>
          </div>
        </Card>
      )}

      {/* Extracted Transactions List & Controls */}
      {parsedItems.length > 0 && !importSuccess && (
        <Card className="p-6 space-y-4">
          {/* Controls Bar */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b pb-4">
            <div>
              <h3 className="font-bold text-lg">Extracted Transactions</h3>
              <p className="text-sm text-gray-600">
                Review and edit extracted details before saving
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handleToggleSelectAll}
              >
                {parsedItems.every((i) => i.selected) ? (
                  <>
                    <Square className="w-4 h-4 mr-1 text-gray-400" /> Deselect All
                  </>
                ) : (
                  <>
                    <CheckSquare className="w-4 h-4 mr-1 text-blue-600" /> Select All
                  </>
                )}
              </Button>

              <Select onValueChange={handleBulkCategoryChange}>
                <SelectTrigger className="w-36 h-9 text-xs">
                  <SelectValue placeholder="Set Category..." />
                </SelectTrigger>
                <SelectContent>
                  {defaultCategories.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {c.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Type Filter */}
          <div className="flex items-center gap-2 text-xs">
            <span className="text-gray-500 font-medium">Filter:</span>
            <Button
              variant={filterType === "all" ? "default" : "outline"}
              size="sm"
              onClick={() => setFilterType("all")}
              className="h-7 text-xs"
            >
              All ({parsedItems.length})
            </Button>
            <Button
              variant={filterType === "expense" ? "default" : "outline"}
              size="sm"
              onClick={() => setFilterType("expense")}
              className="h-7 text-xs"
            >
              Debits ({parsedItems.filter(i => i.type === "expense").length})
            </Button>
            <Button
              variant={filterType === "income" ? "default" : "outline"}
              size="sm"
              onClick={() => setFilterType("income")}
              className="h-7 text-xs"
            >
              Credits ({parsedItems.filter(i => i.type === "income").length})
            </Button>
          </div>

          {/* Cards Grid */}
          <div className="space-y-3">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                className={`p-4 rounded-lg border transition-all ${
                  item.selected
                    ? "bg-blue-50/40 border-blue-200"
                    : "bg-gray-50/50 border-gray-200 opacity-70"
                }`}
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  {/* Left Controls & Info */}
                  <div className="flex items-start gap-3 flex-1 min-w-0">
                    <input
                      type="checkbox"
                      checked={item.selected}
                      onChange={() => handleToggleItem(item.id)}
                      className="mt-1.5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />

                    <div className="space-y-2 flex-1 min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <Input
                          value={item.merchant}
                          onChange={(e) => handleUpdateItem(item.id, { merchant: e.target.value })}
                          placeholder="Merchant name"
                          className="h-8 font-semibold text-sm max-w-xs"
                        />

                        <button
                          type="button"
                          onClick={() =>
                            handleUpdateItem(item.id, {
                              type: item.type === "expense" ? "income" : "expense",
                            })
                          }
                          className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 ${
                            item.type === "income"
                              ? "bg-green-100 text-green-700"
                              : "bg-red-100 text-red-700"
                          }`}
                        >
                          {item.type === "income" ? (
                            <>
                              <ArrowUpRight className="w-3 h-3" /> Credit
                            </>
                          ) : (
                            <>
                              <ArrowDownRight className="w-3 h-3" /> Debit
                            </>
                          )}
                        </button>
                      </div>

                      <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500">
                        {item.upiRef && (
                          <span className="flex items-center gap-1 font-mono">
                            <Hash className="w-3 h-3 text-gray-400" /> Ref: {item.upiRef}
                          </span>
                        )}
                        {item.bankAcc && (
                          <span className="flex items-center gap-1">
                            <CreditCard className="w-3 h-3 text-gray-400" /> A/c xx{item.bankAcc}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Right Amount, Date, Category & Actions */}
                  <div className="flex flex-wrap items-center gap-2 sm:gap-3 justify-between sm:justify-end">
                    <Input
                      type="date"
                      value={item.date}
                      onChange={(e) => handleUpdateItem(item.id, { date: e.target.value })}
                      className="h-8 text-xs w-32"
                    />

                    <Select
                      value={item.category}
                      onValueChange={(val) => handleUpdateItem(item.id, { category: val })}
                    >
                      <SelectTrigger className="h-8 text-xs w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {defaultCategories.map((c) => (
                          <SelectItem key={c.id} value={c.id}>
                            {c.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>

                    <div className="flex items-center gap-1">
                      <span className="text-sm font-semibold text-gray-500">₹</span>
                      <Input
                        type="number"
                        step="0.01"
                        value={item.amount}
                        onChange={(e) =>
                          handleUpdateItem(item.id, {
                            amount: e.target.value === "" ? "" : parseFloat(e.target.value),
                          })
                        }
                        placeholder="0.00"
                        className="h-8 text-sm font-bold w-24 text-right"
                      />
                    </div>

                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleRemoveItem(item.id)}
                      className="h-8 w-8 text-gray-400 hover:text-red-600"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Footer Bar */}
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4 border-t">
            <div className="flex items-center gap-4 text-sm">
              <span className="text-gray-600">
                Selected: <strong>{selectedCount}</strong> of {parsedItems.length}
              </span>
              {totalSelectedExpense > 0 && (
                <span className="text-red-600 font-semibold">
                  Debits: ₹{totalSelectedExpense.toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                </span>
              )}
              {totalSelectedIncome > 0 && (
                <span className="text-green-600 font-semibold">
                  Credits: ₹{totalSelectedIncome.toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                </span>
              )}
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                onClick={() => setParsedItems([])}
              >
                Discard
              </Button>
              <Button
                onClick={handleImportSelected}
                disabled={isProcessing || selectedCount === 0}
              >
                {isProcessing ? (
                  <>
                    <RefreshCw className="w-4 h-4 mr-2 animate-spin" /> Saving...
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-4 h-4 mr-2" /> Save Selected ({selectedCount})
                  </>
                )}
              </Button>
            </div>
          </div>
        </Card>
      )}

      {/* Success View */}
      {importSuccess && (
        <Card className="p-8 text-center space-y-4">
          <CheckCircle className="w-16 h-16 text-green-600 mx-auto" />
          <h3 className="text-2xl font-bold">Import Successful</h3>
          <p className="text-gray-600 max-w-md mx-auto">
            {importedCount} transaction{importedCount > 1 ? "s" : ""} saved successfully to your account.
          </p>

          <div className="flex justify-center gap-3 pt-2">
            <Button
              onClick={() => {
                setImportSuccess(false);
                setParsedItems([]);
                setRawInput("");
              }}
            >
              Import More Messages
            </Button>
            <Button
              variant="outline"
              onClick={() => navigate("/app/transactions")}
            >
              View Transactions
            </Button>
          </div>
        </Card>
      )}

      {/* Bank & App Format Guide */}
      <Card className="p-6">
        <h3 className="font-bold mb-3">Supported Banks & Apps</h3>
        <div className="grid sm:grid-cols-2 gap-4 text-sm text-gray-600">
          <div>
            <span className="font-semibold text-gray-900 block mb-1">Banks:</span>
            SBI, HDFC, ICICI, Axis, Kotak, Canara, PNB, BOB, Union Bank, IDFC, IndusInd, Federal Bank, etc.
          </div>
          <div>
            <span className="font-semibold text-gray-900 block mb-1">UPI Apps:</span>
            Google Pay (GPay), PhonePe, Paytm, Amazon Pay, CRED, BHIM, WhatsApp Pay.
          </div>
        </div>
      </Card>
    </div>
  );
}
