import 'package:flutter/foundation.dart';
import '../models/virtual_card.dart';
import '../models/spend_controls.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

/// Provider managing Card Wallet and Spend Controls for the Financify mobile app.
///
/// Features:
/// - Real persistence (SQLite / SharedPreferences and cloud backend).
/// - No fake hardcoded default cards presented as user data.
/// - Search, type filtering, CRUD for payment cards.
/// - Secure storage (last 4 digits only, no CVV/PIN).
/// - Spending calculations against real Financify transactions.
/// - Configurable limits (Daily, Weekly, Monthly, Category-specific).
/// - Threshold alerts (50%, 80%, 100%) with deduplication.
/// - Truthful labeling of in-app controls vs bank issuer operations.
class VirtualCardProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();

  List<VirtualCardModel> _cards = [];
  int? _selectedCardId;
  bool _isLoading = false;
  String? _error;
  String? _statusMessage;

  // Search & Filter state for Card Wallet
  String _searchQuery = '';
  String _selectedTypeFilter = 'ALL'; // 'ALL', 'Credit Card', 'Debit Card', 'Prepaid Card'

  // Spend Controls state
  SpendPeriod _selectedPeriod = SpendPeriod.monthly;
  SpendLimitModel _spendLimits = SpendLimitModel();

  List<VirtualCardModel> get cards => _cards;
  int get cardCount => _cards.length;
  bool get hasCards => _cards.isNotEmpty;
  int? get selectedCardId => _selectedCardId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusMessage => _statusMessage;

  String get searchQuery => _searchQuery;
  String get selectedTypeFilter => _selectedTypeFilter;
  SpendPeriod get selectedPeriod => _selectedPeriod;
  SpendLimitModel get spendLimits => _spendLimits;

  /// Returns the currently selected card, or the primary card, or the first card.
  VirtualCardModel? get selectedCard {
    if (_cards.isEmpty) return null;
    if (_selectedCardId != null) {
      final found = _cards.firstWhere(
        (c) => c.id == _selectedCardId,
        orElse: () => _cards.firstWhere((c) => c.isPrimary, orElse: () => _cards.first),
      );
      return found;
    }
    return _cards.firstWhere((c) => c.isPrimary, orElse: () => _cards.first);
  }

  /// Backward-compatible getter that returns a safe default if no cards exist yet
  VirtualCardModel get card {
    return selectedCard ??
        VirtualCardModel(
          cardName: 'Financify Card',
          cardType: 'Debit Card',
          cardNetwork: 'VISA',
          bankName: 'Wallet Empty',
          cardNumber: '•••• •••• •••• 0000',
          cardHolder: 'YOUR NAME',
          spendingLimit: _spendLimits.monthlyLimit,
        );
  }

  /// Filtered cards based on active search text and card type filter
  List<VirtualCardModel> get filteredCards {
    return _cards.where((c) {
      // 1. Type filter
      if (_selectedTypeFilter != 'ALL') {
        final filterLower = _selectedTypeFilter.toLowerCase();
        final cardTypeLower = c.cardType.toLowerCase();
        if (!cardTypeLower.contains(filterLower.replaceAll(' card', ''))) {
          return false;
        }
      }

      // 2. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = c.cardName.toLowerCase().contains(q);
        final matchBank = c.bankName.toLowerCase().contains(q);
        final matchHolder = c.cardHolder.toLowerCase().contains(q);
        final matchLast4 = c.lastFourDigits.contains(q);
        final matchNetwork = c.cardNetwork.toLowerCase().contains(q);
        final matchNotes = c.notes.toLowerCase().contains(q);
        return matchName || matchBank || matchHolder || matchLast4 || matchNetwork || matchNotes;
      }

      return true;
    }).toList();
  }

  VirtualCardProvider({bool autoFetch = true}) {
    if (autoFetch) {
      fetchVirtualCard();
    }
  }

  void selectCard(int id) {
    _selectedCardId = id;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String filter) {
    _selectedTypeFilter = filter;
    notifyListeners();
  }

  void setSpendPeriod(SpendPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }

  /// Calculates spending summary from real transactions
  SpendingSummary computeSpendingSummary(List<TransactionModel> transactions,
      {DateTime? referenceDate}) {
    return SpendingSummary.calculate(
      transactions: transactions,
      period: _selectedPeriod,
      limits: _spendLimits,
      referenceDate: referenceDate,
    );
  }

  /// Fetches cards and spend limits from local cache and syncs with backend
  Future<void> fetchVirtualCard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Load local offline storage first
      final localCards = await _offline.getLocalVirtualCards();
      final localLimits = await _offline.getLocalSpendLimits();

      if (localCards.isNotEmpty) {
        _cards = localCards;
      }
      _spendLimits = localLimits;

      if (_cards.isNotEmpty) {
        if (_selectedCardId == null || !_cards.any((c) => c.id == _selectedCardId)) {
          final primary = _cards.firstWhere((c) => c.isPrimary, orElse: () => _cards.first);
          _selectedCardId = primary.id;
        }
      }
      notifyListeners();

      // 2. Sync fresh cards list from backend API
      final remoteList = await _api.getVirtualCards();
      if (remoteList.isNotEmpty) {
        _cards = remoteList;
        if (_selectedCardId == null || !_cards.any((c) => c.id == _selectedCardId)) {
          final primary = _cards.firstWhere((c) => c.isPrimary, orElse: () => _cards.first);
          _selectedCardId = primary.id;
        }
        await _offline.saveLocalVirtualCards(_cards);
      }

      // 3. Sync spend limits from KV store
      final remoteLimits = await _api.getSpendLimitsFromKv();
      if (remoteLimits != null) {
        _spendLimits = remoteLimits;
        await _offline.saveLocalSpendLimits(_spendLimits);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new card with strict validation and no sensitive credential storage
  Future<bool> addCard(Map<String, dynamic> cardData) async {
    final cardName = (cardData['cardName'] ?? '').toString().trim();
    final bankName = (cardData['bankName'] ?? '').toString().trim();
    final cardHolder = (cardData['cardHolder'] ?? '').toString().trim().toUpperCase();
    final rawNumber = (cardData['cardNumber'] ?? cardData['lastFourDigits'] ?? '').toString();
    final cleanDigits = rawNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = cleanDigits.length >= 4 ? cleanDigits.substring(cleanDigits.length - 4) : cleanDigits;

    // Field-level validation
    final errors = VirtualCardModel.validateFields(
      cardName: cardName,
      bankName: bankName,
      cardHolder: cardHolder,
      lastFourDigits: last4,
      expiryDate: cardData['expiryDate']?.toString(),
    );

    if (errors.isNotEmpty) {
      _error = errors.values.first;
      notifyListeners();
      return false;
    }

    // Duplicate check: Prevent accidental duplicate of same bank and last 4 digits
    final duplicate = _cards.any((c) =>
        c.bankName.toLowerCase() == bankName.toLowerCase() &&
        c.lastFourDigits == last4);

    if (duplicate) {
      _error = 'A card from $bankName ending in $last4 is already in your wallet';
      notifyListeners();
      return false;
    }

    final isPrimary = cardData['isPrimary'] == true || _cards.isEmpty;

    // If marked primary, unset existing primary flags
    if (isPrimary) {
      _cards = _cards.map((c) => c.copyWith(isPrimary: false)).toList();
    }

    final localId = DateTime.now().millisecondsSinceEpoch;
    final maskedNum = '•••• •••• •••• $last4';

    final safeData = {
      'id': localId,
      'cardName': cardName,
      'bankName': bankName,
      'cardType': cardData['cardType'] ?? 'Debit Card',
      'cardNetwork': (cardData['cardNetwork'] ?? 'VISA').toString().toUpperCase(),
      'cardNumber': maskedNum,
      'cardHolder': cardHolder,
      'expiryDate': cardData['expiryDate']?.toString().trim() ?? '',
      'cvv': '', // Never store CVV
      'spendingLimit': (cardData['spendingLimit'] is num)
          ? (cardData['spendingLimit'] as num).toDouble()
          : (double.tryParse(cardData['spendingLimit']?.toString() ?? '50000') ?? 50000.0),
      'currentSpend': 0.0,
      'isFrozen': false,
      'tapToPayEnabled': true,
      'internationalTx': false,
      'cardColor': cardData['cardColor'] ?? 'indigo',
      'isPrimary': isPrimary,
      'notes': cardData['notes']?.toString().trim() ?? '',
    };

    final newCard = VirtualCardModel.fromJson(safeData);
    _cards.insert(0, newCard);
    _selectedCardId = newCard.id;
    _error = null;
    _statusMessage = 'Card added to wallet';
    await _offline.saveLocalVirtualCards(_cards);
    notifyListeners();

    try {
      final created = await _api.createVirtualCard(safeData);
      _cards = _cards.map((c) => c.id == localId ? created : c).toList();
      _selectedCardId = created.id;
      await _offline.saveLocalVirtualCards(_cards);
      notifyListeners();
      return true;
    } catch (_) {
      // Saved offline successfully
      return true;
    }
  }

  /// Updates existing card metadata
  Future<bool> updateCardDetails(int id, Map<String, dynamic> updates) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final existing = _cards[index];
    final isPrimary = updates['isPrimary'] == true;

    if (isPrimary) {
      _cards = _cards.map((c) => c.copyWith(isPrimary: false)).toList();
    }

    // Mask card number if updating
    String updatedNumber = existing.cardNumber;
    if (updates['lastFourDigits'] != null || updates['cardNumber'] != null) {
      final raw = (updates['lastFourDigits'] ?? updates['cardNumber']).toString();
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 4) {
        updatedNumber = '•••• •••• •••• ${digits.substring(digits.length - 4)}';
      }
    }

    final merged = existing.copyWith(
      cardName: updates['cardName']?.toString().trim() ?? existing.cardName,
      bankName: updates['bankName']?.toString().trim() ?? existing.bankName,
      cardType: updates['cardType']?.toString() ?? existing.cardType,
      cardNetwork: updates['cardNetwork']?.toString().toUpperCase() ?? existing.cardNetwork,
      cardNumber: updatedNumber,
      cardHolder: updates['cardHolder']?.toString().trim().toUpperCase() ?? existing.cardHolder,
      expiryDate: updates['expiryDate']?.toString().trim() ?? existing.expiryDate,
      cardColor: updates['cardColor']?.toString() ?? existing.cardColor,
      isPrimary: isPrimary ? true : (updates['isPrimary'] == false ? false : existing.isPrimary),
      notes: updates['notes']?.toString().trim() ?? existing.notes,
      spendingLimit: updates['spendingLimit'] != null
          ? (double.tryParse(updates['spendingLimit'].toString()) ?? existing.spendingLimit)
          : existing.spendingLimit,
      isFrozen: updates['isFrozen'] != null ? updates['isFrozen'] == true : existing.isFrozen,
      tapToPayEnabled: updates['tapToPayEnabled'] != null
          ? updates['tapToPayEnabled'] == true
          : existing.tapToPayEnabled,
      internationalTx: updates['internationalTx'] != null
          ? updates['internationalTx'] == true
          : existing.internationalTx,
    );

    _cards[index] = merged;
    await _offline.saveLocalVirtualCards(_cards);
    _statusMessage = 'Card details updated';
    notifyListeners();

    try {
      final updated = await _api.updateVirtualCard(merged.toJson(), id: id);
      _cards[index] = updated;
      await _offline.saveLocalVirtualCards(_cards);
      notifyListeners();
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Sets target card as the primary card
  Future<bool> setPrimaryCard(int id) async {
    return await updateCardDetails(id, {'isPrimary': true});
  }

  /// Deletes a card permanently from local storage and backend
  Future<bool> deleteCard(int id) async {
    _cards.removeWhere((c) => c.id == id);
    if (_cards.isNotEmpty) {
      if (_selectedCardId == id) {
        final primary = _cards.firstWhere((c) => c.isPrimary, orElse: () => _cards.first);
        _selectedCardId = primary.id;
      }
    } else {
      _selectedCardId = null;
    }

    await _offline.deleteLocalVirtualCard(id);
    await _offline.saveLocalVirtualCards(_cards);
    _statusMessage = 'Card removed from wallet';
    notifyListeners();

    try {
      await _api.deleteVirtualCard(id);
      return true;
    } catch (_) {
      return true;
    }
  }

  // =========================================================================
  // SPEND CONTROLS & BUDGET LIMITS MANAGEMENT
  // =========================================================================

  /// Updates period limit (Daily, Weekly, Monthly) with validation
  Future<bool> updatePeriodLimit(SpendPeriod period, double amount) async {
    if (amount <= 0) {
      _error = 'Spending limit must be greater than zero';
      notifyListeners();
      return false;
    }

    switch (period) {
      case SpendPeriod.daily:
        _spendLimits = _spendLimits.copyWith(dailyLimit: amount);
        break;
      case SpendPeriod.weekly:
        _spendLimits = _spendLimits.copyWith(weeklyLimit: amount);
        break;
      case SpendPeriod.monthly:
        _spendLimits = _spendLimits.copyWith(monthlyLimit: amount);
        break;
    }

    await _persistSpendLimits();
    _statusMessage = '${period.displayName} spend limit updated to ${amount.toStringAsFixed(0)}';
    notifyListeners();
    return true;
  }

  /// Sets or updates a category-specific spending limit
  Future<bool> setCategoryLimit(String category, double amount) async {
    if (category.trim().isEmpty || amount <= 0) {
      _error = 'Please enter a valid category and positive limit';
      notifyListeners();
      return false;
    }

    final catMap = Map<String, double>.from(_spendLimits.categoryLimits);
    catMap[category.trim()] = amount;
    _spendLimits = _spendLimits.copyWith(categoryLimits: catMap);

    await _persistSpendLimits();
    _statusMessage = '$category limit set to ${amount.toStringAsFixed(0)}';
    notifyListeners();
    return true;
  }

  /// Removes a category-specific spending limit
  Future<bool> deleteCategoryLimit(String category) async {
    final catMap = Map<String, double>.from(_spendLimits.categoryLimits);
    catMap.remove(category);
    _spendLimits = _spendLimits.copyWith(categoryLimits: catMap);

    await _persistSpendLimits();
    _statusMessage = '$category limit removed';
    notifyListeners();
    return true;
  }

  /// Toggles threshold alert activation (50%, 80%, 100%)
  Future<void> toggleThresholdAlert(int threshold, bool enabled) async {
    if (threshold == 50) {
      _spendLimits = _spendLimits.copyWith(alertAt50: enabled);
    } else if (threshold == 80) {
      _spendLimits = _spendLimits.copyWith(alertAt80: enabled);
    } else if (threshold == 100) {
      _spendLimits = _spendLimits.copyWith(alertAt100: enabled);
    }
    await _persistSpendLimits();
    notifyListeners();
  }

  /// Acknowledges/dismisses an alert so it doesn't repeatedly show on refresh
  Future<void> acknowledgeAlert(String alertId) async {
    if (!_spendLimits.acknowledgedAlertIds.contains(alertId)) {
      final ackList = List<String>.from(_spendLimits.acknowledgedAlertIds)..add(alertId);
      _spendLimits = _spendLimits.copyWith(acknowledgedAlertIds: ackList);
      await _persistSpendLimits();
      notifyListeners();
    }
  }

  /// Toggles in-app tracking preferences (truthfully labeled Level 1 controls)
  Future<void> toggleInAppPreference(String key, bool value) async {
    if (key == 'inAppCardLock') {
      _spendLimits = _spendLimits.copyWith(inAppCardLock: value);
    } else if (key == 'trackTapToPay') {
      _spendLimits = _spendLimits.copyWith(trackTapToPay: value);
    } else if (key == 'trackInternational') {
      _spendLimits = _spendLimits.copyWith(trackInternational: value);
    }
    await _persistSpendLimits();
    notifyListeners();
  }

  Future<void> _persistSpendLimits() async {
    await _offline.saveLocalSpendLimits(_spendLimits);
    try {
      await _api.saveSpendLimitsToKv(_spendLimits);
    } catch (_) {}
  }

  // =========================================================================
  // BACKWARD-COMPATIBLE WRAPPERS FOR EXISTING UI CALLS
  // =========================================================================

  Future<bool> updateCardControls(Map<String, dynamic> updates, {int? id}) async {
    final targetId = id ?? selectedCard?.id;
    if (targetId == null) return false;
    return await updateCardDetails(targetId, updates);
  }

  Future<bool> updateLimit(double newLimit) async {
    return await updatePeriodLimit(SpendPeriod.monthly, newLimit);
  }

  Future<bool> updateColor(String colorKey) async {
    if (selectedCard != null && selectedCard!.id != null) {
      return await updateCardDetails(selectedCard!.id!, {'cardColor': colorKey});
    }
    return false;
  }

  Future<bool> toggleFreeze() async {
    final cur = _spendLimits.inAppCardLock;
    await toggleInAppPreference('inAppCardLock', !cur);
    if (selectedCard != null && selectedCard!.id != null) {
      await updateCardDetails(selectedCard!.id!, {'isFrozen': !cur});
    }
    return true;
  }

  Future<bool> toggleTapToPay() async {
    final cur = _spendLimits.trackTapToPay;
    await toggleInAppPreference('trackTapToPay', !cur);
    if (selectedCard != null && selectedCard!.id != null) {
      await updateCardDetails(selectedCard!.id!, {'tapToPayEnabled': !cur});
    }
    return true;
  }

  Future<bool> toggleInternational() async {
    final cur = _spendLimits.trackInternational;
    await toggleInAppPreference('trackInternational', !cur);
    if (selectedCard != null && selectedCard!.id != null) {
      await updateCardDetails(selectedCard!.id!, {'internationalTx': !cur});
    }
    return true;
  }
}
