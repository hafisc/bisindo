import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/history_item.dart';
import '../models/history_owner.dart';
import '../repositories/history_repository.dart';

class AddHistoryItemParams extends Equatable {
  final HistoryOwner? owner;
  final HistoryItem item;

  const AddHistoryItemParams({this.owner, required this.item});

  @override
  List<Object?> get props => [owner, item];
}

class AddHistoryItemUseCase
    implements UseCase<HistoryItem, AddHistoryItemParams> {
  final HistoryRepository repository;

  AddHistoryItemUseCase(this.repository);

  @override
  Future<Either<Failure, HistoryItem>> call(AddHistoryItemParams params) {
    return repository.add(params.owner, params.item);
  }
}
