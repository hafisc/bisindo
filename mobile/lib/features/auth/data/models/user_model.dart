import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

/// Data layer model extending [UserEntity] with serialization and Firebase mapping.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.isEmailVerified = false,
    super.isGoogleUser = false,
  });

  /// Creates a [UserModel] from a Firebase [User].
  factory UserModel.fromFirebaseUser(User user) {
    final isGoogle = user.providerData.any(
      (info) => info.providerId == 'google.com',
    );

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? (user.email?.split('@').first ?? 'Pengguna'),
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified || isGoogle,
      isGoogleUser: isGoogle,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isGoogleUser: json['isGoogleUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'isGoogleUser': isGoogleUser,
    };
  }
}
