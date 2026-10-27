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

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isGoogleUser = false,
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
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
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
      ];
}
