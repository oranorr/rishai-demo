import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

final dayManager = getIt.get<DayManager>();

@Singleton(as: DayManager)
class DayManagerImpl implements DayManager {
  DayManagerImpl({
    required UserServiceClient userServiceClient,
  }) : _userServiceClient = userServiceClient;

  final UserServiceClient _userServiceClient;

  Map<String, dynamic> _extractDayMap(Map<String, dynamic> response) {
    final dynamic maybeWrappedData = response['data'];
    if (maybeWrappedData is Map<String, dynamic>) {
      return maybeWrappedData;
    }
    return response;
  }

  List<Map<String, dynamic>> _extractDayList(Map<String, dynamic> response) {
    final dynamic rawData = response['data'];
    if (rawData is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawData
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  }) async {
    final cachedDays = await hive.retrieveSavedDays();

    try {
      _logger('[getUserDays] Загрузка days из backend, userId=$userId');

      // Берем максимум, разрешенный контрактом backend.
      final response = await _userServiceClient.getDays(
        userId: userId,
        limit: 100,
        offset: 0,
      );
      final dayList = _extractDayList(response);

      final parsedDays = dayList.map(DayEntity.fromMap).toList();
      for (final day in parsedDays) {
        await hive.saveDay(data: day);
      }

      _logger('[getUserDays] Получено ${parsedDays.length} дней из backend');
      return Right(parsedDays);
    } catch (e, stackTrace) {
      _logger('[getUserDays] Ошибка backend: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_user_days',
        extras: {'user_id': userId},
      );

      if (cachedDays.isNotEmpty) {
        _logger(
          '[getUserDays] Используем fallback на кэш: ${cachedDays.length} дней',
        );
        return Right(cachedDays);
      }

      return const Left(FailedToGetUserData('Failed to get user days'));
    }
  }

  @override
  Future<DayEntity?> getLastUserDay({
    required String userId,
  }) async {
    try {
      _logger('[getLastUserDay] Загрузка последнего дня через /days?limit=1');

      final response = await _userServiceClient.getDays(
        userId: userId,
        limit: 1,
        offset: 0,
      );
      final dayList = _extractDayList(response);

      if (dayList.isEmpty) {
        _logger('[getLastUserDay] У пользователя $userId нет дней');
        return null;
      }

      final lastDay = DayEntity.fromMap(dayList.first);
      _logger('[getLastUserDay] День получен: ${lastDay.dateTime}');
      return lastDay;
    } catch (e, stackTrace) {
      _logger('[getLastUserDay] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_last_user_day',
        extras: {'user_id': userId},
      );
      return null;
    }
  }

  @override
  Future<DayEntity> createOrUpdateDay({
    required DayEntity day,
  }) async {
    try {
      _logger('[createOrUpdateDay] PATCH /days/current');

      final userId = userBloc.state.user.directusId;
      final payload = <String, dynamic>{
        // Передаем только поддержанные backend поля для day patch.
        'mealPlan': day.mealPlanEntity?.toMap(),
        'chatSnap': day.snap.toDirectus(),
        'welnessEntity': day.welnessEntity?.toMap(),
      };

      final response = await _userServiceClient.patchDaysCurrent(
        userId: userId,
        payload: payload,
      );
      final parsedDay = DayEntity.fromMap(_extractDayMap(response));
      await hive.saveDay(data: parsedDay);

      userBloc.add(UserUpdateDay(day: parsedDay));
      _logger('[createOrUpdateDay] Успешно, dayId=${parsedDay.directusId}');
      return parsedDay;
    } on Exception catch (e, stackTrace) {
      _logger('[createOrUpdateDay] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_create_or_update_day',
        extras: {
          'user_id': userBloc.state.user.directusId,
          'day_id': day.directusId,
          'date_time': day.dateTime.toString(),
          'cycle_id': day.cycleId,
        },
      );
      rethrow;
    }
  }

  @override
  Future<LastDayResult?> getLastDayWithCycleStatus({
    required String userId,
    bool checkCycleStatus = true,
  }) async {
    try {
      final response = await _userServiceClient.getCurrentDay(userId: userId);
      final day = DayEntity.fromMap(_extractDayMap(response));

      // Контракт backend: /days/current уже возвращает "актуальный" день.
      // Поэтому здесь всегда помечаем его как active.
      return LastDayResult.active(day);
    } on UserServiceException catch (e, stackTrace) {
      if (e.statusCode == 404) {
        _logger(
          '[getLastDayWithCycleStatus] Нет current day для пользователя $userId',
        );
        return null;
      }

      _logger('[getLastDayWithCycleStatus] Ошибка UserService: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_last_day_with_cycle_status',
        extras: {
          'user_id': userId,
          'check_cycle_status': checkCycleStatus,
        },
      );
      return null;
    } catch (e, stackTrace) {
      _logger('[getLastDayWithCycleStatus] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_last_day_with_cycle_status',
        extras: {
          'user_id': userId,
          'check_cycle_status': checkCycleStatus,
        },
      );
      return null;
    }
  }

