import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'state/auth_provider.dart';
import 'state/transaction_provider.dart';
import 'state/budget_provider.dart';
import 'state/goal_provider.dart';
import 'state/profile_provider.dart';
import 'state/role_provider.dart';
import 'state/virtual_card_provider.dart';
import 'state/invoice_provider.dart';

import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/transactions_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/voice_entry_screen.dart';
import 'screens/bank_import_screen.dart';
import 'screens/upi_import_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/ai_predictions_screen.dart';
import 'screens/smart_insights_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/virtual_card_screen.dart';
import 'screens/statements_invoicing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gracefully suppress any debug overflow banners across the entire application
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final bool isOverflow = details.exceptionAsString().contains('overflowed by');
    if (isOverflow) {
      return const SizedBox.shrink();
    }
    return Material(
      color: const Color(0xFF0B0F19),
      child: Center(
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  runApp(const AiFinancifyApp());
}

class AiFinancifyApp extends StatelessWidget {
  const AiFinancifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => VirtualCardProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'AiFinancify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: auth.isLoading
                ? const Scaffold(
                    backgroundColor: Color(0xFF0B0F19),
                    body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                  )
                : auth.isAuthenticated
                    ? const MainNavigation()
                    : const LandingScreen(),
            routes: {
              '/app': (context) => const MainNavigation(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/email-verification': (context) => const EmailVerificationScreen(),
              '/dashboard': (context) => const MainNavigation(),
              '/transactions': (context) => const TransactionsScreen(),
              '/budget': (context) => const BudgetScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/alerts': (context) => const AlertsScreen(),
              '/scanner': (context) => const ScannerScreen(),
              '/voice-entry': (context) => const VoiceEntryScreen(),
              '/bank-import': (context) => const BankImportScreen(),
              '/upi-import': (context) => const UpiImportScreen(),
              '/chatbot': (context) => const ChatbotScreen(),
              '/predictions': (context) => const AIPredictionsScreen(),
              '/insights': (context) => const SmartInsightsScreen(),
              '/calculator': (context) => const CalculatorScreen(),
              '/admin': (context) => const AdminAnalyticsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/how-it-works': (context) => const HowItWorksScreen(),
              '/virtual-card': (context) => const VirtualCardScreen(),
              '/statements': (context) => const StatementsInvoicingScreen(),
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        },
      ),
    );
  }
}

