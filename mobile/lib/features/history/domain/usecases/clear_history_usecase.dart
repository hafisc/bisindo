import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/history_owner.dart';
import '../repositories/history_repository.dart';

class ClearHistoryParams extends Equatable {
  final HistoryOwner? owner;

  const ClearHistoryParams({this.owner});

  @override
  List<Object?> get props => [owner];
}

class ClearHistoryUseCase implements UseCase<void, ClearHistoryParams> {
  final HistoryRepository repository;

  ClearHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ClearHistoryParams params) {
    return repository.clear(params.owner);
  }
}
