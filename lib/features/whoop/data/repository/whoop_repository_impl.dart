import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/network/request_timer.dart';
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

    final response = await RequestTimer.httpClient.post(
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
  }

  @override
  Future<RefreshTokenModel?> refreshToken(String refreshToken) async {
    const maxAttempts = 3;
    int attempts = 0;
    late http.Response response;

    while (attempts < maxAttempts) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        response = await RequestTimer.httpClient.post(
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
  Future<Either<Failure, BodyMeasurementsEntity?>> getBodyData() async {
    try {
      final isTokenValid = await wTokenService.isAccessTokenValid();
      if (!isTokenValid) {
        log(
          'Token is invalid in repository, attempting to refresh...',
          name: 'WhoopRepo',
        );
        final refreshSuccess =
            await wTokenService.refreshToken(wTokenService.refToken);
        if (!refreshSuccess) {
          log('Failed to refresh token in repository', name: 'WhoopRepo');
          return const Left(WhoopAuthenticationFailure());
        }
        log('Token successfully refreshed in repository', name: 'WhoopRepo');
      }

      final BodyMeasurementsEntity? body = await remoteDataSource.getBodyData();
      log('Body data from remote source: $body', name: 'WhoopRepo');
      return Right(body);
    } catch (e, stackTrace) {
      log('ERROR WHILE FETCHING BODY DATA $e', name: 'WhoopRepo');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_body_data',
        extras: {
          'token_valid': await wTokenService.isAccessTokenValid(),
        },
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
      log('>>> [getData] Starting data fetch for user: ${params.userId}');
      log('>>> [getData] User goal modificator: ${params.goal.modificator}');

      final int? lastCycleId = await getLastCycleId(
        userId: params.userId,
      ); // Обновлено для UUID строки
      log('>>> [getData] Last cycle ID: $lastCycleId');

      isCurrentCycleEnded = await tryFetch(
        () async => remoteDataSource.pingLastCycle(
          cycleId: lastCycleId,
        ),
      );

      log('>>> [getData] Cycle is finished: $isCurrentCycleEnded');

      if (isCurrentCycleEnded == false) {
        log('>>> [getData] Cycle is NOT finished, attempting to get local/remote data');
        final res = await _getLocalOrRemoteData();

        return res.fold(
          (l) async {
            log('>>> [getData] Local/remote data failed, fetching fresh data: ${l.message}');
            return _fetchAndSaveFreshData(params, isCurrentCycleEnded!);
          },
          (r) {
            log('>>> [getData] Successfully retrieved local/remote data with calories: ${r.macros.kcal}');
            return Right(r);
          },
        );
      }

      log('>>> [getData] Cycle is finished, fetching fresh data');
      return await _fetchAndSaveFreshData(params, isCurrentCycleEnded!);
    } catch (e, stackTrace) {
      log('>>> [getData] ERROR WHILE FETCHING WHOOP DATA: $e');
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
    // Обновлено для UUID строки
    try {
      final result = await dayManager.getLastDayWithCycleStatus(
        userId: userId,
        checkCycleStatus: false,
      );

      return result?.cycleId;
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
      // await localDataSource.saveData(data: r);
      return Right(
        r,
      );
    });
  }

  Future<Either<Failure, DayEntity>> _getLocalOrRemoteData() async {
    log('>>> [_getLocalOrRemoteData] Checking for local data...');
    final localData = await localDataSource.retrieveSavedDays();

    if (localData.isNotEmpty) {
      final sortedDays = localData
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      log('>>> [_getLocalOrRemoteData] Found local data: ${sortedDays.last.directusId} with calories: ${sortedDays.last.macros.kcal}');
      return Right(sortedDays.last);
    }

    // Если локальные данные пусты, не пытаемся получить данные с сервера
    // так как они могут быть устаревшими или некорректными
    log('>>> [_getLocalOrRemoteData] Local data is empty, will fetch fresh data instead of remote data');
    return const Left(
      FailedToGetUserData('Local data is empty, need fresh data'),
    );
  }

  Future<Either<Failure, DayEntity>> _fetchFreshData({
    required double modificator,
    required Gender gender,
    required String userId,
    required bool needsCreateNewDay,
  }) async {
    try {
      // 🔄 ПРОВЕРЯЕМ RECOMP ПЕРЕД СОЗДАНИЕМ ДНЯ
      if (needsCreateNewDay) {
        log('🔄 [checkRecompForNewDay] Проверяем recomp перед созданием дня...');
        final updatedModifier = await userBloc.checkRecompForNewDay();
        log('🔄 [checkRecompForNewDay] Обновленный модификатор: $updatedModifier (был: $modificator)');

        // Используем обновленный модификатор
        modificator = updatedModifier;
      }

      final BodyMeasurementsEntity? body =
          await tryFetch(() => remoteDataSource.getBodyData());
      final res = await tryFetch(() => remoteDataSource.getCycles());

      // Если не смогли получить циклы, считаем это критичной ошибкой и выходим
      if (res == null) {
        await WhoopErrorHandler.handleError(
          'Failed to fetch cycles (null response)',
          StackTrace.current,
          context: 'whoop_fetch_fresh_data_cycles_null',
          extras: {
            'user_id': userId,
            'directus_user_id': userId,
          },
        );
        return const Left(WhoopNoDataFailure());
      }

      List<CycleModel> cycles = res.$1;
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

      // -------------------------
      // Жесткие гварды перед расчетами (без усложнения UI/UX)
      // -------------------------
      final List<String> missingReasons = [];

      final hasCycles = cycles.isNotEmpty;
      if (!hasCycles) {
        missingReasons.add('cycles_empty');
      }

      if (body == null) {
        missingReasons.add('body_null');
      }

      if (recovery == null) {
        missingReasons.add('recovery_null');
      } else if (recovery.score == null) {
        missingReasons.add('recovery_score_null');
      } else if (recovery.score!.recoveryScore.isNaN) {
        missingReasons.add('recovery_score_nan');
      }

      if (sleep == null) {
        missingReasons.add('sleep_null');
      } else if (sleep.score == null) {
        missingReasons.add('sleep_score_null');
      } else if (sleep.score!.sleepPerformancePercentage == null) {
        missingReasons.add('sleep_performance_null');
      }

      // Для расчетов нужны score в цикле (strain + kilojoule)
      final CycleScore? cycleScore = hasCycles ? cycles.first.score : null;
      if (cycleScore == null) {
        missingReasons.add('cycle_score_null');
      } else {
        if (cycleScore.strain.isNaN) {
          missingReasons.add('cycle_score_strain_nan');
        }
        if (cycleScore.kilojoule.isNaN) {
          missingReasons.add('cycle_score_kilojoule_nan');
        }
      }

      if (missingReasons.isNotEmpty) {
        // Логируем четкую причину, но поведение UI остается прежним (snackbar)
        await WhoopErrorHandler.handleError(
          'Missing required data for fresh data fetch',
          StackTrace.current,
          context: 'whoop_fetch_fresh_data',
          extras: {
            'user_id': userId,
            'directus_user_id': userId,
            'missing_reasons': missingReasons,
            'has_cycles': hasCycles,
            'has_recovery': recovery != null,
            'has_sleep': sleep != null,
            'has_body': body != null,
          },
        );
        return const Left(WhoopNoDataFailure());
      }

      if (cycles.isNotEmpty &&
          recovery != null &&
          sleep != null &&
          body != null) {
        final DateTime askTime = DateTime.now();

        final double tdeeAverage = calculateTDEEAverage(cycles);
        print('>>> [_fetchFreshData] Calculated TDEE Average: $tdeeAverage');
        final double strainValue = cycleScore!.strain;

        print(
          '>>> [_fetchFreshData] Calculating calorie goal with modificator: $modificator',
        );
        final int calorieGoal = calculateCalorieGoal(
          tdeeAvrage: tdeeAverage,
          modificator: modificator,
        ).round();
        print('>>> [_fetchFreshData] Calculated Calorie Goal: $calorieGoal');

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

        // [DIET_MACRO_FIX] Проверяем диету пользователя и используем правильный алгоритм
        final user = userBloc.state.user;
        final userDiets = user.foodPreferences?.diets ?? [];
        final needsKetoCarnivoreAlgorithm =
            UserDataEntity.needsNewMacrosOnDietChange(userDiets);

        log('[_fetchFreshData] 👤 Диеты пользователя: $userDiets');
        log('[_fetchFreshData] 🥩 Нужен кето/карнивор алгоритм: $needsKetoCarnivoreAlgorithm');

        // Используем правильный метод расчета макросов
        final MacrosBreakdown macros;
        if (needsKetoCarnivoreAlgorithm) {
          // Определяем конкретный тип специальной диеты для нового пользователя
          final specialDietType = UserDataEntity.getSpecialDietType(userDiets);

          switch (specialDietType) {
            case 'carnivore':
              log('[_fetchFreshData] 🥩 Применяю CARNIVORE алгоритм для нового пользователя (1% углеводов, 30-35% белки, 65-70% жиры)');
              macros = userData.calcMacrosForCarnivore();
              break;
            case 'keto':
              log('[_fetchFreshData] 🥑 Применяю KETO алгоритм для нового пользователя (5-10% углеводов, 20-25% белки, 65-75% жиры)');
              macros = userData.calcMacrosForKeto();
              break;
            default:
              // Fallback на keto алгоритм для совместимости
              log('[_fetchFreshData] ⚠️ Неопознанная специальная диета для нового пользователя, используем KETO fallback алгоритм');
              macros = userData.calcMacrosForKeto();
          }
        } else {
          log('[_fetchFreshData] 🍽️ Применяю СТАНДАРТНЫЙ алгоритм для нового пользователя');
          macros = userData.calcMacros();
        }

        log('[_fetchFreshData] 📊 Рассчитанные макросы: P=${macros.protein}г, C=${macros.carbs}г, F=${macros.fat}г, K=${macros.kcal}ккал');

        DayEntity newDay = DayEntity(
          cycleId: indexOfCurrentCycle,
          directusId: 0,
          snap: ChatSnapshotEntity(
            messages: [],
            date: askTime,
            requestsLeft: chatBloc.state.requestsLeft,
          ),
          healthMetrics: calcHealthMetrics(
            (cycleScore.kilojoule * kjToKcal).round(),
          ),
          dateTime: askTime,
          weekTdeeAverage: tdeeAverage.toInt(),
          macros:
              macros, // Используем рассчитанные макросы вместо раздельных значений
        );

        print(
          '>>> [_fetchFreshData] Final Macros: Kcal=${newDay.macros.kcal}, P=${newDay.macros.protein}, C=${newDay.macros.carbs}, F=${newDay.macros.fat}',
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
          print('>>> [_fetchFreshData] Creating fresh day...');
          newDay = await createFreshDay(newDay: newDay, userId: userId);
        }
        // await tryFetch(() => remoteDataSource.updateDirectus(day: newDay));
        // await tryFetch(() => localDataSource.saveData(data: newDay));

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
    } on Exception catch (e, stackTrace) {
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
      print(
        '>>> [createFreshDay] Before saving - New day macros: ${newDay.macros}',
      );
      final DayEntity createdDay =
          await dayManager.createOrUpdateDay(day: newDay);
      print(
        '>>> [createFreshDay] After saving - Created day macros: ${createdDay.macros}',
      );
      return createdDay;

      // if (kDebugMode) {
      //   log(
      //     'Creating fresh day:\n'
      //     'New day date: ${newDay.dateTime}\n'
      //     'New day cycle: ${newDay.cycleId}\n'
      //     'Current time: ${DateTime.now()}',
      //     name: 'WhoopRepository',
      //   );
      // }

      // final now = DateTime.now();
      // final isNewDay = newDay.dateTime.year == now.year &&
      //     newDay.dateTime.month == now.month &&
      //     newDay.dateTime.day == now.day;

      // if (!isNewDay) {
      //   final String warning =
      //       'Warning: Attempting to create a day that is not today:\n'
      //       'New day date: ${newDay.dateTime}\n'
      //       'Current time: $now';
      //   log(warning, name: 'WhoopRepository');
      //   await WhoopErrorHandler.handleError(
      //     warning,
      //     StackTrace.current,
      //     context: 'whoop_create_fresh_day',
      //     extras: {
      //       'new_day_date': newDay.dateTime.toString(),
      //       'current_time': now.toString(),
      //       'user_id': userId,
      //     },
      //   );
      // }

      // await localDataSource.saveData(data: freshDay);
      // await remoteDataSource.updateDirectus(day: freshDay);
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
    print(
      '>>> [calculateCalorieGoal] Calculating goal: TDEE Average = $tdeeAvrage, Modificator = $modificator',
    );
    final result = (1 + modificator) * tdeeAvrage;
    print('>>> [calculateCalorieGoal] Resulting Goal = $result');
    return result;
  }

  double calculateTDEEAverage(List<CycleModel> cycles) {
    double sum = 0;
    print(
      '>>> [calculateTDEEAverage] Calculating TDEE Average for ${cycles.length} cycles:',
    );
    for (final cyc in cycles) {
      final kj = cyc.score!.kilojoule;
      print(
        '>>> [calculateTDEEAverage]   - Cycle ID: ${cyc.id}, Kilojoules: $kj',
      );
      sum += kj;
    }
    sum = sum * kjToKcal;
    final average = sum / cycles.length;
    print(
      '>>> [calculateTDEEAverage] Total Kcal Sum: $sum, Average TDEE (kcal): $average',
    );
    return average;
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
        print(
          '>>> [changeModificatorOfSex] Modificator/Sex changed. Old day data: $r',
        );
        try {
          // [FIX] Убираем двойное обновление дня - выполняем обновление сразу
          final dayUpdateResult = await dayManager.createOrUpdateDay(day: r);
          print(
            '>>> [changeModificatorOfSex] Day updated successfully. New Macros: ${r.macros}',
          );

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
