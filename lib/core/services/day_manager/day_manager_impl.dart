import 'dart:async';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart'
    show whoopRemote;
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

final dayManager = getIt.get<DayManager>();

@Singleton(as: DayManager)
class DayManagerImpl implements DayManager {
  // Старый метод fetchDays удалён - используем только getUserDays

  @override
  Future<DayEntity> createDay({required DayEntity day}) async {
    try {
      _logger(
        'Начало создания/обновления дня: ${day.dateTime}, cycleId: ${day.cycleId}',
      );

      // Проверяем существование дня по cycleId
      final existingDay = await _findExistingDayByCycleId(
        userId: userBloc.state.user.directusId,
        cycleId: day.cycleId,
      );

      DayEntity resultDay;

      if (existingDay != null) {
        // Обновляем существующий день
        _logger('Обновление существующего дня: ${existingDay.directusId}');
        final raw = await directus.updateOne(
          collection: daysCollection,
          itemId: existingDay.directusId.toString(),
          updateData: day.toDirectus(userId: userBloc.state.user.directusId),
        );
        resultDay = DayEntity.fromMap(raw);
        await hive.saveDay(data: resultDay);
        _logger('День успешно обновлен');
      } else {
        // Создаем новый день
        _logger('Создание нового дня');
        final dayData = day.toDirectus(userId: userBloc.state.user.directusId);
        final createdDay = await directus.createOne(
          collection: daysCollection,
          data: dayData,
        );
        resultDay = DayEntity.fromMap(createdDay);
        _logger('Новый день создан с id: ${resultDay.directusId}');

        // Сохраняем созданный день в Hive
        await hive.saveDay(data: resultDay);
      }

      // Обновляем состояние в UserBloc
      userBloc.add(UserUpdateDay(day: resultDay));

      _logger(
        'Успешно создан/обновлен день с датой: ${resultDay.dateTime}, cycleId: ${resultDay.cycleId} и directusId: ${resultDay.directusId}',
      );
      return resultDay;
    } on Exception catch (e, stackTrace) {
      _logger('Ошибка при создании/обновлении дня: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_create_day',
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

  /// Поиск существующего дня по cycleId
  Future<DayEntity?> _findExistingDayByCycleId({
    required String userId,
    required int? cycleId,
  }) async {
    if (cycleId == null) return null;

    try {
      final days = await directus.readMany(
        collection: daysCollection,
        filters: Filters({
          'userId': F.eq(userId),
          'cycleId': F.eq(cycleId.toString()),
        }),
        query: Query(limit: 1),
      );

      return days.isNotEmpty ? DayEntity.fromMap(days.first) : null;
    } catch (e) {
      _logger('Ошибка поиска дня по cycleId: $e');
      return null;
    }
  }

  // Старый метод getDaysIds удалён - используем getUserDays напрямую

  // === НОВЫЕ МЕТОДЫ (упрощенная архитектура) ===

  @override
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  }) async {
    try {
      _logger('Получение всех дней пользователя: $userId');

      // Сначала пытаемся получить из кэша
      final cachedDays = await hive.retrieveSavedDays();
      if (cachedDays.isNotEmpty) {
        _logger('Найдено ${cachedDays.length} дней в кэше');

        // Проверяем, нужно ли обновить кэш
        final remoteDays = await directus.readMany(
          collection: daysCollection,
          filters: Filters({'userId': F.eq(userId)}),
          query: Query(
            fields: ['id'],
            sort: ['dateTime'],
          ),
        );

        final remoteIds = remoteDays.map((day) => day['id'] as int).toSet();
        final cachedIds = cachedDays.map((day) => day.directusId).toSet();

        // Если кэш актуален, возвращаем его
        if (remoteIds.difference(cachedIds).isEmpty &&
            cachedIds.difference(remoteIds).isEmpty) {
          final sortedDays = cachedDays
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          _logger('Кэш актуален, возвращаем ${sortedDays.length} дней');
          return Right(sortedDays);
        }
      }

      // Получаем полные данные из Directus
      final days = await directus.readMany(
        collection: daysCollection,
        filters: Filters({'userId': F.eq(userId)}),
        query: Query(
          sort: ['dateTime'],
          limit: 1000,
        ),
      );

      _logger('Получено ${days.length} дней из Directus');

      // Конвертируем в сущности и сохраняем в кэш
      final dayEntities = <DayEntity>[];
      for (final dayData in days) {
        final dayEntity = DayEntity.fromMap(dayData);
        dayEntities.add(dayEntity);
        await hive.saveDay(data: dayEntity);
      }

      _logger('Успешно обработано ${dayEntities.length} дней');
      return Right(dayEntities);
    } catch (e, stackTrace) {
      _logger('Ошибка при получении дней пользователя: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_user_days',
        extras: {'user_id': userId},
      );
      return const Left(FailedToGetUserData('Failed to get user days'));
    }
  }

  @override
  Future<DayEntity?> getLastUserDay({
    required String userId,
  }) async {
    try {
      _logger('Получение последнего дня пользователя: $userId');

      final days = await directus.readMany(
        collection: daysCollection,
        filters: Filters({'userId': F.eq(userId)}),
        query: Query(
          sort: ['-dateTime'], // Сортировка по убыванию даты
          limit: 1,
        ),
      );

      if (days.isEmpty) {
        _logger('У пользователя $userId нет дней');
        return null;
      }

      final lastDay = DayEntity.fromMap(days.first);
      _logger('Последний день пользователя: ${lastDay.dateTime}');
      return lastDay;
    } catch (e, stackTrace) {
      _logger('Ошибка при получении последнего дня: $e');
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
      _logger(
        'Создание/обновление дня: ${day.dateTime}, cycleId: ${day.cycleId}',
      );

      // Используем тот же userId что и в оригинальном методе
      final userId = userBloc.state.user.directusId;

      // Сначала ищем существующий день по cycleId
      final existingDay = await _findExistingDayByCycleId(
        userId: userId,
        cycleId: day.cycleId,
      );

      DayEntity resultDay;

      if (existingDay != null) {
        // Обновляем существующий день
        _logger('Обновление существующего дня: ${existingDay.directusId}');
        final raw = await directus.updateOne(
          collection: daysCollection,
          itemId: existingDay.directusId.toString(),
          updateData: day.toDirectus(userId: userId),
        );
        resultDay = DayEntity.fromMap(raw);
        _logger('День успешно обновлен');
      } else {
        // Создаем новый день
        _logger('Создание нового дня');
        final createdDay = await directus.createOne(
          collection: daysCollection,
          data: day.toDirectus(userId: userId),
        );
        resultDay = DayEntity.fromMap(createdDay);
        _logger('Новый день создан с id: ${resultDay.directusId}');

        // 🔄 Проверяем recomp только при создании НОВОГО дня
        try {
          await userBloc.checkRecompForNewDay();
          _logger('Recomp check completed for new day in createOrUpdateDay');
        } catch (e) {
          _logger('Recomp check failed for new day in createOrUpdateDay: $e');
          // Не прерываем создание дня из-за ошибки проверки recomp
        }
      }

      // Сохраняем в кэш
      await hive.saveDay(data: resultDay);

      // Обновляем состояние в UserBloc
      userBloc.add(UserUpdateDay(day: resultDay));

      _logger(
        'Успешно создан/обновлен день с датой: ${resultDay.dateTime}',
      );
      return resultDay;
    } on Exception catch (e, stackTrace) {
      _logger('Ошибка при создании/обновлении дня: $e');
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
  Future<DayEntity?> getDayByCycleId({
    required String userId,
    required int cycleId,
  }) async {
    try {
      _logger('Поиск дня пользователя $userId по cycleId: $cycleId');

      final days = await directus.readMany(
        collection: daysCollection,
        filters: Filters({
          'userId': F.eq(userId),
          'cycleId': F.eq(cycleId.toString()),
        }),
        query: Query(limit: 1),
      );

      if (days.isEmpty) {
        _logger('День не найден для пользователя $userId с cycleId: $cycleId');
        return null;
      }

      final dayEntity = DayEntity.fromMap(days.first);
      _logger('Найден день с cycleId: ${dayEntity.cycleId}');
      return dayEntity;
    } catch (e, stackTrace) {
      _logger('Ошибка при поиске дня по cycleId: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_day_by_cycle_id',
        extras: {
          'user_id': userId,
          'cycle_id': cycleId,
        },
      );
      return null;
    }
  }

  @override
  Future<DayEntity?> getActiveDay({
    required String userId,
  }) async {
    try {
      _logger('Получение активного дня для пользователя: $userId');

      // Используем унифицированный метод вместо дублирующей логики
      final result = await getLastDayWithCycleStatus(
        userId: userId,
      );

      // Возвращаем день только если цикл активен
      if (result != null && result.isCycleActive) {
        _logger('Найден активный день с cycleId: ${result.cycleId}');
        return result.day;
      } else {
        _logger(
          result == null
              ? 'Последний день не найден'
              : 'Цикл ${result.cycleId} завершен, активного дня нет',
        );
        return null;
      }
    } catch (e, stackTrace) {
      _logger('Ошибка при получении активного дня: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_active_day',
        extras: {'user_id': userId},
      );
      return null;
    }
  }

  @override
  Future<LastDayResult?> getLastDayWithCycleStatus({
    required String userId,
    bool checkCycleStatus = true,
  }) async {
    try {
      _logger(
        'Получение последнего дня с проверкой статуса цикла: $userId, проверка=$checkCycleStatus',
      );

      // Получаем дни пользователя и находим день с самым большим ID
      final days = await directus.readMany(
        collection: daysCollection,
        filters: Filters({'userId': F.eq(userId)}),
        query: Query(
          fields: [
            'id',
            'dateTime',
            'cycleId',
          ], // Получаем только нужные поля для оптимизации
          sort: [
            '-id',
          ], // Сортируем по убыванию ID (самый большой ID = последний день)
          limit: 1, // Берем только самый последний
        ),
      );

      if (days.isEmpty) {
        _logger('Дни не найдены для пользователя $userId');
        return null;
      }

      // Получаем информацию о дне с самым большим ID
      final lastDayRaw = days.first; // Уже отсортировано по убыванию ID
      final lastDayId = lastDayRaw['id'] as int;
      final lastDayDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastDayRaw['dateTime']),
      );
      final cycleId = lastDayRaw['cycleId'] != null
          ? int.parse(lastDayRaw['cycleId'])
          : null;

      _logger(
        'Найден последний день по ID: directusId=$lastDayId, дата=$lastDayDate, cycleId=$cycleId',
      );

      // Получаем полную информацию о дне
      final fullDayData = await directus.readOne(
        collection: daysCollection,
        id: lastDayId.toString(),
      );

      final lastDay = DayEntity.fromMap(fullDayData);

      // Если проверка статуса цикла не требуется, возвращаем день как активный
      if (!checkCycleStatus || cycleId == null) {
        _logger(
          'Возвращаем день без проверки статуса: cycleId=$cycleId',
        );
        return LastDayResult.active(lastDay);
      }

      // Проверяем статус цикла через внешний сервис
      try {
        final isCycleEnded = await whoopRemote.pingLastCycle(
          cycleId: cycleId,
        );

        if (isCycleEnded) {
          _logger(
            'Цикл $cycleId завершен (день ID=$lastDayId, дата: ${lastDay.dateTime})',
          );
          return LastDayResult.ended(lastDay);
        } else {
          _logger(
            'Цикл $cycleId активен (день ID=$lastDayId, дата: ${lastDay.dateTime})',
          );
          return LastDayResult.active(lastDay);
        }
      } catch (e) {
        _logger(
          'Ошибка при проверке статуса цикла: $e. Считаем день активным',
        );
        // В случае ошибки считаем день активным
        return LastDayResult.active(lastDay);
      }
    } catch (e, stackTrace) {
      _logger('Ошибка при получении последнего дня с проверкой статуса: $e');
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
      _logger('Инициализация дней пользователя при входе: $userId');

      // Создаем комплитер для ожидания загрузки дней
      final completer = Completer<bool>();

      // Переменные для отслеживания статуса загрузки
      bool loadingHasStarted = false;
      bool loadingInProgress = false;
      int daysLoadedSoFar = 0;

      _logger('Загрузка дней для пользователя: $userId');

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

      _logger(
        'Используем адаптивный таймаут $adaptiveTimeout секунд для $totalDaysToLoad дней',
      );

      // Подписываемся на состояние UserBloc
      late StreamSubscription subscription;
      subscription = userBloc.stream.listen((userState) {
        _logger(
          'Изменение состояния UserBloc: ${userState.status}, дней: ${userState.days.length}',
        );

        // Проверяем начало загрузки
        if (userState.status == Status.loading) {
          loadingHasStarted = true;
          loadingInProgress = true;
          _logger('Начата загрузка дней');
        }

        // Отслеживаем прогресс загрузки
        if (loadingInProgress && userState.days.length > daysLoadedSoFar) {
          daysLoadedSoFar = userState.days.length;
          _logger('Прогресс загрузки: $daysLoadedSoFar/$totalDaysToLoad дней');
        }

        // Успешное завершение загрузки
        if (userState.status == Status.success &&
            loadingHasStarted &&
            !completer.isCompleted) {
          loadingInProgress = false;
          _logger(
            'Загрузка дней завершена успешно (${userState.days.length} дней)',
          );

          // Проверяем, что в списке есть хотя бы один день
          if (userState.days.isNotEmpty) {
            completer.complete(true);
          } else {
            _logger('Предупреждение: Успешное состояние но пустой список дней');
            completer.complete(false);
          }
        }

        // Завершение с ошибкой
        if (userState.status == Status.error &&
            loadingHasStarted &&
            !completer.isCompleted) {
          loadingInProgress = false;
          _logger('Загрузка дней завершена с ошибкой');
          completer.complete(false);
        }
      });

      // Запускаем загрузку дней
      _logger('Запуск загрузки дней...');
      userBloc.add(UserGetDays(newDay: newDay));

      // Ждем загрузки дней с таймаутом
      bool loadingResult = false;
      bool didTimeout = false;

      try {
        // Создаем Future для таймаута
        final timeoutFuture =
            Future.delayed(Duration(seconds: adaptiveTimeout)).then((_) {
          if (!completer.isCompleted) {
            _logger(
              'Таймаут ожидания загрузки дней после $adaptiveTimeout секунд',
            );

            // Проверяем, идет ли загрузка все еще
            if (loadingInProgress && daysLoadedSoFar > 0) {
              // Если загрузка идет и уже загружено какое-то количество дней,
              // считаем это частичным успехом и не прерываем загрузку
              _logger(
                'Загрузка продолжается, загружено $daysLoadedSoFar дней, продолжаем без ошибки',
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

        _logger(
          'Результат загрузки дней: $loadingResult, таймаут: $didTimeout, загружено дней: $daysLoadedSoFar',
        );
      } catch (e) {
        _logger('Ошибка ожидания дней: $e');
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
        _logger('Частичный успех: загружено $daysLoadedSoFar дней до таймаута');
        return InitializationResult.partialSuccess(daysLoadedSoFar);
      } else {
        _logger('Все дни загружены успешно');
        return InitializationResult.success(daysLoadedSoFar);
      }
    } catch (e, stackTrace) {
      _logger('Ошибка при инициализации дней пользователя: $e');
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
      _logger('Очистка локального хранилища дней при логауте');
      await hive.flushSavedDays();
      _logger('Локальное хранилище дней успешно очищено');
    } catch (e, stackTrace) {
      _logger('Ошибка при очистке локального хранилища дней: $e');
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
