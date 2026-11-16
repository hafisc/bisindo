class HistoryItem {
  /// Id baris di SQLite lokal.
  final int? id;

  /// Id entri di server (`detection_logs.id`). `null` berarti belum terkirim.
  final int? remoteId;

  final String title;
  final String type; // 'Kata' | 'Huruf'
  final String category; // 'Teks' | 'Suara'
  final String mode; // 'BISINDO → Teks' | 'BISINDO → Suara'

  /// Waktu lokal dalam format ISO-8601 tanpa zona waktu.
  final String timestamp;
  final double confidence;
  final String? imagePath;

  const HistoryItem({
    this.id,
    this.remoteId,
    required this.title,
    required this.type,
    required this.category,
    required this.mode,
    required this.timestamp,
    required this.confidence,
    this.imagePath,
  });

  bool get isSynced => remoteId != null;

  HistoryItem copyWith({
    int? id,
    int? remoteId,
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
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      mode: mode ?? this.mode,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Kolom untuk tabel `history`. `userId` diisi oleh data source lokal.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'remoteId': remoteId,
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
      remoteId: map['remoteId'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      mode: map['mode'] as String,
      timestamp: map['timestamp'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
    );
  }

  /// Body untuk `POST /api/history`. Waktu dikirim dalam UTC agar server
  /// menyimpan nilai yang benar apa pun zona waktu HP.
  Map<String, dynamic> toServerJson() {
    final local = DateTime.tryParse(timestamp) ?? DateTime.now();
    return {
      'title': title,
      'type': type,
      'category': category,
      'mode': mode,
      'confidence': confidence,
      'timestamp': local.toUtc().toIso8601String(),
    };
  }

  /// Entri dari `GET /api/history`. Server mengirim waktu UTC tanpa zona
  /// waktu, jadi diubah ke waktu lokal HP.
  factory HistoryItem.fromServerJson(Map<String, dynamic> json) {
    final rawTime = (json['timestamp'] as String?)?.trim() ?? '';
    final hasZone = rawTime.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(rawTime);
    final parsed = DateTime.tryParse(hasZone ? rawTime : '${rawTime}Z');
    final type = json['type'] as String?;
    final category = json['category'] as String?;

    return HistoryItem(
      remoteId: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? (json['letter'] as String?) ?? '-',
      type: type == 'Kata' ? 'Kata' : 'Huruf',
      category: category == 'Suara' ? 'Suara' : 'Teks',
      mode: (json['mode'] as String?) ??
          (category == 'Suara' ? 'BISINDO → Suara' : 'BISINDO → Teks'),
      timestamp: (parsed ?? DateTime.now().toUtc()).toLocal().toIso8601String(),
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      imagePath: json['image_path'] as String?,
    );
  }
}
