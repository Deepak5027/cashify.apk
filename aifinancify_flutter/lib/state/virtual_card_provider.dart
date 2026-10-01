import 'package:flutter/foundation.dart';
import '../models/virtual_card.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class VirtualCardProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final OfflineStorageService _offline = OfflineStorageService();

  static final List<VirtualCardModel> _defaultCards = [
    VirtualCardModel(
      id: 1,
      cardName: "HDFC Regalia Gold",
      cardType: "Credit Card",
      cardNetwork: "VISA",
      bankName: "HDFC Bank",
      cardNumber: "4532 9988 7766 1234",
      cardHolder: "DEEPAK R",
      expiryDate: "12/28",
      cvv: "567",
      spendingLimit: 75000.0,
      currentSpend: 18450.0,
      isFrozen: false,
      tapToPayEnabled: true,
      internationalTx: true,
      cardColor: "indigo",
      isPrimary: true,
    ),
    VirtualCardModel(
      id: 2,
      cardName: "SBI Cashback Card",
      cardType: "Debit Card",
      cardNetwork: "MASTERCARD",
      bankName: "State Bank of India",
      cardNumber: "5241 6655 4433 9876",
      cardHolder: "DEEPAK R",
      expiryDate: "08/29",
      cvv: "321",
      spendingLimit: 50000.0,
      currentSpend: 12300.0,
      isFrozen: false,
      tapToPayEnabled: true,
      internationalTx: false,
      cardColor: "emerald",
      isPrimary: false,
    ),
    VirtualCardModel(
      id: 3,
      cardName: "ICICI Coral Virtual",
      cardType: "Virtual Prepaid",
      cardNetwork: "RUPAY",
      bankName: "ICICI Bank",
      cardNumber: "6080 1122 3344 5566",
      cardHolder: "DEEPAK R",
      expiryDate: "05/30",
      cvv: "842",
      spendingLimit: 30000.0,
      currentSpend: 4200.0,
      isFrozen: false,
      tapToPayEnabled: true,
      internationalTx: false,
      cardColor: "gold",
      isPrimary: false,
    ),
  ];

  List<VirtualCardModel> _cards = List.from(_defaultCards);
  int? _selectedCardId = 1;
  bool _isLoading = false;
  String? _error;

  List<VirtualCardModel> get cards => _cards;
  int? get selectedCardId => _selectedCardId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  VirtualCardModel get card {
    if (_cards.isNotEmpty) {
      if (_selectedCardId != null) {
        final found = _cards.firstWhere(
          (c) => c.id == _selectedCardId,
          orElse: () => _cards.first,
        );
        return found;
      }
      return _cards.first;
    }
    return _defaultCards.first;
  }

  VirtualCardProvider() {
    fetchVirtualCard();
  }

  void selectCard(int id) {
    _selectedCardId = id;
    notifyListeners();
  }

  Future<void> fetchVirtualCard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Try local offline cache first
      final local = await _offline.getLocalVirtualCard();
      if (local != null) {
        if (!_cards.any((c) => c.id == local.id)) {
          _cards.insert(0, local);
        }
        _selectedCardId = local.id;
        notifyListeners();
      }

      // 2. Fetch fresh cards list from backend
      final list = await _api.getVirtualCards();
      if (list.isNotEmpty) {
        _cards = list;
        if (_selectedCardId == null || !_cards.any((c) => c.id == _selectedCardId)) {
          _selectedCardId = _cards.first.id;
        }
        await _offline.saveLocalVirtualCard(card);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCard(Map<String, dynamic> cardData) async {
    final localId = DateTime.now().millisecondsSinceEpoch;
    final localCard = VirtualCardModel.fromJson({
      'id': localId,
      ...cardData,
    });
    _cards.insert(0, localCard);
    _selectedCardId = localId;
    await _offline.saveLocalVirtualCard(localCard);
    notifyListeners();

    try {
      final created = await _api.createVirtualCard(cardData);
      _cards = _cards.map((c) => c.id == localId ? created : c).toList();
      _selectedCardId = created.id;
      await _offline.saveLocalVirtualCard(created);
      notifyListeners();
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> updateCardControls(Map<String, dynamic> updates, {int? id}) async {
    final targetId = id ?? card.id;

    // 1. Optimistic instant local memory update
    if (_cards.isEmpty) {
      final currentMap = card.toJson();
      final merged = {...currentMap, ...updates};
      _cards = [VirtualCardModel.fromJson(merged)];
      _selectedCardId = _cards.first.id;
    } else {
      _cards = _cards.map((c) {
        if (targetId != null ? c.id == targetId : true) {
          final currentMap = c.toJson();
          final merged = {...currentMap, ...updates};
          return VirtualCardModel.fromJson(merged);
        }
        return c;
      }).toList();
    }
    notifyListeners();

    // 2. Persist to offline cache
    if (_cards.isNotEmpty) {
      await _offline.saveLocalVirtualCard(card);
    }

    // 3. Sync to API
    try {
      final updated = await _api.updateVirtualCard(updates, id: targetId);
      _cards = _cards.map((c) {
        if (targetId != null ? c.id == targetId : true) {
          return updated;
        }
        return c;
      }).toList();
      if (_cards.isNotEmpty) {
        await _offline.saveLocalVirtualCard(card);
      }
      notifyListeners();
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> deleteCard(int id) async {
    _cards.removeWhere((c) => c.id == id);
    if (_cards.isNotEmpty) {
      _selectedCardId = _cards.first.id;
    } else {
      _cards = List.from(_defaultCards);
      _selectedCardId = _cards.first.id;
    }
    notifyListeners();

    try {
      await _api.deleteVirtualCard(id);
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> toggleFreeze() async {
    return await updateCardControls({'isFrozen': !card.isFrozen});
  }

  Future<bool> toggleTapToPay() async {
    return await updateCardControls({'tapToPayEnabled': !card.tapToPayEnabled});
  }

  Future<bool> toggleInternational() async {
    return await updateCardControls({'internationalTx': !card.internationalTx});
  }

  Future<bool> updateLimit(double newLimit) async {
    return await updateCardControls({'spendingLimit': newLimit});
  }

  Future<bool> updateColor(String colorKey) async {
    return await updateCardControls({'cardColor': colorKey});
  }
}
