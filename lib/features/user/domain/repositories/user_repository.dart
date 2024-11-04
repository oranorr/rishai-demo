import 'package:dartz/dartz.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

import '../../../../core/errors/failure.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateUser({required UserEntity user});
  Future<Either<Failure, List<DayEntity>>> getDays(
      {required GetDaysParams params});
  Future<Either<Failure, void>> manageDay({required ManageDayParams params});
}
