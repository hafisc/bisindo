import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
