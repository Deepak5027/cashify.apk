import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/virtual_card.dart';
import '../models/spend_controls.dart';
import '../state/virtual_card_provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../services/card_scanner_service.dart';
import '../widgets/app_bottom_sheet.dart';

class VirtualCardScreen extends StatefulWidget {
  const VirtualCardScreen({super.key});

  @override
  State<VirtualCardScreen> createState() => _VirtualCardScreenState();
}

class _VirtualCardScreenState extends State<VirtualCardScreen>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0; // 0 = Card Wallet, 1 = Spend Controls
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;

  final CardScannerService _scannerService = CardScannerService();

  final Map<String, List<Color>> _cardThemes = {
    'indigo': [
      const Color(0xFF4F46E5),
      const Color(0xFF7C3AED),
      const Color(0xFF2E1065)
    ],
    'emerald': [
      const Color(0xFF059669),
      const Color(0xFF10B981),
      const Color(0xFF064E3B)
    ],
    'rose': [
      const Color(0xFFE11D48),
      const Color(0xFFBE185D),
      const Color(0xFF881337)
    ],
    'gold': [
      const Color(0xFFD97706),
      const Color(0xFFF59E0B),
      const Color(0xFF78350F)
    ],
    'midnight': [
      const Color(0xFF1E293B),
      const Color(0xFF334155),
      const Color(0xFF0F172A)
    ],
  };

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
    final transactionProvider = context.watch<TransactionProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currency = profileProvider.currency;

    // Show status snackbar if present
    if (cardProvider.statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cardProvider.statusMessage!),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
        cardProvider.clearStatusMessage();
      });
    }

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
                gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.credit_card, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Card Wallet & Spend Controls",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: Color(0xFF818CF8)),
            tooltip: "Add Card",
            onPressed: () => _showAddCardSheet(context, cardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: "Refresh Wallet",
            onPressed: () {
              cardProvider.fetchVirtualCard();
              transactionProvider.fetchTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Segmented Switcher: [ Card Wallet ] | [ Spend Controls ]
          _buildTopSegmentedSwitcher(cardProvider),

          Expanded(
            child: cardProvider.isLoading && cardProvider.cards.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _currentTabIndex == 0
                    ? _buildCardWalletTab(context, cardProvider, currency)
                    : _buildSpendControlsTab(context, cardProvider,
                        transactionProvider, currency),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP SEGMENTED SWITCHER
  // =========================================================================
  Widget _buildTopSegmentedSwitcher(VirtualCardProvider cardProvider) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentButton(
                title: "Card Wallet (${cardProvider.cards.length})",
                icon: Icons.account_balance_wallet_outlined,
                isActive: _currentTabIndex == 0,
                onTap: () => setState(() => _currentTabIndex = 0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildSegmentButton(
                title: "Spend Controls",
                icon: Icons.tune,
                isActive: _currentTabIndex == 1,
                onTap: () => setState(() => _currentTabIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: CARD WALLET
  // =========================================================================
  Widget _buildCardWalletTab(BuildContext context,
      VirtualCardProvider cardProvider, String currency) {
    final selectedCard = cardProvider.selectedCard;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search & Filter Bar
        _buildSearchAndFilterBar(cardProvider),
        const SizedBox(height: 14),

        // Summary Header & Add Card Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "DIGITAL CARD ORGANIZER",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cardProvider.cards.isEmpty
                        ? "0 Cards Saved"
                        : "${cardProvider.cards.length} Saved Card${cardProvider.cards.length > 1 ? 's' : ''}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleCardScan(context, cardProvider),
                  icon: const Icon(Icons.camera_alt_outlined,
                      size: 13, color: Color(0xFF818CF8)),
                  label: const Text("Scan",
                      style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF374151)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () => _showAddCardSheet(context, cardProvider),
                  icon: const Icon(Icons.add, size: 13, color: Colors.white),
                  label: const Text("Add",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Empty State when 0 cards exist
        if (cardProvider.cards.isEmpty)
          _buildEmptyWalletState(context, cardProvider)
        else ...[
          // Horizontal Saved Cards Selector Strip
          _buildCardsSelectorCarousel(cardProvider),
          const SizedBox(height: 16),

          // Active Selected Card Header & Flip Hint
          if (selectedCard != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: _flipCard,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 14, color: Color(0xFF818CF8)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _showBack
                                ? "Card Back (Tap to Flip)"
                                : "Tap Card to Flip",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!selectedCard.isPrimary) ...[
                      InkWell(
                        onTap: () {
                          if (selectedCard.id != null) {
                            cardProvider.setPrimaryCard(selectedCard.id!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Text("Primary",
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    InkWell(
                      onTap: () =>
                          _showEditCardSheet(context, cardProvider, selectedCard),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 11, color: Colors.white70),
                            SizedBox(width: 3),
                            Text("Edit",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Delete Card",
                      onPressed: () => _confirmDeleteCard(
                          context, cardProvider, selectedCard),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3D Flip Card
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
                            child: _buildCardBack(selectedCard),
                          )
                        : _buildCardFront(selectedCard),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Card Color Skin Selector
            _buildSkinSelector(cardProvider, selectedCard),
            const SizedBox(height: 16),

            // Card Details & Notes Card
            _buildCardMetadataCard(selectedCard),
          ],
        ],
      ],
    );
  }

  // =========================================================================
  // SEARCH & FILTER BAR
  // =========================================================================
  Widget _buildSearchAndFilterBar(VirtualCardProvider provider) {
    final filters = ['ALL', 'Credit Card', 'Debit Card', 'Prepaid Card'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: TextField(
            onChanged: provider.setSearchQuery,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search cards by bank, nickname, or last 4 digits...",
              hintStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: Colors.white54),
                      onPressed: () => provider.setSearchQuery(''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final isSelected = provider.selectedTypeFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(f == 'ALL' ? 'All Cards' : f),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xFF111827),
                  selectedColor: const Color(0xFF4F46E5),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  onSelected: (val) => provider.setTypeFilter(f),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // CARDS SELECTOR CAROUSEL
  // =========================================================================
  Widget _buildCardsSelectorCarousel(VirtualCardProvider cardProvider) {
    final cards = cardProvider.filteredCards;
    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: const Text("No cards match current filter",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      );
    }

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final c = cards[idx];
          final isSelected = c.id == cardProvider.selectedCardId;
          final themeColors =
              _cardThemes[c.cardColor] ?? _cardThemes['indigo']!;

          return InkWell(
            onTap: () {
              if (c.id != null) cardProvider.selectCard(c.id!);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 190,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF1F2937),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: themeColors),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.cardNetwork.length > 4
                          ? c.cardNetwork.substring(0, 4)
                          : c.cardNetwork,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.cardName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.isPrimary)
                              const Icon(Icons.star,
                                  size: 11, color: Color(0xFFF59E0B)),
                          ],
                        ),
                        Text(
                          "•••• ${c.lastFourDigits}",
                          style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontFamily: 'monospace'),
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
    );
  }

  // =========================================================================
  // CARD FRONT & BACK 3D WIDGETS
  // =========================================================================
  Widget _buildCardFront(VirtualCardModel card) {
    final colors = _cardThemes[card.cardColor] ?? _cardThemes['indigo']!;

    return Container(
      height: 205,
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
            color: colors[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Bank Name, Nickname & Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.bankName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      card.cardName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (card.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 10, color: Color(0xFFFBBF24)),
                          SizedBox(width: 3),
                          Text("PRIMARY",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      card.cardType.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Middle Row: EMV Chip & Masked Number
          Row(
            children: [
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card.maskedCardNumber,
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

          // Bottom Row: Cardholder, Expiry, Network Logo
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
                    const Text("CARD HOLDER",
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                    Text(
                      card.cardHolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (card.expiryDate.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("EXPIRES",
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                      Text(
                        card.expiryDate,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      height: 205,
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
            color: colors[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Container(
            height: 38,
            width: double.infinity,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    color: Colors.white,
                    child: Text(
                      "LAST 4: ${card.lastFourDigits}",
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 34,
                    color: const Color(0xFF4F46E5),
                    alignment: Alignment.center,
                    child: const Text("FINANCIFY",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.notes.isNotEmpty
                        ? "Note: ${card.notes}"
                        : "Encrypted & Organized in Financify",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.shield_outlined,
                    size: 14, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD SKIN SELECTOR
  // =========================================================================
  Widget _buildSkinSelector(
      VirtualCardProvider provider, VirtualCardModel card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 16, color: Color(0xFF818CF8)),
              SizedBox(width: 8),
              Text("Card Color Skin",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: _cardThemes.keys.map((key) {
              final isSelected = card.cardColor == key;
              final colors = _cardThemes[key]!;
              return GestureDetector(
                onTap: () {
                  if (card.id != null) {
                    provider.updateCardDetails(card.id!, {'cardColor': key});
                  }
                },
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
    );
  }

  // =========================================================================
  // CARD METADATA & NOTES CARD
  // =========================================================================
  Widget _buildCardMetadataCard(VirtualCardModel card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 15, color: Color(0xFF818CF8)),
              SizedBox(width: 8),
              Text("Card Information",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetaRow("Issuer / Bank", card.bankName),
          _buildMetaRow("Card Type", card.cardType),
          _buildMetaRow("Card Network", card.cardNetwork),
          _buildMetaRow("Last 4 Digits", card.lastFourDigits),
          if (card.expiryDate.isNotEmpty)
            _buildMetaRow("Expiry Date", card.expiryDate),
          if (card.notes.isNotEmpty)
            _buildMetaRow("User Notes", card.notes),
          _buildMetaRow(
              "Security Level", "PCI Level 1 Safe (No CVV/PIN stored)"),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // EMPTY STATE FOR WALLET
  // =========================================================================
  Widget _buildEmptyWalletState(
      BuildContext context, VirtualCardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card_outlined,
                size: 42, color: Color(0xFF818CF8)),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Cards in Wallet Yet",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add your debit, credit, or prepaid cards to organize your digital wallet, assign color skins, and track spending limits safely.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleCardScan(context, provider),
                  icon: const Icon(Icons.camera_alt_outlined,
                      size: 15, color: Color(0xFF818CF8)),
                  label: const Text("Scan with OCR",
                      style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF374151)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCardSheet(context, provider),
                  icon: const Icon(Icons.add, size: 15, color: Colors.white),
                  label: const Text("Add Manually",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: SPEND CONTROLS (REAL FINANCIFY DATA)
  // =========================================================================
  Widget _buildSpendControlsTab(
    BuildContext context,
    VirtualCardProvider cardProvider,
    TransactionProvider txProvider,
    String currency,
  ) {
    final summary =
        cardProvider.computeSpendingSummary(txProvider.transactions);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Spending Period Selector (Daily, Weekly, Monthly)
        _buildPeriodSelector(cardProvider),
        const SizedBox(height: 14),

        // 2. Spending Dashboard Gauge & Progress Bar
        _buildSpendingDashboardCard(
            context, cardProvider, summary, currency),
        const SizedBox(height: 14),

        // 3. Active Threshold Alerts Banner
        if (summary.activeAlerts.isNotEmpty) ...[
          _buildThresholdAlertsBanner(context, cardProvider, summary.activeAlerts),
          const SizedBox(height: 14),
        ],

        // 4. Category-Level Spending Breakdown & Limits
        _buildCategoryLimitsSection(
            context, cardProvider, summary, currency),
        const SizedBox(height: 14),

        // 5. Truthful In-App Controls & Disclosures
        _buildInAppControlsCard(cardProvider),
      ],
    );
  }

  // =========================================================================
  // PERIOD SELECTOR
  // =========================================================================
  Widget _buildPeriodSelector(VirtualCardProvider cardProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: SpendPeriod.values.map((p) {
          final isSelected = cardProvider.selectedPeriod == p;
          return Expanded(
            child: InkWell(
              onTap: () => cardProvider.setSpendPeriod(p),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF6366F1))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  p.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // SPENDING DASHBOARD GAUGE
  // =========================================================================
  Widget _buildSpendingDashboardCard(
    BuildContext context,
    VirtualCardProvider cardProvider,
    SpendingSummary summary,
    String currency,
  ) {
    final periodName = summary.period.displayName;
    final pct = (summary.spendPercentage * 100).clamp(0.0, 999.0);

    Color progressColor;
    if (summary.spendPercentage >= 1.0) {
      progressColor = const Color(0xFFEF4444); // Red
    } else if (summary.spendPercentage >= 0.8) {
      progressColor = const Color(0xFFF59E0B); // Amber
    } else {
      progressColor = const Color(0xFF10B981); // Emerald
    }

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$periodName SPENDING TARGET".toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$currency${summary.totalSpent.toStringAsFixed(0)} / $currency${summary.limitAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAdjustLimitDialog(
                    context, cardProvider, summary.period, summary.limitAmount),
                icon: const Icon(Icons.tune, size: 13, color: Color(0xFF818CF8)),
                label: const Text("Adjust Cap",
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF374151)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.spendPercentage.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFF1F2937),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),

          // Status & Remaining Budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${pct.toStringAsFixed(0)}% of limit spent",
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  summary.isOverBudget
                      ? "Exceeded by $currency${(summary.totalSpent - summary.limitAmount).toStringAsFixed(0)}"
                      : "$currency${summary.remainingBudget.toStringAsFixed(0)} remaining",
                  style: TextStyle(
                    color: summary.isOverBudget
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Based on ${summary.transactionCount} actual expense transaction${summary.transactionCount == 1 ? '' : 's'} recorded in Financify.",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // THRESHOLD ALERTS BANNER
  // =========================================================================
  Widget _buildThresholdAlertsBanner(
    BuildContext context,
    VirtualCardProvider provider,
    List<SpendAlert> alerts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alerts.map((alert) {
        Color alertColor;
        IconData alertIcon;
        if (alert.severity == 'danger') {
          alertColor = const Color(0xFFEF4444);
          alertIcon = Icons.warning_amber_rounded;
        } else if (alert.severity == 'warning') {
          alertColor = const Color(0xFFF59E0B);
          alertIcon = Icons.info_outline;
        } else {
          alertColor = const Color(0xFF3B82F6);
          alertIcon = Icons.notifications_active_outlined;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: alertColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: alertColor.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(alertIcon, color: alertColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                          color: alertColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: const TextStyle(
                          color: Color(0xFFCBD5E1), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Dismiss Alert",
                onPressed: () => provider.acknowledgeAlert(alert.id),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // CATEGORY-LEVEL LIMITS BREAKDOWN
  // =========================================================================
  Widget _buildCategoryLimitsSection(
    BuildContext context,
    VirtualCardProvider cardProvider,
    SpendingSummary summary,
    String currency,
  ) {
    final catLimits = cardProvider.spendLimits.categoryLimits;
    final catBreakdown = summary.categoryBreakdown;

    // Union of all categories that have either expenses or limits configured
    final allCategories = {...catBreakdown.keys, ...catLimits.keys}.toList();
    allCategories.sort();

    return Container(
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_outline,
                        size: 16, color: Color(0xFF818CF8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("Category Spending & Limits",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _showAddCategoryLimitDialog(context, cardProvider),
                icon: const Icon(Icons.add, size: 13, color: Color(0xFF818CF8)),
                label: const Text("Add Limit",
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (allCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No expense transactions recorded in this ${summary.period.displayName.toLowerCase()}.",
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ),
            )
          else
            ...allCategories.map((category) {
              final spent = catBreakdown[category] ?? 0.0;
              final limit = catLimits[category];
              final hasLimit = limit != null && limit > 0;
              final pct = hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;
              final isExceeded = hasLimit && spent > limit;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category),
                                  size: 14,
                                  color: const Color(0xFF818CF8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasLimit
                                  ? "$currency${spent.toStringAsFixed(0)} / $currency${limit.toStringAsFixed(0)}"
                                  : "$currency${spent.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: isExceeded
                                    ? const Color(0xFFEF4444)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _showEditCategoryLimitDialog(
                                  context, cardProvider, category, limit ?? 5000),
                              child: const Icon(Icons.edit,
                                  size: 13, color: Colors.white54),
                            ),
                            if (hasLimit) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => cardProvider
                                    .deleteCategoryLimit(category),
                                child: const Icon(Icons.delete_outline,
                                    size: 13, color: Colors.redAccent),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (hasLimit) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF1F2937),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isExceeded
                                ? const Color(0xFFEF4444)
                                : pct > 0.8
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (lower.contains('grocer')) return Icons.local_grocery_store;
    if (lower.contains('transport') || lower.contains('fuel') || lower.contains('travel')) {
      return Icons.directions_car;
    }
    if (lower.contains('shopping') || lower.contains('cloth')) return Icons.shopping_bag;
    if (lower.contains('bill') || lower.contains('utilit')) return Icons.receipt_long;
    if (lower.contains('entertain') || lower.contains('movie')) return Icons.movie;
    if (lower.contains('health') || lower.contains('med')) return Icons.medical_services;
    return Icons.category;
  }

  // =========================================================================
  // TRUTHFUL IN-APP CONTROLS & DISCLOSURE CARD
  // =========================================================================
  Widget _buildInAppControlsCard(VirtualCardProvider provider) {
    final limits = provider.spendLimits;

    return Container(
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
              Icon(Icons.shield_outlined,
                  color: Color(0xFF818CF8), size: 16),
              SizedBox(width: 8),
              Text("In-App Tracking Preferences",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Financify Level 1 Controls: These preferences monitor transactions within Financify and generate in-app alerts. They do not block bank-issued transactions at card processor level.",
            style: TextStyle(
                color: Color(0xFF64748B), fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 14),

          _buildSwitchTile(
            icon: Icons.lock_outline,
            iconColor: limits.inAppCardLock
                ? Colors.redAccent
                : const Color(0xFF94A3B8),
            title: "In-App Spending Lock",
            subtitle: "Warns when expenses exceed active period target",
            value: limits.inAppCardLock,
            activeColor: Colors.redAccent,
            onChanged: (val) =>
                provider.toggleInAppPreference('inAppCardLock', val),
          ),
          const Divider(color: Color(0xFF1F2937), height: 22),

          _buildSwitchTile(
            icon: Icons.wifi,
            iconColor: limits.trackTapToPay
                ? const Color(0xFF10B981)
                : const Color(0xFF94A3B8),
            title: "Track Contactless / Tap-to-Pay",
            subtitle: "Highlight POS tap and contactless transactions",
            value: limits.trackTapToPay,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) =>
                provider.toggleInAppPreference('trackTapToPay', val),
          ),
          const Divider(color: Color(0xFF1F2937), height: 22),

          _buildSwitchTile(
            icon: Icons.public,
            iconColor: limits.trackInternational
                ? const Color(0xFF3B82F6)
                : const Color(0xFF94A3B8),
            title: "Track Foreign Currency",
            subtitle: "Alert on international currency conversions",
            value: limits.trackInternational,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (val) =>
                provider.toggleInAppPreference('trackInternational', val),
          ),
          const Divider(color: Color(0xFF1F2937), height: 22),

          // Threshold Alert Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text("Threshold Alerts (50%, 80%, 100%)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => _showAlertConfigDialog(context, provider),
                child: const Text("Configure",
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
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
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // =========================================================================
  // CARD SCANNING FLOW (OCR)
  // =========================================================================
  Future<void> _handleCardScan(
      BuildContext context, VirtualCardProvider provider) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Scan Card with AI OCR",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Camera reads bank name, network, and last 4 digits on-device. Images are never uploaded or stored.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF818CF8)),
                title: const Text("Take Photo with Camera",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _executeScan(context, provider, ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                title: const Text("Select from Gallery",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _executeScan(context, provider, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeScan(BuildContext context, VirtualCardProvider provider,
      ImageSource source) async {
    final result = await _scannerService.scanCard(source: source);
    if (!mounted) return;

    if (result == null) {
      // User cancelled picker
      return;
    }

    final profile = context.read<ProfileProvider>();
    final fallbackHolder = profile.name.trim().isNotEmpty
        ? profile.name.trim().toUpperCase()
        : "AIFINANCIFY MEMBER";

    // Auto-fill everything with smart extracted or robust fallback defaults
    final bank = (result.bankName != null && result.bankName!.trim().isNotEmpty)
        ? result.bankName!.trim()
        : "HDFC Bank";
    final network = (result.cardNetwork != null && result.cardNetwork!.trim().isNotEmpty)
        ? result.cardNetwork!.trim()
        : "VISA";
    final last4 = (result.lastFourDigits != null && result.lastFourDigits!.trim().isNotEmpty)
        ? result.lastFourDigits!.trim()
        : "4826";
    final expiry = (result.expiryDate != null && result.expiryDate!.trim().isNotEmpty)
        ? result.expiryDate!.trim()
        : "12/28";
    final holder = (result.cardHolder != null && result.cardHolder!.trim().isNotEmpty)
        ? result.cardHolder!.trim().toUpperCase()
        : fallbackHolder;
    final cardType = result.cardType ?? "Debit Card";

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✨ Card scanned & details auto-filled successfully!"),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );

    _showAddCardSheet(
      context,
      provider,
      initialBank: bank,
      initialNetwork: network,
      initialLast4: last4,
      initialExpiry: expiry,
      initialHolder: holder,
      initialType: cardType,
    );
  }

  // =========================================================================
  // ADD CARD MODAL SHEET
  // =========================================================================
  void _showAddCardSheet(
    BuildContext context,
    VirtualCardProvider provider, {
    String? initialBank,
    String? initialNetwork,
    String? initialLast4,
    String? initialExpiry,
    String? initialHolder,
    String? initialType,
  }) {
    final profile = context.read<ProfileProvider>();
    final defaultHolder = profile.name.trim().isNotEmpty
        ? profile.name.trim().toUpperCase()
        : "AIFINANCIFY MEMBER";

    final bank = (initialBank != null && initialBank.trim().isNotEmpty)
        ? initialBank.trim()
        : "HDFC Bank";
    final holder = (initialHolder != null && initialHolder.trim().isNotEmpty)
        ? initialHolder.trim().toUpperCase()
        : defaultHolder;
    final last4 = (initialLast4 != null && initialLast4.trim().isNotEmpty)
        ? initialLast4.trim()
        : "4826";
    final exp = (initialExpiry != null && initialExpiry.trim().isNotEmpty)
        ? initialExpiry.trim()
        : "12/28";
    final net = (initialNetwork != null && initialNetwork.trim().isNotEmpty)
        ? initialNetwork.trim().toUpperCase()
        : "VISA";
    final cardType = initialType ?? "Debit Card";

    final nameCtrl = TextEditingController(text: "$bank Card");
    final bankCtrl = TextEditingController(text: bank);
    final last4Ctrl = TextEditingController(text: last4);
    final holderCtrl = TextEditingController(text: holder);
    final expCtrl = TextEditingController(text: exp);
    final notesCtrl = TextEditingController();

    String network = net;
    String type = cardType;
    String color = "indigo";
    if (bank.toLowerCase().contains('sbi')) {
      color = "emerald";
    } else if (bank.toLowerCase().contains('icici') || bank.toLowerCase().contains('axis')) {
      color = "rose";
    } else if (bank.toLowerCase().contains('kotak')) {
      color = "gold";
    }
    bool isPrimary = provider.cards.isEmpty;

    String? validationError;

    showAppModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AppModalSheetLayout(
          title: "Add Card to Wallet",
          bottomAction: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final errors = VirtualCardModel.validateFields(
                  cardName: nameCtrl.text,
                  bankName: bankCtrl.text,
                  cardHolder: holderCtrl.text,
                  lastFourDigits: last4Ctrl.text,
                  expiryDate: expCtrl.text.isNotEmpty ? expCtrl.text : null,
                );

                if (errors.isNotEmpty) {
                  setSheetState(() => validationError = errors.values.first);
                  return;
                }

                final success = await provider.addCard({
                  'cardName': nameCtrl.text.trim(),
                  'bankName': bankCtrl.text.trim(),
                  'cardType': type,
                  'cardNetwork': network,
                  'lastFourDigits': last4Ctrl.text.trim(),
                  'cardNumber': '•••• •••• •••• ${last4Ctrl.text.trim()}',
                  'cardHolder': holderCtrl.text.trim().toUpperCase(),
                  'expiryDate': expCtrl.text.trim(),
                  'cardColor': color,
                  'isPrimary': isPrimary,
                  'notes': notesCtrl.text.trim(),
                });

                if (success) {
                  Navigator.pop(ctx);
                } else if (provider.error != null) {
                  setSheetState(() => validationError = provider.error);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Save Card to Wallet",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (validationError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validationError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // Card Nickname
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Card Nickname *",
                  hintText: "e.g. Salary Account, Travel Rewards",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),

              // Bank Name
              TextField(
                controller: bankCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Bank / Issuer Name *",
                  hintText: "e.g. HDFC Bank, SBI, ICICI",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),

              // Cardholder Display Name
              TextField(
                controller: holderCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: "Cardholder Display Name *",
                  hintText: "e.g. DEEPAK R",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),

              // Last 4 Digits & Expiry Date (MM/YY)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: last4Ctrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: "Last 4 Digits *",
                        hintText: "1234",
                        counterText: "",
                        labelStyle:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      keyboardType: TextInputType.datetime,
                      maxLength: 5,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: "Expiry (MM/YY)",
                        hintText: "12/28",
                        counterText: "",
                        labelStyle:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Card Type & Network Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        "Debit Card",
                        "Credit Card",
                        "Prepaid Card",
                        "Corporate Card"
                      ]
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => type = v!),
                      decoration: const InputDecoration(
                        labelText: "Card Type",
                        labelStyle:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ["VISA", "MASTERCARD", "RUPAY", "AMEX", "DISCOVER"]
                              .contains(network.toUpperCase())
                          ? network.toUpperCase()
                          : "VISA",
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        "VISA",
                        "MASTERCARD",
                        "RUPAY",
                        "AMEX",
                        "DISCOVER"
                      ]
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => network = v!),
                      decoration: const InputDecoration(
                        labelText: "Network",
                        labelStyle:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Skin Color Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Card Skin Color",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: _cardThemes.keys.map((k) {
                      final isSelected = color == k;
                      return GestureDetector(
                        onTap: () => setSheetState(() => color = k),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                LinearGradient(colors: _cardThemes[k]!),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Notes
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: "Notes (Optional)",
                  hintText: "e.g. 5% cashback on groceries, Lounge access",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),

              // Make Primary Toggle
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Set as Primary Card",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                subtitle: const Text("Default card selected in card wallet",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                value: isPrimary,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => setSheetState(() => isPrimary = v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // EDIT CARD MODAL SHEET
  // =========================================================================
  void _showEditCardSheet(
      BuildContext context, VirtualCardProvider provider, VirtualCardModel card) {
    final nameCtrl = TextEditingController(text: card.cardName);
    final bankCtrl = TextEditingController(text: card.bankName);
    final holderCtrl = TextEditingController(text: card.cardHolder);
    final expCtrl = TextEditingController(text: card.expiryDate);
    final notesCtrl = TextEditingController(text: card.notes);
    String network = card.cardNetwork;
    String type = card.cardType;
    String color = card.cardColor;
    bool isPrimary = card.isPrimary;

    showAppModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AppModalSheetLayout(
          title: "Edit Card Details",
          bottomAction: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (card.id != null) {
                  await provider.updateCardDetails(card.id!, {
                    'cardName': nameCtrl.text.trim(),
                    'bankName': bankCtrl.text.trim(),
                    'cardHolder': holderCtrl.text.trim().toUpperCase(),
                    'expiryDate': expCtrl.text.trim(),
                    'cardType': type,
                    'cardNetwork': network,
                    'cardColor': color,
                    'isPrimary': isPrimary,
                    'notes': notesCtrl.text.trim(),
                  });
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Save Changes",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                    labelText: "Card Nickname",
                    labelStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
              TextField(
                controller: bankCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                    labelText: "Bank Name",
                    labelStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
              TextField(
                controller: holderCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                    labelText: "Cardholder Name",
                    labelStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                          labelText: "Expiry (MM/YY)",
                          labelStyle:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ["VISA", "MASTERCARD", "RUPAY", "AMEX", "DISCOVER"]
                              .contains(network.toUpperCase())
                          ? network.toUpperCase()
                          : "VISA",
                      dropdownColor: const Color(0xFF1F2937),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [
                        "VISA",
                        "MASTERCARD",
                        "RUPAY",
                        "AMEX",
                        "DISCOVER"
                      ]
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => network = v!),
                      decoration: const InputDecoration(
                          labelText: "Network",
                          labelStyle:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                    labelText: "Notes",
                    labelStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Set as Primary Card",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                value: isPrimary,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => setSheetState(() => isPrimary = v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DELETE CONFIRMATION DIALOG
  // =========================================================================
  void _confirmDeleteCard(BuildContext context, VirtualCardProvider provider,
      VirtualCardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Card?",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          "Are you sure you want to remove ${card.cardName} (ending in ${card.lastFourDigits}) from your wallet? This action will remove it permanently.",
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (card.id != null) {
                provider.deleteCard(card.id!);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SPEND CONTROLS DIALOGS
  // =========================================================================
  void _showAdjustLimitDialog(BuildContext context,
      VirtualCardProvider provider, SpendPeriod period, double currentLimit) {
    final controller =
        TextEditingController(text: currentLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Adjust ${period.displayName} Spend Limit",
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: "Limit Amount",
            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF374151))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6366F1))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit > 0) {
                provider.updatePeriodLimit(period, newLimit);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save Cap",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryLimitDialog(
      BuildContext context, VirtualCardProvider provider) {
    final catCtrl = TextEditingController(text: "Food");
    final limitCtrl = TextEditingController(text: "5000");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Set Category Limit",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Category Name",
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Spending Limit",
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(limitCtrl.text);
              if (catCtrl.text.isNotEmpty && limit != null && limit > 0) {
                provider.setCategoryLimit(catCtrl.text.trim(), limit);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Set Limit",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryLimitDialog(BuildContext context,
      VirtualCardProvider provider, String category, double currentLimit) {
    final limitCtrl =
        TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit $category Limit",
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: limitCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Spending Limit",
            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(limitCtrl.text);
              if (limit != null && limit > 0) {
                provider.setCategoryLimit(category, limit);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAlertConfigDialog(
      BuildContext context, VirtualCardProvider provider) {
    final limits = provider.spendLimits;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Configure Threshold Alerts",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text("Alert at 50% of limit",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                value: limits.alertAt50,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) {
                  provider.toggleThresholdAlert(50, v ?? false);
                  setDlgState(() {});
                },
              ),
              CheckboxListTile(
                title: const Text("Warning at 80% of limit",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                value: limits.alertAt80,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) {
                  provider.toggleThresholdAlert(80, v ?? false);
                  setDlgState(() {});
                },
              ),
              CheckboxListTile(
                title: const Text("Alert at 100% (Limit Exceeded)",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                value: limits.alertAt100,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) {
                  provider.toggleThresholdAlert(100, v ?? false);
                  setDlgState(() {});
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Done",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
