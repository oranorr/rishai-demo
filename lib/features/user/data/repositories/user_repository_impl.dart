import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

import '../../domain/repositories/user_repository.dart';

@Singleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

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
  Future<Either<Failure, List<DayEntity>>> getDays(
      {required GetDaysParams params}) async {
    try {
      DayEntity currentDay = whoopBloc.state.day;
      final rawList = await directus.readMany(
          collection: daysCollection,
          filters: Filters({'id': F.isIn(params.daysIds)}));
      final days = rawList.map((map) => DayEntity.fromMap(map)).toList();

      if (days.last.dateTime.isSameDate(DateTime.now())) {
        if (days.last.mealPlanEntity != null) {
          chatBloc.add(ChatFetchLastMealPlan(day: days.last));
        }
        days.removeLast();
      } else {
        await directus.createOne(
            collection: daysCollection,
            data: currentDay.toDirectus(userId: params.userId));
      }
      days.add(currentDay);
      return Right(days);
    } catch (e) {
      log('Error getting days: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> manageDay(
      {required ManageDayParams params}) async {
    try {
      final rawUser = await directus.readOne(
          collection: usersCollection, id: params.userId);
      final List<int> ids = List.from(rawUser['days']).cast<int>();

      if (ids.isEmpty) {
        await directus.createOne(
            collection: daysCollection, data: params.dayMap);
        log('Day is created');
        return const Right(null);
      }
      final lastRecord = await directus.readOne(
          collection: daysCollection, id: ids.last.toString());

      final lastDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastRecord['dateTime']));

      if (lastDate.isSameDate(DateTime.now())) {
        final lastEntity = DayEntity.fromMap(lastRecord);

        if ((lastEntity.mealPlanEntity != params.incomingDay.mealPlanEntity &&
                params.incomingDay.mealPlanEntity != null) ||
            lastEntity.macros != params.incomingDay.macros ||
            lastEntity.snap != params.incomingDay.snap) {
          log('Day is updating');
          await directus.updateOne(
              collection: daysCollection,
              itemId: lastRecord['id'].toString(),
              updateData: params.dayMap);
        }
        log('Day is not updating');
        return const Right(null);
      } else {
        await directus.createOne(
            collection: daysCollection, data: params.dayMap);
        log('Day is created');
        return const Right(null);
      }
    } catch (e) {
      log('Error while managing day: $e');
      return const Left(UnknownFailure());
    }
  }
}
