import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'phrase.dart';
import 'db_service.dart';
import 'ai_validation_service.dart';

void main() { runApp(const BizLingoApp()); }

class BizLingoApp extends StatelessWidget {
  const BizLingoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF001B3D),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
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
  List<Phrase> _phrases = [];
  List<String> _availableTopics = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  final AiValidationService _ai = AiValidationService();
  final DbService _db = DbService();

  int _idx = 0;
  bool _isChecking = false;
  String _feedback = "";
  String _aiExplanation = "";
  Color _fbColor = Colors.transparent;
  int _streak = 0;

  String _topic = "";
  String _from = "ru";
  String _to = "en";

  final Map<String, String> _langLabels = {"en": "EN", "ru": "RU", "de": "DE", "uk": "UK"};
  final Map<String, String> _ttsCodes = {"en": "en-US", "ru": "ru-RU", "de": "de-DE", "uk": "uk-UA"};

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    _initApp();
  }

  Future<void> _initApp() async {
    await _ai.initialize();
    _availableTopics = await _db.getAvailableTopics();
    if (_availableTopics.isNotEmpty) {
      _topic = _availableTopics.first;
    }
    _refreshBatch();
  }

  void _refreshBatch() async {
    if (_topic.isEmpty) return;
    setState(() { _isChecking = true; });
    final list = await _db.getRandomPhrases(_topic, _from, _to, 5);

    if (mounted) {
      setState(() {
        _isChecking = false;
        if (list.isEmpty) {
          _feedback = "All phrases learned!";
          _phrases = [];
        } else {
          _phrases = list;
          _idx = 0;
          _controller.clear();
          _feedback = "";
          _aiExplanation = "";
          _fbColor = Colors.transparent;
        }
      });
    }
  }

  void _speak(String text, String langCode) async {
    await _tts.setLanguage(_ttsCodes[langCode]!);
    await _tts.speak(text);
  }

  void _swapLanguages() {
    setState(() {
      final temp = _from;
      _from = _to;
      _to = temp;
      _refreshBatch();
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
    if (_aiExplanation.isNotEmpty && _feedback == "Correct!") {
      _nextPhrase();
      return;
    }
    if (_isChecking || _controller.text.isEmpty || _phrases.isEmpty) return;

    setState(() {
      _isChecking = true;
      _feedback = "Evaluating...";
      _aiExplanation = "";
      _fbColor = Colors.blueGrey;
    });

    final result = await _ai.detailedValidate(_controller.text, _phrases[_idx].translatedText);

    setState(() {
      _isChecking = false;
      _aiExplanation = result.reason;
      if (result.isValid) {
        _feedback = "Correct!";
        _fbColor = Colors.green;
        _streak++;
        _phrases[_idx].successStreak++;
        if (_phrases[_idx].successStreak >= 3) _phrases[_idx].isLearned = true;

        _db.updateProgress(_phrases[_idx].id, _phrases[_idx].successStreak, _phrases[_idx].isLearned);
        _speak(_phrases[_idx].translatedText, _to);

        if (result.reason.contains("Exact match") || result.reason.isEmpty) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && _feedback == "Correct!") _nextPhrase();
          });
        }
      } else {
        _feedback = "Not quite. Correct variant below:";
        _fbColor = Colors.redAccent;
        _streak = 0;
      }
    });
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required List<T> items,
    required Map<String, String>? labels,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF001B3D)),
          style: const TextStyle(color: Color(0xFF001B3D), fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labels != null ? labels[item.toString()]! : item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ai.isInitialized) return const Scaffold(backgroundColor: Color(0xFF001B3D));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("BizLingo AI", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF001B3D))),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _availableTopics.isEmpty
                      ? const Text("Loading...")
                      : _buildStyledDropdown<String>(
                    value: _topic,
                    items: _availableTopics,
                    labels: null,
                    onChanged: (v) => setState(() { _topic = v!; _refreshBatch(); }),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStyledDropdown<String>(
                  value: _from,
                  items: _langLabels.keys.toList(),
                  labels: _langLabels,
                  onChanged: (v) => setState(() { _from = v!; _refreshBatch(); }),
                ),
                IconButton(icon: const Icon(Icons.swap_horiz), onPressed: _swapLanguages),
                _buildStyledDropdown<String>(
                  value: _to,
                  items: _langLabels.keys.toList(),
                  labels: _langLabels,
                  onChanged: (v) => setState(() { _to = v!; _refreshBatch(); }),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_phrases.isNotEmpty) ...[
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(_phrases[_idx].originalText,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Color(0xFF001B3D)),
                    onPressed: () => _speak(_phrases[_idx].originalText, _from),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_aiExplanation.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(12)),
                  child: Text(_aiExplanation, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                ),
            ],
            const SizedBox(height: 20),
            TextField(
                controller: _controller,
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(
                    hintText: "Your translation...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 12),
            if (_feedback.isNotEmpty)
              Text(_feedback, style: TextStyle(color: _fbColor, fontWeight: FontWeight.bold)),

            if (_feedback.contains("Correct variant")) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Text(_phrases[_idx].translatedText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.orange),
                      onPressed: () => _speak(_phrases[_idx].translatedText, _to),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(flex: 2, child: SizedBox(height: 56, child: ElevatedButton(
                    onPressed: _isChecking ? null : _check,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001B3D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                    ),
                    child: Text(_isChecking ? "WAIT..." : (_aiExplanation.isNotEmpty && _feedback == "Correct!" ? "NEXT" : "CHECK"))
                ))),
                const SizedBox(width: 12),
                SizedBox(height: 56, child: OutlinedButton(
                    onPressed: _isChecking ? null : _nextPhrase,
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text("SKIP")
                )),
              ],
            ),
            const SizedBox(height: 30),
            if (_phrases.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _phrases.length,
                itemBuilder: (context, i) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: _idx == i ? const Color(0xFFF0F7FF) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _idx == i ? const Color(0xFF001B3D).withOpacity(0.1) : Colors.grey[100]!)
                  ),
                  child: ListTile(title: Text(_phrases[i].originalText, style: const TextStyle(fontSize: 14)), trailing: Text("${_phrases[i].successStreak}/3 ⭐")),
                ),
              ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text("© 2025-2026 Viktor Ralchenko. All rights reserved.", style: TextStyle(fontSize: 10, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}