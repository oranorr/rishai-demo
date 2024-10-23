import 'package:dartz/dartz.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

import '../../../../core/errors/failure.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateUser({required UserEntity user});
}
