import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountParams extends Equatable {
  /// Wajib untuk akun email/password. `null` untuk akun Google.
  final String? password;

  const DeleteAccountParams({this.password});

  @override
  List<Object?> get props => [password];
}

class DeleteAccountUseCase implements UseCase<void, DeleteAccountParams> {
  final AuthRepository repository;

  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) {
    return repository.deleteAccount(password: params.password);
  }
}
