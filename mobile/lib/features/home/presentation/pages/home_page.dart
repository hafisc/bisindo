import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/home_tips_card.dart';

/// Halaman Beranda.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Nama depan untuk sapaan, supaya nama panjang tidak memenuhi header.
  static String greetingName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Teman';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = greetingName(
      ref.watch(profileNotifierProvider.select((state) => state.profile.name)),
    );

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
                  userName: userName,
                  onNotificationTap: () =>
                      context.push(AppRoutes.notifications),
                  onAvatarTap: () => context.go(AppRoutes.profile),
                ),
                const SizedBox(height: 24),
                HomeBanner(onScanTap: () => context.push(AppRoutes.scan)),
                const SizedBox(height: 18),
                HomeMenuGrid(
                  onDictionaryTap: () => context.go(AppRoutes.dictionary),
                  onLearnTap: () => context.push(AppRoutes.learn),
                  onHistoryTap: () => context.go(AppRoutes.history),
                  onFavoriteTap: () => context.push(AppRoutes.favorites),
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
