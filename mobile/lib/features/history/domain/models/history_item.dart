class HistoryItem {
  final int? id;
  final String title;
  final String type; // 'Kata' | 'Huruf'
  final String category; // 'Teks' | 'Suara'
  final String mode; // 'BISINDO → Teks' | 'BISINDO → Suara'
  final String timestamp;
  final double confidence;
  final String? imagePath;

  const HistoryItem({
    this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.mode,
    required this.timestamp,
    required this.confidence,
    this.imagePath,
  });

  HistoryItem copyWith({
    int? id,
    String? title,
    String? type,
    String? category,
    String? mode,
    String? timestamp,
    double? confidence,
    String? imagePath,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      mode: mode ?? this.mode,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type': type,
      'category': category,
      'mode': mode,
      'timestamp': timestamp,
      'confidence': confidence,
      'imagePath': imagePath,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      mode: map['mode'] as String,
      timestamp: map['timestamp'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
    );
  }
}
