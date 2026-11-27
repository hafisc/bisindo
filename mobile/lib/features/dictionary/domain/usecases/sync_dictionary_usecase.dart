import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../models/dictionary_item.dart';
import '../repositories/dictionary_repository.dart';

class SyncDictionaryUseCase implements UseCase<List<DictionaryItem>, NoParams> {
  final DictionaryRepository repository;

  SyncDictionaryUseCase(this.repository);

  @override
  Future<Either<Failure, List<DictionaryItem>>> call(NoParams params) {
    return repository.syncFromRemote();
  }
}
