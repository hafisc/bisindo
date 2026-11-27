import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_remote_data_source_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_email_verified_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reauthenticate_usecase.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/send_verification_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

// ── Dependency Injection Providers (Clean Architecture) ──────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ── Use Cases ────────────────────────────────────────────────────────────────

final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  return LoginWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>((ref) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final sendVerificationEmailUseCaseProvider =
    Provider<SendVerificationEmailUseCase>((ref) {
  return SendVerificationEmailUseCase(ref.watch(authRepositoryProvider));
});

final checkEmailVerifiedUseCaseProvider =
    Provider<CheckEmailVerifiedUseCase>((ref) {
  return CheckEmailVerifiedUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>((ref) {
  return SendPasswordResetUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final reauthenticateUseCaseProvider = Provider<ReauthenticateUseCase>((ref) {
  return ReauthenticateUseCase(ref.watch(authRepositoryProvider));
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth State Stream Provider ───────────────────────────────────────────────

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

// ── Presentation Auth State ──────────────────────────────────────────────────

enum AuthStatus { idle, loading, success, error, emailNotVerified }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;
  final String? unverifiedEmail;
  final String? unverifiedPassword;

  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
    this.unverifiedEmail,
    this.unverifiedPassword,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    String? unverifiedEmail,
    String? unverifiedPassword,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      unverifiedEmail: unverifiedEmail ?? this.unverifiedEmail,
      unverifiedPassword: unverifiedPassword ?? this.unverifiedPassword,
    );
  }
}

// ── Login Notifier ──────────────────────────────────────────────────────────

class LoginNotifier extends Notifier<AuthState> {
  late LoginWithEmailUseCase _loginWithEmailUseCase;
  late SignInWithGoogleUseCase _signInWithGoogleUseCase;
  bool _isDisposed = false;

  @override
  AuthState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _loginWithEmailUseCase = ref.watch(loginWithEmailUseCaseProvider);
    _signInWithGoogleUseCase = ref.watch(signInWithGoogleUseCaseProvider);
    return const AuthState();
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _loginWithEmailUseCase(
      LoginWithEmailParams(email: email, password: password),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) {
        if (failure is EmailNotVerifiedFailure) {
          state = state.copyWith(
            status: AuthStatus.emailNotVerified,
            unverifiedEmail: failure.email.isNotEmpty ? failure.email : email.trim(),
            unverifiedPassword: password,
            errorMessage: failure.message,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        }
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
        );
      },
    );
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _signInWithGoogleUseCase(const NoParams());
    if (_isDisposed) return;

    result.fold(
      (failure) {
        if (failure is GoogleSignInCancelledFailure) {
          state = state.copyWith(status: AuthStatus.idle);
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        }
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
        );
      },
    );
  }

  void resetState() {
    state = const AuthState();
  }
}

final loginNotifierProvider =
    NotifierProvider<LoginNotifier, AuthState>(LoginNotifier.new);

// ── Register Notifier ───────────────────────────────────────────────────────

class RegisterNotifier extends Notifier<AuthState> {
  late RegisterWithEmailUseCase _registerWithEmailUseCase;
  late SignInWithGoogleUseCase _signInWithGoogleUseCase;
  bool _isDisposed = false;

  @override
  AuthState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _registerWithEmailUseCase = ref.watch(registerWithEmailUseCaseProvider);
    _signInWithGoogleUseCase = ref.watch(signInWithGoogleUseCaseProvider);
    return const AuthState();
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _registerWithEmailUseCase(
      RegisterWithEmailParams(name: name, email: email, password: password),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.emailNotVerified,
          unverifiedEmail: email.trim(),
          unverifiedPassword: password,
        );
      },
    );
  }

  Future<void> registerWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _signInWithGoogleUseCase(const NoParams());
    if (_isDisposed) return;

    result.fold(
      (failure) {
        if (failure is GoogleSignInCancelledFailure) {
          state = state.copyWith(status: AuthStatus.idle);
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        }
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
        );
      },
    );
  }

  void resetState() {
    state = const AuthState();
  }
}

final registerNotifierProvider =
    NotifierProvider<RegisterNotifier, AuthState>(RegisterNotifier.new);

// ── Email Verification Notifier ─────────────────────────────────────────────

class EmailVerificationState {
  final bool isSending;
  final bool isChecking;
  final bool isVerified;
  final String? message;

  const EmailVerificationState({
    this.isSending = false,
    this.isChecking = false,
    this.isVerified = false,
    this.message,
  });

  EmailVerificationState copyWith({
    bool? isSending,
    bool? isChecking,
    bool? isVerified,
    String? message,
  }) {
    return EmailVerificationState(
      isSending: isSending ?? this.isSending,
      isChecking: isChecking ?? this.isChecking,
      isVerified: isVerified ?? this.isVerified,
      message: message,
    );
  }
}

class EmailVerificationNotifier extends Notifier<EmailVerificationState> {
  late SendVerificationEmailUseCase _sendVerificationEmailUseCase;
  late CheckEmailVerifiedUseCase _checkEmailVerifiedUseCase;
  bool _isDisposed = false;

