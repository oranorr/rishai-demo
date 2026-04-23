import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part './remote_data_source.dart';

final whoopRemote = getIt.get<WhoopRemoteDataSource>();

@Singleton(as: WhoopRemoteDataSource)
class WhoopRemoteDataSourceImpl implements WhoopRemoteDataSource {
  WhoopRemoteDataSourceImpl(this._userServiceClient);
  final UserServiceClient _userServiceClient;

  final int maxRetries = 3;
  final Duration retryDelay = const Duration(seconds: 2);

  String get _currentUserId => userBloc.state.user.directusId;

  @override
  Future<DayEntity> getCurrentDay({bool forceRefresh = false}) async {
    final rawDay = await _userServiceClient.getCurrentDay(
      userId: _currentUserId,
      forceRefresh: forceRefresh,
    );
    return DayEntity.fromMap(rawDay);
  }

  @override
  Future<bool> isWhoopConnected() async {
    try {
      final status = await _userServiceClient.getWhoopStatus(
        userId: _currentUserId,
      );
      return status['connected'] == true;
    } on UserServiceException catch (e) {
      log(
        'Failed to get WHOOP status: ${e.message}',
        name: 'WhoopRemoteStatus',
      );
      return false;
    } catch (e) {
      log('Unexpected WHOOP status error: $e', name: 'WhoopRemoteStatus');
      return false;
    }
  }

  @override
  Future<BodyMeasurementsEntity?> getBodyData() async {
    try {
      log('Making request to get body measurements...', name: 'WhoopBodyData');
      final rawBm = await _makeRequest(
        endpointName: '/whoop/body',
        request: () => _userServiceClient.getWhoopBody(userId: _currentUserId),
      );

      if (rawBm == null) {
        await WhoopErrorHandler.handleError(
          'Body measurements response is null',
          StackTrace.current,
          context: 'whoop_body_data_null',
          extras: {
            'directus_user_id': userBloc.state.user.directusId,
            'endpoint': '/whoop/body',
          },
        );
        return null;
      }

      if (!rawBm.containsKey('height_meter') ||
          !rawBm.containsKey('weight_kilogram') ||
          !rawBm.containsKey('max_heart_rate')) {
        await WhoopErrorHandler.handleError(
          'Body measurements data is incomplete',
          StackTrace.current,
          context: 'whoop_body_data_incomplete',
          extras: {
            'directus_user_id': userBloc.state.user.directusId,
            'record_keys': rawBm.keys.toList(),
          },
        );
        return null;
      }

      final height = (rawBm['height_meter'] as num?)?.toDouble();
      final weightKg = (rawBm['weight_kilogram'] as num?)?.toDouble();
      final maxHeartRateRaw = rawBm['max_heart_rate'];
      final maxHeartRate = maxHeartRateRaw is int
          ? maxHeartRateRaw
          : maxHeartRateRaw is num
              ? maxHeartRateRaw.toInt()
              : int.tryParse(maxHeartRateRaw?.toString() ?? '');

      if (height == null || weightKg == null || maxHeartRate == null) {
        await WhoopErrorHandler.handleError(
          'Body measurements data has invalid types',
          StackTrace.current,
          context: 'whoop_body_data_invalid_types',
          extras: {
            'directus_user_id': userBloc.state.user.directusId,
            'height_type': rawBm['height_meter']?.runtimeType.toString(),
            'weight_type': rawBm['weight_kilogram']?.runtimeType.toString(),
            'max_hr_type': rawBm['max_heart_rate']?.runtimeType.toString(),
          },
        );
        return null;
      }

      return BodyMeasurementsEntity(
        height: height,
        weight: weightKg.round(),
        maxHeartRate: maxHeartRate,
      );
    } catch (e, stackTrace) {
      log('Error getting body measurements: $e', name: 'WhoopBodyData');
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'context': 'whoop_get_body_data',
          'endpoint': '/whoop/body',
        }),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> _makeRequest({
    required String endpointName,
    required Future<Map<String, dynamic>> Function() request,
  }) async {
    for (int attempts = 0; attempts <= maxRetries; attempts++) {
      try {
        return await request();
      } on UserServiceException catch (e, stackTrace) {
        log(
          'WHOOP proxy request failed: ${e.statusCode} - ${e.message}',
          name: 'WhoopRemoteDataSource',
        );
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_api_status',
          extras: {
            'directus_user_id': _currentUserId,
            'endpoint': endpointName,
            'attempts': attempts + 1,
            'status_code': e.statusCode,
            'error_code': e.code,
          },
        );
        if (attempts == maxRetries) {
          return null;
        }
        await Future.delayed(retryDelay);
      } catch (e, stackTrace) {
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_api_status',
          extras: {
            'directus_user_id': _currentUserId,
            'endpoint': endpointName,
            'attempts': attempts + 1,
          },
        );
        if (attempts == maxRetries) {
          return null;
        }
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  @override
  Future<bool> pingLastCycle({required int? cycleId}) async {
    if (cycleId == null) return true;

    final raw = await _makeRequest(
      endpointName: '/whoop/cycle/$cycleId',
      request: () => _userServiceClient.getWhoopCycleById(
        userId: _currentUserId,
        cycleId: cycleId,
      ),
    );

    if (raw == null) return true;

    return raw['end'] != null && raw['score_state'] == 'SCORED';
  }

  @override
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId}) async {
    try {
      await _userServiceClient.disconnectWhoop(userId: userId);
      return true;
    } on Exception catch (e) {
      log('Error: $e', name: 'Disconnect Whoop RDS');
      return false;
    }
  }
}
