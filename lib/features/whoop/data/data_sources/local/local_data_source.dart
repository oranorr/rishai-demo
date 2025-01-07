import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

abstract class WhoopLocalDataSource {
  Future<void> saveData({required WhoopDataEntity data});
  Future<WhoopDataEntity?> fetchSavedData();
  Future<Either<Failure, (MacrosBreakdown, WhoopDataEntity)>>
      changeModificatorOrSexLocal({
    required ChangeModificatorOrSexParams params,
  });
}
