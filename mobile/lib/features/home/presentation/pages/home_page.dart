import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/home_tips_card.dart';

/// Halaman Beranda.
class HomePage extends StatelessWidget {
  /// Nama yang tampil di sapaan. Sementara masih default, nanti diisi dari
  /// data pengguna yang login.
  final String userName;

  const HomePage({super.key, this.userName = 'Hafis'});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.featureComingSoon)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppPalette.lightGray,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  onNotificationTap: () => _showComingSoon(context),
                  onAvatarTap: () => context.go(AppRoutes.profile),
                ),
                const SizedBox(height: 24),
                Text(
                  '${AppStrings.homeGreeting}$userName \u{1F44B}',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppPalette.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.homeSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.6,
                    color: AppPalette.gray600,
                  ),
                ),
                const SizedBox(height: 20),
                HomeBanner(onScanTap: () => context.push(AppRoutes.scan)),
                const SizedBox(height: 18),
                HomeMenuGrid(
                  onDictionaryTap: () => context.go(AppRoutes.dictionary),
                  onLearnTap: () => _showComingSoon(context),
                  onHistoryTap: () => context.go(AppRoutes.history),
                  onFavoriteTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 26),
                const HomeTipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
