import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart' as dm;
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/error/local_storage_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';

final userBloc = getIt.get<UserBloc>();

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
      await dm.dayManager.createDay(day: data);
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
      log('Starting changeModificatorOrSexLocal with params: userId=${params.userId}, modificator=${params.modificator}, weekTdeeAverage=${params.weekTdeeAverage}');

      UserDataEntity? userData;
      final newCalorieGoal = (1 + params.modificator) * params.weekTdeeAverage;

      log('Attempting to fetch user data from Hive...');
      userData = await hive.fetchUserDataEntity(userId: params.userId);

      if (userData == null) {
        log('userData is null - checking userDataBox status');
        log('Requesting information about userDataBox from Hive...');
        final allUserData = await hive.retrieveAllUserData();
        final isEmpty = allUserData.isEmpty;
        final count = allUserData.length;
        log('userDataBox isEmpty: $isEmpty, count: $count');

        if (!isEmpty) {
          log('userDataBox has data but none matching userId: ${params.userId}');
          final allUserIds = allUserData.map((e) => e.userId).toList();
          log('Available userIds in box: $allUserIds');
        }

        log('Attempting to create UserDataEntity from existing DayEntity');

        // Попытка получить последний день из кэша или с сервера
        DayEntity? latestDay;
        final cachedDays = await hive.retrieveSavedDays();

        if (cachedDays.isNotEmpty) {
          cachedDays.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          latestDay = cachedDays.last;
          log('Found latest day in cache: directusId=${latestDay.directusId}, cycleId=${latestDay.cycleId}');
        }

        if (latestDay == null) {
          // Используем новую архитектуру - получаем последний день напрямую
          latestDay = await dm.dayManager.getLastUserDay(userId: params.userId);

          if (latestDay == null) {
            log('No saved days found for user');
            return const Left(WhoopDataDueToRefresh());
          }
        }

        final user = userBloc.state.user;

        // Создаем UserDataEntity на основе сохраненного дня
        userData = UserDataEntity(
          userId: params.userId,
          workouts: [], // Пустой список, так как данные отсутствуют
          userWeightLbs: user.bodyMeasurements?.weight != null
              ? user.bodyMeasurements!.weight * 2.20462
              : 75 * 2.20462, // конвертация из кг в фунты
          gender: params.gender,
          strainValue: 10, // стандартное значение
          recoveryScore: 70, // стандартное значение
          sleepPerformance: 80, // стандартное значение
          calorieGoal: newCalorieGoal.round(),
          askTime: DateTime.now(),
          currentCycleId: latestDay.cycleId ?? 0,
        );

        // Проверка созданного объекта
        if (userData.userWeightLbs <= 0) {
          log('WARNING: Created UserDataEntity with zero weight, defaulting to 75kg');
          userData = userData.copyWith(userWeightLbs: 75 * 2.20462);
        }

        // Сохраняем созданный UserDataEntity
        await hive.saveUserData(dataEntity: userData);
        log('Created and saved new UserDataEntity for userId: ${params.userId}');
      }

      log('Found userData: $userData');

      try {
        log('Updating userData with new calorie goal: $newCalorieGoal');

        // Проверяем, что вес пользователя не равен 0
        double userWeight = userData.userWeightLbs;
        if (userWeight <= 0) {
          // Получаем актуальный вес из userBloc
          final user = userBloc.state.user;
          userWeight = user.bodyMeasurements?.weight != null
              ? user.bodyMeasurements!.weight *
                  2.20462 // конвертация из кг в фунты
              : 75 * 2.20462; // стандартный вес, если не указан

          log('Correcting user weight from 0 to: $userWeight lbs');
        }

        userData = userData.copyWith(
          calorieGoal: newCalorieGoal.round(),
          gender: params.gender,
          userWeightLbs: userWeight, // Убеждаемся, что вес не равен 0
        );

        await hive.saveUserData(dataEntity: userData);
        log('UserData saved successfully');

        // [FIX] Используем diet-aware макрос расчет
        // Получаем диеты из параметров, если переданы, иначе из userBloc.state.user
        final currentDiets = params.currentDiets ??
            userBloc.state.user.foodPreferences?.diets ??
            [];
        log('[changeModificatorOrSexLocal] 🔍 Получены диеты: $currentDiets (из параметров: ${params.currentDiets != null})');
        final specialDietType = UserDataEntity.getSpecialDietType(currentDiets);
        log('[changeModificatorOrSexLocal] 🔍 Определенный тип специальной диеты: $specialDietType');

        final MacrosBreakdown newMacros;
        if (specialDietType != null) {
          // Применяем специальный алгоритм для кето/карнивор диет
          switch (specialDietType) {
            case 'carnivore':
              log('[changeModificatorOrSexLocal] 🥩 Применяю CARNIVORE алгоритм (1% углеводов, 30-35% белки, 65-70% жиры)');
              newMacros = userData.calcMacrosForCarnivore();
              break;
            case 'keto':
              log('[changeModificatorOrSexLocal] 🥑 Применяю KETO алгоритм (5-10% углеводов, 20-25% белки, 65-75% жиры)');
              newMacros = userData.calcMacrosForKeto();
              break;
            default:
              // Fallback на keto алгоритм для совместимости
              log('[changeModificatorOrSexLocal] ⚠️ Неопознанная специальная диета, используем KETO fallback алгоритм');
              newMacros = userData.calcMacrosForKeto();
          }
        } else {
          // Используем стандартный алгоритм для обычных диет
          log('[changeModificatorOrSexLocal] 🍽️ Применяю СТАНДАРТНЫЙ алгоритм (обычное распределение)');
          newMacros = userData.calcMacros();
        }
        log('New macros calculated with diet awareness: $newMacros');

        final cachedDays = await hive.retrieveSavedDays();
        DayEntity? latestDay;

        if (cachedDays.isNotEmpty) {
          cachedDays.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          latestDay = cachedDays.last;
        }

        if (latestDay == null) {
          // Используем новую архитектуру - получаем последний день напрямую
          latestDay = await dm.dayManager.getLastUserDay(userId: params.userId);

          if (latestDay == null) {
            log('No saved days found for user');
            return const Left(WhoopDataDueToRefresh());
          }
        }

        final dayData = latestDay.copyWith(
          weekTdeeAverage: params.weekTdeeAverage,
          macros: newMacros,
          healthMetrics: latestDay.healthMetrics.copyWith(
            lastTdee: params.lastTdee,
          ),
        );

        await dm.dayManager.createDay(day: dayData);
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
