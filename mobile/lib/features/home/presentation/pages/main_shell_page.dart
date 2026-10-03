import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// Kerangka halaman utama yang membungkus tab Beranda, Kamus, Riwayat, Profil
/// beserta bottom navigation bar.
class MainShellPage extends StatelessWidget {
  final Widget child;

  /// Path aktif, dipakai untuk menentukan tab yang menyala.
  final String location;

  const MainShellPage({super.key, required this.child, required this.location});

  static const List<String> _tabRoutes = [
    AppRoutes.home,
    AppRoutes.dictionary,
    AppRoutes.history,
    AppRoutes.profile,
  ];

  int? get _currentIndex {
    final index = _tabRoutes.indexWhere((route) => location.startsWith(route));
    return index == -1 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          if (index != _currentIndex) context.go(_tabRoutes[index]);
        },
        onScanTap: () => context.push(AppRoutes.scan),
      ),
    );
  }
}
