class Phrase {
  final String id;
  final String originalText;
  final String translatedText;
  int successStreak;
  bool isLearned;

  Phrase({
    required this.id,
    required this.originalText,
    required this.translatedText,
    this.successStreak = 0,
    this.isLearned = false,
  });
}