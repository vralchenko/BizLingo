import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'phrase.dart';
import 'phrases_data.dart';
import 'ai_validation_service.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const BizLingoApp());
}

class BizLingoApp extends StatelessWidget {
  const BizLingoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizLingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF001B3D),
        useMaterial3: true,
      ),
      home: const TrainingScreen(),
    );
  }
}

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  List<Phrase> _phrases = getInitialPhrases();
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final AiValidationService _aiValidationService = AiValidationService();

  String _resultMessage = "";
  bool _isChecking = false;
  bool _showNextButton = false;
  int _currentIdxInBuffer = 0;
  final String _appVersion = "1.1.2-Final";

  String _learningLanguage = 'ru';
  String _translationLanguage = 'en';

  final Map<String, String> _languageNames = {
    'ru': 'Русский',
    'en': 'English',
    'de': 'Deutsch',
    'uk': 'Українська',
  };

  final Map<String, String> _ttsLanguageCodes = {
    'ru': 'ru-RU',
    'en': 'en-US',
    'de': 'de-DE',
    'uk': 'uk-UA',
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadData();
    _loadLanguageSettings();
    _initializeAiModel();
  }

  Future<void> _initializeAiModel() async {
    try {
      await _aiValidationService.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    _aiValidationService.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_ttsLanguageCodes[_translationLanguage] ?? "en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _learningLanguage = prefs.getString('learning_language') ?? 'ru';
      _translationLanguage = prefs.getString('translation_language') ?? 'en';
    });
    await _initTts();
  }

  Future<void> _saveLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_language', _learningLanguage);
    await prefs.setString('translation_language', _translationLanguage);
    await _initTts();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('bizlingo_v1_data');
    if (data != null) {
      final List decode = jsonDecode(data);
      setState(() {
        _phrases = decode.map((item) => Phrase.fromJson(item)).toList();
      });
    }
    FlutterNativeSplash.remove();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'bizlingo_v1_data',
      jsonEncode(_phrases.map((p) => p.toJson()).toList()),
    );
  }

  List<Phrase> get _activeBuffer =>
      _phrases.where((p) => !p.isLearned).take(5).toList();

  Future<void> _check() async {
    if (_isChecking || _showNextButton || _activeBuffer.isEmpty || _aiValidationService.isInitializing) return;

    final current = _activeBuffer[_currentIdxInBuffer];
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    final correctTranslation = current.getText(_translationLanguage);
    final originalText = current.getText(_learningLanguage);

    setState(() {
      _isChecking = true;
      _resultMessage = _aiValidationService.isInitialized
          ? "🤖 AI is checking..."
          : "Checking...";
    });

    final RegExp punctuation = RegExp(r'[^\w\s]');
    final normalizedUser = userInput.toLowerCase().replaceAll(punctuation, '');
    final normalizedCorrect = correctTranslation.toLowerCase().replaceAll(punctuation, '');

    if (normalizedUser == normalizedCorrect) {
      _handleSuccess(current, correctTranslation, "✅ Perfect match!");
      return;
    }

    if (!_aiValidationService.isInitialized) {
      _handleFailure(current, correctTranslation, "❌ Try again!");
      return;
    }

    try {
      final result = await _aiValidationService.validateTranslation(
        originalText: originalText,
        userTranslation: userInput,
        correctTranslation: correctTranslation,
        learningLanguage: _learningLanguage,
        translationLanguage: _translationLanguage,
      );

      if (result.isValid) {
        _handleSuccess(current, correctTranslation, "✅ ${result.feedback}");
      } else {
        _handleFailure(current, correctTranslation, "❌ ${result.feedback}");
      }
    } catch (_) {
      _handleFailure(current, correctTranslation, "❌ AI error.");
    }
  }

  void _handleSuccess(Phrase current, String translation, String message) {
    setState(() {
      _resultMessage = message;
      _speak(translation);
      current.successStreak++;
      if (current.successStreak >= 3) current.isLearned = true;
      _saveData();
      _isChecking = false;
      _showNextButton = true;
    });
  }

  void _handleFailure(Phrase current, String translation, String message) {
    setState(() {
      _resultMessage = "$message\n\nCorrect answer: $translation";
      current.errors++;
      current.successStreak = 0;
      _saveData();
      _isChecking = false;
      _showNextButton = true;
    });
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _resultMessage = "";
      _isChecking = false;
      _showNextButton = false;
      final bufferSize = _activeBuffer.length;
      if (bufferSize > 1) {
        int nextIdx;
        do {
          nextIdx = Random().nextInt(bufferSize);
        } while (nextIdx == _currentIdxInBuffer);
        _currentIdxInBuffer = nextIdx;
      } else {
        _currentIdxInBuffer = 0;
      }
    });
  }

  void _showLanguageSettings() {
    String tempLearningLanguage = _learningLanguage;
    String tempTranslationLanguage = _translationLanguage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Original:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: tempLearningLanguage,
                isExpanded: true,
                items: _languageNames.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setDialogState(() => tempLearningLanguage = v!),
              ),
              const SizedBox(height: 20),
              const Text('Target:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: tempTranslationLanguage,
                isExpanded: true,
                items: _languageNames.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setDialogState(() => tempTranslationLanguage = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _learningLanguage = tempLearningLanguage;
                  _translationLanguage = tempTranslationLanguage;
                });
                _saveLanguageSettings();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buffer = _activeBuffer;
    int learnedCount = _phrases.where((p) => p.isLearned).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("BizLingo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSettings,
          ),
          if (buffer.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () => _speak(
                buffer[_currentIdxInBuffer].getText(_translationLanguage),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: buffer.isEmpty
                ? const Center(child: Text("All phrases learned! 🏆"))
                : Column(
              children: [
                LinearProgressIndicator(
                  value: learnedCount / _phrases.length,
                  minHeight: 10,
                ),
                const SizedBox(height: 40),
                Text(
                  buffer[_currentIdxInBuffer].getText(_learningLanguage),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _controller,
                  enabled: !_showNextButton,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _check(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Translation",
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _resultMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: _aiValidationService.isInitializing
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _isChecking ? null : (_showNextButton ? _next : _check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001B3D),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isChecking ? "AI..." : (_showNextButton ? "NEXT" : "CHECK")),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "V $_appVersion",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "© 2025-2026 Viktor Ralchenko. All rights reserved.",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}