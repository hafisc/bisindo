import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pembaca suara huruf hasil deteksi.
///
/// Preferensi hidup/mati disimpan di perangkat supaya tidak berubah setiap
/// kali aplikasi dibuka. Semua kegagalan TTS diabaikan: fitur suara tambahan,
/// bukan syarat agar scan berjalan.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const String _prefsKey = 'tts_enabled';

  final FlutterTts _tts;

  bool _enabled = true;
  bool _configured = false;

  bool get enabled => _enabled;

  /// Muat preferensi pengguna. Panggil sekali saat aplikasi mulai.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      _enabled = true;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) {
      await stop();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // Gagal menyimpan preferensi bukan alasan menggagalkan scan.
    }
  }

  /// Ucapkan [text] bila fitur suara sedang aktif.
  Future<void> speak(String text) async {
    final value = text.trim();
    if (!_enabled || value.isEmpty) return;

    try {
      if (!_configured) {
        await _tts.setLanguage('id-ID');
        await _tts.setSpeechRate(0.45);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _configured = true;
      }
      await _tts.stop();
      await _tts.speak(value);
    } catch (error) {
      debugPrint('[TtsService] Gagal mengucapkan "$value": $error');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}
