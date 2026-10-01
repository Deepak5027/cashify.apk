import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/transaction.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcript = '';
  bool _isSaving = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  String _category = 'Food & Dining';
  String _type = 'expense';
  String _paymentMode = 'UPI';

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Transport',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Salary',
    'Investment',
    'Other',
  ];

  final List<String> _paymentModes = ['UPI', 'Cash', 'Card', 'Net Banking'];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _parseVoiceInput(_transcript);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _transcript = '';
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _transcript = val.recognizedWords;
            });
            _parseVoiceInput(_transcript);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _parseVoiceInput(_transcript);
    }
  }

  void _parseVoiceInput(String text) {
    if (text.trim().isEmpty) return;
    final lower = text.toLowerCase().trim();

    // 1. Parse Payment Mode
    if (RegExp(r'\b(upi|gpay|google pay|paytm|phonepe|bhic|net banking|transfer)\b').hasMatch(lower)) {
      _paymentMode = 'UPI';
    } else if (RegExp(r'\b(card|credit|debit|visa|mastercard|amex|online)\b').hasMatch(lower)) {
      _paymentMode = 'Card';
    } else if (RegExp(r'\b(cash)\b').hasMatch(lower)) {
      _paymentMode = 'Cash';
    }

    // 2. Parse Income vs Expense
    if (RegExp(r'\b(received|salary|income|refund|earned|deposit|credited)\b').hasMatch(lower)) {
      _type = 'income';
    } else {
      _type = 'expense';
    }

    // 3. Parse Amount with multiplier support (k, thousand, lakh, crore)
    final amountRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*(k|thousand|thousands|lakh|lakhs|lac|lacs|cr|crore|crores)?\b');
    final amountMatch = amountRegex.firstMatch(lower);

    if (amountMatch != null) {
      final baseStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      double baseNum = double.tryParse(baseStr) ?? 0.0;
      final multiplier = (amountMatch.group(2) ?? '').toLowerCase();

      if (multiplier == 'k' || multiplier.startsWith('thousand')) {
        baseNum *= 1000;
      } else if (multiplier.startsWith('lakh') || multiplier.startsWith('lac')) {
        baseNum *= 100000;
      } else if (multiplier.startsWith('cr') || multiplier.startsWith('crore')) {
        baseNum *= 10000000;
      }

      if (baseNum > 0) {
        _amountController.text = baseNum.toStringAsFixed(baseNum.truncateToDouble() == baseNum ? 0 : 2);
      }
    }

    // 4. Parse Category
    final Map<String, List<String>> catKeywords = {
      'Food & Dining': ['zomato', 'swiggy', 'starbucks', 'restaurant', 'cafe', 'coffee', 'food', 'dining', 'biryani', 'dominos', 'pizza', 'burger', 'lunch', 'dinner', 'breakfast'],
      'Groceries': ['jiomart', 'grocery', 'groceries', 'supermarket', 'dmart', 'bigbazaar', 'reliance', 'instamart', 'blinkit', 'zepto', 'milk', 'vegetables', 'fruits'],
      'Transport': ['uber', 'ola', 'auto', 'cab', 'taxi', 'metro', 'bus', 'train', 'rapido', 'petrol', 'fuel', 'diesel'],
      'Entertainment': ['netflix', 'spotify', 'prime', 'hotstar', 'youtube', 'movie', 'cinema', 'ticket', 'show', 'bookmyshow', 'game'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'meesho', 'shopping', 'shop', 'mall', 'clothes', 'clothing', 'shirt', 'shoes'],
      'Bills & Utilities': ['bill', 'electricity', 'water', 'gas', 'internet', 'recharge', 'postpaid', 'rent', 'wifi', 'broadband'],
      'Health': ['hospital', 'pharmacy', 'doctor', 'medical', 'medicine', 'clinic', 'apollo'],
      'Salary': ['salary', 'bonus', 'freelance', 'paycheck'],
    };

    bool catFound = false;
    for (var entry in catKeywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        _category = entry.key;
        catFound = true;
        break;
      }
    }
    if (!catFound && _type == 'income') {
      _category = 'Salary';
    }

    // 5. Clean Merchant / Description by stripping filler words
    String cleaned = lower;
    if (amountMatch != null) {
      cleaned = cleaned.replaceFirst(amountMatch.group(0)!, ' ');
    }

    final fillerPatterns = [
      RegExp(r'\bi\b', caseSensitive: false),
      RegExp(r'\bmy\b', caseSensitive: false),
      RegExp(r'\bme\b', caseSensitive: false),
      RegExp(r'\bwe\b', caseSensitive: false),
      RegExp(r'\bspend\b', caseSensitive: false),
      RegExp(r'\bspent\b', caseSensitive: false),
      RegExp(r'\bpaid\b', caseSensitive: false),
      RegExp(r'\bpay\b', caseSensitive: false),
      RegExp(r'\bfor\b', caseSensitive: false),
      RegExp(r'\bat\b', caseSensitive: false),
      RegExp(r'\bfrom\b', caseSensitive: false),
      RegExp(r'\bon\b', caseSensitive: false),
      RegExp(r'\bin\b', caseSensitive: false),
      RegExp(r'\bto\b', caseSensitive: false),
      RegExp(r'\bby\b', caseSensitive: false),
      RegExp(r'\bvia\b', caseSensitive: false),
      RegExp(r'\busing\b', caseSensitive: false),
      RegExp(r'\bwith\b', caseSensitive: false),
      RegExp(r'\brupees\b', caseSensitive: false),
      RegExp(r'\brupee\b', caseSensitive: false),
      RegExp(r'\brs\b', caseSensitive: false),
      RegExp(r'\b₹\b', caseSensitive: false),
      RegExp(r'\bupi\b', caseSensitive: false),
      RegExp(r'\bcash\b', caseSensitive: false),
      RegExp(r'\bcard\b', caseSensitive: false),
      RegExp(r'\bonline\b', caseSensitive: false),
      RegExp(r'\bgpay\b', caseSensitive: false),
      RegExp(r'\bpaytm\b', caseSensitive: false),
      RegExp(r'\bphonepe\b', caseSensitive: false),
      RegExp(r'\bthousand\b', caseSensitive: false),
      RegExp(r'\bthousands\b', caseSensitive: false),
      RegExp(r'\blakh\b', caseSensitive: false),
      RegExp(r'\blakhs\b', caseSensitive: false),
      RegExp(r'\bplease\b', caseSensitive: false),
      RegExp(r'\badd\b', caseSensitive: false),
      RegExp(r'\btransaction\b', caseSensitive: false),
      RegExp(r'\bexpense\b', caseSensitive: false),
      RegExp(r'\bof\b', caseSensitive: false),
    ];

    for (var pat in fillerPatterns) {
      cleaned = cleaned.replaceAll(pat, ' ');
    }

    cleaned = cleaned.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()?]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.length >= 2) {
      final words = cleaned.split(' ');
      final titleCased = words.map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : '').join(' ');
      _merchantController.text = titleCased;
    } else if (_merchantController.text.isEmpty) {
      _merchantController.text = _category;
    }

    setState(() {});
  }

  Future<void> _handleSave() async {
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please speak or enter a valid amount"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final merchant = _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : _category;

      final tx = TransactionModel(
        amount: amt,
        description: merchant,
        category: _category,
        type: _type,
        paymentMode: _paymentMode,
        date: DateTime.now(),
      );
      await context.read<TransactionProvider>().addTransaction(tx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Voice expense recorded successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileProvider>().currency;

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
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Voice Expense Logger", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  Text("Natural Language Voice Recognition", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Voice Recording Hero Card
              _buildRecordingHeroCard(),
              const SizedBox(height: 16),

              // Live Transcript Card
              if (_transcript.isNotEmpty || _isListening) _buildTranscriptCard(),
              const SizedBox(height: 16),

              // Parsed Transaction Form Card
              _buildParsedDetailsCard(currency),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(_isSaving ? "Saving..." : "Save Transaction", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isListening ? const Color(0xFF6366F1) : const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _listen,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withOpacity(0.4),
                          blurRadius: _isListening ? 30 : 15,
                          spreadRadius: _isListening ? 6 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _isListening ? "Listening... Speak your expense" : "Tap microphone to record expense",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            "Example: 'Spent 450 rupees on dinner with friends via UPI'",
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              const Text("Voice Audio Transcript:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _transcript.isNotEmpty ? "\"$_transcript\"" : "Listening for voice input...",
            style: TextStyle(
              color: _transcript.isNotEmpty ? Colors.white : const Color(0xFF64748B),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedDetailsCard(String currency) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Parsed Transaction Details", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("AI Parsed", style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Amount ($currency)",
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF6366F1), size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 14),

          // Merchant / Description Field
          TextField(
            controller: _merchantController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Merchant / Description",
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF6366F1), size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 14),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _categories.contains(_category) ? _category : 'Other',
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Category",
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF6366F1), size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _category = val ?? 'Other'),
          ),
          const SizedBox(height: 14),

          // Type & Payment Mode Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF1E293B),
                  style: TextStyle(color: _type == 'expense' ? Colors.redAccent : Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Type",
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text("Expense")),
                    DropdownMenuItem(value: 'income', child: Text("Income")),
                  ],
                  onChanged: (val) => setState(() => _type = val ?? 'expense'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _paymentMode,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Payment Mode",
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  ),
                  items: _paymentModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => _paymentMode = val ?? 'UPI'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
