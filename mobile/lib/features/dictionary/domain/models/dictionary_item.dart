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
