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

  /// Waktu akun dibuat menurut Firebase Auth. Dipakai sebagai tanggal
  /// bergabung bila dokumen profil di Firestore belum mencatatnya.
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isGoogleUser = false,
    this.hasPassword = false,
    this.createdAt,
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
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      hasPassword: hasPassword ?? this.hasPassword,
      createdAt: createdAt ?? this.createdAt,
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
        createdAt,
      ];
}
