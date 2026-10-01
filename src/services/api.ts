import apiClient from "../utils/apiClient";

export interface Transaction {
  id: number | string;
  userId?: string;
  user_id?: string;
  amount: number;
  description?: string;
  merchant?: string;
  category?: string;
  type: 'income' | 'expense';
  paymentMode?: string;
  payment_mode?: string;
  isRecurring?: boolean;
  is_recurring?: boolean;
  recurringPeriod?: 'weekly' | 'monthly' | string;
  recurring_period?: 'weekly' | 'monthly' | string;
  nextRecurringDate?: string;
  next_recurring_date?: string;
  risk_score?: number;
  riskScore?: number;
  status?: string;
  notes?: string;
  receipt_url?: string;
  date: string;
  createdAt?: string;
}

export interface Activity {
  id: number | string;
  userId?: string;
  action: string;
  title: string;
  details?: string;
  type: string;
  createdAt: string;
}

export interface Budget {
  id: number | string;
  userId?: string;
  name?: string;
  category: string;
  limit?: number;
  amount: number;
  period?: string;
  spent?: number;
  predicted?: number;
  month?: string;
  year?: number;
}

export interface Goal {
  id: number | string;
  userId?: string;
  name: string;
  target?: number;
  target_amount: number;
  saved?: number;
  current_amount: number;
  dueDate?: string;
  deadline: string;
  category?: string;
}

export interface Bill {
  id: number | string;
  userId?: string;
  name: string;
  amount: number;
  dueDate?: string;
  paid?: boolean;
}

export interface Investment {
  id: number | string;
  userId?: string;
  name: string;
  amount: number;
}

export interface Receipt {
  id: number | string;
  userId?: string;
  total: number;
  merchant?: string;
  date?: string;
  items?: Array<{ name: string; price: number; quantity: number }>;
}

// Helper to get current user ID from backend
async function getUserId(): Promise<string> {
  const res = await apiClient.get('/auth/me');
  if (!res || !res.user) throw new Error('User not authenticated');
  return res.user.id;
}

// Transactions API
export const transactionsAPI = {
  async getAll(): Promise<{ transactions: Transaction[]; data?: Transaction[] }> {
    const userId = await getUserId();
    const res = await apiClient.get(`/api/transactions?userId=${encodeURIComponent(userId)}`);
    const raw = res.data || res.transactions || [];
    const txs: Transaction[] = raw.map((t: any) => {
      const cat = (t.category || "").toLowerCase();
      const isIncome = cat === "salary" || cat === "revenue" || cat === "income" || cat === "refund";
      return {
        ...t,
        type: t.type || (isIncome ? "income" : "expense"),
        merchant: t.merchant || t.description || "Unknown",
        paymentMode: t.payment_mode || t.paymentMode || "Cash",
      };
    });
    return { transactions: txs, data: txs };
  },

  async create(transaction: Partial<Transaction>): Promise<Transaction> {
    const userId = await getUserId();
    const res = await apiClient.post('/api/transactions', { ...transaction, userId });
    const cat = (res?.category || "").toLowerCase();
    const isIncome = cat === "salary" || cat === "revenue" || cat === "income" || cat === "refund";
    return {
      ...res,
      type: (transaction.type as 'income' | 'expense') || (isIncome ? "income" : "expense"),
      merchant: res?.merchant || res?.description || transaction.merchant || "Unknown",
      paymentMode: res?.payment_mode || transaction.payment_mode || "Cash",
    };
  },

  async update(id: string | number, updates: Partial<Transaction>): Promise<Transaction> {
    const res = await apiClient.put(`/api/transactions/${encodeURIComponent(String(id))}`, updates);
    const cat = (res?.category || "").toLowerCase();
    const isIncome = cat === "salary" || cat === "revenue" || cat === "income" || cat === "refund";
    return {
      ...res,
      type: (updates.type as 'income' | 'expense') || (isIncome ? "income" : "expense"),
      merchant: res?.merchant || res?.description || "Unknown",
    };
  },

  async delete(id: string | number): Promise<{ success: boolean }> {
    await apiClient.del(`/api/transactions/${encodeURIComponent(String(id))}`);
    return { success: true };
  },
};

