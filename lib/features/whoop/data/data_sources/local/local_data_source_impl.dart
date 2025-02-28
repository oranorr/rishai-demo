import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

@Singleton(as: WhoopLocalDataSource)
class WhoopLocalDataSourceImpl implements WhoopLocalDataSource {
  @override
  Future<List<DayEntity>> retrieveSavedDays() async {
    final data = await hive.retrieveSavedDays();
    return data;
  }

  @override
  Future<void> saveData({required DayEntity data}) async {
    await hive.saveDay(data: data);
  }

  @override
  Future<Either<Failure, DayEntity>> changeModificatorOrSexLocal({
    required ChangeModificatorOrSexParams params,
  }) async {
    UserDataEntity? userData;
    final newCalorieGoal = (1 + params.modificator) * params.weekTdeeAverage;
    userData = await hive.fetchUserDataEntity(userId: params.userId);
    if (userData == null) {
      log('userData is dead, need to refresh');
      return const Left(WhoopDataDueToRefresh());
    } else {
      userData = userData.copyWith(
        calorieGoal: newCalorieGoal.round(),
        gender: params.gender,
      );
      await hive.saveUserData(dataEntity: userData);
      final newMacros = userData.calcMacros();

      final savedDays = await hive.retrieveSavedDays();
      final savedDay = savedDays.last;

      final dayData = savedDay.copyWith(
        weekTdeeAverage: params.weekTdeeAverage,
        macros: newMacros,
        healthMetrics: savedDay.healthMetrics.copyWith(
          lastTdee: params.lastTdee,
        ),
      );
      await hive.saveDay(data: dayData);
      return Right(dayData);
    }
  }
}
