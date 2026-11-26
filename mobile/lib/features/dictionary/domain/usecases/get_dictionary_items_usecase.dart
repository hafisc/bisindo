import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/dictionary_item.dart';
import '../repositories/dictionary_repository.dart';

class GetDictionaryItemsParams extends Equatable {
  final DictionaryCategory? category;

  const GetDictionaryItemsParams({this.category});

  @override
  List<Object?> get props => [category];
}

class GetDictionaryItemsUseCase
    implements UseCase<List<DictionaryItem>, GetDictionaryItemsParams> {
  final DictionaryRepository repository;

  GetDictionaryItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DictionaryItem>>> call(
    GetDictionaryItemsParams params,
  ) {
    return repository.getItems(category: params.category);
  }
}
