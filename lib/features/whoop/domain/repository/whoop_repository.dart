import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';

abstract class WhoopRepository {
  Future<Either<Failure, void>> authenticateUser();
  Future<Either<Failure, DayEntity>> getData({
    required GetDataParams params,
  });
  Future<Either<Failure, BodyMeasurementsEntity?>> getBodyData();
  Future<Either<Failure, MacrosBreakdown>> changeModificatorOfSex({
    required ChangeModificatorOrSexParams params,
  });
  Future<Either<Failure, void>> disconnectWhoop({
    required DisconnecWhoopParams params,
  });
}
