import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/history_item.dart';
import '../models/history_owner.dart';
import '../repositories/history_repository.dart';

class GetLocalHistoryParams extends Equatable {
  final HistoryOwner? owner;

  const GetLocalHistoryParams({this.owner});

  @override
  List<Object?> get props => [owner];
}

class GetLocalHistoryUseCase
    implements UseCase<List<HistoryItem>, GetLocalHistoryParams> {
  final HistoryRepository repository;

  GetLocalHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<HistoryItem>>> call(GetLocalHistoryParams params) {
    return repository.getLocal(params.owner);
  }
}
