import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rishai/core/errors/failure.dart';

// ignore: one_member_abstracts
abstract interface class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
