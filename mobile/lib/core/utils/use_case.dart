import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base class for all use cases that return [Either<Failure, Type>].
///
/// Usage:
/// ```dart
/// class GetUserUseCase extends UseCase<UserEntity, NoParams> {
///   @override
///   Future<Either<Failure, UserEntity>> call(NoParams params) async { ... }
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use for use cases that take no parameters.
class NoParams {
  const NoParams();
}
