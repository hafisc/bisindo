import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class BisindoApp extends ConsumerWidget {
  const BisindoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'BISINDO Translator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Seluruh halaman dirancang dengan warna terang (kartu putih, teks navy).
      // Mengikuti mode gelap HP membuat latar dan AppBar navy bertabrakan dengan
      // warna itu, sehingga teks tidak terbaca. Jadi aplikasi selalu memakai tema
      // terang sampai ada tema gelap yang dirancang untuk semua halaman.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
