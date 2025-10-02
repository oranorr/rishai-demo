import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
// Удалён импорт старого GetDaysParams
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@Singleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dayManager,
  });
  final UserRemoteSource remoteDataSource;
  final UserLocalDataSource localDataSource;
  final DayManager dayManager;

  @override
  Future<Either<Failure, void>> updateUser({required UserEntity user}) async {
    try {
      // [FIX] Сначала всегда сохраняем локально
      final localRes = await localDataSource.updateUser(user: user);

      // Затем пытаемся синхронизировать с backend
      final remoteRes = await remoteDataSource.updateUser(user: user);

      // Если локальное сохранение успешно, возвращаем успех
      // даже если remote операция фэйлится (данные синхронизируются позже)
      if (localRes) {
        if (!remoteRes) {
          log(
            'Пользователь сохранен локально, но не синхронизирован с сервером',
            name: 'UserRepositoryImpl',
          );
        }
        return const Right(null);
      } else {
        return const Left(FailedUpdateUser('Ошибка локального сохранения'));
      }
    } on Exception catch (error) {
      log(
        'Ошибка при обновлении пользователя: $error',
        name: 'UserRepositoryImpl',
      );
      return Left(FailedUpdateUser(error.toString()));
    }
  }

  // Старый метод getDays удалён - используем только getUserDays

  // try {
  //   final ids = await dayManager.getDaysIds(userId: params.userId);

  //   if (ids.isEmpty) {
  //     final result = await directus.createOne(
  //       collection: daysCollection,
  //       data: params.dayMap,
  //     );
  //     log('Day is created with id: ${result['id']}');
  //     return const Right(null);
  //   }

  //   final lastRecord = await directus.readOne(
  //     collection: daysCollection,
  //     id: ids.last.toString(),
  //   );

  //   final needsFreshDay = await whoopRemote.pingLastCycle(
  //     cycleId: int.parse(lastRecord['cycleId']),
  //   );

  //   if (!needsFreshDay) {
  //     final lastEntity = DayEntity.fromMap(lastRecord);

  //     // Проверяем, изменились ли параметры, требующие обновления
  //     bool needsUpdate = params.incomingDay.mealPlanEntity != null;

  //     // Также проверяем, изменились ли макросы и другие важные параметры
  //     if (!needsUpdate) {
  //       needsUpdate = lastEntity.macros != params.incomingDay.macros ||
  //           lastEntity.healthMetrics != params.incomingDay.healthMetrics;

  //       if (needsUpdate) {
  //         log('Day needs update due to changes in macros or health metrics:');
  //         log('Old macros: ${lastEntity.macros}');
  //         log('New macros: ${params.incomingDay.macros}');
  //       }
  //     }

  //     if (needsUpdate) {
  //       log('Updating day with ID: ${lastRecord['id']} (changes detected)');

  //       // Всегда обновляем весь объект для обеспечения целостности данных
  //       final updateResult = await directus.updateOne(
  //         collection: daysCollection,
  //         itemId: lastRecord['id'].toString(),
  //         updateData: params.dayMap,
  //       );
  //       await saveDay(data: DayEntity.fromMap(updateResult));
  //       log('Day updated successfully. Update result: $updateResult');
  //     } else {
  //       log('No updates needed for the day. All data is up to date.');
  //     }
  //     return const Right(null);
  //   } else {
  //     final result = await directus.createOne(
  //       collection: daysCollection,
  //       data: params.dayMap,
  //     );
  //     log('New day created with id: ${result['id']}');
  //     return const Right(null);
  //   }
  // } on Exception catch (e) {
  //   log('Error while managing day: $e', name: 'UserRepositoryImpl');
  //   return Left(FailedUpdateUser(e.toString()));
  // }
  // }
  // @override
  // Future<Either<Failure, void>> manageDay({
  //   required ManageDayParams params,
  // }) async {
  //   try {
  //     final ids = await dayManager.getDaysIds(userId: params.userId);

  //     if (ids.isEmpty) {
  //       final result = await directus.createOne(
  //         collection: daysCollection,
  //         data: params.dayMap,
  //       );
  //       log('Day is created with id: ${result['id']}');
  //       return const Right(null);
  //     }

  //     final lastRecord = await directus.readOne(
  //       collection: daysCollection,
  //       id: ids.last.toString(),
  //     );

  //     // final lastDate = DateTime.fromMillisecondsSinceEpoch(
  //     //   int.parse(lastRecord['dateTime']),
  //     // );

  //     final needsFreshDay = await whoopRemote.pingLastCycle(
  //       cycleId: int.parse(lastRecord['cycleId']),
  //     );

  //     if (!needsFreshDay) {
  //       final lastEntity = DayEntity.fromMap(lastRecord);

  //       // Всегда обновляем день, если есть новый план питания
  //       if (params.incomingDay.mealPlanEntity != null) {
  //         log('Day is updating with new meal plan: ${params.incomingDay.mealPlanEntity?.toMap()}');
  //         log('Previous meal plan was: ${lastEntity.mealPlanEntity?.toMap()}');

  //         // Всегда обновляем весь объект для обеспечения целостности данных
  //         final updateResult = await directus.updateOne(
  //           collection: daysCollection,
  //           itemId: lastRecord['id'].toString(),
  //           updateData: params.dayMap,
  //         );
  //         log('Day updated successfully. Update result: $updateResult');
  //       } else {
  //         log('No updates needed for the day. Current meal plan: ${lastEntity.mealPlanEntity?.toMap()}');
  //       }
  //       return const Right(null);
  //     } else {
  //       final result = await directus.createOne(
  //         collection: daysCollection,
  //         data: params.dayMap,
  //       );
  //       log('New day created with id: ${result['id']}');
  //       return const Right(null);
  //     }
  //   } on Exception catch (e) {
  //     log('Error while managing day: $e', name: 'UserRepositoryImpl');
  //     return Left(FailedUpdateUser(e.toString()));
  //   }
  // }

  @override
  Future<Either<Failure, void>> updateDayWithMealPlan({
    required String userId,
    required ChatSnapshotEntity snapshot,
    required MealPlanEntity mealPlan,
  }) async {
    try {
      log(
        'Обновление дня планом питания: пользователь $userId',
        name: 'UserRepositoryImpl',
      );

      DayEntity? dayEntity;

      // Если в плане питания есть cycleId, ищем день по нему
      if (mealPlan.cycleId != null) {
        log(
          'Поиск дня по cycleId из плана питания: ${mealPlan.cycleId}',
          name: 'UserRepositoryImpl',
        );
        dayEntity = await dayManager.getDayByCycleId(
          userId: userId,
          cycleId: mealPlan.cycleId!,
        );
      }

      // Если день не найден по cycleId, ищем активный день
      if (dayEntity == null) {
        log(
          'День по cycleId не найден, ищем активный день для пользователя $userId',
          name: 'UserRepositoryImpl',
        );
        dayEntity = await dayManager.getActiveDay(userId: userId);
      }

      if (dayEntity == null) {
        log(
          'Активный день не найден для пользователя $userId',
          name: 'UserRepositoryImpl',
        );
        return const Left(FailedUpdateUser('No active day found'));
      }

      // Проверяем совместимость cycleId если он есть в обоих местах
      if (mealPlan.cycleId != null &&
          dayEntity.cycleId != null &&
          mealPlan.cycleId != dayEntity.cycleId) {
        log(
          'Несоответствие cycleId: план=${mealPlan.cycleId}, день=${dayEntity.cycleId}',
          name: 'UserRepositoryImpl',
        );
        return const Left(FailedUpdateUser('Cycle ID mismatch'));
      }

      // Создаем обновленный день с новым планом питания и снапшотом
      final updatedDay = dayEntity.copyWith(
        mealPlanEntity: mealPlan,
        snap: snapshot,
      );

      // Используем метод dayManager для обновления
      await dayManager.createOrUpdateDay(day: updatedDay);

      log('День успешно обновлен планом питания', name: 'UserRepositoryImpl');
      return const Right(null);
    } on Exception catch (e) {
      log(
        'Ошибка обновления дня планом питания: $e',
        name: 'UserRepositoryImpl',
      );
      return Left(FailedUpdateUser(e.toString()));
    }
  }

  /// Глубокое сравнение Map объектов
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;

      final value1 = map1[key];
      final value2 = map2[key];

      if (value1 is Map<String, dynamic> && value2 is Map<String, dynamic>) {
        if (!_mapEquals(value1, value2)) return false;
      } else if (value1 is List && value2 is List) {
        if (!_listEquals(value1, value2)) return false;
      } else if (value1 != value2) {
        return false;
      }
    }
    return true;
  }

  /// Глубокое сравнение List объектов
  bool _listEquals(List list1, List list2) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];

      if (item1 is Map<String, dynamic> && item2 is Map<String, dynamic>) {
        if (!_mapEquals(item1, item2)) return false;
      } else if (item1 is List && item2 is List) {
        if (!_listEquals(item1, item2)) return false;
      } else if (item1 != item2) {
        return false;
      }
    }
    return true;
  }

  Future<void> saveDay({required DayEntity data}) async {
    try {
      await dayManager.createOrUpdateDay(day: data);
      // Для удобства отладки
      log('День сохранен через dayManager: ID=${data.directusId}, Макросы=${data.macros}');
    } catch (e, stackTrace) {
      log('Ошибка при сохранении дня через dayManager: $e');
      rethrow;
    }
  }

  // === НОВЫЕ МЕТОДЫ (упрощенная архитектура) ===

  @override
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  }) async {
    try {
      log(
        'Получение дней пользователя через новый метод: $userId',
        name: 'UserRepositoryImpl',
      );

      final result = await dayManager.getUserDays(userId: userId);

      return result.fold(
        (failure) {
          log(
            'Ошибка при получении дней: ${failure.message}',
            name: 'UserRepositoryImpl',
          );
          return Left(failure);
        },
        (days) {
          log(
            'Успешно получено ${days.length} дней через новый метод',
            name: 'UserRepositoryImpl',
          );
          return Right(days);
        },
      );
    } on Exception catch (e, stackTrace) {
      log(
        'Исключение при получении дней пользователя: $e',
        name: 'UserRepositoryImpl',
      );
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'user_repository_get_user_days',
        extras: {'user_id': userId},
      );
      return const Left(UnknownFailure());
    }
  }
}
