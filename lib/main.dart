import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'phrase.dart';
import 'phrases_data.dart';

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

  String _resultMessage = "";
  bool _isChecking = false;
  int _currentIdxInBuffer = 0;
  final String _appVersion = "1.0.1";
  
  // Language selection
  String _learningLanguage = 'ru'; // Language shown to user
  String _translationLanguage = 'en'; // Language user needs to translate to
  
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
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
    await prefs.setString('bizlingo_v1_data', jsonEncode(_phrases.map((p) => p.toJson()).toList()));
  }

  List<Phrase> get _activeBuffer => _phrases.where((p) => !p.isLearned).take(5).toList();

  void _check() {
    if (_isChecking || _activeBuffer.isEmpty) return;

    setState(() {
      _isChecking = true;
      final current = _activeBuffer[_currentIdxInBuffer];
      final RegExp punctuation = RegExp(r'[^\w\s]');

      String user = _controller.text.trim().toLowerCase().replaceAll(punctuation, '');
      String correct = current.getText(_translationLanguage).toLowerCase().replaceAll(punctuation, '');

      if (user == correct) {
        _resultMessage = "✅ Excellent!";
        _speak(current.getText(_translationLanguage));
        current.successStreak++;
        if (current.successStreak >= 3) current.isLearned = true;
        _saveData();
        Future.delayed(const Duration(seconds: 2), _next);
      } else {
        _resultMessage = "❌ Wrong. Correct:\n${current.getText(_translationLanguage)}";
        current.errors++;
        current.successStreak = 0;
        _saveData();
        _isChecking = false;
      }
    });
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _resultMessage = "";
      _isChecking = false;

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Learning Language:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _learningLanguage,
              isExpanded: true,
              items: _languageNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != _translationLanguage) {
                  setState(() {
                    _learningLanguage = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text('Translation Language:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _translationLanguage,
              isExpanded: true,
              items: _languageNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != _learningLanguage) {
                  setState(() {
                    _translationLanguage = value;
                  });
                }
              },
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
              _saveLanguageSettings();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _phrases.length,
                itemBuilder: (context, index) {
                  final p = _phrases[index];
                  return ListTile(
                    leading: Text("${index + 1}"),
                    title: Text(p.getText(_learningLanguage)),
                    subtitle: Text("${p.getText(_translationLanguage)}\nErrors: ${p.errors} | Streak: ${p.successStreak}/3"),
                    trailing: p.isLearned ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  );
                },
              ),
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
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.bar_chart), onPressed: _showStats),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSettings,
            tooltip: 'Language Settings',
          ),
          if (buffer.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () => _speak(buffer[_currentIdxInBuffer].getText(_translationLanguage)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: buffer.isEmpty
            ? const Center(child: Text("All Done! 🏆", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))
            : Column(
          children: [
            LinearProgressIndicator(
              value: learnedCount / _phrases.length,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Text("Overall Progress: $learnedCount / ${_phrases.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            Text("Phrase Mastery: ${buffer[_currentIdxInBuffer].successStreak}/3", style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 10),
            Text(
              buffer[_currentIdxInBuffer].getText(_learningLanguage),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              maxLines: 1,
              autofocus: true,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _check(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "${_languageNames[_translationLanguage]} Translation",
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => _controller.clear()),
              ),
            ),
            const SizedBox(height: 20),
            Text(_resultMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001B3D), foregroundColor: Colors.white),
                child: const Text("CHECK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            Text(
                "© 2025-2026 Viktor Ralchenko. Version $_appVersion",
                style: const TextStyle(fontSize: 10, color: Colors.grey)
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}