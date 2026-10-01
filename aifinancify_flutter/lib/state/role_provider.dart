import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleCategory {
  final String id;
  final String name;
  final String color;
  final bool incomeType;

  RoleCategory({
    required this.id,
    required this.name,
    required this.color,
    this.incomeType = false,
  });
}

class RoleProvider extends ChangeNotifier {
  String? _role; // 'business' | 'student' | 'home' | 'freelancer' | null
  String? _userEmail;

  static final Map<String, List<RoleCategory>> roleCategoriesMap = {
    'business': [
      RoleCategory(id: 'revenue', name: 'Revenue / Sales', color: '#10b981', incomeType: true),
      RoleCategory(id: 'supplier', name: 'Supplier Payment', color: '#f59e0b'),
      RoleCategory(id: 'payroll', name: 'Payroll / Salaries', color: '#3b82f6'),
      RoleCategory(id: 'operations', name: 'Operations', color: '#8b5cf6'),
      RoleCategory(id: 'tax_gst', name: 'Tax / GST', color: '#ef4444'),
      RoleCategory(id: 'marketing', name: 'Marketing & Ads', color: '#ec4899'),
      RoleCategory(id: 'inventory', name: 'Inventory / Stock', color: '#06b6d4'),
      RoleCategory(id: 'office', name: 'Office Utilities', color: '#84cc16'),
      RoleCategory(id: 'loan_emi', name: 'Business Loan EMI', color: '#f97316'),
      RoleCategory(id: 'other_income', name: 'Other Income', color: '#22c55e', incomeType: true),
    ],
    'student': [
      RoleCategory(id: 'pocket_money', name: 'Pocket Money', color: '#06b6d4', incomeType: true),
      RoleCategory(id: 'part_time', name: 'Part-time Income', color: '#22c55e', incomeType: true),
      RoleCategory(id: 'food_delivery', name: 'Food Delivery', color: '#ef4444'),
      RoleCategory(id: 'digital_tools', name: 'Digital & Mobile Tools', color: '#7c3aed'),
      RoleCategory(id: 'study', name: 'Study Expenses', color: '#3b82f6'),
      RoleCategory(id: 'transport', name: 'Transport / Auto', color: '#10b981'),
      RoleCategory(id: 'entertainment', name: 'Entertainment', color: '#f59e0b'),
      RoleCategory(id: 'clothing', name: 'Clothing / Accessories', color: '#ec4899'),
      RoleCategory(id: 'savings_transfer', name: 'Savings Transfer', color: '#84cc16'),
    ],
    'home': [
      RoleCategory(id: 'salary_income', name: 'Salary / Income', color: '#10b981', incomeType: true),
      RoleCategory(id: 'groceries', name: 'Groceries', color: '#f59e0b'),
      RoleCategory(id: 'electricity', name: 'Electricity Bill', color: '#ef4444'),
      RoleCategory(id: 'water', name: 'Water Bill', color: '#3b82f6'),
      RoleCategory(id: 'gas_lpg', name: 'Gas / LPG', color: '#84cc16'),
      RoleCategory(id: 'internet', name: 'Internet / Cable', color: '#8b5cf6'),
      RoleCategory(id: 'dining', name: 'Dining Out', color: '#ec4899'),
      RoleCategory(id: 'school_fees', name: 'School Fees', color: '#06b6d4'),
      RoleCategory(id: 'household', name: 'Household Items', color: '#f97316'),
      RoleCategory(id: 'vehicle_fuel', name: 'Vehicle / Fuel', color: '#a855f7'),
      RoleCategory(id: 'medical', name: 'Medical / Health', color: '#22c55e'),
    ],
    'freelancer': [
      RoleCategory(id: 'client_payment', name: 'Client Payment', color: '#7c3aed', incomeType: true),
      RoleCategory(id: 'retainer', name: 'Monthly Retainer', color: '#10b981', incomeType: true),
      RoleCategory(id: 'project_expense', name: 'Project Expense', color: '#ef4444'),
      RoleCategory(id: 'tools_software', name: 'Tools & Software', color: '#3b82f6'),
      RoleCategory(id: 'coworking', name: 'Coworking / Office', color: '#06b6d4'),
      RoleCategory(id: 'tax_advance', name: 'Advance Tax', color: '#f59e0b'),
      RoleCategory(id: 'self_marketing', name: 'Self Marketing', color: '#ec4899'),
      RoleCategory(id: 'equipment', name: 'Equipment', color: '#84cc16'),
      RoleCategory(id: 'professional_dev', name: 'Professional Dev', color: '#8b5cf6'),
      RoleCategory(id: 'internet_phone', name: 'Internet / Phone', color: '#f97316'),
    ],
  };

  static final Map<String, List<String>> roleGoalTemplatesMap = {
    'business': [
      "Business Expansion Fund",
      "Emergency Reserve (3 months ops)",
      "Tax Payment Reserve",
      "Equipment / Tech Upgrade",
      "Marketing Campaign Budget",
      "New Product Launch Fund",
    ],
    'student': [
      "Laptop / Phone Fund",
      "Trip / Vacation Fund",
      "Emergency Savings",
      "Skill Course / Certification",
      "Gadget / Accessories",
      "Semester Expenses Buffer",
    ],
    'home': [
      "Summer Vacation",
      "Home Renovation",
      "Emergency Fund (6 months)",
      "Children Education Fund",
      "Vehicle Purchase",
      "Festival / Wedding Fund",
    ],
    'freelancer': [
      "Tax Reserve (Q2 Advance)",
      "Equipment / Studio Upgrade",
      "Business Travel Fund",
      "Skill Development Budget",
      "Emergency Income Buffer",
      "Retirement / SIP Corpus",
    ],
  };

  String? get role => _role;
  List<RoleCategory> get roleCategories => _role != null ? (roleCategoriesMap[_role] ?? []) : [];
  List<String> get goalTemplates => _role != null ? (roleGoalTemplatesMap[_role] ?? []) : [];

  void updateEmail(String? email) {
    if (_userEmail != email) {
      _userEmail = email;
      _loadRole();
    }
  }

  String _getRoleKey() {
    return 'financeai_role_${_userEmail ?? "guest"}';
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(_getRoleKey());
    notifyListeners();
  }

  Future<void> setRole(String? newRole) async {
    final prefs = await SharedPreferences.getInstance();
    if (newRole != null) {
      await prefs.setString(_getRoleKey(), newRole);
    } else {
      await prefs.remove(_getRoleKey());
    }
    _role = newRole;
    notifyListeners();
  }

  Future<void> clearRole() async {
    await setRole(null);
  }
}
