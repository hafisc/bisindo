import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class ReauthenticateParams extends Equatable {
  final String password;

  const ReauthenticateParams({required this.password});

  @override
  List<Object?> get props => [password];
}

class ReauthenticateUseCase implements UseCase<void, ReauthenticateParams> {
  final AuthRepository repository;

  ReauthenticateUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReauthenticateParams params) {
    return repository.reauthenticate(password: params.password);
  }
}
