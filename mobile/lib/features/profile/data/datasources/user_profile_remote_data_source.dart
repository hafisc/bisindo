import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/avatar_data_uri.dart';
import '../models/user_profile_model.dart';

/// Kontrak akses data profil pengguna di Firestore. Foto profil ikut
/// disimpan di dokumen yang sama, lihat [AvatarDataUri].
abstract class UserProfileRemoteDataSource {
  /// Mengambil dokumen `users/{uid}`.
  /// Mengembalikan `null` jika dokumen belum pernah dibuat.
  Future<UserProfileModel?> fetchProfile(String uid);

  /// Menyimpan (membuat atau menimpa) dokumen `users/{uid}`.
  Future<void> saveProfile(UserProfileModel profile);

  /// Menghapus dokumen `users/{uid}` (dipakai saat hapus akun).
  Future<void> deleteProfile(String uid);

  /// Menyimpan foto dari [filePath] ke field `avatarUrl` dokumen
  /// `users/{uid}` dalam bentuk data URI, lalu mengembalikan data URI itu.
  Future<String> uploadAvatar({required String uid, required String filePath});

  /// Mengosongkan field `avatarUrl` di dokumen pengguna.
  Future<void> deleteAvatar(String uid);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  static const String collectionName = 'users';

  final FirebaseFirestore _firestore;

  UserProfileRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(collectionName);

  @override
  Future<UserProfileModel?> fetchProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      debugPrint('[PROFILE DATA] Dokumen users/$uid belum ada.');
      return null;
    }

    return UserProfileModel.fromFirestore(uid, data);
  }

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await _users.doc(profile.id).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
    debugPrint('[PROFILE DATA] Profil users/${profile.id} tersimpan.');
  }

  @override
  Future<void> deleteProfile(String uid) async {
    await _users.doc(uid).delete();
    debugPrint('[PROFILE DATA] Profil users/$uid dihapus.');
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('File foto tidak ditemukan.');
    }

    final dataUri = AvatarDataUri.encode(await file.readAsBytes());

    await _users.doc(uid).set(
          {
            'avatarUrl': dataUri,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    debugPrint('[PROFILE DATA] Avatar users/$uid diperbarui.');
    return dataUri;
  }

  @override
  Future<void> deleteAvatar(String uid) async {
    await _users.doc(uid).set(
          {
            'avatarUrl': null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    debugPrint('[PROFILE DATA] Avatar users/$uid dihapus.');
  }
}
