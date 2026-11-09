import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/use_case.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/user_profile_remote_data_source.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

// ── Dependency Injection Providers ───────────────────────────────────────────

final userProfileRemoteDataSourceProvider =
    Provider<UserProfileRemoteDataSource>((ref) {
  return UserProfileRemoteDataSourceImpl();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(
    remoteDataSource: ref.watch(userProfileRemoteDataSourceProvider),
  );
});

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  return GetUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
});

final updateUserProfileUseCaseProvider =
    Provider<UpdateUserProfileUseCase>((ref) {
  return UpdateUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(userProfileRepositoryProvider));
});

final deleteAvatarUseCaseProvider = Provider<DeleteAvatarUseCase>((ref) {
  return DeleteAvatarUseCase(ref.watch(userProfileRepositoryProvider));
});

// ── State ────────────────────────────────────────────────────────────────────

class ProfileState {
  final UserProfile profile;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? errorMessage;

  const ProfileState({
    this.profile = UserProfile.empty,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingAvatar,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required DeleteAvatarUseCase deleteAvatarUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase,
        _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserProfileUseCase = updateUserProfileUseCase,
        _uploadAvatarUseCase = uploadAvatarUseCase,
        _deleteAvatarUseCase = deleteAvatarUseCase,
        super(const ProfileState());

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final DeleteAvatarUseCase _deleteAvatarUseCase;

  /// Profil sementara dari data Firebase Auth, dipakai saat dokumen Firestore
  /// belum ada atau gagal dimuat.
  static UserProfile _fallbackProfile(UserEntity user) {
    if (user.isEmpty) return UserProfile.empty;

    return UserProfile(
      id: user.id,
      name: user.displayName.trim().isNotEmpty ? user.displayName.trim() : '',
      email: user.email,
      studentId: '',
      role: 'Pengguna BISINDO',
      avatarUrl: user.photoUrl,
      joinedAt: DateTime.now(),
    );
  }

  /// Memuat profil dari Firestore. Jika dokumen belum ada, profil awal dibuat
  /// dari data Firebase Auth lalu langsung disimpan.
  Future<void> load() async {
    final user = _getCurrentUserUseCase();

    if (user == null || user.isEmpty) {
      state = const ProfileState(profile: UserProfile.empty);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getUserProfileUseCase(
      GetUserProfileParams(uid: user.id),
    );

    result.fold(
      (failure) {
        // Firestore tidak tersedia (mis. Firebase belum dikonfigurasi) —
        // tetap tampilkan data dari Firebase Auth agar UI tidak kosong.
        state = state.copyWith(
          isLoading: false,
          profile: _fallbackProfile(user),
          errorMessage: failure.message,
        );
      },
      (profile) {
        if (profile == null) {
          final fresh = _fallbackProfile(user);
          state = state.copyWith(isLoading: false, profile: fresh);
          _createInitialProfile(fresh);
          return;
        }

        state = state.copyWith(isLoading: false, profile: profile);
      },
    );
  }

  /// Membuat dokumen profil pertama kali (dipanggil sekali, hasil diabaikan
  /// karena UI sudah memakai data fallback).
  Future<void> _createInitialProfile(UserProfile profile) async {
    final result = await _updateUserProfileUseCase(
      UpdateUserProfileParams(profile: profile),
    );

    result.fold(
      (failure) => debugPrint('[PROFILE] Gagal membuat profil awal: ${failure.message}'),
      (saved) => debugPrint('[PROFILE] Profil awal dibuat untuk ${saved.id}'),
    );
  }

  /// Menyimpan perubahan nama, NIM, dan peran.
  /// Mengembalikan `true` jika berhasil.
  Future<bool> saveProfile({
    required String name,
    required String studentId,
    required String role,
  }) async {
    final updated = state.profile.copyWith(
      name: name.trim(),
      studentId: studentId.trim(),
      role: role.trim(),
    );

    state = state.copyWith(isSaving: true, errorMessage: null);

    final result = await _updateUserProfileUseCase(
      UpdateUserProfileParams(profile: updated),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isSaving: false, errorMessage: failure.message);
        return false;
      },
      (saved) {
        state = state.copyWith(isSaving: false, profile: saved);
        return true;
      },
    );
  }

  /// Mengunggah foto profil baru dari [filePath] lokal.
  /// Mengembalikan `true` jika berhasil.
  Future<bool> uploadAvatar(String filePath) async {
    final uid = state.profile.id;
    if (uid.isEmpty) return false;

    state = state.copyWith(isUploadingAvatar: true, errorMessage: null);

    final result = await _uploadAvatarUseCase(
      UploadAvatarParams(uid: uid, filePath: filePath),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploadingAvatar: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (url) {
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: state.profile.copyWith(avatarUrl: url),
        );
        return true;
      },
    );
  }

  /// Menghapus foto profil dan kembali ke avatar default.
  Future<bool> removeAvatar() async {
    final uid = state.profile.id;
    if (uid.isEmpty) return false;

    state = state.copyWith(isUploadingAvatar: true, errorMessage: null);

    final result = await _deleteAvatarUseCase(DeleteAvatarParams(uid: uid));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploadingAvatar: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: state.profile.copyWith(avatarUrl: ''),
        );
        return true;
      },
    );
  }

  /// Muat ulang profil (mis. setelah login/logout).
  Future<void> refreshProfile() => load();

  Future<void> logout(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    await _logoutUseCase(const NoParams());
    state = const ProfileState(profile: UserProfile.empty);
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
    getUserProfileUseCase: ref.watch(getUserProfileUseCaseProvider),
    updateUserProfileUseCase: ref.watch(updateUserProfileUseCaseProvider),
    uploadAvatarUseCase: ref.watch(uploadAvatarUseCaseProvider),
    deleteAvatarUseCase: ref.watch(deleteAvatarUseCaseProvider),
  );

  // Muat profil pertama kali.
  notifier.load();

  // Muat ulang setiap kali status autentikasi berubah.
  ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (prev, next) {
    next.whenData((_) => notifier.refreshProfile());
  });

  return notifier;
});