// Budgets API
export const budgetsAPI = {
  async getAll(): Promise<{ budgets: Budget[]; data?: Budget[] }> {
    const userId = await getUserId();
    const res = await apiClient.get(`/api/budgets?userId=${encodeURIComponent(userId)}`);
    const mapped: Budget[] = (res.data || res.budgets || []).map((b: any) => ({
      ...b,
      category: b.category || b.name || "",
      amount: typeof b.limit === 'number' ? b.limit : (typeof b.amount === 'number' ? b.amount : 0),
      limit: typeof b.limit === 'number' ? b.limit : (typeof b.amount === 'number' ? b.amount : 0),
      spent: b.spent || 0,
      predicted: b.predicted || 0,
      month: b.month || 'current',
      year: b.year || new Date().getFullYear(),
    }));
    return { budgets: mapped, data: mapped };
  },

  async create(budget: { category: string; amount: number; period?: string }): Promise<Budget> {
    const userId = await getUserId();
    const res = await apiClient.post('/api/budgets', {
      name: budget.category,
      limit: budget.amount,
      period: budget.period || 'monthly',
      userId,
    });
    return {
      ...res,
      category: res?.category || res?.name || budget.category,
      amount: res?.limit || res?.amount || budget.amount,
      limit: res?.limit || res?.amount || budget.amount,
      spent: 0,
      predicted: 0,
      month: 'current',
      year: new Date().getFullYear(),
    };
  },

  async update(id: string | number, updates: { category?: string; amount?: number; period?: string }): Promise<Budget> {
    const res = await apiClient.put(`/api/budgets/${encodeURIComponent(String(id))}`, {
      name: updates.category,
      limit: updates.amount,
      period: updates.period,
    });
    return {
      ...res,
      category: res?.category || res?.name || "",
      amount: res?.limit || res?.amount || 0,
      limit: res?.limit || res?.amount || 0,
      spent: res?.spent || 0,
      predicted: res?.predicted || 0,
      month: 'current',
      year: new Date().getFullYear(),
    };
  },

  async delete(id: string | number): Promise<{ success: boolean }> {
    await apiClient.del(`/api/budgets/${encodeURIComponent(String(id))}`);
    return { success: true };
  },
};

// Goals API
export const goalsAPI = {
  async getAll(): Promise<{ goals: Goal[]; data?: Goal[] }> {
    const userId = await getUserId();
    const res = await apiClient.get(`/api/goals?userId=${encodeURIComponent(userId)}`);
    const mapped: Goal[] = (res.data || res.goals || []).map((g: any) => ({
      ...g,
      name: g.name || "",
      target_amount: typeof g.target === 'number' ? g.target : (g.target_amount || 0),
      current_amount: typeof g.saved === 'number' ? g.saved : (g.current_amount || 0),
      deadline: g.dueDate || g.deadline || new Date().toISOString(),
      category: g.category || "custom",
    }));
    return { goals: mapped, data: mapped };
  },

  async create(goal: { name: string; target_amount: number; current_amount?: number; deadline: string; category?: string }): Promise<Goal> {
    const userId = await getUserId();
    const res = await apiClient.post('/api/goals', {
      name: goal.name,
      target: goal.target_amount,
      saved: goal.current_amount || 0,
      dueDate: goal.deadline,
      userId,
    });
    return {
      ...res,
      name: res?.name || goal.name,
      target_amount: res?.target || goal.target_amount,
      current_amount: res?.saved || goal.current_amount || 0,
      deadline: res?.dueDate || goal.deadline,
      category: goal.category || "custom",
    };
  },

  async update(id: string | number, updates: { name?: string; target_amount?: number; current_amount?: number; deadline?: string }): Promise<Goal> {
    const res = await apiClient.put(`/api/goals/${encodeURIComponent(String(id))}`, {
      name: updates.name,
      target: updates.target_amount,
      saved: updates.current_amount,
      dueDate: updates.deadline,
    });
    return {
      ...res,
      name: res?.name || "",
      target_amount: res?.target || updates.target_amount || 0,
      current_amount: res?.saved || updates.current_amount || 0,
      deadline: res?.dueDate || updates.deadline || new Date().toISOString(),
      category: res?.category || "custom",
    };
  },

  async delete(id: string | number): Promise<{ success: boolean }> {
    await apiClient.del(`/api/goals/${encodeURIComponent(String(id))}`);
    return { success: true };
  },
};

