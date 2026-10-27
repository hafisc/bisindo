enum DictionaryCategory {
  huruf,
  kataUmum,
  frasa,
}

class DictionaryItem {
  final String id;
  final String title;
  final DictionaryCategory category;
  final String imageUrl; // We'll use this for offline images or fallback to a placeholder
  final List<String> instructions; // "Cara Melakukan"
  final String tips;

  const DictionaryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.instructions = const [],
    this.tips = '',
  });

  String get categoryName {
    switch (category) {
      case DictionaryCategory.huruf:
        return 'Huruf';
      case DictionaryCategory.kataUmum:
        return 'Kata Umum';
      case DictionaryCategory.frasa:
        return 'Frasa';
    }
  }
}