import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetParams extends Equatable {
  final String email;

  const SendPasswordResetParams({required this.email});

  @override
  List<Object?> get props => [email];
}

class SendPasswordResetUseCase
    implements UseCase<void, SendPasswordResetParams> {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) {
    return repository.sendPasswordReset(email: params.email);
  }
}
