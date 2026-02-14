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

      // Inject demo phrases if missing (Critical for Portfolio Demo)
      final demoPhrasesData = [
        {
          "category": "IT & Software",
          "ru": "Нам следует изучить возможности больших языковых моделей для улучшения поддержки клиентов.",
          "en": "We should explore LLM capabilities to improve customer support.",
          "de": "Wir sollten die Möglichkeiten großer Sprachmodelle untersuchen, um den Kundensupport zu verbessern.",
          "uk": "Нам слід вивчити можливості великих мовних моделей для покращення підтримки клієнтів."
        },
        {
          "category": "IT & Software",
          "ru": "Использование машинного обучения поможет нам предсказывать поведение пользователей.",
          "en": "Using machine learning will help us predict user behavior.",
          "de": "Der Einsatz von maschinellem Lernen wird uns helfen, das Nutzerverhalten vorherzusagen.",
          "uk": "Використання машинного навчання допоможе нам передбачати поведінку користувачів."
        },
        {
          "category": "IT & Software",
          "ru": "Интеграция ИИ в наш рабочий процесс позволит автоматизировать рутинные задачи кодирования.",
          "en": "Integrating AI into our workflow will automate routine coding tasks.",
          "de": "Die Integration von KI in unseren Arbeitsprozess wird es ermöglichen, Routineaufgaben beim Codieren zu automatisieren.",
          "uk": "Інтеграція ШІ в наш робочий процес дозволить автоматизувати рутинні задачі кодування."
        }
      ];

      for (var p in demoPhrasesData) {
        if (!_allPhrases.any((existing) => existing['ru'] == p['ru'])) {
          _allPhrases.add(p);
        }
      }
      
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

    // filtered.shuffle(); // Disable shuffle for deterministic demo
    
    // Sort specific phrases to the top for the demo
    final demoOrder = [
      "Нам следует изучить возможности больших языковых моделей для улучшения поддержки клиентов.",
      "Использование машинного обучения поможет нам предсказывать поведение пользователей.",
      "Интеграция ИИ в наш рабочий процесс позволит автоматизировать рутинные задачи кодирования."
    ];

    filtered.sort((a, b) {
      final aText = a['ru'] ?? "";
      final bText = b['ru'] ?? "";
      final aIdx = demoOrder.indexOf(aText);
      final bIdx = demoOrder.indexOf(bText);

      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
      if (aIdx != -1) return -1;
      if (bIdx != -1) return 1;
      return 0;
    });

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