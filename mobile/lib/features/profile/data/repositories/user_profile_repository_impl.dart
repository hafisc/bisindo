import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;

  UserProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String uid) async {
    try {
      final profile = await remoteDataSource.fetchProfile(uid);
      return Right(profile);
    } catch (e) {
      debugPrint('[PROFILE REPO] getProfile gagal: $e');
      return const Left(
        ServerFailure('Gagal memuat profil dari server.'),
      );
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      await remoteDataSource.saveProfile(model);
      return Right(profile);
    } catch (e) {
      debugPrint('[PROFILE REPO] updateProfile gagal: $e');
      return const Left(
        ServerFailure('Gagal menyimpan profil. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfile(String uid) async {
    try {
      await remoteDataSource.deleteProfile(uid);
      return const Right(null);
    } catch (e) {
      debugPrint('[PROFILE REPO] deleteProfile gagal: $e');
      return const Left(
        ServerFailure('Gagal menghapus data profil.'),
      );
    }
  }
}
