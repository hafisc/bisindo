import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/history_owner.dart';
import '../repositories/history_repository.dart';

class SyncHistoryParams extends Equatable {
  final HistoryOwner? owner;

  const SyncHistoryParams({this.owner});

  @override
  List<Object?> get props => [owner];
}

class SyncHistoryUseCase
    implements UseCase<HistoryLoadResult, SyncHistoryParams> {
  final HistoryRepository repository;

  SyncHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, HistoryLoadResult>> call(SyncHistoryParams params) {
    return repository.sync(params.owner);
  }
}
