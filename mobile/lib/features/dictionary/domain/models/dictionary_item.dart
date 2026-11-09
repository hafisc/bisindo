class DictionaryItem {
  final String letter;
  final String title;
  final String description;
  final String? assetPath;
  final List<String> tips;

  const DictionaryItem({
    required this.letter,
    required this.title,
    required this.description,
    this.assetPath,
    this.tips = const [],
  });

  factory DictionaryItem.fromJson(Map<String, dynamic> json) {
    return DictionaryItem(
      letter: json['letter'] as String? ?? '',
      title: json['title'] as String? ?? 'Huruf ${json['letter']}',
      description: json['description'] as String? ?? '',
      assetPath: json['asset_path'] as String? ?? json['image_url'] as String?,
      tips: (json['tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'title': title,
      'description': description,
      'asset_path': assetPath,
      'tips': tips,
    };
  }
}
=======
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
