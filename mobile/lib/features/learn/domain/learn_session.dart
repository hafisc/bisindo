import 'dart:math';

/// Hasil mencocokkan huruf yang dikenali dengan target latihan.
enum LearnAnswer { correct, wrong, ignored }

/// Satu sesi latihan Mode Belajar: sejumlah huruf acak tanpa duplikat yang
/// harus diperagakan satu per satu.
class LearnSession {
  LearnSession({
    List<String>? letters,
    this.length = 10,
    Random? random,
  })  : _letters = letters ?? _alphabet,
        _random = random ?? Random() {
    assert(length > 0 && length <= _letters.length);
    restart();
  }

  static final List<String> _alphabet = List.unmodifiable(
    List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)),
  );

  final List<String> _letters;
  final Random _random;

  /// Jumlah huruf dalam satu sesi.
  final int length;

  List<String> _targets = const [];
  int _currentIndex = 0;
  int _score = 0;

  List<String> get targets => _targets;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get isFinished => _currentIndex >= _targets.length;

  /// Huruf yang sedang harus diperagakan, atau `null` bila sesi selesai.
  String? get current => isFinished ? null : _targets[_currentIndex];

  /// Cocokkan huruf yang dikenali model dengan target saat ini.
  ///
  /// Jawaban benar menambah skor dan memajukan ke huruf berikutnya. Jawaban
  /// salah tidak memajukan, sehingga pengguna bisa mencoba lagi.
  LearnAnswer submit(String letter) {
    final target = current;
    if (target == null) return LearnAnswer.ignored;

    if (letter.toUpperCase() != target) return LearnAnswer.wrong;

    _score++;
    _currentIndex++;
    return LearnAnswer.correct;
  }

  /// Lewati huruf saat ini tanpa menambah skor.
  void skip() {
    if (!isFinished) _currentIndex++;
  }

  /// Mulai sesi baru dengan urutan acak yang baru.
  void restart() {
    _targets = (List<String>.of(_letters)..shuffle(_random))
        .take(length)
        .toList(growable: false);
    _currentIndex = 0;
    _score = 0;
  }
}
