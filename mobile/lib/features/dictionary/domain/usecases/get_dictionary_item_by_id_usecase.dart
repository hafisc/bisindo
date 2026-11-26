import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/dictionary_item.dart';
import '../repositories/dictionary_repository.dart';

class GetDictionaryItemByIdParams extends Equatable {
  final String id;
  final bool refreshRemote;

  const GetDictionaryItemByIdParams({
    required this.id,
    this.refreshRemote = true,
  });

  @override
  List<Object?> get props => [id, refreshRemote];
}

class GetDictionaryItemByIdUseCase
    implements UseCase<DictionaryItem?, GetDictionaryItemByIdParams> {
  final DictionaryRepository repository;

  GetDictionaryItemByIdUseCase(this.repository);

  @override
  Future<Either<Failure, DictionaryItem?>> call(
    GetDictionaryItemByIdParams params,
  ) {
    return repository.getItemById(
      params.id,
      refreshRemote: params.refreshRemote,
    );
  }
}
