import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/data/data_sources/local/local_data_source.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/refresh_token_model.dart';
import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/auth_response_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';
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
  Future<Either<Failure, WhoopDataEntity>> getData({
    required GetDataParams params,
  }) async {
    try {
      // Получаем сохранённые данные пользователя из локального хранилища
      UserDataEntity? savedUserData =
          await hive.fetchUserDataEntity(userId: params.userId);

      // Если данных пользователя нет, загружаем свежие данные и возвращаем
      if (savedUserData == null) {
        return await _fetchAndSaveFreshData(params);
      }

      final isCurrentCycleEnded = await tryFetch(
        () => remoteDataSource.pingCurrentCycle(
          cycleId: savedUserData.currentCycleId,
        ),
      );

      log('Cycle is finished: $isCurrentCycleEnded');

      // Если цикл не завершён, проверяем данные в локальном хранилище
      if (isCurrentCycleEnded == false) {
        return await _getLocalOrRemoteData();
      }

      // Если цикл завершился или данные в локальном хранилище отсутствуют, загружаем свежие данные
      return await _fetchAndSaveFreshData(params);
    } on Exception catch (e) {
      log('ERROR WHILE FETCHING WHOOP DATA: $e');
      return Left(FailedToGetUserData('$e'));
    }
  }

// Вспомогательная функция для загрузки свежих данных и их сохранения
  Future<Either<Failure, WhoopDataEntity>> _fetchAndSaveFreshData(
    GetDataParams params,
  ) async {
    final res = await tryFetch(
      () => _fetchFreshData(
        modificator: params.goal.modificator,
        gender: params.gender,
        userId: params.userId,
      ),
    );
    return res!.fold((l) {
      return Left(l);
    }, (r) async {
      await localDataSource.saveData(data: r);
      return Right(r);
    });
  }

// Вспомогательная функция для получения локальных данных или загрузки удалённых данных
  Future<Either<Failure, WhoopDataEntity>> _getLocalOrRemoteData() async {
    final localData = await localDataSource.fetchSavedData();
    if (localData != null) {
      return Right(localData);
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

  Future<Either<Failure, WhoopDataEntity>> _fetchFreshData({
    required double modificator,
    required Gender gender,
    required String userId,
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

        final data = WhoopDataEntity(
          weekTdeeAverage: tdeeAverage,
          askTime: askTime,
          macros: MacrosBreakdown(
            kcal: calorieGoal,
            protein: proteins,
            carbs: carbs,
            fat: fats,
          ),
          lastTdee: (cycles.first.score!.kilojoule * kjToKcal).round(),
        );

        await tryFetch(() => remoteDataSource.updateDirectus(data: data));
        await tryFetch(() => localDataSource.saveData(data: data));

        final chatNeedsRefresh =
            await remoteDataSource.doesChatNeedsRefreshment(userId: userId);

        chatBloc.add(
          ChatRefreshChat(
            needsRequestsAmountRefresh: chatNeedsRefresh,
            messagesRefresh: chatNeedsRefresh,
          ),
        );

        return Right(data);
      } else {
        return const Left(WhoopNoDataFailure());
      }
    } on Exception catch (e) {
      log('EROR WHILE FETCHING FRESHDATA, $e');
      return const Left(WhoopNoDataFailure());
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
        await remoteDataSource.updateDirectus(data: r.$2);
        return Right(r.$1);
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
