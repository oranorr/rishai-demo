import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/endpoints.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';

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
      log('Failed to get cycle data: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  @override
  Future<void> updateDirectus({required WhoopDataEntity data}) async {
    await directus.updateOne(
      collection: usersCollection,
      itemId: userBloc.state.user.directusId,
      updateData: {
        'whoopData': data.toMap(),
      },
    );
  }

  @override
  Future<WhoopDataEntity?> fetchDirectusData() async {
    final res = await directus.readOne(
      collection: usersCollection,
      id: userBloc.state.user.directusId,
    );
    if (res.isNotEmpty) {
      final data = res['whoopData'];
      if (data != null && data.isNotEmpty) {
        final whoopData = WhoopDataEntity.fromMap(data);
        return whoopData;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Future<bool> pingCurrentCycle({required int cycleId}) async {
    await wTokenService.initService();
    final raw = await _requestData(
      endpoint: WhoopEndpoints().cycleById(cycleId: cycleId),
    );
    return raw!['end'] != null;
  }

  @override
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId}) async {
    try {
      final res =
          await directus.readOne(collection: usersCollection, id: userId);
      await directus.updateOne(
        collection: daysCollection,
        itemId: res['days'].last.toString(),
        updateData: {'mealPlan': null},
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

    //if same date — we don't need to refresh chat
    return !dateOfLast.isSameDate(DateTime.now());
  }
}
