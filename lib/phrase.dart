class Phrase {
  final String ru;
  final String en;
  final String de;
  final String uk;
  int errors;
  int successStreak;
  bool isLearned;

  Phrase({
    required this.ru,
    required this.en,
    required this.de,
    required this.uk,
    this.errors = 0,
    this.successStreak = 0,
    this.isLearned = false
  });

  Map<String, dynamic> toJson() => {
    'ru': ru, 'en': en, 'de': de, 'uk': uk, 'errors': errors,
    'successStreak': successStreak, 'isLearned': isLearned
  };

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
      ru: json['ru'] ?? '',
      en: json['en'] ?? '',
      de: json['de'] ?? '',
      uk: json['uk'] ?? '',
      errors: json['errors'] ?? 0,
      successStreak: json['successStreak'] ?? 0,
      isLearned: json['isLearned'] ?? false
  );

  String getText(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return ru;
      case 'en':
        return en;
      case 'de':
        return de;
      case 'uk':
        return uk;
      default:
        return en;
    }
  }
}