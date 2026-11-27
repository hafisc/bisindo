import 'dart:convert';

import 'package:equatable/equatable.dart';

enum DictionaryCategory {
  huruf;

  String get key => name;

  static DictionaryCategory fromKey(String raw) {
    return DictionaryCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => DictionaryCategory.huruf,
    );
  }
}

class DictionaryItem extends Equatable {
  final String id;
  final String title;
  final DictionaryCategory category;
  final String imageUrl;
  final String description;
  final List<String> instructions; // "Cara Melakukan"
  final String tips;

  const DictionaryItem({
    required this.id,
    required this.title,
    this.category = DictionaryCategory.huruf,
    this.imageUrl = '',
    this.description = '',
    this.instructions = const [],
    this.tips = '',
  });

  String get categoryName => 'Huruf';

  DictionaryItem copyWith({
    String? id,
    String? title,
    DictionaryCategory? category,
    String? imageUrl,
    String? description,
    List<String>? instructions,
    String? tips,
  }) {
    return DictionaryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      tips: tips ?? this.tips,
    );
  }

  Map<String, dynamic> toMap({int sortOrder = 0}) {
    return {
      'id': id,
      'title': title,
      'category': category.key,
      'imageUrl': imageUrl,
      'description': description,
      'instructionsJson': jsonEncode(instructions),
      'tips': tips,
      'sortOrder': sortOrder,
    };
  }

  factory DictionaryItem.fromMap(Map<String, dynamic> map) {
    final rawInstructions = map['instructionsJson'] as String? ?? '[]';
    List<String> instructions = const [];
    try {
      final decoded = jsonDecode(rawInstructions);
      if (decoded is List) {
        instructions = decoded.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {}

    return DictionaryItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: DictionaryCategory.fromKey(map['category'] as String? ?? 'huruf'),
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      instructions: instructions,
      tips: map['tips'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    imageUrl,
    description,
    instructions,
    tips,
  ];
}
