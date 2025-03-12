import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';

import 'package:dartz/dartz.dart';
import 'package:directus/directus.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/refresh_token_model.dart';
import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/auth_response_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';

final wRepo = getIt.get<WhoopRepository>();

@Singleton(as: WhoopRepository)
class WhoopRepositoryImpl implements WhoopRepository {
  WhoopRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  final WhoopRemoteDataSource remoteDataSource;
  final WhoopLocalDataSource localDataSource;

  final String authorizeUrl = 'https://api.prod.whoop.com/oauth/oauth2/auth';
  final String tokenUrl = 'https://api.prod.whoop.com/oauth/oauth2/token';
  final String customUriScheme = 'com.rishai';
  final String redirectUri = 'com.rishai://redirect';
  final String clientId = Env.clientId;
  final String clientSecret = Env.clientSecret;
  final List<String> scopes = [
    'read:recovery',
    'read:cycles',
    'read:sleep',
    'read:workout',
    'read:profile',
    'read:body_measurement',
    'offline',
  ];

  @override
  Future<Either<Failure, void>> authenticateUser() async {
    try {
      String aT = '';

      final authUrl =
          '$authorizeUrl?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&scope=${scopes.join('%20')}&state=secureRandomState';

      String? result;
      try {
        result = await FlutterWebAuth2.authenticate(
          url: authUrl,
          callbackUrlScheme: 'com.rishai',
        );
      } catch (e, stackTrace) {
        log('Authentication failed or error occurred: $e');
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_web_auth',
          extras: {'auth_url': authUrl},
        );
        return const Left(WhoopAuthenticationFailure());
      }

      log('Returned result URL: $result');

      final code = Uri.parse(result).queryParameters['code'];
      log('Authorization code: $code');

      if (code == null) {
        await WhoopErrorHandler.handleError(
          'No authorization code returned',
          StackTrace.current,
          context: 'whoop_auth_code',
          extras: {'result_url': result},
        );
        return const Left(WhoopDidNotReturnAuthCodeFailure());
      }

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': 'com.rishai://redirect',
          'client_id': clientId,
          'client_secret': clientSecret,
          'state': 'randomGeneratedState',
        },
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        aT = tokenData['access_token'];
        log(tokenData.toString());
        await wTokenService.createTokenService(
          AuthResponseEntity(
            accessToken: tokenData['access_token'],
            refreshToken: tokenData['refresh_token'],
            expiresIn: Duration(seconds: tokenData['expires_in']),
          ),
        );
        log('Access Token: $aT');
        return const Right(null);
      } else {
        log('Failed to get access token: ${response.body}');
        await WhoopErrorHandler.handleError(
          'Failed to get access token',
          StackTrace.current,
          context: 'whoop_access_token',
          response: response,
          extras: {'auth_code': code},
        );
        return const Left(WhoopFailedToReturnAccessToken());
      }
    } catch (e, stackTrace) {
      log('Error during authentication: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_auth_general',
      );
      return const Left(WhoopFailedToReturnAccessToken());
    }
  }

  @override
  Future<RefreshTokenModel?> refreshToken(String refreshToken) async {
    const maxAttempts = 3;
    int attempts = 0;
    late http.Response response;

    while (attempts < maxAttempts) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        response = await http.post(
          Uri.parse(tokenUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
            'client_id': clientId,
            'client_secret': clientSecret,
            'scope': 'offline',
          },
        );

        log('token: $refreshToken, response: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return RefreshTokenModel.fromMap(data);
        } else {
          await WhoopErrorHandler.handleError(
            'Failed to refresh token',
            StackTrace.current,
            context: 'whoop_refresh_token',
            response: response,
            extras: {
              'attempt': attempts + 1,
              'max_attempts': maxAttempts,
            },
          );
          attempts++;
        }
      } catch (e, stackTrace) {
        log('Error during token refresh attempt: $e');
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_refresh_token',
          extras: {
            'attempt': attempts + 1,
            'max_attempts': maxAttempts,
          },
        );
        attempts++;
      }
    }

    await WhoopErrorHandler.handleError(
      'Max refresh token attempts reached',
      StackTrace.current,
      context: 'whoop_refresh_token_max_attempts',
      extras: {'max_attempts': maxAttempts},
    );
    log('Max attempts reached, failed to refresh token');
    return null;
  }

  @override
  Future<Either<Failure, BodyMeasurementsEntity>> getBodyData() async {
    try {
      final BodyMeasurementsEntity? body = await remoteDataSource.getBodyData();
      log('Body is: $body\n\n');
      if (body != null) {
        return Right(body);
      } else {
        await WhoopErrorHandler.handleError(
          'Body data is null',
          StackTrace.current,
          context: 'whoop_get_body_data',
        );
        return const Left(UnknownFailure());
      }
    } catch (e, stackTrace) {
      log('ERROR WHILE FETCHING BODY DATA $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_body_data',
      );
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, DayEntity>> getData({
    required GetDataParams params,
  }) async {
    bool? isCurrentCycleEnded;
    try {
      isCurrentCycleEnded = await tryFetch(
        () async => remoteDataSource.pingLastCycle(
          cycleId: await getLastCycleId(userId: params.userId),
        ),
      );

      log('Cycle is finished: $isCurrentCycleEnded');

      if (isCurrentCycleEnded == false) {
        print('cycle IS NOT finished, pulling old data');
        final res = await _getLocalOrRemoteData();
        return res.fold(
          (l) async {
            print('stored data came null, fetching fresh data');
            return _fetchAndSaveFreshData(params, isCurrentCycleEnded!);
          },
          (r) {
            return Right(r);
          },
        );
      }

      return await _fetchAndSaveFreshData(params, isCurrentCycleEnded!);
    } catch (e, stackTrace) {
      log('ERROR WHILE FETCHING WHOOP DATA: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_data',
        extras: {
          'user_id': params.userId,
          'is_current_cycle_ended': isCurrentCycleEnded,
        },
      );
      return Left(FailedToGetUserData('$e'));
    }
  }

  Future<int?> getLastCycleId({required String userId}) async {
    try {
      final rawUser =
          await directus.readOne(collection: usersCollection, id: userId);
      final List<int> days = List.from(rawUser['days']).cast<int>();
      if (days.isEmpty) return null;
      final rawLastDay = await directus.readOne(
        collection: daysCollection,
        id: days.last.toString(),
      );
      return rawLastDay['cycleId'] != null
          ? int.parse(rawLastDay['cycleId'])
          : null;
    } catch (e, stackTrace) {
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_last_cycle_id',
        extras: {'user_id': userId},
      );
      rethrow;
    }
  }

  Future<Either<Failure, DayEntity>> _fetchAndSaveFreshData(
    GetDataParams params,
    bool needsCreateNewDay,
  ) async {
    final res = await tryFetch(
      () => _fetchFreshData(
        modificator: params.goal.modificator,
        gender: params.gender,
        userId: params.userId,
        needsCreateNewDay: needsCreateNewDay,
      ),
    );
    return res!.fold((l) {
      return Left(l);
    }, (r) async {
      await localDataSource.saveData(data: r);
      return Right(
        r,
      );
    });
  }

  Future<Either<Failure, DayEntity>> _getLocalOrRemoteData() async {
    final localData = await localDataSource.retrieveSavedDays();
    if (localData.isNotEmpty) {
      print('local data is: $localData');
      return Right(localData.last);
    }

    final remoteData =
        await tryFetch(() => remoteDataSource.fetchDirectusData());

    if (remoteData != null) {
      await localDataSource.saveData(data: remoteData);
      return Right(remoteData);
    } else {
      log('remote data empty, fetching any data now.');
      return const Left(FailedToGetUserData('Remote data is empty'));
    }
  }

  Future<Either<Failure, DayEntity>> _fetchFreshData({
    required double modificator,
    required Gender gender,
    required String userId,
    required bool needsCreateNewDay,
  }) async {
    try {
      final BodyMeasurementsEntity? body =
          await tryFetch(() => remoteDataSource.getBodyData());
      final res = await tryFetch(() => remoteDataSource.getCycles());

      List<CycleModel> cycles = res!.$1;
      int indexOfCurrentCycle = res.$2;

      List<WorkoutModel> workouts = [];
      RecoveryModel? recovery;

      if (cycles.isNotEmpty) {
        workouts =
            await remoteDataSource.getWorkoutsOfCycle(cycle: cycles.first);
        log('workouts are: $workouts\n\n');

        recovery = await tryFetch(
          () => remoteDataSource.getRecoveryOfCycle(cycleId: cycles.first.id),
        );
        log('recovery is: $recovery\n\n');
      }

      final SleepModel? sleep =
          await tryFetch(() => remoteDataSource.getLastSleep());
      log('sleep is: $sleep\n\n');

      if (cycles.isNotEmpty &&
          recovery != null &&
          sleep != null &&
          body != null) {
        final DateTime askTime = DateTime.now();

        final double tdeeAverage = calculateTDEEAverage(cycles);
        final double strainValue = cycles.first.score!.strain;

        final int calorieGoal = calculateCalorieGoal(
          tdeeAvrage: tdeeAverage,
          modificator: modificator,
        ).round();

        final int recoveryScore = recovery.score!.recoveryScore.round();
        final int sleepScore = sleep.score!.sleepPerformancePercentage!.round();

        final userData = UserDataEntity(
          workouts: workouts,
          userWeightLbs: body.weight * kgToLbs,
          gender: gender,
          strainValue: strainValue,
          recoveryScore: recoveryScore,
          sleepPerformance: sleepScore,
          calorieGoal: calorieGoal,
          userId: userId,
          askTime: askTime,
          currentCycleId: indexOfCurrentCycle,
        );

        await hive.saveUserData(dataEntity: userData);

        final int proteins = userData.calcProteins();
        final int fats = userData.clacFats();
        final int carbs = userData.calcCarbs(
          kalorieGoal: calorieGoal,
          proteinsInKcal: proteins * 4,
          fatsInKcal: fats * 9,
        );

        DayEntity newDay = DayEntity(
          cycleId: indexOfCurrentCycle,
          directusId: 0,
          snap: ChatSnapshotEntity(
            messages: [],
            date: askTime,
            requestsLeft: chatBloc.state.requestsLeft,
          ),
          healthMetrics: calcHealthMetrics(
            (cycles.first.score!.kilojoule * kjToKcal).round(),
          ),
          dateTime: askTime,
          weekTdeeAverage: tdeeAverage.toInt(),
          macros: MacrosBreakdown(
            kcal: calorieGoal,
            protein: proteins,
            carbs: carbs,
            fat: fats,
          ),
        );

        final chatNeedsRefresh =
            await remoteDataSource.doesChatNeedsRefreshment(userId: userId);

        chatBloc.add(
          ChatRefreshChat(
            needsRequestsAmountRefresh: chatNeedsRefresh,
            messagesRefresh: chatNeedsRefresh,
          ),
        );
        print('needs creating fresh day? $needsCreateNewDay');
        if (needsCreateNewDay) {
          newDay = await createFreshDay(newDay: newDay, userId: userId);
        }
        await tryFetch(() => remoteDataSource.updateDirectus(day: newDay));
        await tryFetch(() => localDataSource.saveData(data: newDay));

        return Right(newDay);
      } else {
        await WhoopErrorHandler.handleError(
          'Missing required data for fresh data fetch',
          StackTrace.current,
          context: 'whoop_fetch_fresh_data',
          extras: {
            'has_cycles': cycles.isNotEmpty,
            'has_recovery': recovery != null,
            'has_sleep': sleep != null,
            'has_body': body != null,
            'user_id': userId,
          },
        );
        return const Left(WhoopNoDataFailure());
      }
    } catch (e, stackTrace) {
      log('ERROR WHILE FETCHING FRESH DATA: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_fetch_fresh_data',
        extras: {
          'user_id': userId,
          'gender': gender.toString(),
          'modificator': modificator,
          'needs_create_new_day': needsCreateNewDay,
        },
      );
      return const Left(WhoopNoDataFailure());
    }
  }

  Future<DayEntity> createFreshDay({
    required DayEntity newDay,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        log(
          'Creating fresh day:\n'
          'New day date: ${newDay.dateTime}\n'
          'New day cycle: ${newDay.cycleId}\n'
          'Current time: ${DateTime.now()}',
          name: 'WhoopRepository',
        );
      }

      final now = DateTime.now();
      final isNewDay = newDay.dateTime.year == now.year &&
          newDay.dateTime.month == now.month &&
          newDay.dateTime.day == now.day;

      if (!isNewDay) {
        final String warning =
            'Warning: Attempting to create a day that is not today:\n'
            'New day date: ${newDay.dateTime}\n'
            'Current time: $now';
        log(warning, name: 'WhoopRepository');
        await WhoopErrorHandler.handleError(
          warning,
          StackTrace.current,
          context: 'whoop_create_fresh_day',
          extras: {
            'new_day_date': newDay.dateTime.toString(),
            'current_time': now.toString(),
            'user_id': userId,
          },
        );
      }

      final freshDay = newDay.copyWith(
        dateTime: now,
        cycleId: newDay.cycleId,
      );

      await localDataSource.saveData(data: freshDay);
      await remoteDataSource.updateDirectus(day: freshDay);

      return freshDay;
    } catch (e, stackTrace) {
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_create_fresh_day',
        extras: {
          'user_id': userId,
          'cycle_id': newDay.cycleId,
          'date_time': newDay.dateTime.toString(),
        },
      );
      rethrow;
    }
  }

  double calculateCalorieGoal({
    required double tdeeAvrage,
    required double modificator,
  }) {
    return (1 + modificator) * tdeeAvrage;
  }

  double calculateTDEEAverage(List<CycleModel> cycles) {
    double sum = 0;
    for (final cyc in cycles) {
      sum += cyc.score!.kilojoule;
    }
    sum = sum * kjToKcal;
    return sum / cycles.length;
  }

  HealthMetricsEntity calcHealthMetrics(int lastTdee) {
    int calcBMI() {
      BodyMeasurementsEntity bm = userBloc.state.user.bodyMeasurements!;
      return (bm.weight / (bm.height * bm.height)).round();
    }

    int calcBMR() {
      final user = userBloc.state.user;
      final s = user.gender == Gender.male ? 5 : -161;
      final res = (10 * user.bodyMeasurements!.weight) +
          (6.25 * (user.bodyMeasurements!.height * 100)) -
          (5 * user.age!) +
          s;

      return res.round();
    }

    return HealthMetricsEntity(
      bmi: calcBMI(),
      lastTdee: lastTdee,
      bmr: calcBMR(),
      bodyFatPerc: 0,
    );
  }

  @override
  Future<Either<Failure, MacrosBreakdown>> changeModificatorOfSex({
    required ChangeModificatorOrSexParams params,
  }) async {
    try {
      final res =
          await localDataSource.changeModificatorOrSexLocal(params: params);

      return res.fold((l) async {
        return Left(l);
      }, (r) async {
        try {
          await remoteDataSource.updateDirectus(day: r);
          return Right(r.macros);
        } catch (e, stackTrace) {
          await WhoopErrorHandler.handleError(
            e,
            stackTrace,
            context: 'whoop_change_modificator_update_directus',
            extras: {
              'modificator': params.modificator,
              'gender': params.gender.toString(),
            },
          );
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_change_modificator',
        extras: {
          'modificator': params.modificator,
          'gender': params.gender.toString(),
        },
      );
      rethrow;
    }
  }

  Future<T?> tryFetch<T>(Future<T?> Function() fetchFunction) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await fetchFunction();
        if (result != null) return result;
      } catch (e, stackTrace) {
        log('Attempt ${attempt + 1} failed: $e');
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_try_fetch',
          extras: {
            'attempt': attempt + 1,
            'max_retries': maxRetries,
            'function': fetchFunction.toString(),
          },
        );
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, void>> disconnectWhoop({
    required DisconnecWhoopParams params,
  }) async {
    try {
      await remoteDataSource.clearWhoopUserDataOnDisconnect(
        userId: params.userId,
      );
      await wTokenService.diconnect(params.userId);
      await hive.disconnectWhoop();
      return const Right(null);
    } catch (e, stackTrace) {
      log('Error while disconnecting Whoop: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_disconnect',
        extras: {'user_id': params.userId},
      );
      return const Left(UnknownFailure());
    }
  }
}
