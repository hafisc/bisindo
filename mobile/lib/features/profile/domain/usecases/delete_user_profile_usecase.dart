import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/user_profile_repository.dart';

class DeleteUserProfileParams extends Equatable {
  final String uid;

  const DeleteUserProfileParams({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class DeleteUserProfileUseCase
    implements UseCase<void, DeleteUserProfileParams> {
  final UserProfileRepository repository;

  DeleteUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserProfileParams params) {
    return repository.deleteProfile(params.uid);
  }
}
