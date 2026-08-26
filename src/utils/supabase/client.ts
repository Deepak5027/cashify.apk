// Supabase client removed — types only (backend migrated to Express + SQLite)

// Type definitions for database models
export type Transaction = {
  id: string;
  user_id: string;
  merchant: string;
  amount: number;
  category: string;
  date: string;
  type: 'income' | 'expense';
  payment_mode: string;
  risk_score: number;
  status: 'normal' | 'suspicious';
  notes?: string;
  receipt_url?: string;
  created_at: string;
};

export type Budget = {
  id: string;
  user_id: string;
  category: string;
  limit: number;
  spent: number;
  period: 'monthly' | 'weekly' | 'yearly';
  created_at: string;
};

export type Goal = {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  deadline: string;
  category: string;
  created_at: string;
};

export type Investment = {
  id: string;
  user_id: string;
  name: string;
  type: 'stock' | 'mutual_fund' | 'sip' | 'fd' | 'gold';
  amount: number;
  current_value: number;
  purchase_date: string;
  created_at: string;
};
