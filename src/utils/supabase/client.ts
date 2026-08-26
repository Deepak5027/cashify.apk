import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = (import.meta as any).env?.VITE_SUPABASE_URL || 'https://wmfbbapborfpcixxxiab.supabase.co';
const SUPABASE_ANON_KEY = (import.meta as any).env?.VITE_SUPABASE_ANON_KEY || 'sb_publishable_dHRS1PLqBue2PVzl5GNz6g_4iEb3S30';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

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
