import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';

enum LegalDocument { terms, privacy }

class _Section {
  final String title;
  final List<String> paragraphs;
  const _Section(this.title, this.paragraphs);
}

/// Syarat dan Ketentuan serta Kebijakan Privasi.
///
/// Isinya mengikuti perilaku aplikasi yang sebenarnya. Bila alur data berubah
/// (misalnya gambar kamera mulai dikirim ke server), teks di sini wajib ikut
/// diperbarui.
class LegalPage extends StatelessWidget {
  final LegalDocument document;
  const LegalPage({super.key, required this.document});

  static const String lastUpdated = '15 November 2026';

  static const List<_Section> _terms = [
    _Section('Tentang aplikasi', [
      'BISINDO Translator adalah aplikasi bantu belajar dan menerjemahkan huruf '
          'Bahasa Isyarat Indonesia (BISINDO) A-Z melalui kamera. Aplikasi ini '
          'dikembangkan sebagai proyek mata kuliah Project Based Learning.',
    ]),
    _Section('Ketepatan hasil terjemahan', [
      'Hasil deteksi berasal dari model machine learning dan tidak selalu tepat. '
          'Pada data uji, model mengenali huruf dengan benar sekitar 96%, dan '
          'hasil di dunia nyata bisa lebih rendah karena pencahayaan, sudut '
          'kamera, atau cara memperagakan.',
      'Aplikasi ini tidak menggantikan juru bahasa isyarat untuk keperluan '
          'penting seperti layanan kesehatan, hukum, atau keadaan darurat.',
    ]),
    _Section('Akun', [
      'Kamu bertanggung jawab atas kebenaran data yang diisi saat mendaftar '
          'dan atas kerahasiaan password akunmu.',
      'Akun dapat dihapus kapan saja melalui menu Profil, lalu Hapus Akun.',
    ]),
    _Section('Penggunaan yang wajar', [
      'Jangan menyalahgunakan layanan, misalnya mengirim permintaan berulang '
          'secara otomatis ke server prediksi atau mencoba mengakses data '
          'pengguna lain.',
    ]),
    _Section('Ketersediaan layanan', [
      'Fitur Scan dan Mode Belajar membutuhkan server prediksi yang sedang '
          'berjalan. Karena ini proyek akademik, server dapat tidak tersedia '
          'sewaktu-waktu dan fitur dapat berubah tanpa pemberitahuan.',
    ]),
    _Section('Perubahan ketentuan', [
      'Ketentuan ini dapat diperbarui. Versi terbaru selalu tersedia di '
          'halaman ini beserta tanggal pembaruannya.',
    ]),
  ];

  static const List<_Section> _privacy = [
    _Section('Data akun', [
      'Saat mendaftar, aplikasi menyimpan nama dan email melalui Firebase '
          'Authentication. Data profil tambahan yang kamu isi, yaitu NIM atau '
          'nomor identitas, peran, dan foto profil, disimpan di Firebase '
          'Firestore dan Firebase Storage.',
    ]),
    _Section('Kamera', [
      'Gambar dari kamera diproses langsung di ponselmu oleh MediaPipe untuk '
          'menemukan posisi tangan. Gambar tidak dikirim ke server dan tidak '
          'disimpan.',
      'Yang dikirim ke server prediksi hanya koordinat titik tangan (21 titik '
          'per tangan) beserta ID akunmu, untuk ditebak hurufnya.',
    ]),
    _Section('Riwayat terjemahan', [
      'Huruf yang berhasil dikenali, tingkat keyakinan model, dan waktunya '
          'disimpan di ponselmu dan dikirim ke server bersama ID akunmu. Data '
          'ini ditampilkan di dashboard admin untuk memantau kinerja model.',
      'Nama dan email juga disinkronkan ke server agar riwayat bisa dikenali '
          'di dashboard admin.',
    ]),
    _Section('Data yang hanya ada di perangkat', [
      'Daftar favorit kamus dan alamat server yang kamu atur di layar Scan '
          'hanya disimpan di ponselmu.',
    ]),
    _Section('Siapa yang dapat melihat data', [
      'Data di server hanya dapat dilihat oleh tim pengembang melalui dashboard '
          'admin yang dilindungi login. Data tidak dijual atau dibagikan ke '
          'pihak lain.',
    ]),
    _Section('Menghapus data', [
      'Menu Profil, lalu Hapus Akun, menghapus akun Firebase, data profil, dan '
          'foto profilmu. Riwayat di ponsel bisa dihapus dari halaman Riwayat.',
      'Riwayat yang sudah tersinkron ke server belum ikut terhapus otomatis. '
          'Hubungi tim pengembang bila ingin riwayat di server dihapus.',
    ]),
    _Section('Keamanan', [
      'Login dan data akun di Firebase memakai koneksi terenkripsi (HTTPS). '
          'Server prediksi untuk demo berjalan di jaringan lokal dengan HTTP '
          'biasa, jadi gunakan hanya di jaringan yang kamu percaya.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final isTerms = document == LegalDocument.terms;
    final title = isTerms ? 'Syarat dan Ketentuan' : 'Kebijakan Privasi';
    final sections = isTerms ? _terms : _privacy;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text(
            'Terakhir diperbarui $lastUpdated',
            style: TextStyle(fontSize: 12, color: AppPalette.gray400),
          ),
          const SizedBox(height: 8),
          for (final section in sections) ...[
            const SizedBox(height: 16),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPalette.darkBlue,
              ),
            ),
            for (final paragraph in section.paragraphs) ...[
              const SizedBox(height: 6),
              Text(
                paragraph,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: AppPalette.gray600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
