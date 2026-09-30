import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';

/// App-wide route names as constants.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String dictionary = '/dictionary';
  static const String dictionaryDetail = '/dictionary/:id';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
}

@singleton
class AppRouter {
  GoRouter get config => _router;

  final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _PlaceholderShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Beranda'),
          ),
          GoRoute(
            path: AppRoutes.scan,
            name: 'scan',
            builder: (context, state) => const ScanPage(),
          ),
          GoRoute(
            path: AppRoutes.dictionary,
            name: 'dictionary',
            builder: (context, state) => const _PlaceholderPage(title: 'Kamus'),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Riwayat'),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Profil'),
          ),
        ],
      ),
    ],
  );
}

// ── Temporary placeholder widgets — replace as features are built ─────────────

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

class _PlaceholderShell extends StatelessWidget {
  final Widget child;
  const _PlaceholderShell({required this.child});

  @override
  Widget build(BuildContext context) => child;
}
