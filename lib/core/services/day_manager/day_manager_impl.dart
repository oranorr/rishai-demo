import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
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

  /// Максимальный [limit] по контракту backend для [GET /days].
  static const int _kDaysPageSize = 100;

  /// Защита от бесконечного цикла при баге пагинации на backend.
  static const int _kMaxDaysPages = 100;

  final UserServiceClient _userServiceClient;

  /// Один активный sync на userId — защита от параллельных [UserGetDays].
  Future<Either<Failure, List<DayEntity>>>? _syncInFlight;
  String? _syncInFlightUserId;

  /// Парсинг списка day maps без записи в Hive.
  Future<List<DayEntity>> _parseDayMaps(
    List<Map<String, dynamic>> dayMaps,
  ) async {
    final parsedDays = <DayEntity>[];

    for (final map in dayMaps) {
      try {
        parsedDays.add(DayEntity.fromMap(map));
      } on Object catch (e) {
        _logger('[getUserDays] Пропуск дня (fromMap): $e');
      }
    }

    parsedDays.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return parsedDays;
  }

  void _logDaysWithoutCycleId(List<DayEntity> days, {required String context}) {
    final withoutCycle = days.where((d) => d.cycleId == null).length;
    if (withoutCycle == 0) {
      return;
    }
    _logger(
      '[getUserDays] ℹ️ $context: $withoutCycle/${days.length} дней без cycleId '
      '(legacy / до WHOOP / seed — на backend cycleId опционален)',
    );
  }

  /// Запись deduped-списка в Hive одним replace (убирает старые дубликаты).
  Future<void> _persistDaysToHive(List<DayEntity> days) async {
    final deduped = _dedupeDaysByDirectusId(days);
    await hive.replaceSavedDays(days: deduped);
  }

  /// Убираем дубликаты Hive (merge по cycleId раздувает box).
  List<DayEntity> _dedupeDaysByDirectusId(List<DayEntity> days) {
    final byId = <int, DayEntity>{};
    final withoutId = <DayEntity>[];

    for (final day in days) {
      if (day.directusId > 0) {
        byId[day.directusId] = day;
      } else {
        withoutId.add(day);
      }
    }

    final result = [...byId.values, ...withoutId]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return result;
  }

  /// Все страницы [GET /days?limit&offset], начиная с [startOffset].
  Future<List<Map<String, dynamic>>> _fetchDayMapsFromBackend({
    required String userId,
    int startOffset = 0,
  }) async {
    final allMaps = <Map<String, dynamic>>[];
    var offset = startOffset;
    var page = 0;

    while (page < _kMaxDaysPages) {
      final response = await _userServiceClient.getDays(
        userId: userId,
        limit: _kDaysPageSize,
        offset: offset,
      );
      final batch = _extractDayList(response);
      allMaps.addAll(batch);

      _logger(
        '[getUserDays] Страница ${page + 1}: offset=$offset, batch=${batch.length}, total=${allMaps.length}',
      );

      if (batch.length < _kDaysPageSize) {
        break;
      }

      offset += _kDaysPageSize;
      page++;
    }

    if (page >= _kMaxDaysPages) {
      _logger(
        '[getUserDays] ⚠️ Достигнут лимит $_kMaxDaysPages страниц, загружено ${allMaps.length} дней',
      );
    }

    return allMaps;
  }

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

  /// Все страницы [GET /days?limit&offset], как [_fetchAllWeekPlansFromUserApi]
  /// в [WeekPlanBloc].
  Future<List<Map<String, dynamic>>> _fetchAllDayMapsFromBackend({
    required String userId,
  }) {
    return _fetchDayMapsFromBackend(userId: userId);
  }

  /// [syncUserDaysFromBackend] Умный sync без meta.total (при limit=1 backend
  /// отдаёт total=1, а не общее число записей).
  Future<Either<Failure, List<DayEntity>>> _syncUserDaysFromBackend({
    required String userId,
    required List<DayEntity> cachedDays,
  }) async {
    final storedTotal = prefsRepo.getDaysServerTotal(userId);

    _logger(
      '[getUserDays] sync: storedTotal=$storedTotal, cache=${cachedDays.length}',
    );

    // 1. Всегда обновляем current day (1 запрос).
    DayEntity? currentDay;
    try {
      final currentResponse =
          await _userServiceClient.getCurrentDay(userId: userId);
      currentDay = DayEntity.fromMap(_extractDayMap(currentResponse));
      await hive.saveDay(data: currentDay);
    } on UserServiceException catch (e) {
      if (e.statusCode != 404) {
        rethrow;
      }
      _logger('[getUserDays] GET /days/current → 404, пропуск');
    }

    List<DayEntity> mergeWithCurrent(List<DayEntity> days) {
      if (currentDay == null) {
        return days;
      }
      final result = List<DayEntity>.from(days);
      final idx = result.indexWhere(
        (d) =>
            d.directusId == currentDay!.directusId ||
            (d.dateTime.year == currentDay!.dateTime.year &&
                d.dateTime.month == currentDay!.dateTime.month &&
                d.dateTime.day == currentDay!.dateTime.day),
      );
      if (idx == -1) {
        result.add(currentDay!);
      } else {
        final existing = result[idx];
        result[idx] = existing.copyWith(
          healthMetrics: currentDay!.healthMetrics,
          macros: currentDay!.macros,
          weekTdeeAverage: currentDay!.weekTdeeAverage,
          welnessEntity: existing.welnessEntity ?? currentDay!.welnessEntity,
          mealPlanEntity: currentDay!.mealPlanEntity ?? existing.mealPlanEntity,
        );
      }
      result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return result;
    }

    // 2. Кэш актуален → tail-probe (offset = cache.length), без полной пагинации.
    // Сравниваем ==, не >=: иначе битый storedTotal=1 (старый probe) даст ложный skip.
    if (storedTotal != null &&
        cachedDays.isNotEmpty &&
        cachedDays.length == storedTotal) {
      final tailProbeResponse = await _userServiceClient.getDays(
        userId: userId,
        limit: 1,
        offset: cachedDays.length,
      );
      final tailProbeBatch = _extractDayList(tailProbeResponse);

      if (tailProbeBatch.isEmpty) {
        _logger(
          '[getUserDays] ✅ Кэш актуален ($storedTotal дней) — полная загрузка пропущена',
        );
        return Right(mergeWithCurrent(cachedDays));
      }

      _logger(
        '[getUserDays] Incremental sync: cache=${cachedDays.length}, tail probe +1',
      );
      final tailMaps = await _fetchDayMapsFromBackend(
        userId: userId,
        startOffset: cachedDays.length,
      );
      final tailDays = await _parseDayMaps(tailMaps);
      final merged = _dedupeDaysByDirectusId([...cachedDays, ...tailDays]);
      await _persistDaysToHive(merged);
      await prefsRepo.setDaysServerTotal(userId, merged.length);
      return Right(mergeWithCurrent(merged));
    }

    // 3. Полная загрузка: первый вход, нет storedTotal, или рассинхрон.
    _logger('[getUserDays] Полная загрузка с сервера');
    final dayMaps = await _fetchAllDayMapsFromBackend(userId: userId);
    final parsedDays = await _parseDayMaps(dayMaps);
    final deduped = _dedupeDaysByDirectusId(parsedDays);
    _logDaysWithoutCycleId(deduped, context: 'full sync');
    await hive.replaceSavedDays(days: deduped);
    await prefsRepo.setDaysServerTotal(userId, deduped.length);
    return Right(mergeWithCurrent(deduped));
  }

  Future<Either<Failure, List<DayEntity>>> _getUserDaysImpl({
    required String userId,
  }) async {
    final rawCached = await hive.retrieveSavedDays();
    final cachedDays = _dedupeDaysByDirectusId(rawCached);

    try {
      return await _syncUserDaysFromBackend(
        userId: userId,
        cachedDays: cachedDays,
      );
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
          '[getUserDays] Fallback на кэш: ${cachedDays.length} дней',
        );
        return Right(cachedDays);
      }

      return const Left(FailedToGetUserData('Failed to get user days'));
    }
  }

  @override
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  }) async {
    // Дедуп параллельных вызовов (HomePage bootstrap + initializeUserDaysOnLogin).
    if (_syncInFlight != null && _syncInFlightUserId == userId) {
      _logger('[getUserDays] Sync уже идёт — ждём тот же Future');
      return _syncInFlight!;
    }

    final future = _getUserDaysImpl(userId: userId);
    _syncInFlight = future;
    _syncInFlightUserId = userId;

    try {
      final result = await future;
      result.fold(
        (_) {},
        (days) => _logger('[getUserDays] Sync завершён: ${days.length} дней'),
      );
      return result;
    } finally {
      _syncInFlight = null;
      _syncInFlightUserId = null;
    }
  }

  @override
  Future<DayEntity?> getLastUserDay({
    required String userId,
  }) async {
    try {
      _logger(
        '[getLastUserDay] Загрузка последнего дня через GET /days/current',
      );

      final response = await _userServiceClient.getCurrentDay(userId: userId);
      final lastDay = DayEntity.fromMap(_extractDayMap(response));
      _logger('[getLastUserDay] День получен: ${lastDay.dateTime}');
      return lastDay;
    } on UserServiceException catch (e, stackTrace) {
      if (e.statusCode == 404) {
        _logger('[getLastUserDay] У пользователя $userId нет current day (404)');
        return null;
      }

      _logger('[getLastUserDay] Ошибка UserService: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_get_last_user_day',
        extras: {'user_id': userId},
      );
      return null;
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

      // ─────────────────────────────────────────────────────────────────────
      // Оптимизация: таймаут считаем по размеру Hive-кэша, а не по сетевому
      // запросу. Это быстро (чтение диска) и не порождает double-fetch.
      // ─────────────────────────────────────────────────────────────────────
      final rawCached = await hive.retrieveSavedDays();
      final uniqueCached = _dedupeDaysByDirectusId(rawCached);
      const baseTimeout = 15;
      // ~5 секунд на каждые 50 дней в кэше — но теперь ждём только фазу 1
      // (кэш → emit), которая занимает <100 мс, так что таймаут лишь страховка.
      final adaptiveTimeout =
          baseTimeout + ((uniqueCached.length / 50).ceil() * 5).clamp(0, 30);

      _logger(
        '[initializeUserDaysOnLogin] кэш=${uniqueCached.length} уникальных '
        '(${rawCached.length} raw в Hive), таймаут=${adaptiveTimeout}с',
      );

      final completer = Completer<bool>();

      // Ждём первого появления дней в UserBloc (фаза 1 = кэш готов).
      // Полная сетевая загрузка (фаза 2) продолжается в фоне — нас она
      // здесь не блокирует.
      late StreamSubscription subscription;
      subscription = userBloc.stream.listen((userState) {
        _logger(
          '[initializeUserDaysOnLogin] UserBloc: ${userState.status}, days=${userState.days.length}',
        );

        // Как только дни появились (фаза 1 готова) — считаем успехом.
        if (userState.days.isNotEmpty && !completer.isCompleted) {
          _logger(
            '[initializeUserDaysOnLogin] Дни появились (${userState.days.length}) — готово к навигации',
          );
          completer.complete(true);
        }

        if (userState.status == Status.error && !completer.isCompleted) {
          _logger('[initializeUserDaysOnLogin] UserBloc вернул error');
          completer.complete(false);
        }
      });

      _logger('[initializeUserDaysOnLogin] Запуск UserGetDays');
      userBloc.add(UserGetDays(newDay: newDay));

      bool loadingResult = false;

      try {
        loadingResult = await completer.future.timeout(
          Duration(seconds: adaptiveTimeout),
          onTimeout: () {
            _logger('[initializeUserDaysOnLogin] Таймаут — days=${userBloc.state.days.length}');
            // Если хоть что-то есть в state — считаем частичным успехом.
            return userBloc.state.days.isNotEmpty;
          },
        );
      } on Object catch (e) {
        _logger('[initializeUserDaysOnLogin] Ошибка ожидания: $e');
        loadingResult = userBloc.state.days.isNotEmpty;
      } finally {
        unawaited(subscription.cancel());
      }

      _logger(
        '[initializeUserDaysOnLogin] Результат: $loadingResult, дней=${userBloc.state.days.length}',
      );

      if (!loadingResult) {
        return InitializationResult.failure(
          'Failed to load user data. Please check your connection.',
        );
      }

      return InitializationResult.success(userBloc.state.days.length);
    } on Object catch (e, stackTrace) {
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
      await prefsRepo.clearDaysSyncMeta();
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

  /// [deleteCurrentDayBeforeWhoopDisconnect] Снимаем текущий WHOOP-день до POST /whoop/disconnect.
  @override
  Future<int?> deleteCurrentDayBeforeWhoopDisconnect({
    required String userId,
  }) async {
    try {
      _logger(
        '[deleteCurrentDayBeforeWhoopDisconnect] GET /days/current userId=$userId',
      );

      final response = await _userServiceClient.getCurrentDay(userId: userId);
      final day = DayEntity.fromMap(_extractDayMap(response));
      final dayId = day.directusId;

      if (dayId <= 0) {
        _logger(
          '[deleteCurrentDayBeforeWhoopDisconnect] Пропуск: невалидный id=$dayId',
        );
        return null;
      }

      try {
        await _userServiceClient.deleteDay(userId: userId, dayId: dayId);
        _logger(
          '[deleteCurrentDayBeforeWhoopDisconnect] DELETE /days/$dayId — ok',
        );
      } on UserServiceException catch (e) {
        if (e.statusCode == 404) {
          _logger(
            '[deleteCurrentDayBeforeWhoopDisconnect] День $dayId уже удалён (404)',
          );
        } else {
          rethrow;
        }
      }

      userBloc.add(UserRemoveDayByDirectusId(directusId: dayId));
      return dayId;
    } on UserServiceException catch (e, stackTrace) {
      if (e.statusCode == 404) {
        _logger(
          '[deleteCurrentDayBeforeWhoopDisconnect] Нет current day (404), пропуск',
        );
        return null;
      }

      _logger('[deleteCurrentDayBeforeWhoopDisconnect] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_delete_current_before_whoop_disconnect',
        extras: {'user_id': userId},
      );
      rethrow;
    } catch (e, stackTrace) {
      _logger('[deleteCurrentDayBeforeWhoopDisconnect] Ошибка: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_delete_current_before_whoop_disconnect',
        extras: {'user_id': userId},
      );
      rethrow;
    }
  }
}

void _logger(String message) {
  log(message, name: 'DayManager');
}
