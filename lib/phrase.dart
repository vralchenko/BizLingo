class Phrase {
  final String ru;
  final String en;
  int errors;
  int successStreak;
  bool isLearned;

  Phrase({
    required this.ru,
    required this.en,
    this.errors = 0,
    this.successStreak = 0,
    this.isLearned = false
  });

  Map<String, dynamic> toJson() => {
    'ru': ru, 'en': en, 'errors': errors,
    'successStreak': successStreak, 'isLearned': isLearned
  };

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
      ru: json['ru'], en: json['en'],
      errors: json['errors'], successStreak: json['successStreak'],
      isLearned: json['isLearned']
  );
}