import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfileParams extends Equatable {
  final String uid;

  const GetUserProfileParams({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class GetUserProfileUseCase
    implements UseCase<UserProfile?, GetUserProfileParams> {
  final UserProfileRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile?>> call(GetUserProfileParams params) {
    return repository.getProfile(params.uid);
  }
}
