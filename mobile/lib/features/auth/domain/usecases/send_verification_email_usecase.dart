import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class SendVerificationEmailParams extends Equatable {
  final String email;
  final String password;

  const SendVerificationEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SendVerificationEmailUseCase
    implements UseCase<void, SendVerificationEmailParams> {
  final AuthRepository repository;

  SendVerificationEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendVerificationEmailParams params) {
    return repository.sendVerificationEmail(
      email: params.email,
      password: params.password,
    );
  }
}
