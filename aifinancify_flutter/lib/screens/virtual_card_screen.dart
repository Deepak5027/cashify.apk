import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/virtual_card.dart';
import '../state/virtual_card_provider.dart';
import '../state/profile_provider.dart';

class VirtualCardScreen extends StatefulWidget {
  const VirtualCardScreen({super.key});

  @override
  State<VirtualCardScreen> createState() => _VirtualCardScreenState();
}

class _VirtualCardScreenState extends State<VirtualCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;

  final Map<String, List<Color>> _cardThemes = {
    'indigo': [const Color(0xFF4F46E5), const Color(0xFF7C3AED), const Color(0xFF2E1065)],
    'emerald': [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF064E3B)],
    'rose': [const Color(0xFFE11D48), const Color(0xFFBE185D), const Color(0xFF881337)],
    'gold': [const Color(0xFFD97706), const Color(0xFFF59E0B), const Color(0xFF78350F)],
    'midnight': [const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF0F172A)],
  };

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<VirtualCardProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;
    final card = cardProvider.card;
    final cards = cardProvider.cards;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.credit_card, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Card Wallet & Spend Controls",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF818CF8)),
            tooltip: "Add Card",
            onPressed: () => _showAddCardDialog(context, cardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => cardProvider.fetchVirtualCard(),
          ),
        ],
      ),
      body: cardProvider.isLoading && cards.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Wallet Cards Selector Carousel
                if (cards.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "WALLET CARDS (${cards.length})",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddCardDialog(context, cardProvider),
                        icon: const Icon(Icons.add, size: 14, color: Color(0xFF818CF8)),
                        label: const Text("Add Card", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final c = cards[idx];
                        final isSelected = c.id == card.id;
                        final themeColors = _cardThemes[c.cardColor] ?? _cardThemes['indigo']!;

                        return InkWell(
                          onTap: () {
                            if (c.id != null) cardProvider.selectCard(c.id!);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8)]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: themeColors),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      c.cardNetwork,
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        c.cardName,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        c.cardNumber.length > 8 ? c.cardNumber.substring(c.cardNumber.length - 8) : c.cardNumber,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Card Header Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _flipCard,
                      child: Row(
                        children: [
                          const Icon(Icons.sync, size: 14, color: Color(0xFF818CF8)),
                          const SizedBox(width: 4),
                          Text(
                            _showBack ? "Showing Back (Tap to Flip)" : "Tap card to reveal CVV",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showEditCardDialog(context, cardProvider, card),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 12, color: Colors.white70),
                                SizedBox(width: 4),
                                Text("Edit Details", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        if (cards.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              if (card.id != null) {
                                cardProvider.deleteCard(card.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Card deleted from wallet")),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. 3D Interactive Flip Card
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * pi;
                      final isUnder = angle > pi / 2;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildCardBack(card),
                              )
                            : _buildCardFront(card),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Color Theme Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 18, color: Color(0xFF818CF8)),
                          SizedBox(width: 8),
                          Text("Card Skin", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: _cardThemes.keys.map((key) {
                          final isSelected = card.cardColor == key;
                          final colors = _cardThemes[key]!;
                          return GestureDetector(
                            onTap: () => cardProvider.updateColor(key),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: colors),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Monthly Spend Cap Gauge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("MONTHLY SPEND CAP", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                "$currency${card.currentSpend.toStringAsFixed(0)} / $currency${card.spendingLimit.toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showLimitDialog(context, cardProvider, card.spendingLimit),
                            icon: const Icon(Icons.edit, size: 14, color: Color(0xFF818CF8)),
                            label: const Text("Adjust Cap", style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF374151)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: card.spendPercentage,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF1F2937),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            card.spendPercentage > 0.85
                                ? const Color(0xFFEF4444)
                                : card.spendPercentage > 0.65
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${(card.spendPercentage * 100).toStringAsFixed(0)}% used",
                            style: TextStyle(
                              color: card.spendPercentage > 0.85 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "$currency${card.remainingBudget.toStringAsFixed(0)} remaining",
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Security Toggles Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF818CF8), size: 18),
                          SizedBox(width: 8),
                          Text("Card Security & Channels", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Freeze Switch
                      _buildSwitchTile(
                        icon: Icons.ac_unit,
                        iconColor: card.isFrozen ? Colors.redAccent : const Color(0xFF94A3B8),
                        title: card.isFrozen ? "Card Frozen (Locked)" : "Freeze Card",
                        subtitle: "Instantly lock card from transactions",
                        value: card.isFrozen,
                        activeColor: Colors.redAccent,
                        onChanged: (val) => cardProvider.toggleFreeze(),
                      ),
                      const Divider(color: Color(0xFF1F2937), height: 24),

                      // Contactless / Tap-to-Pay
                      _buildSwitchTile(
                        icon: Icons.wifi,
                        iconColor: card.tapToPayEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        title: "Contactless / Tap to Pay",
                        subtitle: "Enable POS tap and NFC payments",
                        value: card.tapToPayEnabled,
                        activeColor: const Color(0xFF10B981),
                        disabled: card.isFrozen,
                        onChanged: (val) => cardProvider.toggleTapToPay(),
                      ),
                      const Divider(color: Color(0xFF1F2937), height: 24),

                      // International Payments
                      _buildSwitchTile(
                        icon: Icons.public,
                        iconColor: card.internationalTx ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                        title: "International Payments",
                        subtitle: "Allow foreign currency transactions",
                        value: card.internationalTx,
                        activeColor: const Color(0xFF3B82F6),
                        disabled: card.isFrozen,
                        onChanged: (val) => cardProvider.toggleInternational(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildCardFront(VirtualCardModel card) {
    final colors = _cardThemes[card.cardColor] ?? _cardThemes['indigo']!;

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.bankName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    card.cardName,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              Row(
                children: [
                  if (card.isFrozen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.ac_unit, size: 10, color: Colors.white),
                          SizedBox(width: 4),
                          Text("FROZEN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.wifi, color: Colors.white70, size: 20),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card.cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("CARD HOLDER", style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                    Text(
                      card.cardHolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("EXPIRES", style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                    Text(
                      card.expiryDate,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card.cardNetwork,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(VirtualCardModel card) {
    final colors = _cardThemes[card.cardColor] ?? _cardThemes['indigo']!;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            height: 38,
            width: double.infinity,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.only(right: 10),
                    alignment: Alignment.centerRight,
                    color: Colors.white,
                    child: Text(
                      "CVV: ${card.cvv}",
                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 36,
                    color: const Color(0xFF4F46E5),
                    alignment: Alignment.center,
                    child: const Text("VERIFIED", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("24/7 Security • Tokenized", style: TextStyle(color: Colors.white60, fontSize: 10)),
                Icon(Icons.lock_outline, size: 14, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: activeColor,
          onChanged: disabled ? null : onChanged,
        ),
      ],
    );
  }

  void _showLimitDialog(BuildContext context, VirtualCardProvider provider, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Adjust Monthly Spend Cap", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: "Monthly Limit (₹)",
            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF374151))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit > 0) {
                provider.updateLimit(newLimit);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Spending cap updated successfully")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save Cap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, VirtualCardProvider provider) {
    final nameCtrl = TextEditingController(text: "HDFC Regalia");
    final bankCtrl = TextEditingController(text: "HDFC Bank");
    final numCtrl = TextEditingController(text: "4532 9988 7766 1234");
    final holderCtrl = TextEditingController(text: "DEEPAK R");
    final expCtrl = TextEditingController(text: "12/28");
    final cvvCtrl = TextEditingController(text: "567");
    final limitCtrl = TextEditingController(text: "75000");
    String network = "VISA";
    String type = "Credit Card";
    String color = "emerald";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Card to Wallet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Card Nickname", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: bankCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Bank / Issuer Name", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: numCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: const InputDecoration(labelText: "Card Number (16 Digits)", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: holderCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Cardholder Name", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: expCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Expiry (MM/YY)", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "CVV", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: network,
                        dropdownColor: const Color(0xFF1F2937),
                        style: const TextStyle(color: Colors.white),
                        items: ["VISA", "MASTERCARD", "RUPAY", "AMEX"].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (v) => setModalState(() => network = v!),
                        decoration: const InputDecoration(labelText: "Network", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: color,
                        dropdownColor: const Color(0xFF1F2937),
                        style: const TextStyle(color: Colors.white),
                        items: ["indigo", "emerald", "rose", "gold", "midnight"].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                        onChanged: (v) => setModalState(() => color = v!),
                        decoration: const InputDecoration(labelText: "Skin", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (numCtrl.text.isNotEmpty && holderCtrl.text.isNotEmpty) {
                        await provider.addCard({
                          'cardName': nameCtrl.text.trim(),
                          'bankName': bankCtrl.text.trim(),
                          'cardType': type,
                          'cardNetwork': network,
                          'cardNumber': numCtrl.text.trim(),
                          'cardHolder': holderCtrl.text.trim().toUpperCase(),
                          'expiryDate': expCtrl.text.trim(),
                          'cvv': cvvCtrl.text.trim(),
                          'spendingLimit': double.tryParse(limitCtrl.text) ?? 50000.0,
                          'cardColor': color,
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Card added to wallet")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Save Card to Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCardDialog(BuildContext context, VirtualCardProvider provider, VirtualCardModel card) {
    final nameCtrl = TextEditingController(text: card.cardName);
    final bankCtrl = TextEditingController(text: card.bankName);
    final numCtrl = TextEditingController(text: card.cardNumber);
    final holderCtrl = TextEditingController(text: card.cardHolder);
    final expCtrl = TextEditingController(text: card.expiryDate);
    final cvvCtrl = TextEditingController(text: card.cvv);
    String network = card.cardNetwork;
    String color = card.cardColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Card Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Card Nickname", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: bankCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Bank Name", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextField(
                  controller: numCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: const InputDecoration(labelText: "Card Number", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: holderCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Cardholder Name", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: expCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Expiry (MM/YY)", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "CVV", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ["VISA", "MASTERCARD", "RUPAY", "AMEX"].contains(network) ? network : "VISA",
                        dropdownColor: const Color(0xFF1F2937),
                        style: const TextStyle(color: Colors.white),
                        items: ["VISA", "MASTERCARD", "RUPAY", "AMEX"].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (v) => setModalState(() => network = v!),
                        decoration: const InputDecoration(labelText: "Network", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ["indigo", "emerald", "rose", "gold", "midnight"].contains(color) ? color : "indigo",
                        dropdownColor: const Color(0xFF1F2937),
                        style: const TextStyle(color: Colors.white),
                        items: ["indigo", "emerald", "rose", "gold", "midnight"].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                        onChanged: (v) => setModalState(() => color = v!),
                        decoration: const InputDecoration(labelText: "Card Skin", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.updateCardControls({
                        'cardName': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : card.cardName,
                        'bankName': bankCtrl.text.trim().isNotEmpty ? bankCtrl.text.trim() : card.bankName,
                        'cardNumber': numCtrl.text.trim().isNotEmpty ? numCtrl.text.trim() : card.cardNumber,
                        'cardHolder': holderCtrl.text.trim().isNotEmpty ? holderCtrl.text.trim().toUpperCase() : card.cardHolder,
                        'expiryDate': expCtrl.text.trim().isNotEmpty ? expCtrl.text.trim() : card.expiryDate,
                        'cvv': cvvCtrl.text.trim().isNotEmpty ? cvvCtrl.text.trim() : card.cvv,
                        'cardNetwork': network,
                        'cardColor': color,
                      }, id: card.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Card details saved successfully!"), backgroundColor: Color(0xFF10B981)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
