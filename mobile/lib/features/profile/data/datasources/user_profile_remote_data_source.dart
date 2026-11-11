import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile_model.dart';

/// Kontrak akses data profil pengguna di penyimpanan remote
/// (Firestore untuk data teks, Cloud Storage untuk foto).
abstract class UserProfileRemoteDataSource {
  /// Mengambil dokumen `users/{uid}`.
  /// Mengembalikan `null` jika dokumen belum pernah dibuat.
  Future<UserProfileModel?> fetchProfile(String uid);

  /// Menyimpan (membuat atau menimpa) dokumen `users/{uid}`.
  Future<void> saveProfile(UserProfileModel profile);

  /// Menghapus dokumen `users/{uid}` (dipakai saat hapus akun).
  Future<void> deleteProfile(String uid);

  /// Mengunggah foto profil ke `avatars/{uid}.jpg`, menyimpan URL-nya ke
  /// dokumen `users/{uid}`, lalu mengembalikan URL tersebut.
  Future<String> uploadAvatar({required String uid, required String filePath});

  /// Menghapus foto profil dari Cloud Storage dan mengosongkan field
  /// `avatarUrl` di dokumen pengguna.
  Future<void> deleteAvatar(String uid);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  static const String collectionName = 'users';
  static const String avatarFolder = 'avatars';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserProfileRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(collectionName);

  Reference _avatarRef(String uid) =>
      _storage.ref().child(avatarFolder).child('$uid.jpg');

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

    final uploadTask = await _avatarRef(uid).putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Simpan URL ke dokumen agar tidak perlu diunggah ulang tiap buka app.
    await _users.doc(uid).set(
          {
            'avatarUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    debugPrint('[PROFILE DATA] Avatar users/$uid diperbarui.');
    return downloadUrl;
  }

  @override
  Future<void> deleteAvatar(String uid) async {
    try {
      await _avatarRef(uid).delete();
    } on FirebaseException catch (e) {
      // object-not-found berarti foto memang belum pernah diunggah.
      if (e.code != 'object-not-found') rethrow;
    }

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
