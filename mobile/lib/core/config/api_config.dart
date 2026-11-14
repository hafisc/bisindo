import 'package:shared_preferences/shared_preferences.dart';

/// Alamat server prediksi BISINDO.
///
/// Ada dua cara mengatur alamat, dan keduanya sengaja didukung supaya
/// aplikasi bisa dipakai di komputer siapa pun, bukan hanya di satu laptop:
///
/// 1. **Saat build**, lewat `--dart-define`:
///
///    ```bash
///    flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000
///    ```
///
/// 2. **Saat aplikasi berjalan**, lewat ikon gerigi di layar Scan. Nilai ini
///    disimpan di perangkat, jadi pengguna bisa pindah WiFi atau berganti
///    laptop tanpa perlu build ulang aplikasi.
///
/// Alamat bawaan `127.0.0.1` dipilih karena jalur pengembangan yang dipakai
/// adalah HP fisik lewat kabel USB dengan `adb reverse tcp:5000 tcp:5000`.
/// Alamat itu juga berfungsi untuk HP yang tersambung ke WiFi lewat fitur
/// "port forwarding" lain, dan bisa diganti kapan saja di layar Scan.
///
/// Emulator Android memakai alias `10.0.2.2`, tetapi emulator x86_64 tidak
/// punya MediaPipe native, jadi kamera tidak bisa diuji di sana. Karena itu
/// alias emulator tidak dijadikan bawaan.
class ApiConfig {
  const ApiConfig._();

  static const String _prefsKey = 'api_base_url';

  /// Nilai bawaan bila tidak diatur lewat `--dart-define` maupun layar Scan.
  static const String buildTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  static String? _cached;

  /// Alamat yang sedang dipakai. Dibaca dari cache agar aman dipanggil
  /// berkali-kali tanpa menyentuh disk.
  static String get baseUrl => _cached ?? buildTimeBaseUrl;

  /// Apakah alamat diatur manual oleh pengguna di perangkat ini.
  static bool get isCustom => _cached != null;

  /// Muat alamat tersimpan. Panggil sekali saat aplikasi mulai.
  static Future<String> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored != null && stored.trim().isNotEmpty) {
        _cached = normalize(stored);
      }
    } catch (_) {
      // SharedPreferences gagal dibaca: tetap pakai nilai bawaan.
    }
    return baseUrl;
  }

  /// Simpan alamat baru dan kembalikan nilai yang sudah dinormalkan.
  static Future<String> save(String raw) async {
    final value = normalize(raw);
    _cached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, value);
    } catch (_) {
      // Gagal menyimpan bukan alasan menggagalkan sesi scan.
    }
    return value;
  }

  /// Kembali ke alamat bawaan.
  static Future<String> reset() async {
    _cached = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
    return baseUrl;
  }

  /// Rapikan tulisan pengguna menjadi URL yang bisa dipakai.
  ///
  /// Menerima `192.168.1.5:5000`, `192.168.1.5`, atau URL lengkap. Awalan
  /// `http://` ditambahkan bila belum ada, garis miring di akhir dibuang,
  /// dan akhiran `/api` dihapus karena client menambahkannya sendiri.
  static String normalize(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return buildTimeBaseUrl;

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    if (value.endsWith('/api')) {
      value = value.substring(0, value.length - '/api'.length);
    }

    return value;
  }

  /// Periksa tulisan pengguna. Kembalikan pesan galat, atau `null` bila valid.
  static String? validate(String raw) {
    if (raw.trim().isEmpty) {
      return 'Alamat server tidak boleh kosong.';
    }

    final value = normalize(raw);
    final uri = Uri.tryParse(value);

    if (uri == null || uri.host.isEmpty) {
      return 'Alamat tidak valid. Contoh yang benar: 192.168.1.5:5000';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Alamat harus diawali http:// atau https://';
    }

    return null;
  }

  /// Alamat tanpa skema, dipakai untuk ditampilkan di layar.
  static String display(String raw) {
    final value = normalize(raw);
    return value.replaceFirst(RegExp(r'^https?://'), '');
  }
}
