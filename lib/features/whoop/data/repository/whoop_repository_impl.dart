import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/services/user_service/user_service_exception_extensions.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';

final wRepo = getIt.get<WhoopRepository>();

@Singleton(as: WhoopRepository)
class WhoopRepositoryImpl implements WhoopRepository {
  WhoopRepositoryImpl({
    required this.remoteDataSource,
  });
  final WhoopRemoteDataSource remoteDataSource;

  final String authorizeUrl = 'https://api.prod.whoop.com/oauth/oauth2/auth';
  final String customUriScheme = 'com.rishai';
  final String redirectUri = 'com.rishai://redirect';
  final String clientId = Env.clientId;
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

    try {
      await getIt.get<UserServiceClient>().exchangeWhoopCode(
        userId: userBloc.state.user.directusId,
        code: code,
        redirectUri: redirectUri,
      );
      // [authenticateUser] Чистим старые локальные WHOOP токены после успешной миграции на backend flow.
      await prefsRepo.clearTokens();
      return const Right(null);
    } on UserServiceException catch (e, stackTrace) {
      log('Failed to exchange WHOOP code on backend: ${e.message}');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_access_token',
        extras: {
          'auth_code': code,
          'user_id': userBloc.state.user.directusId,
          'status_code': e.statusCode,
          'error_code': e.code,
        },
      );
      return const Left(WhoopFailedToReturnAccessToken());
    }
  }

  @override
  Future<Either<Failure, BodyMeasurementsEntity?>> getBodyData() async {
    try {
      final BodyMeasurementsEntity? body = await remoteDataSource.getBodyData();
      log('Body data from remote source: $body', name: 'WhoopRepo');
      if (body == null) {
        // Null after proxy retries usually means WHOOP auth failed on the backend.
        return const Left(WhoopFailedToReturnAccessToken());
      }
      return Right(body);
    } on UserServiceException catch (e, stackTrace) {
      log(
        'WHOOP body data auth error: ${e.statusCode} ${e.message}',
        name: 'WhoopRepo',
      );
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_body_data_auth',
        extras: {
          'status_code': e.statusCode,
          'error_code': e.code,
          'refresh_blocked': e.isWhoopTokenRefreshBlocked,
        },
      );
      if (e.requiresWhoopReconnect) {
        return const Left(WhoopFailedToReturnAccessToken());
      }
      return const Left(WhoopAuthenticationFailure());
    } catch (e, stackTrace) {
      log('ERROR WHILE FETCHING BODY DATA $e', name: 'WhoopRepo');
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
    try {
      log(
        '>>> [getData] Fetching current day from backend for user: ${params.userId}, forceRefresh=${params.forceRefresh}',
      );

      final day = await remoteDataSource.getCurrentDay(forceRefresh: params.forceRefresh);
      await _cacheDay(day);

      return Right(day);
    } on UserServiceException catch (e, stackTrace) {
      log('>>> [getData] Backend /days/current failed: ${e.statusCode} ${e.message}');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_current_day',
        extras: {
          'user_id': params.userId,
          'force_refresh': params.forceRefresh,
          'status_code': e.statusCode,
          'error_code': e.code,
        },
      );

      return Left(_mapCurrentDayFailure(e));
    } catch (e, stackTrace) {
      log('>>> [getData] ERROR WHILE FETCHING CURRENT DAY: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_get_current_day',
        extras: {
          'user_id': params.userId,
          'force_refresh': params.forceRefresh,
        },
      );
      return Left(FailedToGetUserData('$e'));
    }
  }

  Future<void> _cacheDay(DayEntity day) async {
    // Держим локальный день и чат-снэп синхронизированными с backend-ответом,
    // чтобы остальной UI и DayManager продолжали работать прозрачно.
    await hive.saveDay(data: day);
    await hive.saveChatSnapshot(day.snap, day.dateTime);
  }

  Failure _mapCurrentDayFailure(UserServiceException exception) {
    if (exception.requiresWhoopReconnect) {
      return const WhoopFailedToReturnAccessToken();
    }
    switch (exception.statusCode) {
      case 403:
        return const WhoopFailedToReturnAccessToken();
      case 503:
        return const WhoopNoDataFailure();
      case 400:
      case 401:
      case 404:
      case 502:
      default:
        return FailedToGetUserData(exception.message);
    }
  }

  @override
  Future<Either<Failure, void>> disconnectWhoop({
    required DisconnecWhoopParams params,
  }) async {
    try {
      // [disconnectWhoop] Пока WHOOP ещё подключён: current day → hard delete → disconnect.
      try {
        final deletedDayId = await dayManager.deleteCurrentDayBeforeWhoopDisconnect(
          userId: params.userId,
        );
        log(
          '[disconnectWhoop] Current day deleted: ${deletedDayId ?? 'none'}',
          name: 'WhoopRepository',
        );
      } on UserServiceException catch (e, stackTrace) {
        log(
          '[disconnectWhoop] Не удалось удалить current day (${e.statusCode}): ${e.message}',
          name: 'WhoopRepository',
        );
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_disconnect_delete_current_day',
          extras: {'user_id': params.userId, 'status_code': e.statusCode},
        );
        // Не блокируем отключение WHOOP из‑за сбоя удаления дня.
      } catch (e, stackTrace) {
        log(
          '[disconnectWhoop] Не удалось удалить current day: $e',
          name: 'WhoopRepository',
        );
        await WhoopErrorHandler.handleError(
          e,
          stackTrace,
          context: 'whoop_disconnect_delete_current_day',
          extras: {'user_id': params.userId},
        );
      }

      await remoteDataSource.clearWhoopUserDataOnDisconnect(
        userId: params.userId,
      );
      await prefsRepo.clearTokens();
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
