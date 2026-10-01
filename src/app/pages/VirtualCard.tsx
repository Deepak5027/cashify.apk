import React, { useState, useEffect, useCallback } from "react";
import {
  CreditCard,
  Snowflake,
  Wifi,
  Globe,
  Shield,
  RefreshCw,
  Palette,
  Edit3,
  Plus,
  Trash2,
  CheckCircle2,
  Star,
  Layers,
  RotateCw,
  Sliders,
  Lock,
  Unlock,
  ChevronRight,
} from "lucide-react";
import { virtualCardAPI, VirtualCard as VirtualCardType } from "../../services/api";
import { toast } from "sonner";

const LOCAL_STORAGE_KEY = "financify_wallet_cards_v2";

const DEFAULT_CARDS: VirtualCardType[] = [
  {
    id: 1,
    cardName: "HDFC Regalia Gold",
    cardType: "Credit Card",
    cardNetwork: "VISA",
    bankName: "HDFC Bank",
    cardNumber: "4532 9988 7766 1234",
    cardHolder: "DEEPAK R",
    expiryDate: "12/28",
    cvv: "567",
    spendingLimit: 75000,
    currentSpend: 18450,
    isFrozen: false,
    tapToPayEnabled: true,
    internationalTx: true,
    cardColor: "indigo",
    isPrimary: true,
  },
  {
    id: 2,
    cardName: "SBI Cashback Card",
    cardType: "Debit Card",
    cardNetwork: "MASTERCARD",
    bankName: "State Bank of India",
    cardNumber: "5241 6655 4433 9876",
    cardHolder: "DEEPAK R",
    expiryDate: "08/29",
    cvv: "321",
    spendingLimit: 50000,
    currentSpend: 12300,
    isFrozen: false,
    tapToPayEnabled: true,
    internationalTx: false,
    cardColor: "emerald",
    isPrimary: false,
  },
  {
    id: 3,
    cardName: "ICICI Coral Virtual",
    cardType: "Virtual Prepaid",
    cardNetwork: "RUPAY",
    bankName: "ICICI Bank",
    cardNumber: "6080 1122 3344 5566",
    cardHolder: "DEEPAK R",
    expiryDate: "05/30",
    cvv: "842",
    spendingLimit: 30000,
    currentSpend: 4200,
    isFrozen: false,
    tapToPayEnabled: true,
    internationalTx: false,
    cardColor: "gold",
    isPrimary: false,
  },
];

