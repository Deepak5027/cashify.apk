import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../state/auth_provider.dart';
import '../state/profile_provider.dart';
import '../state/transaction_provider.dart';
import '../state/budget_provider.dart';
import '../state/goal_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _isSeeding = false;
  final ApiService _api = ApiService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricPrefKey = 'pref_biometric_lock_enabled';

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool(_biometricPrefKey) ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enable) {
      await prefs.setBool(_biometricPrefKey, false);
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Biometric Lock disabled."), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    // Attempting to enable - verify hardware & prompt authentication
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics && !isDeviceSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric authentication (fingerprint/face) is not supported on this device."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or face to enable Biometric Lock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await prefs.setBool(_biometricPrefKey, true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric Lock successfully enabled! Your app is secured."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric authentication was cancelled or not recognized."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Biometric setup error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    try {
      final success = await _api.seedDemoData();
      if (success) {
        // Refresh all providers
        final txProvider = context.read<TransactionProvider>();
        await txProvider.fetchTransactions();
        if (mounted) {
          context.read<BudgetProvider>().fetchBudgets(txProvider.transactions);
          context.read<GoalProvider>().fetchGoals();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Demo transactions & budgets seeded successfully!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Seeding failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Backend Server Configuration", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set the backend API host IP address for local network testing or cloud URL:",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: "Server Base URL",
                labelStyle: TextStyle(color: Colors.white54),
                hintText: "http://10.34.0.116:4000",
                filled: true,
                fillColor: Color(0xFF0B0F19),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text("Wi-Fi (10.34.0.116)", style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = "http://10.34.0.116:4000",
                ),
                ActionChip(
                  label: const Text("USB ADB (localhost)", style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = "http://localhost:4000",
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await _api.updateBaseUrl(newUrl);
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Server URL updated to $newUrl"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text("Save URL"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authUser = context.watch<AuthProvider>().user;
    final currency = profileProvider.currency;

    final userName = profileProvider.profile?.name ?? authUser?['name'] ?? 'User';
    final userEmail = profileProvider.profile?.email ?? authUser?['email'] ?? 'user@example.com';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text("Settings & Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card Profile Link
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(userEmail, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Connectivity & Server Section
          _buildSectionHeader("Cloud Sync & Database Connection"),
          const SizedBox(height: 8),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: Color(0xFF10B981)),
              title: const Text("Cloud Account Sync & Restore", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text("Bound to: $userEmail", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF312E81),
                  foregroundColor: const Color(0xFFA5B4FC),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final txProvider = context.read<TransactionProvider>();
                  await txProvider.fetchTransactions();
                  if (context.mounted) {
                    context.read<BudgetProvider>().fetchBudgets(txProvider.transactions);
                    context.read<GoalProvider>().fetchGoals();
                    context.read<ProfileProvider>().fetchProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text("Cloud data synchronized with email account!"),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync, size: 14),
                label: const Text("Sync Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.dns_outlined, color: Color(0xFF818CF8)),
              title: const Text("Backend Server IP", style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(ApiService.baseUrl, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.edit, color: Colors.white54, size: 16),
              onTap: _showServerConfigDialog,
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.storage_outlined, color: Colors.blueAccent),
              title: const Text("Seed Demo Data", style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text("Populate mock transactions, budgets & goals", style: TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: _isSeeding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_download_outlined, color: Colors.white54),
              onTap: _isSeeding ? null : _seedDemoData,
            ),
          ]),
          const SizedBox(height: 20),

          // Regional & Preferences
          _buildSectionHeader("Regional & Preferences"),
          const SizedBox(height: 8),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.currency_exchange, color: Colors.greenAccent),
              title: const Text("Currency Symbol", style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text("Current: $currency", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            const Divider(color: Colors.white12, height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: Colors.amberAccent),
              title: const Text("Biometric Lock (Face/Fingerprint)", style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(_biometricEnabled ? "Active & Enforced" : "Disabled", style: TextStyle(color: _biometricEnabled ? Colors.greenAccent : Colors.white38, fontSize: 11)),
              value: _biometricEnabled,
              activeColor: const Color(0xFF6366F1),
              onChanged: _toggleBiometrics,
            ),
          ]),
          const SizedBox(height: 20),

          // Documentation & Tools
          _buildSectionHeader("Information & Tools"),
          const SizedBox(height: 8),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.tealAccent),
              title: const Text("How AiFinancify Works", style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              onTap: () => Navigator.pushNamed(context, '/how-it-works'),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.purpleAccent),
              title: const Text("Executive Admin Analytics", style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              onTap: () => Navigator.pushNamed(context, '/admin'),
            ),
          ]),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold));
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }
}
