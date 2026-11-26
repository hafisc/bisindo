import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/history_item.dart';
import '../models/history_owner.dart';
import '../repositories/history_repository.dart';

class DeleteHistoryItemParams extends Equatable {
  final HistoryOwner? owner;
  final HistoryItem item;

  const DeleteHistoryItemParams({this.owner, required this.item});

  @override
  List<Object?> get props => [owner, item];
}

class DeleteHistoryItemUseCase
    implements UseCase<void, DeleteHistoryItemParams> {
  final HistoryRepository repository;

  DeleteHistoryItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteHistoryItemParams params) {
    return repository.delete(params.owner, params.item);
  }
}
