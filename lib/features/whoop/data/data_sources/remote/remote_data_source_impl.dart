import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:directus/directus.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/endpoints.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part './remote_data_source.dart';

final whoopRemote = getIt.get<WhoopRemoteDataSource>();

@Singleton(as: WhoopRemoteDataSource)
class WhoopRemoteDataSourceImpl implements WhoopRemoteDataSource {
  bool emptify = emptifyWhoopData;
  @override
  Future<BodyMeasurementsEntity> getBodyData() async {
    final rawBm =
        await _requestData(endpoint: WhoopEndpoints().bodyMeasurements);
    // log(rawBm.toString());
    return BodyMeasurementsEntity(
      height: rawBm!['height_meter'],
      weight: (rawBm['weight_kilogram'] as double).round(),
      maxHeartRate: rawBm['max_heart_rate'],
    );
  }

  @override
  Future<(List<CycleModel>, int)> getCycles() async {
    try {
      final data = await _requestData(endpoint: WhoopEndpoints().whoopCycles);

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
    final data = await _requestData(endpoint: WhoopEndpoints().workouts);

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
    final data = await _requestData(endpoint: WhoopEndpoints().recoveries);

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
    final rawSleeps = await _requestData(endpoint: WhoopEndpoints().sleeps);
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

  Future<Map<String, dynamic>?> _requestData({
    required String endpoint,
    bool? needsLimit,
  }) async {
    final uri = Uri.parse(endpoint);
    late http.Response response;

    if (needsLimit ?? false) {
      uri.replace(queryParameters: {'limit': '7'});
    }
    const maxAttempts = 3;
    int attempts = 0;
    // print(wTokenService.accessToken);
    while (attempts <= maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      final thisResponse = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${wTokenService.accessToken}',
        },
      );
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
  Future<void> updateDirectus({required DayEntity day}) async {
    await directus.updateOne(
      collection: usersCollection,
      itemId: userBloc.state.user.directusId,
      updateData: {
        'whoopData': {
          'weekTdeeAverage': day.weekTdeeAverage,
          'macros': day.macros.toMap(),
          'askTime': day.dateTime.millisecondsSinceEpoch,
          'lastTdee': day.healthMetrics.lastTdee,
        },
      },
    );
  }

  @override
  Future<DayEntity?> fetchDirectusData() async {
    final res = await directus.readOne(
      collection: usersCollection,
      id: userBloc.state.user.directusId,
    );
    int lastDayId = res['days'].last;
    final lastDayRes = await directus.readOne(
      collection: daysCollection,
      id: lastDayId.toString(),
    );

    if (res.isNotEmpty && lastDayRes.isNotEmpty) {
      final data = res['whoopData'];

      if (data != null && data.isNotEmpty) {
        final dayEntity = DayEntity(
          directusId: lastDayId,
          cycleId: lastDayRes['cycleId'] != null
              ? int.parse(lastDayRes['cycleId'])
              : null,
          weekTdeeAverage: data['weekTdeeAverage'],
          macros: MacrosBreakdown.fromMap(data['macros']),
          mealPlanEntity: lastDayRes['mealPlan'] != null
              ? MealPlanEntity.fromMap(lastDayRes['mealPlan'])
              : null,
          healthMetrics:
              HealthMetricsEntity.fromMap(lastDayRes['healthMetrics']),
          snap: ChatSnapshotEntity.fromDirectus(lastDayRes['chatSnap']),
          dateTime: DateTime.fromMillisecondsSinceEpoch(data['askTime']),
        );
        return dayEntity;
      } else {
        return null;
      }
    } else {
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

    final raw = await _requestData(
      endpoint: WhoopEndpoints().cycleById(cycleId: cycleId),
    );
    log(raw.toString());

    if (raw == null) return true;

    return raw['end'] != null && raw['score_state'] == 'SCORED';
  }

  @override
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId}) async {
    try {
      await directus.deleteOne(
        collection: daysCollection,
        id: whoopBloc.state.day.directusId.toString(),
      );
      return true;
    } on Exception catch (e) {
      log('Error: $e', name: 'Diconnect Whoop RDS');
      return false;
    }
  }

  @override
  Future<bool> doesChatNeedsRefreshment({required String userId}) async {
    final rawUser =
        await directus.readOne(collection: usersCollection, id: userId);
    final daysIds = List.from(rawUser['days']).cast<int>();
    if (daysIds.isEmpty) {
      return true;
    }
    final rawLast = await directus.readOne(
      collection: daysCollection,
      id: daysIds.last.toString(),
    );
    final dateOfLast =
        DateTime.fromMillisecondsSinceEpoch(int.parse(rawLast['dateTime']));
    return !dateOfLast.isSameDate(DateTime.now());
  }

  @override
  Future<List<DayEntity>> getDaysWithMealPlans({
    required List<int> daysIds,
  }) async {
    try {
      final List<DayEntity> days = [];
      final Map<String, DayEntity> uniqueDays =
          {}; // Используем Map для хранения уникальных дней по дате

      for (final id in daysIds) {
        final rawDay = await directus.readOne(
          collection: daysCollection,
          id: id.toString(),
        );

        if (rawDay.isNotEmpty) {
          final dayEntity = DayEntity(
            directusId: id,
            cycleId:
                rawDay['cycleId'] != null ? int.parse(rawDay['cycleId']) : null,
            weekTdeeAverage: rawDay['weekTdeeAverage'],
            macros: MacrosBreakdown.fromMap(rawDay['macros']),
            mealPlanEntity: rawDay['mealPlan'] != null
                ? MealPlanEntity.fromMap(rawDay['mealPlan'])
                : null,
            healthMetrics: HealthMetricsEntity.fromMap(rawDay['healthMetrics']),
            snap: ChatSnapshotEntity.fromDirectus(rawDay['chatSnap']),
            dateTime: DateTime.fromMillisecondsSinceEpoch(
              int.parse(rawDay['dateTime']),
            ),
          );

          // Используем дату как ключ для уникальности
          final dateKey = dayEntity.dateTime.toIso8601String().split('T')[0];
          if (!uniqueDays.containsKey(dateKey) ||
              (dayEntity.cycleId != null &&
                  uniqueDays[dateKey]?.cycleId == null)) {
            uniqueDays[dateKey] = dayEntity;
          }
        }
      }

      return uniqueDays.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      log('Error fetching days with meal plans: $e');
      return [];
    }
  }
}
