import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerifiedParams extends Equatable {
  final String email;
  final String password;

  const CheckEmailVerifiedParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class CheckEmailVerifiedUseCase
    implements UseCase<bool, CheckEmailVerifiedParams> {
  final AuthRepository repository;

  CheckEmailVerifiedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckEmailVerifiedParams params) {
    return repository.checkEmailVerified(
      email: params.email,
      password: params.password,
    );
  }
}
