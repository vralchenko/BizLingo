import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'phrase.dart';
import 'phrases_data.dart';
import 'ai_validation_service.dart';

void main() { runApp(const BizLingoApp()); }

class BizLingoApp extends StatelessWidget {
  const BizLingoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF001B3D), useMaterial3: true),
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
  List<Phrase> _phrases = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  final AiValidationService _ai = AiValidationService();
  int _idx = 0;
  bool _isChecking = false;
  String _feedback = "";
  String _aiExplanation = "";
  Color _fbColor = Colors.transparent;
  int _streak = 0;

  String _topic = "General Business";
  String _from = "ru";
  String _to = "en";

  final Map<String, String> _langLabels = {"en": "EN", "de": "DE", "ru": "RU", "uk": "UK"};
  final Map<String, String> _ttsCodes = {"en": "en-US", "de": "de-DE", "ru": "ru-RU", "uk": "uk-UA"};

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    _initAi();
  }

  Future<void> _initAi() async {
    await _ai.initialize();
    _refreshBatch();
    if (mounted) setState(() {});
  }

  void _refreshBatch() {
    final list = businessPhrases[_topic] ?? [];
    if (list.isEmpty) return;
    setState(() {
      final pool = List.from(list)..shuffle();
      _phrases = pool.take(5).map((m) => Phrase(
        id: Random().nextInt(1000000).toString(),
        originalText: m[_from] ?? "",
        translatedText: m[_to] ?? "",
      )).toList();
      _idx = 0;
      _controller.clear();
      _feedback = "";
      _aiExplanation = "";
      _fbColor = Colors.transparent;
    });
  }

  void _nextPhrase() {
    int next = _phrases.indexWhere((p) => !p.isLearned, _idx + 1);
    if (next == -1) next = _phrases.indexWhere((p) => !p.isLearned);

    if (next != -1) {
      setState(() {
        _idx = next;
        _controller.clear();
        _feedback = "";
        _aiExplanation = "";
        _fbColor = Colors.transparent;
      });
    } else {
      _refreshBatch();
    }
  }

  Future<void> _check() async {
    // Если объяснение уже на экране, эта же кнопка работает как "Далее"
    if (_aiExplanation.isNotEmpty && _feedback == "Правильно!") {
      _nextPhrase();
      return;
    }

    if (_isChecking || _controller.text.isEmpty) return;

    setState(() {
      _isChecking = true;
      _feedback = "Проверяем...";
      _aiExplanation = "";
      _fbColor = Colors.blueGrey;
    });

    final result = await _ai.detailedValidate(_controller.text, _phrases[_idx].translatedText);

    setState(() {
      _isChecking = false;
      _aiExplanation = result.reason;
      if (result.isValid) {
        _feedback = "Правильно!";
        _fbColor = Colors.green;
        _streak++;
        _phrases[_idx].successStreak++;
        if (_phrases[_idx].successStreak >= 3) _phrases[_idx].isLearned = true;
      } else {
        _feedback = "Не совсем так. Попробуйте еще раз!";
        _fbColor = Colors.redAccent;
        _streak = 0;
      }
    });

    if (result.isValid) {
      await _tts.setLanguage(_ttsCodes[_to]!);
      await _tts.speak(_phrases[_idx].translatedText);

      // Авто-переход ТОЛЬКО если это был точный маппинг (нет длинного пояснения)
      if (result.reason.contains("Точное совпадение") || result.reason.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted && _feedback == "Правильно!") {
          _nextPhrase();
        }
      }
      // Если есть объяснение от ИИ, код просто остановится здесь, давая время почитать.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ai.isInitialized) return const Scaffold(backgroundColor: Color(0xFF001B3D));

    // Текст кнопки зависит от состояния
    String buttonText = _isChecking ? "ЖДИТЕ..." : "ПРОВЕРИТЬ";
    if (_aiExplanation.isNotEmpty && _feedback == "Правильно!") {
      buttonText = "СЛЕДУЮЩАЯ";
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("BizLingo AI", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                Text(" $_streak", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
              ]),
            )
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshBatch)],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Card(
              elevation: 0, color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: _drop(_topic, businessPhrases.keys.toList(), (v) => setState(() { _topic = v!; _refreshBatch(); }))),
                    const VerticalDivider(),
                    _drop(_from, _langLabels.keys.toList(), (v) => setState(() { _from = v!; _refreshBatch(); }), isCode: true),
                    IconButton(icon: const Icon(Icons.swap_horiz, size: 20), onPressed: () => setState(() { final t = _from; _from = _to; _to = t; _refreshBatch(); })),
                    _drop(_to, _langLabels.keys.toList(), (v) => setState(() { _to = v!; _refreshBatch(); }), isCode: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(_phrases[_idx].originalText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            if (_aiExplanation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                child: Text(_aiExplanation, style: const TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 15),
            TextField(controller: _controller, onSubmitted: (_) => _check(), decoration: const InputDecoration(hintText: "Ваш перевод..."), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_feedback.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _fbColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_feedback, style: TextStyle(color: _fbColor, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: SizedBox(height: 50, child: ElevatedButton(onPressed: _isChecking ? null : _check, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001B3D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(buttonText)))),
                const SizedBox(width: 10),
                SizedBox(height: 50, child: OutlinedButton(onPressed: _isChecking ? null : _nextPhrase, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("ПРОПУСТИТЬ"))),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _phrases.length,
                itemBuilder: (context, i) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), color: _idx == i ? Colors.blue.withOpacity(0.05) : Colors.white, child: ListTile(dense: true, title: Text(_phrases[i].originalText), trailing: Text("${_phrases[i].successStreak}/3 ⭐"))),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 16), child: Text("© 2025-2026 Viktor Ralchenko. All rights reserved.", style: TextStyle(fontSize: 10, color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _drop(String val, List<String> items, ValueChanged<String?> onCh, {bool isCode = false}) {
    return DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, isDense: true, items: items.map((i) => DropdownMenuItem(value: i, child: Text(isCode ? _langLabels[i]! : i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(), onChanged: onCh));
  }
}