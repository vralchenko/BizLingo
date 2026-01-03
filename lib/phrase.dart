class Phrase {
  final String id;
  final String originalText;
  final String translatedText;
  int successStreak;
  bool isLearned;
  int errors;

  Phrase({
    required this.id,
    required this.originalText,
    required this.translatedText,
    this.successStreak = 0,
    this.isLearned = false,
    this.errors = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orig': originalText,
    'trans': translatedText,
    'streak': successStreak,
    'learned': isLearned,
    'errors': errors,
  };

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
    id: json['id'],
    originalText: json['orig'],
    translatedText: json['trans'],
    successStreak: json['streak'] ?? 0,
    isLearned: json['learned'] ?? false,
    errors: json['errors'] ?? 0,
  );
}