import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/user_profile_repository.dart';

class DeleteAvatarParams extends Equatable {
  final String uid;

  const DeleteAvatarParams({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class DeleteAvatarUseCase implements UseCase<void, DeleteAvatarParams> {
  final UserProfileRepository repository;

  DeleteAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAvatarParams params) {
    return repository.deleteAvatar(params.uid);
  }
}
