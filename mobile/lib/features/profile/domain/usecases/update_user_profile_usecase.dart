import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class UpdateUserProfileParams extends Equatable {
  final UserProfile profile;

  const UpdateUserProfileParams({required this.profile});

  @override
  List<Object?> get props => [profile.id, profile.name, profile.studentId, profile.role];
}

class UpdateUserProfileUseCase
    implements UseCase<UserProfile, UpdateUserProfileParams> {
  final UserProfileRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(UpdateUserProfileParams params) {
    return repository.updateProfile(params.profile);
  }
}