  @override
  Future<InitializationResult> initializeUserDaysOnLogin({
    required String userId,
    required DayEntity newDay,
  }) async {
    try {
      _logger('[initializeUserDaysOnLogin] Инициализация дней пользователя');

      // Создаем комплитер для ожидания загрузки дней
      final completer = Completer<bool>();

      // Переменные для отслеживания статуса загрузки
      bool loadingHasStarted = false;
      bool loadingInProgress = false;
      int daysLoadedSoFar = 0;

      _logger('[initializeUserDaysOnLogin] Загрузка days пользователя');

      // Получаем количество дней пользователя для адаптивного таймаута
      final userDaysResult = await getUserDays(userId: userId);
      int totalDaysToLoad = userDaysResult.fold(
        (failure) => 0, // В случае ошибки используем базовый таймаут
        (days) => days.length,
      );

      // Вычисляем адаптивное время ожидания в зависимости от количества дней
      // Базовое время 20 секунд + дополнительное время на каждые 50 дней
      const baseTimeout = 20;
      final adaptiveTimeout =
          baseTimeout + ((totalDaysToLoad / 50).ceil() * 10);

      _logger('[initializeUserDaysOnLogin] Таймаут: $adaptiveTimeout сек');

      // Подписываемся на состояние UserBloc
      late StreamSubscription subscription;
      subscription = userBloc.stream.listen((userState) {
          _logger('[initializeUserDaysOnLogin] UserBloc: ${userState.status}');

        // Проверяем начало загрузки
        if (userState.status == Status.loading) {
          loadingHasStarted = true;
          loadingInProgress = true;
          _logger('[initializeUserDaysOnLogin] Начата загрузка');
        }

        // Отслеживаем прогресс загрузки
        if (loadingInProgress && userState.days.length > daysLoadedSoFar) {
          daysLoadedSoFar = userState.days.length;
          _logger('[initializeUserDaysOnLogin] Прогресс: $daysLoadedSoFar');
        }

        // Успешное завершение загрузки
        if (userState.status == Status.success &&
            loadingHasStarted &&
            !completer.isCompleted) {
          loadingInProgress = false;
          _logger('[initializeUserDaysOnLogin] Загрузка завершена успешно');

          // Проверяем, что в списке есть хотя бы один день
          if (userState.days.isNotEmpty) {
            completer.complete(true);
          } else {
            _logger(
              '[initializeUserDaysOnLogin] success статус, но пустой список',
            );
            completer.complete(false);
          }
        }

        // Завершение с ошибкой
        if (userState.status == Status.error &&
            loadingHasStarted &&
            !completer.isCompleted) {
          loadingInProgress = false;
          _logger('[initializeUserDaysOnLogin] Загрузка завершена с ошибкой');
          completer.complete(false);
        }
      });

      // Запускаем загрузку дней
      _logger('[initializeUserDaysOnLogin] Запуск загрузки');
      userBloc.add(UserGetDays(newDay: newDay));

      // Ждем загрузки дней с таймаутом
      bool loadingResult = false;
      bool didTimeout = false;

      try {
        // Создаем Future для таймаута
        final timeoutFuture =
            Future.delayed(Duration(seconds: adaptiveTimeout)).then((_) {
          if (!completer.isCompleted) {
            _logger('[initializeUserDaysOnLogin] Сработал таймаут ожидания');

            // Проверяем, идет ли загрузка все еще
            if (loadingInProgress && daysLoadedSoFar > 0) {
              // Если загрузка идет и уже загружено какое-то количество дней,
              // считаем это частичным успехом и не прерываем загрузку
              _logger(
                '[initializeUserDaysOnLogin] Есть прогресс, считаем partial success',
              );
              didTimeout = true;
              return true; // Считаем частичный успех
            } else {
              // Если нет прогресса, завершаем с ошибкой
              didTimeout = true;
              completer.complete(false);
              return false;
            }
          }
          return true;
        });

        // Ждем результата от completer
        loadingResult = await completer.future;

        // Отменяем таймаут, если возможно
        unawaited(timeoutFuture);

        _logger('[initializeUserDaysOnLogin] Результат: $loadingResult');
      } catch (e) {
        _logger('[initializeUserDaysOnLogin] Ошибка ожидания: $e');
        loadingResult = false;
      } finally {
        // Отписываемся от стрима
        unawaited(subscription.cancel());
      }

      // Обработка результата загрузки
      if (!loadingResult && didTimeout && daysLoadedSoFar == 0) {
        // Реальная ошибка таймаута - ничего не загрузилось
        return InitializationResult.failure(
          'Loading time exceeded. Possible connection issues.',
        );
      } else if (!loadingResult && !didTimeout) {
        // Другая ошибка загрузки
        return InitializationResult.failure(
          'An error occurred while loading data. Please check your connection.',
        );
      } else if (didTimeout && daysLoadedSoFar > 0) {
        // Частичная загрузка - успешно загрузилась часть данных
        _logger(
          '[initializeUserDaysOnLogin] Частичный успех: $daysLoadedSoFar дней',
        );
        return InitializationResult.partialSuccess(daysLoadedSoFar);
      } else {
        _logger('[initializeUserDaysOnLogin] Все дни загружены');
        return InitializationResult.success(daysLoadedSoFar);
      }
    } catch (e, stackTrace) {
      _logger('[initializeUserDaysOnLogin] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_initialize_user_days_on_login',
        extras: {
          'user_id': userId,
          'new_day_cycle_id': newDay.cycleId,
        },
      );
      return InitializationResult.failure('Failed to initialize user days');
    }
  }

  @override
  Future<void> clearUserDays() async {
    try {
      _logger('[clearUserDays] Очистка локального хранилища дней');
      await hive.flushSavedDays();
      _logger('[clearUserDays] Хранилище очищено');
    } catch (e, stackTrace) {
      _logger('[clearUserDays] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_clear_user_days',
      );
      rethrow;
    }
  }
}

void _logger(String message) {
  log(message, name: 'DayManager');
}
