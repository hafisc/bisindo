import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_profile.dart';

/// Kontrak operasi profil pengguna di domain layer.
abstract class UserProfileRepository {
  /// Mengambil profil pengguna. Mengembalikan `null` jika belum tersimpan.
  Future<Either<Failure, UserProfile?>> getProfile(String uid);

  /// Menyimpan perubahan profil pengguna.
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile);

  /// Menghapus data profil pengguna.
  Future<Either<Failure, void>> deleteProfile(String uid);
}
