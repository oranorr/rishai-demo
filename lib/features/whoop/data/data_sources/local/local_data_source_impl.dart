import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

@Singleton(as: WhoopLocalDataSource)
class WhoopLocalDataSourceImpl implements WhoopLocalDataSource {
  @override
  Future<WhoopDataEntity?> fetchSavedData() async {
    final data = await hive.retrieveLastData();
    return data;
    // if (data != null) {
    //   final then = data.askTime;
    //   // return data;
    //   if (whoopDateDifference(then)) {
    //     return data;
    //   } else {
    //     return null;
    //   }
    // } else {
    //   return null;
    // }
  }

  @override
  Future<void> saveData({required WhoopDataEntity data}) async {
    await hive.saveWhoopData(data: data);
  }

  @override
  Future<Either<Failure, (MacrosBreakdown, WhoopDataEntity)>>
      changeModificatorOrSexLocal({
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

      final savedWhoop = await hive.retrieveLastData();

      final whoopData = savedWhoop!.copyWith(
        weekTdeeAverage: params.weekTdeeAverage,
        macros: newMacros,
        lastTdee: params.lastTdee,
      );
      await hive.saveWhoopData(data: whoopData);
      return Right((newMacros, whoopData));
    }
  }
}
