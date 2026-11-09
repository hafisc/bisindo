import 'package:equatable/equatable.dart';

/// Pure domain entity representing an authenticated user.
///
/// Completely independent of Firebase or any backend framework.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isGoogleUser;

  /// True bila akun punya provider email/password, sehingga operasi sensitif
  /// (ganti password / hapus akun) memerlukan password saat ini.
  final bool hasPassword;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isGoogleUser = false,
    this.hasPassword = false,
  });

  /// An unauthenticated / empty guest user representation
  static const empty = UserEntity(
    id: '',
    email: '',
    displayName: 'Tamu',
    isEmailVerified: false,
    isGoogleUser: false,
  );

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    bool? isGoogleUser,
    bool? hasPassword,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        isEmailVerified,
        isGoogleUser,
        hasPassword,
      ];
}