  @override
  EmailVerificationState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _sendVerificationEmailUseCase =
        ref.watch(sendVerificationEmailUseCaseProvider);
    _checkEmailVerifiedUseCase = ref.watch(checkEmailVerifiedUseCaseProvider);
    return const EmailVerificationState();
  }

  Future<void> resendEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSending: true, message: null);

    final result = await _sendVerificationEmailUseCase(
      SendVerificationEmailParams(email: email, password: password),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isSending: false,
          message: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isSending: false,
          message: 'Email verifikasi telah dikirim ulang.',
        );
      },
    );
  }

  Future<bool> checkVerification({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isChecking: true, message: null);

    final result = await _checkEmailVerifiedUseCase(
      CheckEmailVerifiedParams(email: email, password: password),
    );
    if (_isDisposed) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isChecking: false,
          message: failure.message,
        );
        return false;
      },
      (verified) {
        state = state.copyWith(
          isChecking: false,
          isVerified: verified,
          message: verified
              ? 'Email berhasil diverifikasi!'
              : 'Email belum diverifikasi. Silakan cek inbox kamu.',
        );
        return verified;
      },
    );
  }

  void reset() {
    state = const EmailVerificationState();
  }
}

final emailVerificationProvider =
    NotifierProvider<EmailVerificationNotifier, EmailVerificationState>(
  EmailVerificationNotifier.new,
);

// ── Password Reset Notifier ─────────────────────────────────────────────────

class PasswordResetState {
  final bool isLoading;
  final bool isSent;
  final String? errorMessage;

  const PasswordResetState({
    this.isLoading = false,
    this.isSent = false,
    this.errorMessage,
  });
}

class PasswordResetNotifier extends Notifier<PasswordResetState> {
  late SendPasswordResetUseCase _sendPasswordResetUseCase;
  bool _isDisposed = false;

  @override
  PasswordResetState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _sendPasswordResetUseCase = ref.watch(sendPasswordResetUseCaseProvider);
    return const PasswordResetState();
  }

  Future<void> sendReset({required String email}) async {
    state = const PasswordResetState(isLoading: true);

    final result = await _sendPasswordResetUseCase(
      SendPasswordResetParams(email: email),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) {
        state = PasswordResetState(errorMessage: failure.message);
      },
      (_) {
        state = const PasswordResetState(isSent: true);
      },
    );
  }

  void reset() {
    state = const PasswordResetState();
  }
}

final passwordResetProvider =
    NotifierProvider<PasswordResetNotifier, PasswordResetState>(
  PasswordResetNotifier.new,
);

// ── Account Security Notifier ────────────────────────────────────────────────
// Menangani operasi sensitif pada akun: ganti password, verifikasi ulang,
// dan hapus akun.

class AccountSecurityState {
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;

  const AccountSecurityState({
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
  });
}

class AccountSecurityNotifier extends Notifier<AccountSecurityState> {
  late ChangePasswordUseCase _changePasswordUseCase;
  late ReauthenticateUseCase _reauthenticateUseCase;
  late DeleteAccountUseCase _deleteAccountUseCase;
  bool _isDisposed = false;

  @override
  AccountSecurityState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _changePasswordUseCase = ref.watch(changePasswordUseCaseProvider);
    _reauthenticateUseCase = ref.watch(reauthenticateUseCaseProvider);
    _deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);
    return const AccountSecurityState();
  }

  /// Mengganti password. Mengembalikan `true` bila berhasil.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AccountSecurityState(isProcessing: true);

    final result = await _changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    if (_isDisposed) return false;

    return result.fold(
      (failure) {
        state = AccountSecurityState(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = const AccountSecurityState(
          successMessage: 'Password berhasil diperbarui.',
        );
        return true;
      },
    );
  }

  /// Memverifikasi ulang pengguna dengan password saat ini.
  Future<bool> reauthenticate(String password) async {
    state = const AccountSecurityState(isProcessing: true);

    final result = await _reauthenticateUseCase(
      ReauthenticateParams(password: password),
    );
    if (_isDisposed) return false;

    return result.fold(
      (failure) {
        state = AccountSecurityState(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = const AccountSecurityState();
        return true;
      },
    );
  }

  /// Menghapus akun. Mengembalikan `true` bila berhasil.
  ///
  /// [password] hanya diperlukan untuk akun email/password; akun Google
  /// akan diverifikasi ulang lewat Google Sign-In.
  Future<bool> deleteAccount({String? password}) async {
    state = const AccountSecurityState(isProcessing: true);

    final result = await _deleteAccountUseCase(
      DeleteAccountParams(password: password),
    );
    if (_isDisposed) return false;

    return result.fold(
      (failure) {
        state = AccountSecurityState(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = const AccountSecurityState(
          successMessage: 'Akun berhasil dihapus.',
        );
        return true;
      },
    );
  }

  void reset() => state = const AccountSecurityState();
}

final accountSecurityProvider =
    NotifierProvider<AccountSecurityNotifier, AccountSecurityState>(
  AccountSecurityNotifier.new,
);
