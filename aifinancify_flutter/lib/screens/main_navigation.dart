import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'analytics_screen.dart';
import '../state/auth_provider.dart';
import '../state/profile_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      TransactionsScreen(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      BudgetScreen(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      GoalsScreen(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
      AnalyticsScreen(onMenuPressed: () => _scaffoldKey.currentState?.openDrawer()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final userName = profileProvider.profile?.name ?? authUser?['name'] ?? 'User';
    final userEmail = profileProvider.profile?.email ?? authUser?['email'] ?? 'user@example.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),

            // Navigation Items
            _buildDrawerTile(Icons.dashboard_rounded, "Dashboard", 0),
            _buildDrawerTile(Icons.receipt_long_rounded, "Transactions", 1),
            _buildDrawerTile(Icons.pie_chart_rounded, "Monthly Budget", 2),
            _buildDrawerTile(Icons.flag_rounded, "Savings Goals", 3),
            _buildDrawerTile(Icons.analytics_rounded, "Financial Analytics", 4),

            const Divider(color: Colors.white12, height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Text("SMART AI TOOLS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),

            _buildActionTile(Icons.credit_card, "Multi-Card Wallet", '/virtual-card', const Color(0xFF6366F1)),
            _buildActionTile(Icons.picture_as_pdf, "Statements & Invoices", '/statements', const Color(0xFFF59E0B)),
            _buildActionTile(Icons.camera_alt, "OCR Receipt Scanner", '/scanner', const Color(0xFF818CF8)),
            _buildActionTile(Icons.mic, "Voice Expense Logger", '/voice-entry', const Color(0xFFA855F7)),
            _buildActionTile(Icons.message, "Indian UPI Import", '/upi-import', const Color(0xFF10B981)),
            _buildActionTile(Icons.file_upload, "Bank Statement CSV", '/bank-import', const Color(0xFF14B8A6)),
            _buildActionTile(Icons.smart_toy, "AI Chatbot Advisor", '/chatbot', const Color(0xFF3B82F6)),
            _buildActionTile(Icons.trending_up, "AI Spend Predictions", '/predictions', const Color(0xFF06B6D4)),
            _buildActionTile(Icons.psychology, "Smart Insights", '/insights', const Color(0xFFF43F5E)),
            _buildActionTile(Icons.calculate, "Financial Calculators", '/calculator', const Color(0xFFF97316)),
            _buildActionTile(Icons.security, "Fraud & Risk Alerts", '/alerts', const Color(0xFFEF4444)),

            const Divider(color: Colors.white12, height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 6),
              child: Text("MANAGEMENT & SYSTEM", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),

            _buildActionTile(Icons.admin_panel_settings, "Admin Analytics", '/admin', const Color(0xFF8B5CF6)),
            _buildActionTile(Icons.person, "User Profile", '/profile', const Color(0xFF60A5FA)),
            _buildActionTile(Icons.settings, "Settings & Preferences", '/settings', const Color(0xFF94A3B8)),
            _buildActionTile(Icons.menu_book, "How It Works Guide", '/how-it-works', const Color(0xFF2DD4BF)),

            const Divider(color: Colors.white12, height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text("Log Out", style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          border: Border(top: BorderSide(color: Color(0xFF1F2937))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF111827),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF818CF8),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Budgets'),
            BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'Goals'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8), size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF818CF8) : Colors.white,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }

  Widget _buildActionTile(IconData icon, String title, String route, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF64748B)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
