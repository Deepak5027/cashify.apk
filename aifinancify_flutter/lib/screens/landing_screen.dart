import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  int _selectedPersonaIndex = 0;
  late AnimationController _animController;
  late Animation<double> _glowAnimation;

  final List<Map<String, dynamic>> _personas = [
    {
      'title': 'Business Owner',
      'tagline': 'Profit-driven cash flow foresight & P&L control',
      'icon': Icons.business_center_rounded,
      'color': const Color(0xFF10B981),
      'badge': 'ENTERPRISE GRADE',
      'stat': '₹28,400/mo',
      'statLabel': 'Avg. Business Savings',
      'points': [
        'Real-time P&L analytics & vendor runway',
        'GST & advance tax liability estimator',
        '6-month predictive Holt cash flow runway',
      ],
    },
    {
      'title': 'Student',
      'tagline': 'Smart money habits for high-impact futures',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF38BDF8),
      'badge': 'COLLEGE READY',
      'stat': '₹3,200/mo',
      'statLabel': 'Pocket Allowance Saved',
      'points': [
        'Daily burn-rate limits & food spend tracker',
        'Smart multi-card spend & limit controls',
        'Gamified milestone savings challenges',
      ],
    },
    {
      'title': 'Home Manager',
      'tagline': 'Run your household finances like a Fortune 500 CFO',
      'icon': Icons.home_rounded,
      'color': const Color(0xFFF59E0B),
      'badge': 'FAMILY FIRST',
      'stat': '₹6,800/mo',
      'statLabel': 'Family Surplus Growth',
      'points': [
        'Smart grocery list optimizer with price alerts',
        'Electricity, tuition & utility bill calendar',
        'Long-term family emergency cushion builder',
      ],
    },
    {
      'title': 'Freelancer',
      'tagline': 'Total financial clarity with irregular income streams',
      'icon': Icons.laptop_chromebook_rounded,
      'color': const Color(0xFFA855F7),
      'badge': 'CREATOR ECONOMY',
      'stat': '+62% Smoothed',
      'statLabel': 'Income Predictability',
      'points': [
        'Irregular income smoothing & safe-spend envelope',
        'Client invoice status tracker & overdue nudges',
        'Advance tax estimator with quarterly countdown',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePersona = _personas[_selectedPersonaIndex];
    final activeColor = activePersona['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Background ambient gradient orbs
          Positioned(
            top: -100,
            left: -80,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 320 * _glowAnimation.value,
                height: 320 * _glowAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 300 * _glowAnimation.value,
                height: 300 * _glowAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      activeColor.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Top Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "AI-POWERED FINANCIAL SUITE 2.0",
                          style: TextStyle(
                            color: Color(0xFFC7D2FE),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Hero App Logo with Glowing Halo
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 82,
                          height: 82,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 42,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Hero Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: "Ai",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF818CF8),
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: "Financify",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Smart Cash Flow, Clear Choices",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7D2FE),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Automate receipt scanning, voice expense tracking, Holt predictive budgeting, and fraud detection with on-device AI.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Primary Call-To-Action Buttons (Vertical Stack to guarantee zero overflow on any device width)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Login to Account",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Create Free Account",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC7D2FE)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Interactive Persona Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1F2937)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_personas.length, (index) {
                          final p = _personas[index];
                          final isSelected = _selectedPersonaIndex == index;
                          final color = p['color'] as Color;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedPersonaIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? Border.all(color: color.withOpacity(0.6)) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    p['icon'] as IconData,
                                    size: 16,
                                    color: isSelected ? color : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    p['title'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dynamic Persona Feature Spotlight Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C31),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: activeColor.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: activeColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                activePersona['badge'] as String,
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  activePersona['stat'] as String,
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  activePersona['statLabel'] as String,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activePersona['tagline'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF1E293B), height: 1),
                        const SizedBox(height: 14),
                        ...(activePersona['points'] as List<String>).map((point) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Highlights & Visual Features
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Cutting-Edge AI Modules",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        "100% On-Device",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Feature Cards
                  _buildHighlightCard(
                    icon: Icons.document_scanner_rounded,
                    color: const Color(0xFF6366F1),
                    title: "Google ML Kit OCR Scanner",
                    tag: "ON-DEVICE VISION",
                    description: "Point your camera at paper bills or invoices. Fast on-device text parsing automatically detects vendor, date, and grand totals.",
                  ),
                  _buildHighlightCard(
                    icon: Icons.mic_rounded,
                    color: const Color(0xFFA855F7),
                    title: "Natural Language Voice Logger",
                    tag: "AUDIO SPEECH NLP",
                    description: "Speak naturally ('Spent 450 rupees on dinner at Starbucks'). Filler words are removed and transaction fields are auto-populated.",
                  ),
                  _buildHighlightCard(
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF14B8A6),
                    title: "Holt's Exponential Smoothing",
                    tag: "CASH FLOW PREDICTION",
                    description: "Calculates mathematical trend forecasting across past historical entries to predict next month's expense ceiling and safe runway.",
                  ),
                  _buildHighlightCard(
                    icon: Icons.security_rounded,
                    color: const Color(0xFFEF4444),
                    title: "Heuristic Fraud & Anomaly Shield",
                    tag: "RISK DETECTION",
                    description: "Flags duplicate transactions, abnormal velocity spikes, and suspicious merchant keywords with multi-tier risk scores.",
                  ),

                  const SizedBox(height: 24),

                  // Trust & Privacy Footer Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Bank-Grade Encryption & Offline First",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Your financial records are stored securely on your device with local fallback and private token encryption.",
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String tag,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      tag,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
