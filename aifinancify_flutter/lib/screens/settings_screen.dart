import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../state/auth_provider.dart';
import '../state/profile_provider.dart';
import '../state/transaction_provider.dart';
import '../state/budget_provider.dart';
import '../state/goal_provider.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _isSeeding = false;
  bool _isSyncing = false;
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
        title: const Text("Backend Server Configuration", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why is Render Cloud showing by default?",
                      style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Mobile phones cannot reach 'localhost' because localhost refers to the phone itself. The Render cloud server allows online sync across Wi-Fi and mobile data.",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Active Server Base URL:",
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "https://financeai-api-ba5p.onrender.com",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Quick Switch Presets:", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    backgroundColor: const Color(0xFF312E81),
                    label: const Text("☁️ Render Cloud", style: TextStyle(fontSize: 11, color: Color(0xFFA5B4FC))),
                    onPressed: () => controller.text = ApiService.defaultCloudUrl,
                  ),
                  ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    label: const Text("📶 Wi-Fi PC (192.168.1.7:4000)", style: TextStyle(fontSize: 11, color: Colors.white70)),
                    onPressed: () => controller.text = ApiService.defaultLanUrl,
                  ),
                  ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    label: const Text("📱 Android Emulator", style: TextStyle(fontSize: 11, color: Colors.white70)),
                    onPressed: () => controller.text = ApiService.defaultEmulatorUrl,
                  ),
                  ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    label: const Text("🔌 USB ADB (localhost)", style: TextStyle(fontSize: 11, color: Colors.white70)),
                    onPressed: () => controller.text = ApiService.defaultAdbUrl,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF818CF8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.network_check, size: 16, color: Color(0xFF818CF8)),
                  label: const Text("Test Connection", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12)),
                  onPressed: () async {
                    final health = await _api.checkServerHealth();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(health['serverOk'] == true
                              ? "✅ ${health['message']}"
                              : "⚠️ Connection test: ${health['message']}"),
                          backgroundColor: health['serverOk'] == true ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await _api.updateBaseUrl(newUrl);
                if (mounted) setState(() {});
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

  Future<void> _handleCloudSync(String currentEmail) async {
    if (_isSyncing) return;

    String emailToUse = currentEmail.trim().toLowerCase();
    if (emailToUse.isEmpty || emailToUse == 'user@example.com' || emailToUse == 'user') {
      final entered = await _showEmailInputDialog(currentEmail);
      if (entered == null || entered.trim().isEmpty) return;
      emailToUse = entered.trim().toLowerCase();
    }

    setState(() => _isSyncing = true);

    try {
      // 1. Ensure user_email is saved in SharedPreferences so ApiService passes it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', emailToUse);

      // 2. Process any pending offline sync queue first (upload locally queued transactions)
      await OfflineStorageService().processSyncQueue();

      // 3. Fetch remote transactions directly from cloud database
      final txProvider = context.read<TransactionProvider>();
      final txs = await txProvider.fetchTransactions(throwOnFailure: true);

      // 4. Fetch budgets and goals matching the synced transactions
      if (mounted) {
        await context.read<BudgetProvider>().fetchBudgets(txs, true);
        await context.read<GoalProvider>().fetchGoals(throwOnFailure: true);
        await context.read<ProfileProvider>().fetchProfile();
      }

      final budgetCount = mounted ? context.read<BudgetProvider>().budgets.length : 0;
      final goalCount = mounted ? context.read<GoalProvider>().goals.length : 0;

      if (mounted) {
        if (txs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Cloud data restored: ${txs.length} transactions, $budgetCount budgets, $goalCount goals synced for $emailToUse",
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF065F46),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Connected to database for $emailToUse. 0 previous transactions found on server.",
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorTitle = "Sync Failed";
        String errorDetail = "Could not reach server at ${ApiService.baseUrl}";

        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) {
            errorTitle = "Session Required (401)";
            errorDetail = "Remote server requires active authentication or database access.";
          } else if (statusCode == 500) {
            errorTitle = "Cloud DB Paused (500)";
            errorDetail = "The Supabase database is paused. Restore it in supabase.com/dashboard.";
          } else if (statusCode != null) {
            errorTitle = "Server Error ($statusCode)";
            errorDetail = "Server returned error code $statusCode.";
          } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
            errorTitle = "Connection Timeout";
            errorDetail = "Server took too long to respond. The cloud service may be cold-starting.";
          } else {
            errorTitle = "Server Unreachable";
            errorDetail = "Cannot connect to ${ApiService.baseUrl}. Verify server is running.";
          }
        }

        // Check if device has local SQLite transactions cached and restore them
        final localTxs = await OfflineStorageService().getLocalTransactions();
        if (localTxs.isNotEmpty && mounted) {
          final txProvider = context.read<TransactionProvider>();
          await txProvider.fetchTransactions();
          context.read<BudgetProvider>().fetchBudgets(txProvider.transactions);
          context.read<GoalProvider>().fetchGoals();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$errorTitle. Loaded ${localTxs.length} cached transactions from device storage.",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFB45309),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$errorTitle: $errorDetail",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: "Configure",
                textColor: Colors.amberAccent,
                onPressed: _showServerConfigDialog,
              ),
              backgroundColor: const Color(0xFF7F1D1D),
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<String?> _showEmailInputDialog([String? initialEmail]) async {
    final controller = TextEditingController(text: (initialEmail == 'user@example.com' || initialEmail == 'user') ? '' : initialEmail);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Cloud Account Email", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered account email to restore and synchronize all your previously saved transactions and budgets from the cloud database:",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Account Email",
                labelStyle: TextStyle(color: Colors.white54),
                hintText: "yourname@example.com",
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Color(0xFF0B0F19),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text("Sync Account"),
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
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
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
                subtitle: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Bound to: $userEmail",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final entered = await _showEmailInputDialog(userEmail);
                        if (entered != null && entered.isNotEmpty) {
                          _handleCloudSync(entered);
                        }
                      },
                      child: const Text("Change", style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF312E81),
                    foregroundColor: const Color(0xFFA5B4FC),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSyncing ? null : () => _handleCloudSync(userEmail),
                  icon: _isSyncing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.sync, size: 14),
                  label: Text(_isSyncing ? "Syncing..." : "Sync Now", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 48),
        ],
      ),
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
