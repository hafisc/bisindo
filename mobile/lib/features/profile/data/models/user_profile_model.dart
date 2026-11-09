import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_profile.dart';

/// Data layer model extending [UserProfile] with Firestore serialization.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.studentId = '-',
    super.role = 'Pengguna BISINDO',
    super.avatarUrl,
    super.joinedAt,
  });

  /// Membuat model dari dokumen Firestore `users/{uid}`.
  ///
  /// Field yang tidak ada di dokumen diisi nilai default agar UI tidak
  /// menampilkan teks kosong.
  factory UserProfileModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final joinedAt = data['joinedAt'];

    return UserProfileModel(
      id: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      studentId: (data['studentId'] as String?)?.trim() ?? '',
      role: (data['role'] as String?)?.trim() ?? '',
      avatarUrl: (data['avatarUrl'] as String?)?.trim(),
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : null,
    );
  }

  /// Membuat model dari entity domain (dipakai saat menyimpan).
  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      studentId: profile.studentId,
      role: profile.role,
      avatarUrl: profile.avatarUrl,
      joinedAt: profile.joinedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'studentId': studentId,
      'role': role,
      'avatarUrl': avatarUrl,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