// Bills API
export const billsAPI = {
  async getAll(): Promise<{ bills: Bill[]; data?: Bill[] }> {
    const res = await apiClient.get('/api/bills');
    const bills = res.data || [];
    return { bills, data: bills };
  },
  async create(bill: { name: string; amount: number; dueDate?: string; paid?: boolean }): Promise<Bill> {
    const res = await apiClient.post('/api/bills', bill);
    return res;
  },
  async delete(id: string | number): Promise<{ success: boolean }> {
    await apiClient.del(`/api/bills/${encodeURIComponent(String(id))}`);
    return { success: true };
  }
};

// Investments API
export const investmentsAPI = {
  async getAll(): Promise<{ investments: Investment[]; data?: Investment[] }> {
    const res = await apiClient.get('/api/investments');
    const investments = res.data || [];
    return { investments, data: investments };
  },
  async create(inv: { name: string; amount: number }): Promise<Investment> {
    const res = await apiClient.post('/api/investments', inv);
    return res;
  },
  async delete(id: string | number): Promise<{ success: boolean }> {
    await apiClient.del(`/api/investments/${encodeURIComponent(String(id))}`);
    return { success: true };
  }
};

// Receipts API
export const receiptsAPI = {
  async getAll(): Promise<{ receipts: Receipt[]; data?: Receipt[] }> {
    const res = await apiClient.get('/api/receipts');
    const receipts = res.data || [];
    return { receipts, data: receipts };
  },
  async create(receipt: any): Promise<Receipt> {
    const res = await apiClient.post('/api/receipts', receipt);
    return res;
  },
  async save(receipt: any): Promise<Receipt> {
    const res = await apiClient.post('/api/receipts', receipt);
    return res;
  }
};

// AI API
export const aiAPI = {
  async getInsights() {
    const res = await apiClient.get('/api/ai/insights');
    return { insights: res.insights || [] };
  },

  async analyzeFraud(transaction: Partial<Transaction>) {
    const res = await apiClient.post('/api/ai/analyzeFraud', { transaction });
    return res;
  },

  async getAnalytics() {
    const res = await apiClient.get('/api/ai/analytics');
    return { analytics: res.analytics || {} };
  },

  async predictSpending() {
    const res = await apiClient.get('/api/ai/predict');
    return { predictions: res.data || [] };
  },
};

// CSV / Statement Import API
export const importAPI = {
  async importCSV(csvDataOrPayload: string | { csvData?: string; transactions?: any[] }): Promise<{ message: string; transactions: Transaction[]; imported: number }> {
    const payload = typeof csvDataOrPayload === 'string' ? { csvData: csvDataOrPayload } : csvDataOrPayload;
    const res = await apiClient.post('/api/import-csv', payload);
    if (!res || res.error) throw new Error(res?.message || res?.error || 'Import failed');

    const txs = res.transactions || res.data || [];
    return {
      message: res.message || `Successfully imported ${res.imported || txs.length} transactions`,
      transactions: txs,
      imported: res.imported !== undefined ? res.imported : txs.length,
    };
  },
};

// User Profile API
export const profileAPI = {
  async getProfile(): Promise<{ user: any }> {
    const res = await apiClient.get('/api/profile');
    return res;
  },
  async updateProfile(updates: {
    name?: string;
    phone?: string;
    location?: string;
    currency?: string;
    timezone?: string;
    image?: string;
  }): Promise<{ success: boolean; user: any }> {
    const res = await apiClient.put('/api/profile', updates);
    return res;
  },
};

// Activity Feed API
export const activitiesAPI = {
  async getAll(): Promise<{ data: Activity[]; activities?: Activity[] }> {
    const res = await apiClient.get('/api/activities');
    const list = res.data || res.activities || [];
    return { data: list, activities: list };
  },
};

// ==========================================
// 💳 VIRTUAL & REAL WALLET CARDS API
// ==========================================
export interface VirtualCard {
  id?: number;
  cardName?: string;
  cardType?: string;
  cardNetwork?: string;
  bankName?: string;
  cardNumber: string;
  cardHolder: string;
  expiryDate: string;
  cvv: string;
  spendingLimit: number;
  currentSpend: number;
  isFrozen: boolean;
  tapToPayEnabled: boolean;
  internationalTx: boolean;
  cardColor: string;
  isPrimary?: boolean;
}

