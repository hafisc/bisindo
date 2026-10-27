import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../features/auth/data/datasources/auth_remote_data_source_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_wrapper_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../../features/home/presentation/pages/notification_page.dart';
import '../../features/dictionary/presentation/pages/dictionary_page.dart';
import '../../features/dictionary/presentation/pages/dictionary_detail_page.dart';


/// App-wide route names as constants.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String notifications = '/notifications';
  static const String dictionary = '/dictionary';
  static const String dictionaryDetail = '/dictionary/:id';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
}

@singleton
class AppRouter {
  final AuthRepository _authRepository;

  AppRouter({AuthRepository? authRepository})
      : _authRepository = authRepository ??
            AuthRepositoryImpl(
              remoteDataSource: AuthRemoteDataSourceImpl(),
            );

  GoRouter get config => _router;

  late final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    // ── Auth-based redirect ──────────────────────────────────────────────
    redirect: (context, state) {
      final user = _authRepository.currentUser;
      final isLoggedIn = user != null && user.isNotEmpty;
      final isVerified = user?.isEmailVerified ?? false;

      final location = state.uri.path;

      // Routes that don't require auth
      const publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.onboarding,
        AppRoutes.forgotPassword,
        AppRoutes.emailVerification,
        AppRoutes.splash,
      ];

      final isPublicRoute = publicRoutes.contains(location);

      // If NOT logged in and trying to access a protected route → go to login
      if (!isLoggedIn && !isPublicRoute) {
        return AppRoutes.login;
      }

      // If logged in and verified, and on a public route → go to home
      if (isLoggedIn && isVerified && isPublicRoute) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
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
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        name: 'emailVerification',
        builder: (context, state) {
          final extra = (state.extra is Map) ? (state.extra as Map) : const {};
          return EmailVerificationPage(
            email: extra['email']?.toString() ?? '',
            password: extra['password']?.toString() ?? '',
          );
        },
      ),
      // Scan dibuka layar penuh (tanpa bottom nav) karena kamera butuh
      // seluruh layar. Dibuka lewat context.push dari Beranda / tombol tengah.
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) => const ScanPage(),
      ),
      // Notifikasi dibuka dari lonceng Beranda lewat context.push, tanpa
      // bottom nav, dan bisa kembali dengan tombol back.
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainWrapperPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.dictionary,
            name: 'dictionary',
            builder: (context, state) => const DictionaryPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'dictionaryDetail',
                builder: (context, state) => DictionaryDetailPage(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}

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