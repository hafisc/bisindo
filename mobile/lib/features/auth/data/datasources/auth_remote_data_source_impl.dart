import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Implementation of [AuthRemoteDataSource] using Firebase Auth and Google Sign-In SDK.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

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

  @override
  Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    debugPrint('[AUTH DATA] Logged out.');
  }
}