export const virtualCardAPI = {
  async get(): Promise<{ data: VirtualCard; allCards?: VirtualCard[] }> {
    const res = await apiClient.get('/api/virtual-card');
    return { data: res.data || res, allCards: res.allCards || (res.data ? [res.data] : []) };
  },
  async getAll(): Promise<{ data: VirtualCard[] }> {
    const res = await apiClient.get('/api/virtual-cards');
    return { data: Array.isArray(res.data) ? res.data : (Array.isArray(res) ? res : []) };
  },
  async create(cardData: Partial<VirtualCard>): Promise<{ data: VirtualCard }> {
    const res = await apiClient.post('/api/virtual-card', cardData);
    return { data: res.data || res };
  },
  async update(idOrUpdates: number | Partial<VirtualCard>, updates?: Partial<VirtualCard>): Promise<{ data: VirtualCard }> {
    if (typeof idOrUpdates === 'number') {
      const res = await apiClient.put(`/api/virtual-card/${idOrUpdates}`, updates || {});
      return { data: res.data || res };
    }
    const res = await apiClient.put('/api/virtual-card', idOrUpdates);
    return { data: res.data || res };
  },
  async delete(id: number): Promise<{ success: boolean }> {
    const res = await apiClient.delete(`/api/virtual-card/${id}`);
    return { success: res.success !== false };
  },
};

// ==========================================
// 🧛 SUBSCRIPTION & VAMPIRE DRAIN API
// ==========================================
export interface Subscription {
  id?: number;
  name: string;
  amount: number;
  billingCycle: 'monthly' | 'yearly' | 'weekly' | string;
  category: string;
  nextBillingDate: string;
  reminderDays: number;
  isActive: boolean;
  color?: string;
  iconName?: string;
}

export const subscriptionAPI = {
  async getAll(): Promise<{ data: Subscription[] }> {
    const res = await apiClient.get('/api/subscriptions');
    return { data: Array.isArray(res.data) ? res.data : (Array.isArray(res) ? res : []) };
  },
  async create(data: Partial<Subscription>): Promise<{ data: Subscription }> {
    const res = await apiClient.post('/api/subscriptions', data);
    return { data: res.data || res };
  },
  async update(id: number, data: Partial<Subscription>): Promise<{ data: Subscription }> {
    const res = await apiClient.put(`/api/subscriptions/${id}`, data);
    return { data: res.data || res };
  },
  async delete(id: number): Promise<{ success: boolean }> {
    const res = await apiClient.delete(`/api/subscriptions/${id}`);
    return { success: res.success !== false };
  },
  async autoDetect(): Promise<{ data: Subscription[] }> {
    const res = await apiClient.post('/api/subscriptions/auto-detect', {});
    return { data: Array.isArray(res.data) ? res.data : [] };
  },
};

// ==========================================
// 📄 INVOICING & PAYMENT QR API
// ==========================================
export interface InvoiceItem {
  id?: number;
  description: string;
  quantity: number;
  unitPrice: number;
}

export interface Invoice {
  id?: number;
  invoiceNo: string;
  clientName: string;
  clientEmail?: string;
  clientPhone?: string;
  upiId?: string;
  issueDate: string;
  dueDate?: string;
  status: 'paid' | 'unpaid' | 'overdue' | string;
  taxRate: number;
  notes?: string;
  items: InvoiceItem[];
  totalAmount: number;
}

export const invoiceAPI = {
  async getAll(): Promise<{ data: Invoice[] }> {
    const res = await apiClient.get('/api/invoices');
    return { data: Array.isArray(res.data) ? res.data : (Array.isArray(res) ? res : []) };
  },
  async create(data: Partial<Invoice>): Promise<{ data: Invoice }> {
    const res = await apiClient.post('/api/invoices', data);
    return { data: res.data || res };
  },
  async update(id: number, data: Partial<Invoice>): Promise<{ data: Invoice }> {
    const res = await apiClient.put(`/api/invoices/${id}`, data);
    return { data: res.data || res };
  },
  async delete(id: number): Promise<{ success: boolean }> {
    const res = await apiClient.delete(`/api/invoices/${id}`);
    return { success: res.success !== false };
  },
};