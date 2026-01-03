import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phrase.dart';

class DbService {
  List<Map<String, dynamic>> _allPhrases = [];
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/phrases.json');
      _allPhrases = json.decode(response).cast<Map<String, dynamic>>();
      _isLoaded = true;
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }

  Future<List<String>> getAvailableTopics() async {
    await init();
    final topics = _allPhrases.map((p) => p['category'] as String).toSet().toList();
    topics.sort();
    return topics;
  }

  Future<List<Phrase>> getRandomPhrases(String category, String fromLang, String toLang, int limit) async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    final filtered = _allPhrases.where((p) {
      bool hasLangs = p.containsKey(fromLang) && p.containsKey(toLang);
      bool learned = prefs.getBool('learned_${p[toLang]}') ?? false;
      return p['category'] == category && hasLangs && !learned;
    }).toList();

    if (filtered.isEmpty) return [];

    filtered.shuffle();
    final selection = filtered.take(limit).toList();

    return selection.map((p) {
      String targetText = p[toLang];
      return Phrase(
        id: targetText,
        originalText: p[fromLang],
        translatedText: targetText,
        successStreak: prefs.getInt('streak_$targetText') ?? 0,
        isLearned: prefs.getBool('learned_$targetText') ?? false,
      );
    }).toList();
  }

  Future<void> updateProgress(String id, int streak, bool learned) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_$id', streak);
    await prefs.setBool('learned_$id', learned);
  }
}