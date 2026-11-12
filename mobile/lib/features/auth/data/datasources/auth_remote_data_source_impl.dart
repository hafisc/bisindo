import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Implementation of [AuthRemoteDataSource] using Firebase Auth and Google Sign-In SDK.
@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @factoryMethod
  factory AuthRemoteDataSourceImpl.create() => AuthRemoteDataSourceImpl();

  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null ? null : UserModel.fromFirebaseUser(user),
      );

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    await user.sendEmailVerification();

    debugPrint('[AUTH DATA] Registered: ${user.email} — verification email sent.');
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await user.reload();
    final refreshedUser = _auth.currentUser!;

    if (!refreshedUser.emailVerified) {
      await _auth.signOut();
      throw EmailNotVerifiedException(email: email.trim());
    }

    debugPrint('[AUTH DATA] Login success: ${refreshedUser.email}');
    return UserModel.fromFirebaseUser(refreshedUser);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleSignInCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    debugPrint('[AUTH DATA] Google sign-in success: ${user.email}');
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> sendVerificationEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    await user.reload();

    if (!_auth.currentUser!.emailVerified) {
      await user.sendEmailVerification();
      debugPrint('[AUTH DATA] Verification email resent to ${user.email}');
    }

    await _auth.signOut();
  }

  @override
  Future<bool> checkEmailVerified({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.reload();

      final verified = _auth.currentUser!.emailVerified;
      if (!verified) {
        await _auth.signOut();
      }

      return verified;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    debugPrint('[AUTH DATA] Password reset email sent to $email');
  }

  /// True bila akun memakai provider email/password (bukan hanya Google).
  bool _hasPasswordProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Sesi tidak ditemukan. Silakan masuk ulang.');
    }
    return user;
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    final user = _requireCurrentUser();

    if (!_hasPasswordProvider(user)) {
      throw const PasswordNotSetException();
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AppException('Email akun tidak ditemukan.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    debugPrint('[AUTH DATA] Reauthenticated: $email');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await reauthenticate(password: currentPassword);

    final user = _requireCurrentUser();
    await user.updatePassword(newPassword);

    debugPrint('[AUTH DATA] Password diperbarui untuk ${user.email}');
  }

  /// Reautentikasi memakai akun Google (untuk pengguna yang tidak punya
  /// password, atau akun yang terhubung ke Google).
  Future<void> _reauthenticateWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleSignInCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _requireCurrentUser().reauthenticateWithCredential(credential);
    debugPrint('[AUTH DATA] Reauthenticated via Google.');
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _requireCurrentUser();

    if (_hasPasswordProvider(user)) {
      if (password == null || password.isEmpty) {
        throw const AppException('Password diperlukan untuk menghapus akun.');
      }
      await reauthenticate(password: password);
    } else {
      await _reauthenticateWithGoogle();
    }

    await user.delete();
    await _googleSignIn.signOut();

    debugPrint('[AUTH DATA] Akun ${user.email} dihapus.');
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    debugPrint('[AUTH DATA] Logged out.');
  }
}