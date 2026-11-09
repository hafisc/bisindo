import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/user_profile_repository.dart';

class UploadAvatarParams extends Equatable {
  final String uid;
  final String filePath;

  const UploadAvatarParams({required this.uid, required this.filePath});

  @override
  List<Object?> get props => [uid, filePath];
}

class UploadAvatarUseCase implements UseCase<String, UploadAvatarParams> {
  final UserProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadAvatarParams params) {
    return repository.uploadAvatar(
      uid: params.uid,
      filePath: params.filePath,
    );
  }
}
