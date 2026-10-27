import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_remote_data_source_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_email_verified_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
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

class LoginNotifier extends StateNotifier<AuthState> {
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;

  LoginNotifier({
    required LoginWithEmailUseCase loginWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
  })  : _loginWithEmailUseCase = loginWithEmailUseCase,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        super(const AuthState());

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _loginWithEmailUseCase(
      LoginWithEmailParams(email: email, password: password),
    );

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
    StateNotifierProvider<LoginNotifier, AuthState>((ref) {
  return LoginNotifier(
    loginWithEmailUseCase: ref.watch(loginWithEmailUseCaseProvider),
    signInWithGoogleUseCase: ref.watch(signInWithGoogleUseCaseProvider),
  );
});

// ── Register Notifier ───────────────────────────────────────────────────────

class RegisterNotifier extends StateNotifier<AuthState> {
  final RegisterWithEmailUseCase _registerWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;

  RegisterNotifier({
    required RegisterWithEmailUseCase registerWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
  })  : _registerWithEmailUseCase = registerWithEmailUseCase,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        super(const AuthState());

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _registerWithEmailUseCase(
      RegisterWithEmailParams(name: name, email: email, password: password),
    );

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
    StateNotifierProvider<RegisterNotifier, AuthState>((ref) {
  return RegisterNotifier(
    registerWithEmailUseCase: ref.watch(registerWithEmailUseCaseProvider),
    signInWithGoogleUseCase: ref.watch(signInWithGoogleUseCaseProvider),
  );
});

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

class EmailVerificationNotifier
    extends StateNotifier<EmailVerificationState> {
  final SendVerificationEmailUseCase _sendVerificationEmailUseCase;
  final CheckEmailVerifiedUseCase _checkEmailVerifiedUseCase;

  EmailVerificationNotifier({
    required SendVerificationEmailUseCase sendVerificationEmailUseCase,
    required CheckEmailVerifiedUseCase checkEmailVerifiedUseCase,
  })  : _sendVerificationEmailUseCase = sendVerificationEmailUseCase,
        _checkEmailVerifiedUseCase = checkEmailVerifiedUseCase,
        super(const EmailVerificationState());

  Future<void> resendEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSending: true, message: null);

    final result = await _sendVerificationEmailUseCase(
      SendVerificationEmailParams(email: email, password: password),
    );

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

final emailVerificationProvider = StateNotifierProvider<
    EmailVerificationNotifier, EmailVerificationState>((ref) {
  return EmailVerificationNotifier(
    sendVerificationEmailUseCase:
        ref.watch(sendVerificationEmailUseCaseProvider),
    checkEmailVerifiedUseCase: ref.watch(checkEmailVerifiedUseCaseProvider),
  );
});

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

class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final SendPasswordResetUseCase _sendPasswordResetUseCase;

  PasswordResetNotifier({
    required SendPasswordResetUseCase sendPasswordResetUseCase,
  })  : _sendPasswordResetUseCase = sendPasswordResetUseCase,
        super(const PasswordResetState());

  Future<void> sendReset({required String email}) async {
    state = const PasswordResetState(isLoading: true);

    final result = await _sendPasswordResetUseCase(
      SendPasswordResetParams(email: email),
    );

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
    StateNotifierProvider<PasswordResetNotifier, PasswordResetState>((ref) {
  return PasswordResetNotifier(
    sendPasswordResetUseCase: ref.watch(sendPasswordResetUseCaseProvider),
  );
});
