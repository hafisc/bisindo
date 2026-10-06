import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  // ⚠️ Pastikan google-services.json sudah ada di android/app/
  // sebelum enable ini. Download dari Firebase Console.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Jalan tanpa Firebase dulu selama development awal
    debugPrint('[Firebase] Tidak bisa init — pastikan google-services.json sudah ada: $e');
  }

  // Initialize dependency injection
  configureDependencies();

  runApp(
    const ProviderScope(
      child: BisindoApp(),
    ),
  );
}
