import 'package:dartz/dartz.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/data/models/refresh_token_model.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificatorOrSex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';

import '../../../../core/errors/failure.dart';

abstract class WhoopRepository {
  Future<Either<Failure, void>> authenticateUser();
  Future<RefreshTokenModel?> refreshToken(String refreshToken);
  Future<Either<Failure, WhoopDataEntity>> getData(
      {required GetDataParams params});
  Future<Either<Failure, BodyMeasurementsEntity>> getBodyData();
  Future<Either<Failure, MacrosBreakdown>> changeModificatorOfSex(
      {required ChangeModificatorOrSexParams params});
}