export default function VirtualCard() {
  const [cards, setCards] = useState<VirtualCardType[]>(() => {
    try {
      const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch (_) {}
    return DEFAULT_CARDS;
  });

  const [selectedCardId, setSelectedCardId] = useState<number>(() => {
    return cards.length > 0 && cards[0].id ? cards[0].id : 1;
  });

  const [isFlipped, setIsFlipped] = useState(false);
  const [loading, setLoading] = useState(false);

  // Modals
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isLimitModalOpen, setIsLimitModalOpen] = useState(false);
  const [limitInput, setLimitInput] = useState("50000");

  // Form State for Add / Edit
  const [formData, setFormData] = useState({
    cardName: "HDFC Regalia Gold",
    cardType: "Credit Card",
    cardNetwork: "VISA",
    bankName: "HDFC Bank",
    cardNumber: "4532 9988 7766 1234",
    cardHolder: "DEEPAK R",
    expiryDate: "12/28",
    cvv: "567",
    spendingLimit: "75000",
    cardColor: "indigo",
    isPrimary: false,
  });

  const colorThemes: Record<string, { name: string; bg: string; shadow: string; accent: string }> = {
    indigo: {
      name: "Indigo Nebula",
      bg: "linear-gradient(135deg, #4f46e5 0%, #7c3aed 50%, #2e1065 100%)",
      shadow: "0 20px 40px -15px rgba(99, 102, 241, 0.45)",
      accent: "#818cf8",
    },
    emerald: {
      name: "Emerald Wealth",
      bg: "linear-gradient(135deg, #059669 0%, #10b981 50%, #064e3b 100%)",
      shadow: "0 20px 40px -15px rgba(16, 185, 129, 0.45)",
      accent: "#34d399",
    },
    rose: {
      name: "Rose Quartz",
      bg: "linear-gradient(135deg, #e11d48 0%, #be185d 50%, #881337 100%)",
      shadow: "0 20px 40px -15px rgba(225, 29, 72, 0.45)",
      accent: "#fb7185",
    },
    gold: {
      name: "Imperial Gold",
      bg: "linear-gradient(135deg, #d97706 0%, #f59e0b 50%, #78350f 100%)",
      shadow: "0 20px 40px -15px rgba(245, 158, 11, 0.45)",
      accent: "#fbbf24",
    },
    midnight: {
      name: "Midnight Carbon",
      bg: "linear-gradient(135deg, #1e293b 0%, #334155 50%, #0f172a 100%)",
      shadow: "0 20px 40px -15px rgba(15, 23, 42, 0.7)",
      accent: "#94a3b8",
    },
  };

  // Sync to local storage on any card state update
  const persistCards = (updated: VirtualCardType[]) => {
    setCards(updated);
    try {
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(updated));
    } catch (_) {}
  };

  const loadCards = useCallback(async () => {
    try {
      setLoading(true);
      const res = await virtualCardAPI.get();
      if (res && res.allCards && res.allCards.length > 0) {
        persistCards(res.allCards);
        if (!res.allCards.some((c) => c.id === selectedCardId)) {
          setSelectedCardId(res.allCards[0].id || 1);
        }
      } else if (res && res.data && res.data.id) {
        persistCards([res.data]);
        setSelectedCardId(res.data.id);
      }
    } catch (err) {
      console.log("Using cached/local wallet cards");
    } finally {
      setLoading(false);
    }
  }, [selectedCardId]);

  useEffect(() => {
    loadCards();
  }, []);

  const activeCard: VirtualCardType =
    cards.find((c) => c.id === selectedCardId) ||
    cards[0] ||
    DEFAULT_CARDS[0];

  const handleUpdateCard = async (updates: Partial<VirtualCardType>) => {
    const cardId = activeCard.id;
    const updatedCards = cards.map((c) =>
      c.id === cardId ? { ...c, ...updates } : c
    );
    persistCards(updatedCards);
    toast.success("Card updated successfully");

    try {
      if (cardId) {
        await virtualCardAPI.update(cardId, updates);
      } else {
        await virtualCardAPI.update(updates);
      }
    } catch (_) {
      // Local storage backup is active
    }
  };

  const handleCreateCard = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.cardNumber.trim() || !formData.cardHolder.trim()) {
      toast.error("Please enter both card number and cardholder name");
      return;
    }

    const newId = Date.now();
    const newCard: VirtualCardType = {
      id: newId,
      cardName: formData.cardName.trim() || "Custom Card",
      cardType: formData.cardType || "Credit Card",
      cardNetwork: formData.cardNetwork || "VISA",
      bankName: formData.bankName.trim() || "Bank",
      cardNumber: formData.cardNumber.trim(),
      cardHolder: formData.cardHolder.trim().toUpperCase(),
      expiryDate: formData.expiryDate.trim() || "12/28",
      cvv: formData.cvv.trim() || "123",
      spendingLimit: parseFloat(formData.spendingLimit) || 50000,
      currentSpend: 0,
      isFrozen: false,
      tapToPayEnabled: true,
      internationalTx: false,
      cardColor: formData.cardColor || "indigo",
      isPrimary: formData.isPrimary,
    };

    let nextCards = [newCard, ...cards];
    if (newCard.isPrimary) {
      nextCards = nextCards.map((c) =>
        c.id === newId ? c : { ...c, isPrimary: false }
      );
    }

    persistCards(nextCards);
    setSelectedCardId(newId);
    setIsAddModalOpen(false);
    toast.success(`Card "${newCard.cardName}" added to wallet!`);

    try {
      const res = await virtualCardAPI.create(newCard);
      if (res && res.data && res.data.id) {
        const synced = nextCards.map((c) => (c.id === newId ? res.data : c));
        persistCards(synced);
        setSelectedCardId(res.data.id);
      }
    } catch (_) {}
  };

  const handleEditSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const cardId = activeCard.id || selectedCardId || 1;

    const updatedCard: VirtualCardType = {
      ...activeCard,
      cardName: formData.cardName.trim() || activeCard.cardName,
      cardType: formData.cardType || activeCard.cardType,
      cardNetwork: formData.cardNetwork || activeCard.cardNetwork,
      bankName: formData.bankName.trim() || activeCard.bankName,
      cardNumber: formData.cardNumber.trim() || activeCard.cardNumber,
      cardHolder: formData.cardHolder.trim().toUpperCase() || activeCard.cardHolder,
      expiryDate: formData.expiryDate.trim() || activeCard.expiryDate,
      cvv: formData.cvv.trim() || activeCard.cvv,
      spendingLimit: parseFloat(formData.spendingLimit) || activeCard.spendingLimit || 50000,
      cardColor: formData.cardColor || activeCard.cardColor || "indigo",
      isPrimary: formData.isPrimary,
    };

    let nextCards = cards.map((c) => (c.id === cardId ? updatedCard : c));
    if (updatedCard.isPrimary) {
      nextCards = nextCards.map((c) =>
        c.id === cardId ? c : { ...c, isPrimary: false }
      );
    }

    persistCards(nextCards);
    setIsEditModalOpen(false);
    toast.success("Card details saved successfully!");

    try {
      await virtualCardAPI.update(cardId, updatedCard);
    } catch (_) {}
  };

  const handleDeleteCard = async (id: number) => {
    if (cards.length <= 1) {
      toast.error("You must keep at least one card in your wallet");
      return;
    }
    const nextList = cards.filter((c) => c.id !== id);
    persistCards(nextList);
    if (nextList.length > 0) setSelectedCardId(nextList[0].id || 1);
    toast.success("Card removed from wallet");

    try {
      await virtualCardAPI.delete(id);
    } catch (_) {}
  };

  const openEditModal = () => {
    setFormData({
      cardName: activeCard.cardName || "HDFC Regalia Gold",
      cardType: activeCard.cardType || "Credit Card",
      cardNetwork: activeCard.cardNetwork || "VISA",
      bankName: activeCard.bankName || "HDFC Bank",
      cardNumber: activeCard.cardNumber || "4532 9988 7766 1234",
      cardHolder: activeCard.cardHolder || "DEEPAK R",
      expiryDate: activeCard.expiryDate || "12/28",
      cvv: activeCard.cvv || "567",
      spendingLimit: String(activeCard.spendingLimit || 75000),
      cardColor: activeCard.cardColor || "indigo",
      isPrimary: Boolean(activeCard.isPrimary),
    });
    setIsEditModalOpen(true);
  };

  const openAddModal = () => {
    setFormData({
      cardName: "Axis Bank Neo",
      cardType: "Debit Card",
      cardNetwork: "MASTERCARD",
      bankName: "Axis Bank",
      cardNumber: "5123 4455 6677 8899",
      cardHolder: "DEEPAK R",
      expiryDate: "10/29",
      cvv: "429",
      spendingLimit: "60000",
      cardColor: "rose",
      isPrimary: false,
    });
    setIsAddModalOpen(true);
  };

  const limit = Number(activeCard?.spendingLimit) || 50000;
  const spend = Number(activeCard?.currentSpend) || 0;
  const spendPct = limit > 0 ? Math.min(100, (spend / limit) * 100) : 0;
  const remaining = Math.max(0, limit - spend);
  const colorKey = activeCard?.cardColor || "indigo";
  const activeTheme = colorThemes[colorKey] || colorThemes.indigo;

  return (
    <div className="p-4 lg:p-8 max-w-6xl mx-auto space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold tracking-tight text-white flex items-center gap-3">
            <div className="p-2.5 rounded-2xl bg-gradient-to-tr from-indigo-500 via-purple-500 to-pink-500 text-white shadow-lg">
              <CreditCard className="w-6 h-6" />
            </div>
            Multi-Card Wallet & Controls
          </h1>
          <p className="text-slate-400 text-sm mt-1">
            Manage all your real and virtual cards in one place. Switch cards, adjust spend caps, and toggle instant security.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={openAddModal}
            className="flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-sm font-bold shadow-lg shadow-indigo-500/25 transition-all transform hover:scale-[1.02] active:scale-[0.98]"
          >
            <Plus className="w-4 h-4" /> Add New Card
          </button>
          <button
            onClick={loadCards}
            className="p-2.5 rounded-2xl border border-slate-700/80 bg-slate-800/80 hover:bg-slate-700 text-slate-300 transition"
            title="Refresh Wallet Cards"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 🌟 PROMINENT MULTI-CARD SWITCHER CAROUSEL */}
      {/* ========================================================================= */}
      <div className="space-y-3">
        <div className="flex items-center justify-between text-xs text-slate-400 font-bold uppercase tracking-wider px-1">
          <span className="flex items-center gap-2">
            <Layers className="w-4 h-4 text-indigo-400" />
            Your Wallet Cards ({cards.length}) — Click to Switch & View
          </span>
          <span className="text-indigo-400 text-[11px] font-normal normal-case flex items-center gap-1">
            Active: <b>{activeCard.cardName}</b>
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {cards.map((c) => {
            const isSelected = c.id === activeCard.id;
            const theme = colorThemes[c.cardColor || "indigo"] || colorThemes.indigo;
            return (
              <div
                key={c.id}
                onClick={() => c.id && setSelectedCardId(c.id)}
                className={`p-4 rounded-2xl border cursor-pointer transition-all relative overflow-hidden flex flex-col justify-between ${
                  isSelected
                    ? "ring-2 ring-indigo-500 bg-slate-900/95 border-indigo-500/80 shadow-xl shadow-indigo-500/10 transform scale-[1.01]"
                    : "bg-slate-900/60 border-slate-800 hover:border-slate-700 hover:bg-slate-900/80"
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-12 h-8 rounded-xl shadow-md flex items-center justify-center font-black text-[10px] text-white tracking-wider uppercase border border-white/20"
                      style={{ background: theme.bg }}
                    >
                      {c.cardNetwork || "VISA"}
                    </div>
                    <div>
                      <div className="font-bold text-white text-sm flex items-center gap-1.5">
                        <span>{c.cardName || "Card"}</span>
                        {c.isPrimary && (
                          <span className="bg-amber-500/20 text-amber-300 text-[9px] px-1.5 py-0.5 rounded-md font-bold flex items-center gap-0.5">
                            <Star className="w-2.5 h-2.5 fill-amber-300" /> PRIMARY
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">
                        {c.bankName} • <span className="font-mono">{c.cardNumber}</span>
                      </div>
                    </div>
                  </div>

                  {isSelected && (
                    <div className="p-1 rounded-full bg-indigo-500/20 text-indigo-400">
                      <CheckCircle2 className="w-4 h-4" />
                    </div>
                  )}
                </div>

                <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-800/80 text-xs">
                  <span className="text-slate-400">
                    Cap: <b className="text-white font-mono">₹{(c.spendingLimit || 50000).toLocaleString("en-IN")}</b>
                  </span>
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      c.isFrozen
                        ? "bg-red-500/20 text-red-400 border border-red-500/30"
                        : "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"
                    }`}
                  >
                    {c.isFrozen ? "FROZEN" : "ACTIVE"}
                  </span>
                </div>
              </div>
            );
          })}

          {/* Quick Add Card Tile */}
          <button
            onClick={openAddModal}
            className="p-4 rounded-2xl border border-dashed border-slate-700/80 hover:border-indigo-500/60 bg-slate-900/30 hover:bg-slate-900/60 transition-all flex flex-col items-center justify-center gap-2 text-slate-400 hover:text-indigo-300 group min-h-[96px]"
          >
            <div className="w-8 h-8 rounded-full bg-slate-800 group-hover:bg-indigo-600/30 flex items-center justify-center text-slate-300 group-hover:text-indigo-400 transition">
              <Plus className="w-4 h-4" />
            </div>
            <span className="text-xs font-bold">Link Another Card</span>
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* MAIN ACTIVE CARD STAGE & CONTROLS */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start pt-2">
        {/* Left Column: 3D Flip Card */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex items-center justify-between px-1">
            <button
              onClick={() => setIsFlipped(!isFlipped)}
              className="text-xs text-indigo-400 hover:text-indigo-300 font-semibold flex items-center gap-1.5 bg-indigo-500/10 hover:bg-indigo-500/20 px-3 py-1.5 rounded-xl border border-indigo-500/30 transition"
            >
              <RotateCw className="w-3.5 h-3.5" />
              <span>{isFlipped ? "Flip to Front" : "Tap card or Click to reveal CVV"}</span>
            </button>

            <div className="flex items-center gap-2">
              <button
                onClick={openEditModal}
                className="flex items-center gap-1.5 text-xs font-bold text-slate-200 hover:text-white bg-slate-800 hover:bg-slate-700 px-3.5 py-1.5 rounded-xl border border-slate-700 transition shadow-sm"
              >
                <Edit3 className="w-3.5 h-3.5 text-indigo-400" /> Edit Details
              </button>

              {cards.length > 1 && (
                <button
                  onClick={() => activeCard.id && handleDeleteCard(activeCard.id)}
                  className="p-1.5 rounded-xl text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition border border-transparent hover:border-red-500/20"
                  title="Remove Card from Wallet"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>

          {/* 3D Flip Card Container */}
          <div
            className="w-full max-w-md mx-auto h-56 sm:h-64 rounded-3xl cursor-pointer select-none relative transition-transform duration-500"
            style={{ perspective: "1000px" }}
            onClick={() => setIsFlipped(!isFlipped)}
          >
            <div
              className="w-full h-full relative rounded-3xl transition-transform duration-700 shadow-2xl"
              style={{
                transformStyle: "preserve-3d",
                transform: isFlipped ? "rotateY(180deg)" : "rotateY(0deg)",
              }}
            >
              {/* FRONT SIDE */}
              <div
                className="absolute inset-0 w-full h-full rounded-3xl p-6 sm:p-7 flex flex-col justify-between text-white overflow-hidden border border-white/20"
                style={{
                  background: activeTheme.bg,
                  boxShadow: activeTheme.shadow,
                  backfaceVisibility: "hidden",
                  WebkitBackfaceVisibility: "hidden",
                }}
              >
                <div className="absolute -top-16 -right-16 w-48 h-48 rounded-full bg-white/10 blur-2xl pointer-events-none" />
                <div className="absolute -bottom-16 -left-16 w-48 h-48 rounded-full bg-black/20 blur-2xl pointer-events-none" />

                {/* Top Row */}
                <div className="flex items-center justify-between z-10">
                  <div className="flex flex-col">
                    <span className="font-extrabold tracking-wider text-base sm:text-lg drop-shadow">
                      {activeCard.bankName || "AiFinancify Bank"}
                    </span>
                    <span className="text-[10px] text-white/80 font-medium tracking-wide">
                      {activeCard.cardName || activeCard.cardType}
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    {activeCard.isFrozen && (
                      <span className="bg-red-500/90 text-white text-[10px] font-bold px-2.5 py-0.5 rounded-md flex items-center gap-1 shadow">
                        <Snowflake className="w-3 h-3 animate-pulse" /> FROZEN
                      </span>
                    )}
                    <Wifi className="w-5 h-5 text-white/90 rotate-90" />
                  </div>
                </div>

                {/* EMV Chip & Card Number */}
                <div className="flex items-center gap-4 z-10">
                  <div className="w-11 h-8 rounded-lg bg-gradient-to-tr from-amber-400 to-yellow-200 border border-amber-300 shadow-inner flex flex-col justify-around p-1">
                    <div className="w-full h-0.5 bg-amber-600/40" />
                    <div className="w-full h-0.5 bg-amber-600/40" />
                  </div>
                  <div className="font-mono text-base sm:text-xl font-bold tracking-[0.2em] drop-shadow-md">
                    {activeCard.cardNumber || "4532 •••• •••• 1234"}
                  </div>
                </div>

                {/* Cardholder & Expiry */}
                <div className="flex items-end justify-between z-10">
                  <div>
                    <div className="text-[9px] uppercase tracking-wider text-white/60 font-semibold">Card Holder</div>
                    <div className="text-xs sm:text-sm font-bold tracking-wide uppercase">
                      {activeCard.cardHolder || "DEEPAK R"}
                    </div>
                  </div>
                  <div>
                    <div className="text-[9px] uppercase tracking-wider text-white/60 font-semibold">Expires</div>
                    <div className="text-xs sm:text-sm font-bold font-mono">{activeCard.expiryDate || "12/28"}</div>
                  </div>
                  <div className="font-extrabold italic text-lg sm:text-xl tracking-tighter bg-white/20 px-3 py-0.5 rounded-lg shadow-inner">
                    {activeCard.cardNetwork || "VISA"}
                  </div>
                </div>
              </div>

              {/* BACK SIDE */}
              <div
                className="absolute inset-0 w-full h-full rounded-3xl flex flex-col justify-between text-white overflow-hidden border border-white/20"
                style={{
                  background: activeTheme.bg,
                  boxShadow: activeTheme.shadow,
                  backfaceVisibility: "hidden",
                  WebkitBackfaceVisibility: "hidden",
                  transform: "rotateY(180deg)",
                }}
              >
                <div className="h-10 bg-slate-950 w-full mt-6" />

                <div className="px-6 space-y-2">
                  <div className="flex items-center justify-between text-xs text-white/70">
                    <span>Authorized Signature</span>
                    <span>Security Code (CVV)</span>
                  </div>
                  <div className="flex items-center">
                    <div className="h-8 bg-slate-100 flex-1 rounded-l-md px-3 flex items-center justify-end text-slate-900 font-mono font-bold text-sm tracking-wider">
                      CVV: {activeCard.cvv || "567"}
                    </div>
                    <div className="h-8 bg-indigo-600 px-3 flex items-center justify-center rounded-r-md text-xs font-bold">
                      VERIFIED
                    </div>
                  </div>
                </div>

                <div className="p-6 text-[10px] text-white/60 flex items-center justify-between border-t border-white/10">
                  <span>{activeCard.cardType || "Credit Card"} • Protected by AiFinancify Security</span>
                  <Shield className="w-4 h-4 text-white/80" />
                </div>
              </div>
            </div>
          </div>

          {/* Theme Skin Switcher */}
          <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800 flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-300">
              <Palette className="w-4 h-4 text-indigo-400" />
              <span>Card Skin Theme:</span>
            </div>
            <div className="flex items-center gap-2">
              {Object.entries(colorThemes).map(([key, item]) => (
                <button
                  key={key}
                  onClick={() => handleUpdateCard({ cardColor: key })}
                  title={item.name}
                  className={`w-7 h-7 rounded-full transition-transform ${
                    (activeCard.cardColor || "indigo") === key ? "ring-2 ring-white scale-110" : "opacity-70 hover:opacity-100"
                  }`}
                  style={{ background: item.bg }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Right Column: Spending Cap & Security Controls */}
        <div className="lg:col-span-5 space-y-6">
          {/* Monthly Cap Progress Box */}
          <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Monthly Spending Cap</span>
                <div className="text-2xl font-black text-white mt-1">
                  ₹{spend.toLocaleString("en-IN")}
                  <span className="text-sm font-normal text-slate-400"> / ₹{limit.toLocaleString("en-IN")}</span>
                </div>
              </div>
              <button
                onClick={() => {
                  setLimitInput(String(activeCard.spendingLimit || 50000));
                  setIsLimitModalOpen(true);
                }}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-indigo-500/40 bg-indigo-500/10 text-indigo-400 text-xs font-bold hover:bg-indigo-500/20 transition"
              >
                <Edit3 className="w-3.5 h-3.5" /> Adjust Cap
              </button>
            </div>

            {/* Visual Gauge */}
            <div className="space-y-1.5">
              <div className="w-full bg-slate-800 h-3 rounded-full overflow-hidden p-0.5 border border-slate-700">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${
                    spendPct > 85 ? "bg-red-500" : spendPct > 65 ? "bg-amber-500" : "bg-emerald-500"
                  }`}
                  style={{ width: `${spendPct}%` }}
                />
              </div>
              <div className="flex justify-between text-xs font-medium">
                <span className={spendPct > 85 ? "text-red-400 font-bold" : "text-slate-400"}>
                  {spendPct.toFixed(0)}% used this month
                </span>
                <span className="text-emerald-400 font-bold">
                  ₹{remaining.toLocaleString("en-IN")} remaining
                </span>
              </div>
            </div>
          </div>

          {/* Security Toggles Card */}
          <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 space-y-4">
            <h3 className="text-sm font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
              <Shield className="w-4 h-4 text-indigo-400" />
              Card Security & Channel Controls
            </h3>

            <div className="space-y-3 divide-y divide-slate-800/80">
              {/* Freeze Card */}
              <div className="pt-3 first:pt-0 flex items-center justify-between">
                <div className="space-y-0.5">
                  <div className="text-sm font-bold text-white flex items-center gap-2">
                    <Snowflake className={`w-4 h-4 ${activeCard.isFrozen ? "text-red-400" : "text-slate-400"}`} />
                    {activeCard.isFrozen ? "Card Frozen (Locked)" : "Freeze Card"}
                  </div>
                  <div className="text-xs text-slate-400">Instantly block card from transactions</div>
                </div>
                <button
                  onClick={() => handleUpdateCard({ isFrozen: !activeCard.isFrozen })}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    activeCard.isFrozen ? "bg-red-500" : "bg-slate-700"
                  }`}
                >
                  <div
                    className={`w-4 h-4 rounded-full bg-white transition-transform absolute top-1 ${
                      activeCard.isFrozen ? "left-7" : "left-1"
                    }`}
                  />
                </button>
              </div>

              {/* Tap to Pay */}
              <div className="pt-3 flex items-center justify-between">
                <div className="space-y-0.5">
                  <div className="text-sm font-bold text-white flex items-center gap-2">
                    <Wifi className="w-4 h-4 text-emerald-400 rotate-90" />
                    Contactless / Tap to Pay
                  </div>
                  <div className="text-xs text-slate-400">Enable POS tap and NFC payments</div>
                </div>
                <button
                  disabled={activeCard.isFrozen}
                  onClick={() => handleUpdateCard({ tapToPayEnabled: !activeCard.tapToPayEnabled })}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    activeCard.isFrozen
                      ? "opacity-50 cursor-not-allowed bg-slate-700"
                      : activeCard.tapToPayEnabled
                      ? "bg-emerald-500"
                      : "bg-slate-700"
                  }`}
                >
                  <div
                    className={`w-4 h-4 rounded-full bg-white transition-transform absolute top-1 ${
                      activeCard.tapToPayEnabled ? "left-7" : "left-1"
                    }`}
                  />
                </button>
              </div>

              {/* International Transactions */}
              <div className="pt-3 flex items-center justify-between">
                <div className="space-y-0.5">
                  <div className="text-sm font-bold text-white flex items-center gap-2">
                    <Globe className="w-4 h-4 text-blue-400" />
                    International Payments
                  </div>
                  <div className="text-xs text-slate-400">Allow foreign currency transactions</div>
                </div>
                <button
                  disabled={activeCard.isFrozen}
                  onClick={() => handleUpdateCard({ internationalTx: !activeCard.internationalTx })}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    activeCard.isFrozen
                      ? "opacity-50 cursor-not-allowed bg-slate-700"
                      : activeCard.internationalTx
                      ? "bg-indigo-500"
                      : "bg-slate-700"
                  }`}
                >
                  <div
                    className={`w-4 h-4 rounded-full bg-white transition-transform absolute top-1 ${
                      activeCard.internationalTx ? "left-7" : "left-1"
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* MODAL 1: ADD NEW REAL OR VIRTUAL CARD */}
      {/* ========================================================================= */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="w-full max-w-lg rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Plus className="w-5 h-5 text-indigo-400" /> Add Card to Wallet
              </h3>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="text-slate-400 hover:text-white text-sm font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateCard} className="space-y-3.5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Nickname</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. HDFC Regalia, Axis Ace"
                    value={formData.cardName}
                    onChange={(e) => setFormData({ ...formData, cardName: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Bank Name</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. HDFC Bank, SBI, ICICI"
                    value={formData.bankName}
                    onChange={(e) => setFormData({ ...formData, bankName: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Type</label>
                  <select
                    value={formData.cardType}
                    onChange={(e) => setFormData({ ...formData, cardType: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="Debit Card">Debit Card</option>
                    <option value="Credit Card">Credit Card</option>
                    <option value="Virtual Prepaid">Virtual Prepaid</option>
                    <option value="Forex / Travel">Forex / Travel</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Network</label>
                  <select
                    value={formData.cardNetwork}
                    onChange={(e) => setFormData({ ...formData, cardNetwork: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="VISA">VISA</option>
                    <option value="MASTERCARD">Mastercard</option>
                    <option value="RUPAY">RuPay</option>
                    <option value="AMEX">American Express</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Card Number (16 Digits)</label>
                <input
                  type="text"
                  required
                  placeholder="4532 8900 1234 5678"
                  value={formData.cardNumber}
                  onChange={(e) => setFormData({ ...formData, cardNumber: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Cardholder Name</label>
                  <input
                    type="text"
                    required
                    placeholder="DEEPAK R"
                    value={formData.cardHolder}
                    onChange={(e) => setFormData({ ...formData, cardHolder: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs uppercase focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Expiry (MM/YY)</label>
                  <input
                    type="text"
                    required
                    placeholder="08/29"
                    value={formData.expiryDate}
                    onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">CVV</label>
                  <input
                    type="password"
                    maxLength={4}
                    required
                    placeholder="842"
                    value={formData.cvv}
                    onChange={(e) => setFormData({ ...formData, cvv: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Monthly Spend Limit (₹)</label>
                  <input
                    type="number"
                    value={formData.spendingLimit}
                    onChange={(e) => setFormData({ ...formData, spendingLimit: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Skin</label>
                  <select
                    value={formData.cardColor}
                    onChange={(e) => setFormData({ ...formData, cardColor: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="indigo">Indigo Nebula</option>
                    <option value="emerald">Emerald Wealth</option>
                    <option value="rose">Rose Quartz</option>
                    <option value="gold">Imperial Gold</option>
                    <option value="midnight">Midnight Carbon</option>
                  </select>
                </div>
              </div>

              <div className="flex gap-3 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-xs font-bold hover:bg-slate-800 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-xs font-bold shadow-lg transition"
                >
                  Add Card to Wallet
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 2: EDIT CARD DETAILS */}
      {/* ========================================================================= */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="w-full max-w-lg rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Edit3 className="w-5 h-5 text-indigo-400" /> Edit Card Details
              </h3>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="text-slate-400 hover:text-white text-sm font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleEditSave} className="space-y-3.5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Nickname</label>
                  <input
                    type="text"
                    required
                    value={formData.cardName}
                    onChange={(e) => setFormData({ ...formData, cardName: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Bank Name</label>
                  <input
                    type="text"
                    required
                    value={formData.bankName}
                    onChange={(e) => setFormData({ ...formData, bankName: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Type</label>
                  <select
                    value={formData.cardType}
                    onChange={(e) => setFormData({ ...formData, cardType: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="Debit Card">Debit Card</option>
                    <option value="Credit Card">Credit Card</option>
                    <option value="Virtual Prepaid">Virtual Prepaid</option>
                    <option value="Forex / Travel">Forex / Travel</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Network</label>
                  <select
                    value={formData.cardNetwork}
                    onChange={(e) => setFormData({ ...formData, cardNetwork: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="VISA">VISA</option>
                    <option value="MASTERCARD">Mastercard</option>
                    <option value="RUPAY">RuPay</option>
                    <option value="AMEX">American Express</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-300 block mb-1">Card Number</label>
                <input
                  type="text"
                  required
                  value={formData.cardNumber}
                  onChange={(e) => setFormData({ ...formData, cardNumber: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Cardholder Name</label>
                  <input
                    type="text"
                    required
                    value={formData.cardHolder}
                    onChange={(e) => setFormData({ ...formData, cardHolder: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs uppercase focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Expiry (MM/YY)</label>
                  <input
                    type="text"
                    required
                    value={formData.expiryDate}
                    onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">CVV</label>
                  <input
                    type="text"
                    maxLength={4}
                    required
                    value={formData.cvv}
                    onChange={(e) => setFormData({ ...formData, cvv: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Monthly Spend Limit (₹)</label>
                  <input
                    type="number"
                    value={formData.spendingLimit}
                    onChange={(e) => setFormData({ ...formData, spendingLimit: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs font-mono focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-300 block mb-1">Card Skin Theme</label>
                  <select
                    value={formData.cardColor}
                    onChange={(e) => setFormData({ ...formData, cardColor: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white text-xs focus:outline-none focus:border-indigo-500"
                  >
                    <option value="indigo">Indigo Nebula</option>
                    <option value="emerald">Emerald Wealth</option>
                    <option value="rose">Rose Quartz</option>
                    <option value="gold">Imperial Gold</option>
                    <option value="midnight">Midnight Carbon</option>
                  </select>
                </div>
              </div>

              <div className="flex gap-3 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-xs font-bold hover:bg-slate-800 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-xs font-bold shadow-lg transition"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL 3: ADJUST SPENDING CAP */}
      {/* ========================================================================= */}
      {isLimitModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="w-full max-w-sm rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4 shadow-2xl">
            <h3 className="text-lg font-bold text-white">Adjust Spending Cap</h3>
            <p className="text-xs text-slate-400">Set maximum monthly spending limit for {activeCard.cardName || "this card"}.</p>

            <div>
              <label className="text-xs font-semibold text-slate-300 block mb-1">Monthly Limit (₹)</label>
              <input
                type="number"
                value={limitInput}
                onChange={(e) => setLimitInput(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-700 text-white font-mono font-bold focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setIsLimitModalOpen(false)}
                className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-sm font-bold hover:bg-slate-800 transition"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => {
                  const val = parseFloat(limitInput) || activeCard.spendingLimit || 50000;
                  handleUpdateCard({ spendingLimit: val });
                  setIsLimitModalOpen(false);
                }}
                className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white text-sm font-bold shadow-lg transition"
              >
                Save Cap
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
