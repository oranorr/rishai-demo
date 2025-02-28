import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

abstract class WhoopLocalDataSource {
  Future<void> saveData({required DayEntity data});
  Future<List<DayEntity>> retrieveSavedDays();
  Future<Either<Failure, DayEntity>> changeModificatorOrSexLocal({
    required ChangeModificatorOrSexParams params,
  });
}
