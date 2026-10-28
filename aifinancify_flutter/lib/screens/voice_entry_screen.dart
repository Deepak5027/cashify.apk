import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/transaction_provider.dart';
import '../state/profile_provider.dart';
import '../models/transaction.dart';
import '../services/voice_expense_parser.dart';

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
  String? _statusError;
  String? _statusWarning;
  double? _speechConfidence;
  double _soundLevel = 0.0;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  String _category = 'Food & Dining';
  String _type = 'expense';
  String _paymentMode = 'UPI';
  bool _isPaymentModeExplicit = false;
  String? _paymentProvider;
  String _paymentExplanation = '';
  DateTime _transactionDate = DateTime.now();
  bool _isDateExplicit = false;
  String _detectedLanguage = 'en';
  String _detectedLanguageName = 'English (en-IN)';
  double _confidence = 0.0;

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  // Language configuration supporting Auto-Detect and Pan-Indian languages
  final List<Map<String, String>> _languages = [
    {
      'id': 'auto',
      'name': 'Auto Detect',
      'sub': 'AI Multi',
      'locale': 'auto',
      'icon': '⚡',
      'example': "Speaks any language (English, हिंदी, தமிழ், తెలుగు)",
    },
    {
      'id': 'en-IN',
      'name': 'English',
      'sub': 'en-IN',
      'locale': 'en-IN',
      'icon': '🌐',
      'example': "Spent 250 rupees on lunch using Google Pay",
    },
    {
      'id': 'hi-IN',
      'name': 'हिंदी',
      'sub': 'hi-IN',
      'locale': 'hi-IN',
      'icon': '🇮🇳',
      'example': "आज 250 रुपये खाने के लिए Google Pay से दिए",
    },
    {
      'id': 'ta-IN',
      'name': 'தமிழ்',
      'sub': 'ta-IN',
      'locale': 'ta-IN',
      'icon': '🇮🇳',
      'example': "இன்னைக்கு கடையில் 250 ரூபாய்க்கு சாப்பிட்டேன், GPay மூலம் கொடுத்தேன்",
    },
    {
      'id': 'te-IN',
      'name': 'తెలుగు',
      'sub': 'te-IN',
      'locale': 'te-IN',
      'icon': '🇮🇳',
      'example': "ఈరోజు భోజనానికి 250 రూపాయలు ఖర్చు చేశాను, Google Pay ద్వారా చెల్లించాను",
    },
  ];

  String _selectedLocaleId = 'auto';
  List<stt.LocaleName> _deviceLocales = [];

  final List<String> _categories = VoiceExpenseParser.allowedCategories;
  final List<String> _paymentModes = VoiceExpenseParser.allowedPaymentModes;

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

    _initSpeechRecognizer();
  }

  String _localizeSpeechError(String errorMsg, String localeId) {
    final err = errorMsg.toLowerCase();
    final isHindi = localeId.startsWith('hi');
    final isTamil = localeId.startsWith('ta');
    final isTelugu = localeId.startsWith('te');

    if (err.contains('no_match') || err.contains('nomatch')) {
      if (isHindi) return "कोई आवाज़ नहीं सुनी गई। कृपया माइक के पास बोलें।";
      if (isTamil) return "பேச்சு எதுவும் கேட்கவில்லை. தயவுசெய்து மீண்டும் பேசவும்.";
      if (isTelugu) return "మాటలు స్పష్టంగా వినపడలేదు. దయచేసి మళ్ళీ మాట్లాడండి.";
      return "No speech detected. Please speak closer to the microphone.";
    }
    if (err.contains('timeout')) {
      if (isHindi) return "समय समाप्त हो गया। माइक दबाकर फिर से बोलें।";
      if (isTamil) return "நேரம் முடிந்தது. மைக்ரோஃபோனை அழுத்தி மீண்டும் பேசவும்.";
      if (isTelugu) return "సమయం ముగిసింది. మైక్రోఫోన్ నొక్కి మళ్ళీ మాట్లాడండి.";
      return "Listening timed out. Please tap the mic and try again.";
    }
    if (err.contains('permission')) {
      if (isHindi) return "माइक्रोफ़ोन अनुमति आवश्यक है। सेटिंग्स में सक्षम करें।";
      if (isTamil) return "மைக்ரோஃபோன் அனுமதி தேவை. அமைப்புகளில் இயக்கவும்.";
      if (isTelugu) return "మైక్రోఫోన్ అనుమతి అవసరం. సెట్టింగ్స్‌లో అనుమతించండి.";
      return "Microphone permission required. Please enable it in Settings.";
    }
    if (err.contains('network')) {
      if (isHindi) return "नेटवर्क त्रुटि। कृपया इंटरनेट कनेक्शन जांचें।";
      if (isTamil) return "நெட்வொர்க் பிழை. இணைய இணைப்பைச் சரிபார்க்கவும்.";
      if (isTelugu) return "నెట్‌వర్క్ సమస్య. ఇంటర్నెట్ కనెక్షన్‌ను తనిఖీ చేయండి.";
      return "Network issue. Please check your internet connection.";
    }
    if (err.contains('language') || err.contains('not_supported')) {
      if (isHindi) return "इस डिवाइस पर हिंदी वॉइस पहचान समर्थित नहीं है।";
      if (isTamil) return "இந்த சாதனத்தில் தமிழ் குரல் அங்கீகாரம் ஆதரிக்கப்படவில்லை.";
      if (isTelugu) return "ఈ పరికరంలో తెలుగు వాయిస్ రికగ్నిషన్ అందుబాటులో లేదు.";
      return "Selected language is not supported by the device speech engine.";
    }
    if (err.contains('busy') || err.contains('in_use')) {
      if (isHindi) return "वॉइस सेवा व्यस्त है। कृपया थोड़ी देर बाद प्रयास करें।";
      if (isTamil) return "குரல் சேவை தற்போது பயன்பாட்டில் உள்ளது. சிறிது நேரம் கழித்து முயற்சிக்கவும்.";
      if (isTelugu) return "వాయిస్ సర్వీస్ బిజీగా ఉంది. కొద్దిసేపు వేచి ఉండండి.";
      return "Speech service is busy. Please try again in a moment.";
    }
    return errorMsg;
  }

  Future<void> _initSpeechRecognizer() async {
    try {
      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _parseVoiceInput(_transcript, speechConfidence: _speechConfidence);
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusError = _localizeSpeechError(val.errorMsg, _selectedLocaleId);
            });
          }
        },
      );

      if (available) {
        try {
          final locales = await _speech.locales();
          if (mounted) {
            setState(() => _deviceLocales = locales);
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusError = _localizeSpeechError(e.toString(), _selectedLocaleId));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    try {
      _speech.stop();
    } catch (_) {}
    super.dispose();
  }

  void _listen() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    setState(() {
      _statusError = null;
      _statusWarning = null;
    });

    bool available = _speech.isAvailable;
    if (!available) {
      available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            _parseVoiceInput(_transcript, speechConfidence: _speechConfidence);
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusError = _localizeSpeechError(val.errorMsg, _selectedLocaleId);
            });
          }
        },
      );
    }

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Microphone or Speech Recognition unavailable. Please check permissions."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Resolve optimal device locale matching selection
    String effectiveLocale = _selectedLocaleId == 'auto' ? 'en-IN' : _selectedLocaleId;
    if (_deviceLocales.isNotEmpty && _selectedLocaleId != 'auto') {
      final target = _selectedLocaleId.toLowerCase();
      final normTarget = target.replaceAll('-', '_');

      // 1. Exact match (case-insensitive, dash or underscore)
      stt.LocaleName? match = _deviceLocales.cast<stt.LocaleName?>().firstWhere(
        (loc) {
          final id = loc!.localeId.toLowerCase();
          return id == target || id.replaceAll('-', '_') == normTarget;
        },
        orElse: () => null,
      );

      // 2. Language-only prefix match (e.g. 'hi', 'ta', 'te', 'en')
      if (match == null) {
        final langPrefix = target.split('-')[0];
        match = _deviceLocales.cast<stt.LocaleName?>().firstWhere(
          (loc) => loc!.localeId.toLowerCase().startsWith(langPrefix),
          orElse: () => null,
        );
      }

      if (match != null) {
        effectiveLocale = match.localeId;
      }
    } else if (_selectedLocaleId == 'auto' && _deviceLocales.isNotEmpty) {
      // For auto mode, pick en-IN or first Indian regional locale
      stt.LocaleName? match = _deviceLocales.cast<stt.LocaleName?>().firstWhere(
        (loc) => loc!.localeId.toLowerCase().contains('in'),
        orElse: () => _deviceLocales.first,
      );
      if (match != null) {
        effectiveLocale = match.localeId;
      }
    }

    setState(() {
      _isListening = true;
      _transcript = '';
      _speechConfidence = null;
      _soundLevel = 0.0;
    });

    try {
      await _speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              _transcript = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _speechConfidence = val.confidence;
              }
            });
            _parseVoiceInput(_transcript, speechConfidence: _speechConfidence);
          }
        },
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() => _soundLevel = level);
          }
        },
        localeId: effectiveLocale,
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false, // Prevents premature cancellation on ambient noise
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusError = _localizeSpeechError(e.toString(), _selectedLocaleId);
        });
      }
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    try {
      _speech.stop();
    } catch (_) {}
    _parseVoiceInput(_transcript, speechConfidence: _speechConfidence);
  }

  void _parseVoiceInput(String text, {double? speechConfidence}) {
    if (text.trim().isEmpty) return;

    final result = VoiceExpenseParser.parse(
      text,
      hintLocale: _selectedLocaleId == 'auto' ? null : _selectedLocaleId,
      defaultPaymentMode: _paymentMode,
      speechConfidence: speechConfidence,
    );

    if (result.amount != null && result.amount! > 0) {
      final amt = result.amount!;
      _amountController.text = amt.toStringAsFixed(amt.truncateToDouble() == amt ? 0 : 2);
      _statusWarning = null;
    } else {
      _amountController.text = '';
      if (_selectedLocaleId.startsWith('hi')) {
        _statusWarning = "राशि स्पष्ट रूप से नहीं मिली। कृपया राशि दोबारा बोलें या नीचे दर्ज करें।";
      } else if (_selectedLocaleId.startsWith('ta')) {
        _statusWarning = "தொகை தெளிவாக கேட்கவில்லை. தொகையை மீண்டும் பேசவும் அல்லது கீழே உள்ளிடவும்.";
      } else if (_selectedLocaleId.startsWith('te')) {
        _statusWarning = "మొత్తం స్పష్టంగా వినపడలేదు. మొత్తాన్ని మళ్ళీ చెప్పండి లేదా కింద నమోదు చేయండి.";
      } else {
        _statusWarning = "Amount not detected. Please repeat or enter it manually below.";
      }
    }

    if (result.description.isNotEmpty) {
      _merchantController.text = result.description;
    }

    _category = result.category;
    _type = result.type;
    _paymentMode = result.paymentMode;
    _isPaymentModeExplicit = result.isPaymentModeExplicit;
    _paymentProvider = result.paymentProvider;
    _paymentExplanation = result.paymentExplanation;
    _transactionDate = result.date;
    _isDateExplicit = result.isDateExplicit;
    _detectedLanguage = result.detectedLanguage;
    _detectedLanguageName = result.detectedLanguageName;
    _confidence = result.confidence;

    if (mounted) setState(() {});
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please speak or enter a valid amount"),
          backgroundColor: Colors.red,
        ),
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
        date: _transactionDate,
      );
      await context.read<TransactionProvider>().addTransaction(tx);

      if (mounted) {
        final providerTag = _paymentProvider != null ? " ($_paymentProvider)" : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Recorded ₹${amt.toStringAsFixed(0)} via $_paymentMode$providerTag successfully!"),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
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
    final currentLangConfig = _languages.firstWhere(
      (l) => l['locale'] == _selectedLocaleId,
      orElse: () => _languages.first,
    );

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
                  Text("Multilingual AI • Auto Payment Detection", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
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
              // Language Selector Pills with Auto Detect
              _buildLanguageSelector(),
              const SizedBox(height: 12),

              // Voice Recording Hero Card with Live Sound Equalizer
              _buildRecordingHeroCard(currentLangConfig),
              const SizedBox(height: 16),

              // Live Transcript Card
              if (_transcript.isNotEmpty || _isListening) _buildTranscriptCard(),
              if (_transcript.isNotEmpty || _isListening) const SizedBox(height: 12),

              // Prominent Real-time Payment Mode Notification Banner
              if (_transcript.isNotEmpty) _buildPaymentNotificationBanner(),
              if (_transcript.isNotEmpty) const SizedBox(height: 14),

              // Parsed Transaction Form Card with interactive payment mode chips
              _buildParsedDetailsCard(currency),
              const SizedBox(height: 24),

              // Action Save Button
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
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _languages.map((lang) {
            final isSelected = _selectedLocaleId == lang['locale'];
            return GestureDetector(
              onTap: () {
                if (_isListening) _stopListening();
                setState(() {
                  _selectedLocaleId = lang['locale']!;
                });
                if (_transcript.isNotEmpty) {
                  _parseVoiceInput(_transcript);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang['icon']!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          lang['sub']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecordingHeroCard(Map<String, String> langConfig) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening ? const Color(0xFF6366F1) : const Color(0xFF334155),
          width: _isListening ? 1.5 : 1.0,
        ),
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
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          // Live Audio Equalizer Waveform during speech
          if (_isListening) _buildAudioWaveform(),

          const SizedBox(height: 14),
          Text(
            _isListening
                ? (_selectedLocaleId == 'auto'
                    ? "Listening (Auto-Detecting Language)..."
                    : "Listening in ${langConfig['name']}...")
                : "Tap microphone to record expense",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            "Example: \"${langConfig['example']}\"",
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          if (_statusError != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusError!,
              style: const TextStyle(fontSize: 11, color: Color(0xFFF87171)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioWaveform() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(9, (index) {
          final factors = [0.35, 0.65, 0.95, 0.55, 1.0, 0.75, 0.85, 0.45, 0.6];
          final factor = factors[index % factors.length];
          final normalizedLevel = (_soundLevel.clamp(-20.0, 10.0) + 20.0) / 30.0;
          final dynamicHeight = (8.0 + (normalizedLevel * 22.0 * factor) * _pulseAnim.value).clamp(6.0, 28.0);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 4,
            height: dynamicHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
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
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "Audio Transcript",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (_transcript.isNotEmpty && !_isListening) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _transcript = '';
                      _statusError = null;
                      _statusWarning = null;
                      _amountController.clear();
                      _merchantController.clear();
                      _isPaymentModeExplicit = false;
                      _paymentProvider = null;
                      _paymentExplanation = '';
                      _confidence = 0.0;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 11, color: Color(0xFF94A3B8)),
                        SizedBox(width: 2),
                        Text("Clear", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
              if (_transcript.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _detectedLanguage.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 75),
                        child: Text(
                          _detectedLanguageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
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

  /// Prominent Real-time Payment Notification Banner
  Widget _buildPaymentNotificationBanner() {
    final isExplicit = _isPaymentModeExplicit;
    Color primaryColor;
    Color bgColor;
    IconData iconData;

    switch (_paymentMode) {
      case 'Cash':
        primaryColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        iconData = Icons.payments_rounded;
        break;
      case 'Card':
        primaryColor = const Color(0xFFA855F7);
        bgColor = const Color(0xFFA855F7).withOpacity(0.12);
        iconData = Icons.credit_card_rounded;
        break;
      case 'Bank Transfer':
        primaryColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withOpacity(0.12);
        iconData = Icons.account_balance_rounded;
        break;
      case 'UPI':
      default:
        primaryColor = const Color(0xFF06B6D4);
        bgColor = const Color(0xFF06B6D4).withOpacity(0.12);
        iconData = Icons.bolt_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExplicit ? primaryColor.withOpacity(0.7) : const Color(0xFF334155),
          width: isExplicit ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isExplicit ? "Payment Auto-Detected: $_paymentMode" : "Payment Mode: $_paymentMode (Default)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExplicit && _paymentProvider != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _paymentProvider!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _paymentExplanation.isNotEmpty
                      ? _paymentExplanation
                      : (isExplicit ? "Automatically recognized from voice speech" : "Not specified in speech — tap payment chips below to adjust"),
                  style: TextStyle(
                    color: isExplicit ? primaryColor : const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
              const Expanded(
                child: Text(
                  "Parsed Transaction Details",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: [
                  if (_isDateExplicit)
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _transactionDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF6366F1),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _transactionDate = picked;
                            _isDateExplicit = true;
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 10, color: Color(0xFF60A5FA)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd').format(_transactionDate),
                              style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _confidence >= 0.7
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _confidence > 0 ? "AI Parsed (${(_confidence * 100).toInt()}%)" : "AI Ready",
                      style: TextStyle(
                        color: _confidence >= 0.7 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_statusWarning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusWarning!,
                      style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

          // Transaction Type (Expense vs Income)
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: const Color(0xFF1E293B),
            style: TextStyle(color: _type == 'expense' ? Colors.redAccent : Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Transaction Type",
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
          const SizedBox(height: 16),

          // Interactive Payment Mode Selector Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Method", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
                  if (_isPaymentModeExplicit)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          "Auto: $_paymentMode",
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _paymentModes.map((mode) {
                  final isSelected = _paymentMode == mode;
                  final isAutoSelected = _isPaymentModeExplicit && isSelected;

                  IconData modeIcon;
                  Color activeColor;
                  switch (mode) {
                    case 'Cash':
                      modeIcon = Icons.payments_rounded;
                      activeColor = const Color(0xFF10B981);
                      break;
                    case 'Card':
                      modeIcon = Icons.credit_card_rounded;
                      activeColor = const Color(0xFFA855F7);
                      break;
                    case 'Bank Transfer':
                      modeIcon = Icons.account_balance_rounded;
                      activeColor = const Color(0xFF3B82F6);
                      break;
                    case 'UPI':
                    default:
                      modeIcon = Icons.bolt_rounded;
                      activeColor = const Color(0xFF06B6D4);
                      break;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _paymentMode = mode;
                          _paymentExplanation = "Selected: $mode";
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.18) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : const Color(0xFF334155),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  modeIcon,
                                  size: 18,
                                  color: isSelected ? activeColor : const Color(0xFF94A3B8),
                                ),
                                if (isAutoSelected)
                                  Positioned(
                                    top: -6,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: activeColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("✨", style: TextStyle(fontSize: 8)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode == 'Bank Transfer' ? 'Bank' : mode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
