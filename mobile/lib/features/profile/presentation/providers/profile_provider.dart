import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
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
  ProfileNotifier()
      : super(
          const ProfileState(
            profile: UserProfile(
              id: 'USR-2241720000',
              name: 'Mokhamad Rizki Hadiono Singgih',
              email: 'rizki.singgih@student.polinema.ac.id',
              studentId: '2241720000',
              role: 'Mahasiswa / Mobile Dev',
            ),
          ),
        );

  void updateProfileName(String newName) {
    state = state.copyWith(
      profile: state.profile.copyWith(name: newName),
    );
  }

  Future<void> logout(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
