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
      // DartPluginRegistrant.ensureInitialized();
      // log(authUrl);
      try {
        // Выполняем аутентификацию
        result = await FlutterWebAuth2.authenticate(
          url: authUrl,
          callbackUrlScheme: 'com.rishai',
        );
      } on Exception catch (e) {
        // Обрабатываем случай отмены или ошибки при аутентификации
        log('Authentification failed or error occured:: $e');
        return const Left(WhoopAuthenticationFailure());
      }

      log('Returned result URL: $result');

      final code = Uri.parse(result).queryParameters['code'];
      log('Authorization code: $code');

      if (code == null) {
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
        return const Left(WhoopFailedToReturnAccessToken());
      }
    } on Exception catch (e) {
      // Обработка других возможных исключений
      log('Error during authentication: $e');
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
          attempts++;
        }
      } on Exception catch (e) {
        log('Error during token refresh attempt: $e');
        attempts++; // Увеличиваем счётчик при возникновении ошибки
      }
    }
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
        return const Left(UnknownFailure());
      }
    } on Exception catch (e) {
      log('ERROR WHILE FETCHIG BODY DATA $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, DayEntity>> getData({
    required GetDataParams params,
  }) async {
    try {
      final isCurrentCycleEnded = await tryFetch(
        () async => remoteDataSource.pingLastCycle(
          cycleId: await getLastCycleId(userId: params.userId),
        ),
      );

      log('Cycle is finished: $isCurrentCycleEnded');
      // Получаем сохранённые данные пользователя из локального хранилища
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
      // UserDataEntity? savedUserData =
      //     await hive.fetchUserDataEntity(userId: params.userId);

      // Если цикл не завершён, проверяем данные в локальном хранилище
      // if (isCurrentCycleEnded == false) {
      //   return await _getLocalOrRemoteData();
      // }

      // Если цикл завершился или данные в локальном хранилище отсутствуют, загружаем свежие данные
      return await _fetchAndSaveFreshData(params, isCurrentCycleEnded!);
    } on Exception catch (e) {
      log('ERROR WHILE FETCHING WHOOP DATA: $e');
      return Left(FailedToGetUserData('$e'));
    }
  }

  Future<int?> getLastCycleId({required String userId}) async {
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
  }

// Вспомогательная функция для загрузки свежих данных и их сохранения
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

// Вспомогательная функция для получения локальных данных или загрузки удалённых данных
  Future<Either<Failure, DayEntity>> _getLocalOrRemoteData() async {
    final localData = await localDataSource.retrieveSavedDays();
    if (localData.isNotEmpty) {
      print('local data is: $localData');
      return Right(localData.last);
    }

    // Если локальные данные отсутствуют, пытаемся загрузить данные с удалённого сервера
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
        return const Left(WhoopNoDataFailure());
      }
    } on Exception catch (e) {
      log('EROR WHILE FETCHING FRESHDATA, $e');
      return const Left(WhoopNoDataFailure());
    }
  }

  Future<DayEntity> createFreshDay({
    required DayEntity newDay,
    required String userId,
  }) async {
    if (kDebugMode) {
      log(
        'Creating fresh day:\n'
        'New day date: ${newDay.dateTime}\n'
        'New day cycle: ${newDay.cycleId}\n'
        'Current time: ${DateTime.now()}',
        name: 'WhoopRepository',
      );
    }

    // Проверяем, что новый день действительно новый
    final now = DateTime.now();
    final isNewDay = newDay.dateTime.year == now.year &&
        newDay.dateTime.month == now.month &&
        newDay.dateTime.day == now.day;

    if (!isNewDay) {
      log(
        'Warning: Attempting to create a day that is not today:\n'
        'New day date: ${newDay.dateTime}\n'
        'Current time: $now',
        name: 'WhoopRepository',
      );
    }

    // Создаем новый день
    final freshDay = newDay.copyWith(
      dateTime: now,
      cycleId: newDay.cycleId,
    );

    // Сохраняем в локальное хранилище
    await localDataSource.saveData(data: freshDay);

    // Обновляем на сервере
    await remoteDataSource.updateDirectus(day: freshDay);

    return freshDay;
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
        await remoteDataSource.updateDirectus(day: r);
        return Right(r.macros);
      });
    } on Exception catch (__) {
      rethrow;
    }
  }

  Future<T?> tryFetch<T>(Future<T?> Function() fetchFunction) async {
    const int maxRetries = 3; // максимальное количество попыток
    const Duration retryDelay = Duration(seconds: 2);
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await fetchFunction();
        if (result != null) return result;
      } on Exception catch (e) {
        log('Attempt ${attempt + 1} failed: $e');
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
      // Очищаем данные только при намеренном отключении
      await remoteDataSource.clearWhoopUserDataOnDisconnect(
        userId: params.userId,
      );
      await wTokenService.diconnect(params.userId);
      await hive.disconnectWhoop();
      return const Right(null);
    } on Exception catch (e) {
      log('Error: $e', name: 'DiconnectWhoop Repo');
      return const Left(UnknownFailure());
    }
  }
}
