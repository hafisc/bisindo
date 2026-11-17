import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Muat alamat server yang tersimpan di perangkat (bisa diubah di layar Scan).
  await ApiConfig.load();

  // Initialize Firebase
  // ⚠️ Pastikan google-services.json sudah ada di android/app/
  // sebelum enable ini. Download dari Firebase Console.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Jalan tanpa Firebase dulu selama development awal
    debugPrint('[Firebase] Tidak bisa init — pastikan google-services.json sudah ada: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BisindoApp(),
    ),
  );
}
