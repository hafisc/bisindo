import '../../domain/models/dictionary_item.dart';

class DummyDictionaryRepository {
  static final List<DictionaryItem> allItems = [
    // Alphabet A-Z
    ...List.generate(26, (index) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
      return DictionaryItem(
        id: 'letter_$letter',
        title: letter,
        category: DictionaryCategory.huruf,
        imageUrl: '', // Blank for now, we will show a placeholder UI in the view
        instructions: [
          'Bentuk tangan sesuai dengan isyarat $letter.',
          'Posisikan tangan sejajar dengan dada.',
          'Pastikan tangan terlihat jelas.',
        ],
        tips: 'Lakukan dengan gerakan yang jelas dan tidak terlalu cepat.',
      );
    }),
    
    // Some Kata Umum
    const DictionaryItem(
      id: 'word_terima_kasih',
      title: 'Terima kasih',
      category: DictionaryCategory.kataUmum,
      imageUrl: '',
      instructions: [
        'Bentuk tangan terbuka.',
        'Sentuh dagu dengan ujung jari.',
        'Gerakkan tangan ke depan dan ke bawah.',
      ],
      tips: 'Tersenyum saat melakukan isyarat ini.',
    ),
    const DictionaryItem(
      id: 'word_tolong',
      title: 'Tolong',
      category: DictionaryCategory.kataUmum,
      imageUrl: '',
      instructions: [
        'Letakkan telapak tangan kiri terbuka menghadap atas.',
        'Letakkan tangan kanan di atas telapak tangan kiri.',
        'Angkat kedua tangan ke atas perlahan.',
      ],
      tips: 'Gerakan ini menunjukkan mengangkat sesuatu atau meminta bantuan.',
    ),
    const DictionaryItem(
      id: 'word_maaf',
      title: 'Maaf',
      category: DictionaryCategory.kataUmum,
      imageUrl: '',
      instructions: [
        'Kuncupkan semua jari tangan kanan.',
        'Letakkan ujung jari di dada tengah.',
        'Putar tangan di dada.',
      ],
      tips: 'Tunjukkan ekspresi wajah memohon maaf.',
    ),
  ];

  static List<DictionaryItem> getItemsByCategory(DictionaryCategory? category) {
    if (category == null) return allItems;
    return allItems.where((item) => item.category == category).toList();
  }

  static DictionaryItem? getItemById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<DictionaryItem> searchItems(String query) {
    if (query.isEmpty) return allItems;
    final lowerQuery = query.toLowerCase();
    return allItems.where((item) => item.title.toLowerCase().contains(lowerQuery)).toList();
  }
}