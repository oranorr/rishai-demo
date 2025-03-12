import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/error/local_storage_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

@Singleton(as: WhoopLocalDataSource)
class WhoopLocalDataSourceImpl implements WhoopLocalDataSource {
  @override
  Future<List<DayEntity>> retrieveSavedDays() async {
    try {
      final data = await hive.retrieveSavedDays();
      return data;
    } catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_local_storage',
        operation: 'retrieve_saved_days',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> saveData({required DayEntity data}) async {
    try {
      await hive.saveDay(data: data);
    } catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_local_storage',
        operation: 'save_day',
        storageType: 'hive',
        extras: {
          'day_id': data.directusId,
          'cycle_id': data.cycleId,
          'date_time': data.dateTime.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<Either<Failure, DayEntity>> changeModificatorOrSexLocal({
    required ChangeModificatorOrSexParams params,
  }) async {
    try {
      UserDataEntity? userData;
      final newCalorieGoal = (1 + params.modificator) * params.weekTdeeAverage;
      userData = await hive.fetchUserDataEntity(userId: params.userId);

      if (userData == null) {
        log('userData is dead, need to refresh');
        await LocalStorageErrorHandler.handleError(
          'User data is null',
          StackTrace.current,
          context: 'whoop_local_storage',
          operation: 'change_modificator',
          storageType: 'hive',
          extras: {
            'user_id': params.userId,
            'modificator': params.modificator,
            'week_tdee_average': params.weekTdeeAverage,
          },
        );
        return const Left(WhoopDataDueToRefresh());
      }

      try {
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
      } catch (e, stackTrace) {
        await LocalStorageErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_local_storage',
          operation: 'update_user_and_day_data',
          storageType: 'hive',
          extras: {
            'user_id': params.userId,
            'modificator': params.modificator,
            'week_tdee_average': params.weekTdeeAverage,
            'calorie_goal': newCalorieGoal,
          },
        );
        rethrow;
      }
    } catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_local_storage',
        operation: 'change_modificator',
        storageType: 'hive',
        extras: {
          'user_id': params.userId,
          'modificator': params.modificator,
          'week_tdee_average': params.weekTdeeAverage,
        },
      );
      rethrow;
    }
  }
}
