import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/use_case.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_profile.dart';

class ProfileState {
  final UserProfile profile;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    required this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase,
        super(
          ProfileState(
            profile: _buildProfile(getCurrentUserUseCase()),
          ),
        );

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  static UserProfile _buildProfile(UserEntity? user) {
    if (user == null || user.isEmpty) {
      return const UserProfile(
        id: '-',
        name: 'Tamu',
        email: '-',
        studentId: '-',
        role: '-',
      );
    }

    return UserProfile(
      id: user.id,
      name: user.displayName.isNotEmpty ? user.displayName : 'Pengguna',
      email: user.email.isNotEmpty ? user.email : '-',
      studentId: '-',
      role: 'Pengguna BISINDO',
      avatarUrl: user.photoUrl,
    );
  }

  void refreshProfile() {
    state = state.copyWith(profile: _buildProfile(_getCurrentUserUseCase()));
  }

  void updateProfileName(String newName) {
    state = state.copyWith(
      profile: state.profile.copyWith(name: newName),
    );
  }

  Future<void> logout(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    await _logoutUseCase(const NoParams());
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier(
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  );

  ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (prev, next) {
    next.whenData((user) {
      notifier.refreshProfile();
    });
  });

  return notifier;
});
