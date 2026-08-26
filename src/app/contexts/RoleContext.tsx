import { createContext, useContext, useState, useEffect, ReactNode } from "react";
import { useAuth } from "./AuthContext";

export type Role = "business" | "student" | "home" | "freelancer" | null;

export interface RoleCategory {
  id: string;
  name: string;
  color: string;
  incomeType?: boolean;
}

const ROLE_CATEGORIES: Record<string, RoleCategory[]> = {
  business: [
    { id: "revenue", name: "Revenue / Sales", color: "#10b981", incomeType: true },
    { id: "supplier", name: "Supplier Payment", color: "#f59e0b" },
    { id: "payroll", name: "Payroll / Salaries", color: "#3b82f6" },
    { id: "operations", name: "Operations", color: "#8b5cf6" },
    { id: "tax_gst", name: "Tax / GST", color: "#ef4444" },
    { id: "marketing", name: "Marketing & Ads", color: "#ec4899" },
    { id: "inventory", name: "Inventory / Stock", color: "#06b6d4" },
    { id: "office", name: "Office Utilities", color: "#84cc16" },
    { id: "loan_emi", name: "Business Loan EMI", color: "#f97316" },
    { id: "other_income", name: "Other Income", color: "#22c55e", incomeType: true },
  ],
  student: [
    { id: "pocket_money", name: "Pocket Money", color: "#06b6d4", incomeType: true },
    { id: "part_time", name: "Part-time Income", color: "#22c55e", incomeType: true },
    { id: "food_delivery", name: "Food Delivery", color: "#ef4444" },
    { id: "subscriptions", name: "Subscriptions", color: "#7c3aed" },
    { id: "study", name: "Study Expenses", color: "#3b82f6" },
    { id: "transport", name: "Transport / Auto", color: "#10b981" },
    { id: "entertainment", name: "Entertainment", color: "#f59e0b" },
    { id: "clothing", name: "Clothing / Accessories", color: "#ec4899" },
    { id: "savings_transfer", name: "Savings Transfer", color: "#84cc16" },
  ],
  home: [
    { id: "salary_income", name: "Salary / Income", color: "#10b981", incomeType: true },
    { id: "groceries", name: "Groceries", color: "#f59e0b" },
    { id: "electricity", name: "Electricity Bill", color: "#ef4444" },
    { id: "water", name: "Water Bill", color: "#3b82f6" },
    { id: "gas_lpg", name: "Gas / LPG", color: "#84cc16" },
    { id: "internet", name: "Internet / Cable", color: "#8b5cf6" },
    { id: "dining", name: "Dining Out", color: "#ec4899" },
    { id: "school_fees", name: "School Fees", color: "#06b6d4" },
    { id: "household", name: "Household Items", color: "#f97316" },
    { id: "vehicle_fuel", name: "Vehicle / Fuel", color: "#a855f7" },
    { id: "medical", name: "Medical / Health", color: "#22c55e" },
  ],
  freelancer: [
    { id: "client_payment", name: "Client Payment", color: "#7c3aed", incomeType: true },
    { id: "retainer", name: "Monthly Retainer", color: "#10b981", incomeType: true },
    { id: "project_expense", name: "Project Expense", color: "#ef4444" },
    { id: "tools_software", name: "Tools & Software", color: "#3b82f6" },
    { id: "coworking", name: "Coworking / Office", color: "#06b6d4" },
    { id: "tax_advance", name: "Advance Tax", color: "#f59e0b" },
    { id: "self_marketing", name: "Self Marketing", color: "#ec4899" },
    { id: "equipment", name: "Equipment", color: "#84cc16" },
    { id: "professional_dev", name: "Professional Dev", color: "#8b5cf6" },
    { id: "internet_phone", name: "Internet / Phone", color: "#f97316" },
  ],
};

const ROLE_GOAL_TEMPLATES: Record<string, string[]> = {
  business: [
    "Business Expansion Fund",
    "Emergency Reserve (3 months ops)",
    "Tax Payment Reserve",
    "Equipment / Tech Upgrade",
    "Marketing Campaign Budget",
    "New Product Launch Fund",
  ],
  student: [
    "Laptop / Phone Fund",
    "Trip / Vacation Fund",
    "Emergency Savings",
    "Skill Course / Certification",
    "Gadget / Accessories",
    "Semester Expenses Buffer",
  ],
  home: [
    "Summer Vacation",
    "Home Renovation",
    "Emergency Fund (6 months)",
    "Children Education Fund",
    "Vehicle Purchase",
    "Festival / Wedding Fund",
  ],
  freelancer: [
    "Tax Reserve (Q2 Advance)",
    "Equipment / Studio Upgrade",
    "Business Travel Fund",
    "Skill Development Budget",
    "Emergency Income Buffer",
    "Retirement / SIP Corpus",
  ],
};

interface RoleContextType {
  role: Role;
  setRole: (role: Role) => void;
  clearRole: () => void;
  roleCategories: RoleCategory[];
  goalTemplates: string[];
}

const RoleContext = createContext<RoleContextType | undefined>(undefined);

function getRoleKey(email?: string) {
  return `financeai_role_${email || "guest"}`;
}

export function RoleProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [role, setRoleState] = useState<Role>(() => {
    const key = getRoleKey(user?.email);
    return (localStorage.getItem(key) as Role) || null;
  });

  // When user changes (login/logout/switch), reload their role from localStorage
  useEffect(() => {
    const key = getRoleKey(user?.email);
    setRoleState((localStorage.getItem(key) as Role) || null);
  }, [user?.email]);

  const setRole = (r: Role) => {
    const key = getRoleKey(user?.email);
    if (r) localStorage.setItem(key, r);
    setRoleState(r);
  };

  const clearRole = () => {
    const key = getRoleKey(user?.email);
    localStorage.removeItem(key);
    setRoleState(null);
  };

  const roleCategories = role ? (ROLE_CATEGORIES[role] ?? []) : [];
  const goalTemplates = role ? (ROLE_GOAL_TEMPLATES[role] ?? []) : [];

  return (
    <RoleContext.Provider value={{ role, setRole, clearRole, roleCategories, goalTemplates }}>
      {children}
    </RoleContext.Provider>
  );
}

export function useRole() {
  const ctx = useContext(RoleContext);
  if (!ctx) {
    return {
      role: null,
      setRole: () => {},
      clearRole: () => {},
      roleCategories: [],
      goalTemplates: [],
    };
  }
  return ctx;
}
