import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Base Use Case
/// كل Use Case يجب أن يرث من هذا الـ Class
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No Parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}