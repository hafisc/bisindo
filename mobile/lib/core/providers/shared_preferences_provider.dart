import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider instance [SharedPreferences].
///
/// Nilai bawaan adalah `null` sehingga test widget tidak perlu meng-override
/// provider ini jika tidak membutuhkan SharedPreferences.
/// Di aplikasi utama (`main.dart`), provider ini di-override dengan instance riil.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
