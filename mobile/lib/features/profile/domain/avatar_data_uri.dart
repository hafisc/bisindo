import 'dart:convert';
import 'dart:typed_data';

/// Foto profil disimpan langsung di dokumen Firestore `users/{uid}` sebagai
/// data URI (`data:image/jpeg;base64,...`), bukan di Cloud Storage, karena
/// bucket Storage baru mewajibkan paket Blaze.
///
/// Foto sudah dikecilkan ke 256 px saat dipilih sehingga ukurannya sekitar
/// 20 sampai 40 KB, jauh di bawah batas dokumen Firestore 1 MiB.
abstract final class AvatarDataUri {
  /// Batas ukuran foto sebelum di-encode. Base64 menambah sekitar 33%, jadi
  /// 600 KB tetap aman di bawah batas dokumen Firestore.
  static const int maxBytes = 600 * 1024;

  static const String _prefix = 'data:image/';

  static bool isDataUri(String? value) =>
      value != null && value.trimLeft().startsWith(_prefix);

  /// Mengubah isi file JPEG menjadi data URI.
  ///
  /// Melempar [ArgumentError] bila foto kosong atau melebihi [maxBytes].
  static String encode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError('Foto kosong.');
    }
    if (bytes.length > maxBytes) {
      throw ArgumentError('Ukuran foto melebihi ${maxBytes ~/ 1024} KB.');
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Mengambil isi gambar dari data URI. Mengembalikan `null` bila formatnya
  /// tidak valid sehingga UI bisa kembali ke avatar default.
  static Uint8List? decode(String value) {
    if (!isDataUri(value)) return null;
    try {
      return UriData.parse(value.trim()).contentAsBytes();
    } on FormatException {
      return null;
    }
  }
}
