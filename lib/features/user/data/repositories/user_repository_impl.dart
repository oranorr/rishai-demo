import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

@Singleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  final UserRemoteSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  @override
  Future<Either<Failure, void>> updateUser({required UserEntity user}) async {
    try {
      final remoteRes = await remoteDataSource.updateUser(user: user);
      final localRes = await localDataSource.updateUser(user: user);
      if (remoteRes && localRes) {
        return const Right(null);
      } else {
        return const Left(FailedUpdateUser(''));
      }
    } on Exception catch (error) {
      return Left(FailedUpdateUser(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DayEntity>>> getDays({
    required GetDaysParams params,
  }) async {
    try {
      final localDays = await localDataSource.retrieveSavedDays();
      final remoteDays =
          await remoteDataSource.fetchRemoteDays(daysIds: params.daysIds);

      final Map<int, DayEntity> daysMap = {};

      // Добавляем локальные данные
      for (final day in localDays) {
        if (day.cycleId != null) {
          daysMap[day.cycleId!] = day;
        }
      }

      // Обновляем данными с бэка, если они новее
      for (final day in remoteDays) {
        if (day.cycleId != null) {
          if (!daysMap.containsKey(day.cycleId) ||
              day.dateTime.isAfter(daysMap[day.cycleId!]!.dateTime)) {
            daysMap[day.cycleId!] = day;
          }
        }
      }

      // Сортируем дни по дате
      final sortedDays = daysMap.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      log('LAST DAY: ${sortedDays.last}');
      return Right(sortedDays);
    } on Exception catch (e) {
      log('Error getting days: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> manageDay({
    required ManageDayParams params,
  }) async {
    try {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: params.userId,
      );
      final List<int> ids = List.from(rawUser['days']).cast<int>();

      if (ids.isEmpty) {
        final result = await directus.createOne(
          collection: daysCollection,
          data: params.dayMap,
        );
        log('Day is created with id: ${result['id']}');
        return const Right(null);
      }

      final lastRecord = await directus.readOne(
        collection: daysCollection,
        id: ids.last.toString(),
      );

      final lastDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastRecord['dateTime']),
      );

      if (lastDate.isSameDate(DateTime.now())) {
        final lastEntity = DayEntity.fromMap(lastRecord);

        // Всегда обновляем день, если есть новый план питания
        if (params.incomingDay.mealPlanEntity != null) {
          log('Day is updating with new meal plan: ${params.incomingDay.mealPlanEntity?.toMap()}');
          log('Previous meal plan was: ${lastEntity.mealPlanEntity?.toMap()}');

          // Всегда обновляем весь объект для обеспечения целостности данных
          final updateResult = await directus.updateOne(
            collection: daysCollection,
            itemId: lastRecord['id'].toString(),
            updateData: params.dayMap,
          );
          log('Day updated successfully. Update result: $updateResult');
        } else {
          log('No updates needed for the day. Current meal plan: ${lastEntity.mealPlanEntity?.toMap()}');
        }
        return const Right(null);
      } else {
        final result = await directus.createOne(
          collection: daysCollection,
          data: params.dayMap,
        );
        log('New day created with id: ${result['id']}');
        return const Right(null);
      }
    } on Exception catch (e) {
      log('Error while managing day: $e', name: 'UserRepositoryImpl');
      return Left(FailedUpdateUser(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DayEntity>>> getDaysWithMealPlans(
    List<int> daysIds,
  ) async {
    try {
      final days = await whoopRemote.getDaysWithMealPlans(daysIds: daysIds);
      return Right(days);
    } catch (e) {
      log('Error getting days with meal plans: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateDayWithMealPlan({
    required String userId,
    required ChatSnapshotEntity snapshot,
    required MealPlanEntity mealPlan,
  }) async {
    try {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: userId,
      );

      final List<int> ids = List.from(rawUser['days']).cast<int>();
      if (ids.isEmpty) {
        return const Left(FailedUpdateUser('No days found'));
      }

      // Ищем день с такой же датой
      for (final id in ids.reversed) {
        final day = await directus.readOne(
          collection: daysCollection,
          id: id.toString(),
        );

        final dayDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(day['dateTime']),
        );

        if (dayDate.isSameDate(snapshot.date)) {
          await directus.updateOne(
            collection: daysCollection,
            itemId: id.toString(),
            updateData: {
              'mealPlan': mealPlan.toMap(),
              'chatSnap': snapshot.toDirectus(),
            },
          );
          return const Right(null);
        }
      }

      return const Left(FailedUpdateUser('Day not found'));
    } on Exception catch (e) {
      log('Error updating day with meal plan: $e');
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
}
