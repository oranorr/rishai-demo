import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart' as dm;
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/network/request_timer.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/endpoints.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part './remote_data_source.dart';

final whoopRemote = getIt.get<WhoopRemoteDataSource>();

@Singleton(as: WhoopRemoteDataSource)
class WhoopRemoteDataSourceImpl implements WhoopRemoteDataSource {
  bool emptify = emptifyWhoopData;
  // Константы для повторных попыток
  final int maxRetries = 3;
  final Duration retryDelay = const Duration(seconds: 2);

  @override
  Future<BodyMeasurementsEntity?> getBodyData() async {
    try {
      // Проверяем и обновляем токен перед запросом
      final isTokenValid = await wTokenService.isAccessTokenValid();
      if (!isTokenValid) {
        log(
          'Token is invalid, attempting to refresh...',
          name: 'WhoopBodyData',
        );
        final refreshSuccess =
            await wTokenService.refreshToken(wTokenService.refToken);
        if (!refreshSuccess) {
          log(
            'Failed to refresh token for body data request',
            name: 'WhoopBodyData',
          );
          return null;
        }
        log('Token successfully refreshed', name: 'WhoopBodyData');
      }

      log('Making request to get body measurements...', name: 'WhoopBodyData');
      final rawBm = await _makeRequest(WhoopEndpoints().bodyMeasurements);

      if (rawBm == null) {
        log(
          'Failed to get body measurements: API returned null',
          name: 'WhoopBodyData',
        );
        return null;
      }

      log('Received body measurements data: $rawBm', name: 'WhoopBodyData');

      if (!rawBm.containsKey('height_meter') ||
          !rawBm.containsKey('weight_kilogram') ||
          !rawBm.containsKey('max_heart_rate')) {
        log(
          'Body measurements data is incomplete: $rawBm',
          name: 'WhoopBodyData',
        );
        return null;
      }

      final bodyData = BodyMeasurementsEntity(
        height: rawBm['height_meter'],
        weight: (rawBm['weight_kilogram'] as double).round(),
        maxHeartRate: rawBm['max_heart_rate'],
      );

      log(
        'Successfully parsed body measurements: $bodyData',
        name: 'WhoopBodyData',
      );
      return bodyData;
    } catch (e, stackTrace) {
      log('Error getting body measurements: $e', name: 'WhoopBodyData');
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'context': 'whoop_get_body_data',
          'endpoint': WhoopEndpoints().bodyMeasurements,
          'token_valid': await wTokenService.isAccessTokenValid(),
        }),
      );
      return null;
    }
  }

  @override
  Future<(List<CycleModel>, int)> getCycles() async {
    try {
      final data = await _makeRequest(WhoopEndpoints().whoopCycles);

      if (data == null || data['records'] == null) {
        return (<CycleModel>[], 0);
      }

      final List<Map<String, dynamic>> rawCycles =
          List<Map<String, dynamic>>.from(data['records']);

      Map<String, dynamic> currentCycle =
          rawCycles.firstWhere((map) => map['end'] == null);

      final List<CycleModel> cycles = rawCycles
          .take(8)
          .where((raw) => raw['score_state'] == 'SCORED' && raw['end'] != null)
          .map((map) => CycleModel.fromMap(map))
          .toList();
      log('CYCLES LENGTH: ${cycles.length}');
      return (cycles, currentCycle['id'] as int);
    } on Exception catch (__) {
      rethrow;
    }
  }

  @override
  Future<List<WorkoutModel>> getWorkoutsOfCycle({
    required CycleModel cycle,
  }) async {
    final data = await _makeRequest(WhoopEndpoints().workouts);

    List<Map<String, dynamic>> rawWorkouts =
        List.from(data!['records']).cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> rawScoredWorkouts =
        rawWorkouts.where((raw) => raw['score_state'] == 'SCORED').toList();

    List<WorkoutModel> workouts = rawScoredWorkouts.map((raw) {
      return WorkoutModel.fromMap(raw);
    }).toList();
    if (workouts.isNotEmpty) {
      return emptify
          ? []
          : workouts.where((workout) {
              final workoutEnd = workout.end ?? DateTime.now();
              final cycleEnd = cycle.end;

              return workout.start.isAfter(cycle.start) &&
                  workoutEnd.isBefore(cycleEnd!);
            }).toList();
    } else {
      return [];
    }
  }

  @override
  Future<RecoveryModel?> getRecoveryOfCycle({required int cycleId}) async {
    final data = await _makeRequest(WhoopEndpoints().recoveries);

    List<dynamic> list = emptify ? [] : data!['records'];
    if (list.isNotEmpty) {
      final first = list.firstWhere(
        (recovery) =>
            recovery['score_state'] == 'SCORED' &&
            recovery['cycle_id'] == cycleId,
        orElse: () => list.first,
      );
      return RecoveryModel.fromJson(first);
    } else {
      return null;
    }
  }

  @override
  Future<SleepModel?> getLastSleep() async {
    final rawSleeps = await _makeRequest(WhoopEndpoints().sleeps);
    List<dynamic> list = emptify ? [] : rawSleeps!['records'];
    if (list.isNotEmpty) {
      final first = list.firstWhere(
        (sleep) => sleep['score_state'] == 'SCORED',
        orElse: () => list.first,
      );
      return SleepModel.fromMap(first);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _makeRequest(
    String endpoint, {
    bool? needsLimit,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(endpoint);
    late http.Response response;

    if (needsLimit ?? false) {
      uri.replace(queryParameters: {'limit': '7'});
    }
    const maxAttempts = 3;
    int attempts = 0;
    final client = timeout != null ? http.Client() : RequestTimer.httpClient;

    while (attempts <= maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      final thisResponse = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${wTokenService.accessToken}',
        },
      ).timeout(timeout ?? const Duration(seconds: 30));
      if (thisResponse.statusCode == 200) {
        response = thisResponse;
        break;
      } else {
        attempts++;
        response = thisResponse;
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      log('Failed to get cycle data: ${response.statusCode} - ${response.body}, endpoint: $endpoint');
      return null;
    }
  }

  @override
  Future<DayEntity?> fetchDirectusData() async {
    try {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: userBloc.state.user.directusId,
      );

      if (rawUser.isEmpty) {
        log('User data is empty in fetchDirectusData');
        return null;
      }

      // Используем новую архитектуру - получаем последний день напрямую
      final lastDay = await dm.dayManager.getLastUserDay(
        userId: rawUser['id'].toString(),
      );

      if (lastDay == null) {
        log('No days found for user in fetchDirectusData');
        return null;
      }

      log(
        'Found last day for user: ${lastDay.dateTime}',
        name: 'RemoteDataSourceImpl',
      );

      // Проверяем наличие whoopData в пользователе
      final data = rawUser['whoopData'];
      if (data != null &&
          data.isNotEmpty &&
          data['weekTdeeAverage'] != null &&
          data['macros'] != null &&
          data['askTime'] != null) {
        log('Using whoopData from user: weekTdeeAverage=${data['weekTdeeAverage']}');

        // Создаём обновлённый день с данными из whoopData
        final dayEntity = lastDay.copyWith(
          weekTdeeAverage: data['weekTdeeAverage'],
          macros: MacrosBreakdown.fromMap(data['macros']),
          dateTime: DateTime.fromMillisecondsSinceEpoch(data['askTime']),
        );
        return dayEntity;
      } else {
        log('whoopData is missing or incomplete: $data');
        // Возвращаем последний день как есть
        return lastDay;
      }
    } catch (e, stackTrace) {
      log('Error in fetchDirectusData: $e');
      return null;
    }
  }

  // @override
  // Future<bool> pingCurrentCycle() async {
  //   await wTokenService.initService();
  //   UserDataEntity? savedUserData =
  //       await hive.fetchUserDataEntity(userId: userBloc.state.user.directusId);
  //   if (savedUserData == null) {
  //     return false;
  //   }
  //   final raw = await _requestData(
  //     endpoint:
  //         WhoopEndpoints().cycleById(cycleId: savedUserData.currentCycleId),
  //   );
  //   log(raw.toString());
  //   return raw!['end'] != null && raw['score_state'] == 'SCORED';
  // }

  @override
  Future<bool> pingLastCycle({required int? cycleId}) async {
    await wTokenService.initService();
    if (cycleId == null) return true;

    final raw = await _makeRequest(
      WhoopEndpoints().cycleById(cycleId: cycleId),
      timeout: const Duration(seconds: 5),
    );
    // log(raw.toString());

    if (raw == null) return true;

    return raw['end'] != null && raw['score_state'] == 'SCORED';
  }

  @override
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId}) async {
    try {
      // Используем новую архитектуру - получаем последний день
      final lastDay = await dm.dayManager.getLastUserDay(userId: userId);
      if (lastDay != null) {
        await directus.deleteOne(
          collection: daysCollection,
          id: lastDay.directusId.toString(),
        );
      }
      return true;
    } on Exception catch (e) {
      log('Error: $e', name: 'Disconnect Whoop RDS');
      return false;
    }
  }

  @override
  Future<bool> doesChatNeedsRefreshment({required String userId}) async {
    try {
      // Используем новую архитектуру - получаем последний день напрямую
      final lastDay = await dm.dayManager.getLastUserDay(userId: userId);

      if (lastDay == null) {
        return true;
      }

      // Проверяем, отличается ли дата последнего дня от сегодняшней
      return !lastDay.dateTime.isSameDate(DateTime.now());
    } catch (e) {
      log(
        'Ошибка в doesChatNeedsRefreshment: $e',
        name: 'WhoopRemoteDataSource',
      );
      return true; // В случае ошибки считаем, что чат нуждается в обновлении
    }
  }

  // @override
  // Future<List<DayEntity>> getDaysWithMealPlans({
  //   required List<int> daysIds,
  // }) async {
  //   try {
  //     // final List<DayEntity> days = [];
  //     final Map<String, DayEntity> uniqueDays =
  //         {}; // Используем Map для хранения уникальных дней по дате

  //     for (final id in daysIds) {
  //       final rawDay = await directus.readOne(
  //         collection: daysCollection,
  //         id: id.toString(),
  //       );

  //       if (rawDay.isNotEmpty) {
  //         final dayEntity = DayEntity(
  //           directusId: id,
  //           cycleId:
  //               rawDay['cycleId'] != null ? int.parse(rawDay['cycleId']) : null,
  //           weekTdeeAverage: rawDay['weekTdeeAverage'],
  //           macros: MacrosBreakdown.fromMap(rawDay['macros']),
  //           mealPlanEntity: rawDay['mealPlan'] != null
  //               ? MealPlanEntity.fromMap(rawDay['mealPlan'])
  //               : null,
  //           healthMetrics: HealthMetricsEntity.fromMap(rawDay['healthMetrics']),
  //           snap: ChatSnapshotEntity.fromDirectus(rawDay['chatSnap']),
  //           dateTime: DateTime.fromMillisecondsSinceEpoch(
  //             int.parse(rawDay['dateTime']),
  //           ),
  //         );

  //         // Используем дату как ключ для уникальности
  //         final dateKey = dayEntity.dateTime.toIso8601String().split('T')[0];
  //         if (!uniqueDays.containsKey(dateKey) ||
  //             (dayEntity.cycleId != null &&
  //                 uniqueDays[dateKey]?.cycleId == null)) {
  //           uniqueDays[dateKey] = dayEntity;
  //         }
  //       }
  //     }

  //     return uniqueDays.values.toList()
  //       ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  //   } catch (e) {
  //     log('Error fetching days with meal plans: $e');
  //     return [];
  //   }
  // }

  // Метод для повторных попыток
  Future<T?> retryOperation<T>(
    Future<T?> Function() operation,
    String operationName,
  ) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await operation();
        if (result != null) return result;

        await Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'whoop_retry',
            message: 'Retry attempt $attempt for $operationName',
            level: SentryLevel.info,
          ),
        );

        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } catch (e, stackTrace) {
        await Sentry.captureException(
          e,
          stackTrace: stackTrace,
          hint: Hint.withMap({
            'context': 'whoop_retry',
            'operation': operationName,
            'attempt': attempt + 1,
          }),
        );
      }
    }
    return null;
  }
}
