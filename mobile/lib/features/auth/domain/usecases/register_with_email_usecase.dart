import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailParams extends Equatable {
  final String name;
  final String email;
  final String password;

  const RegisterWithEmailParams({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class RegisterWithEmailUseCase
    implements UseCase<UserEntity, RegisterWithEmailParams> {
  final AuthRepository repository;

  RegisterWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterWithEmailParams params) {
    return repository.registerWithEmail(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}
