import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/config/feature_flags.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/generate_week_plan_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_filter_entity.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/domain/params/week_plan_params.dart';

part 'week_plan_bloc.freezed.dart';
part 'week_plan_event.dart';
part 'week_plan_state.dart';

final weekPlanBloc = getIt<WeekPlanBloc>();

@injectable
class WeekPlanBloc extends Bloc<WeekPlanEvent, WeekPlanState> {
  WeekPlanBloc(
    this._generateWeekPlanUsecase,
    this._userService,
  ) : super(
          const WeekPlanState(
            allWeekPlans: [],
            displayWeekPlans: [],
          ),
        ) {
    on<WeekPlanGenerate>(_onGenerate);
    on<WeekPlanReset>(_onReset);
    on<WeekPlanLoad>(_onLoad);
    on<WeekPlanClear>(_onClear);
    on<WeekPlanFilter>(_onFilter);
    on<WeekPlanClearFilter>(_onClearFilter);
  }

  final GenerateWeekPlanUsecaseV2 _generateWeekPlanUsecase;
  final UserServiceClient _userService;

  /// Сериализация параллельных [WeekPlanLoad] (как [_getDaysInFlight] в UserBloc).
  Future<void>? _loadInFlight;

  Future<void> _onGenerate(
    WeekPlanGenerate event,
    Emitter<WeekPlanState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Используем новую структуру API с GenerateWeekPlanUsecaseV2

    final prefs = userBloc.state.user.foodPreferences;
    final params = WeekPlanParams(
      dietary: prefs!.diets,
      cuisines: prefs.cuisines,
      restrictions: prefs.restrictions,
      calorieTarget: event.calorieTarget,
      macros: event.macros,
      hasTraining: event.hasTraining,
      hasSnack: event.hasSnack,
      servings: event.servings,
      startDate: event.startDate,
    );

    final result = await _generateWeekPlanUsecase(params);

    await result.fold((failure) {
      emit(state.copyWith(isLoading: false));
      RishSnackbar()
          .showSnackBar('Failed to generate week plan, please try again later');
    }, (week) async {
      print(
        'Generated ${week.plans.length} meal plans with dates ${week.startDate} - ${week.endDate}',
      );
      week = week.copyWith(
        fitnessGoal: userBloc.state.user.userGoal!.getGoalTypeName(),
        dietaryPreferences: userBloc.state.user.foodPreferences!.diets.first,
        cuisines: prefs.cuisines,
        mealsTypes: event.servings.map((e) {
          if (e.comment != null && e.comment!.isNotEmpty) {
            return '${e.comment!.capitalize()} ${e.type.name}';
          } else {
            return e.type.name.capitalize();
          }
        }).toList(),
      );
      List<WeekPlanEntity> newAllPlans = List.from(state.allWeekPlans)
        ..add(week);
      List<WeekPlanEntity> newDisplayPlans;
      if (state.filter != null) {
        newDisplayPlans = _applyFilter(newAllPlans, state.filter!);
      } else {
        newDisplayPlans = List.from(state.displayWeekPlans)..add(week);
      }

      emit(
        state.copyWith(
          allWeekPlans: newAllPlans,
          displayWeekPlans: newDisplayPlans,
          isLoading: false,
          hasLoaded: true,
        ),
      );
      await saveWeek(week);

      // Сразу кладём свежесгенерированный prep в кэш, чтобы он мгновенно
      // отрисовался при следующем входе (без ожидания GET /week-plans).
      try {
        await hive.replaceSavedWeekPlans(weeks: newAllPlans);
      } on Object catch (e) {
        _logger('Не удалось закэшировать сгенерированный prep: $e');
      }
    });
  }

  void _onReset(WeekPlanReset event, Emitter<WeekPlanState> emit) {
    emit(const WeekPlanState(allWeekPlans: [], displayWeekPlans: []));
    // Чистим кэш недельных планов (например, при смене пользователя).
    unawaited(hive.flushWeekPlans());
  }

  Future<void> _onLoad(WeekPlanLoad event, Emitter<WeekPlanState> emit) async {
    if (_loadInFlight != null) {
      _logger('WeekPlanLoad: уже идёт — ждём завершения');
      await _loadInFlight;
      return;
    }

    _loadInFlight = _onLoadImpl(event, emit);
    try {
      await _loadInFlight;
    } finally {
      _loadInFlight = null;
    }
  }

  /// Фоновая синхронизация списка preps с бэка по схеме
  /// **stale-while-revalidate**:
  ///
  ///   Фаза 1 (кэш) — мгновенно показываем сохранённые в Hive preps, чтобы при
  ///                  входе НЕ мелькало «There are no preps yet», пока идёт сеть.
  ///   Фаза 2 (сеть) — тянем актуальный список с backend и переписываем кэш.
  ///                  Если сеть упала — оставляем кэш, просто гасим [isSyncing].
  ///
  /// [isLoading] намеренно не трогаем: полноэкранный «I'm creating…» только
  /// при [WeekPlanGenerate]. Иначе любой [UpdateUserEvent] с weekPlanIds
  /// (WHOOP sync, food diary, pivot score…) случайно перекрывал уже готовые preps.
  Future<void> _onLoadImpl(
    WeekPlanLoad event,
    Emitter<WeekPlanState> emit,
  ) async {
    final filterPhase1 = state.filter;

    // ─────────────────────────────────────────────────────────────────────
    // Фаза 1 — кэш Hive (только если в памяти ещё пусто, иначе не мигаем).
    // ─────────────────────────────────────────────────────────────────────
    if (state.allWeekPlans.isEmpty) {
      try {
        final cached = await hive.retrieveSavedWeekPlans();
        if (cached.isNotEmpty) {
          final sortedCache = List<WeekPlanEntity>.from(cached)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          _logger('Фаза 1 (кэш): ${sortedCache.length} preps — показываем сразу');
          emit(
            state.copyWith(
              allWeekPlans: sortedCache,
              displayWeekPlans: filterPhase1 != null
                  ? _applyFilter(sortedCache, filterPhase1)
                  : sortedCache,
              isSyncing: true,
            ),
          );
        } else {
          _logger('Фаза 1 (кэш): пусто — показываем индикатор первой загрузки');
          emit(state.copyWith(isSyncing: true));
        }
      } on Object catch (e) {
        _logger('Фаза 1 (кэш) ошибка: $e');
        emit(state.copyWith(isSyncing: true));
      }
    } else {
      emit(state.copyWith(isSyncing: true));
    }

    // ─────────────────────────────────────────────────────────────────────
    // Фаза 2 — сеть. При ошибке remote == null → кэш не трогаем.
    // ─────────────────────────────────────────────────────────────────────
    List<WeekPlanEntity>? remote;
    try {
      remote = await _fetchSortedWeeksFromBackend(
        weekPlanIdHint: event.weekPlanIdHint,
      );
    } on Object catch (e) {
      _logger('Фаза 2 (сеть) недоступна: $e — оставляем кэш');
      remote = null;
    }

    if (remote != null) {
      final filter = state.filter;
      emit(
        state.copyWith(
          allWeekPlans: remote,
          displayWeekPlans: filter != null ? _applyFilter(remote, filter) : remote,
          isSyncing: false,
          hasLoaded: true,
        ),
      );

      // Переписываем кэш актуальным списком (replace = убираем устаревшие preps).
      try {
        await hive.replaceSavedWeekPlans(weeks: remote);
      } on Object catch (e) {
        _logger('Не удалось сохранить preps в кэш: $e');
      }
    } else {
      // Сеть упала: список из фазы 1 (кэш) уже в state — только гасим флаги.
      emit(state.copyWith(isSyncing: false, hasLoaded: true));
    }
  }

  /// **Источник истины:** `GET /week-plans` (User API, заголовки [pivot-identity-key] + [x-user-id]).
  /// Кэш Hive — лишь для мгновенного отображения (stale-while-revalidate).
  ///
  /// В отличие от старого [_syncAndLoadWeeks], этот метод **пробрасывает**
  /// ошибку наверх: вызывающий ([_onLoadImpl]) сам решает оставить кэш.
  ///
  /// [weekPlanIdHint] — id из GET /users: после пагинированного списка догружаем планы по id,
  /// если по [startDate] их ещё нет (гонка: профиль обновился раньше, чем список).
  Future<List<WeekPlanEntity>> _fetchSortedWeeksFromBackend({
    List<int>? weekPlanIdHint,
  }) async {
    final currentUserId = userBloc.state.user.directusId;
    _logger('=== СИНХРОНИЗАЦИЯ: GET /week-plans (User API) ===');

    if (currentUserId == '-1') {
      _logger('Пользователь не авторизован, пусто');
      return [];
    }

    final remoteWeeks = await _fetchAllWeekPlansFromUserApi(
      currentUserId,
      weekPlanIdHint: weekPlanIdHint,
    );
    _logger('User API: ${remoteWeeks.length} недель(и)');
    final sorted = List<WeekPlanEntity>.from(remoteWeeks)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return sorted;
  }

  /// Максимальный [limit] по контракту бэка (как [DayManager] для [GET /days]).
  static const int _kWeekPlansPageSize = 100;

  /// Все страницы списка, затем merge по [weekPlanIdHint] через [GET /week-plans/:id].
  Future<List<WeekPlanEntity>> _fetchAllWeekPlansFromUserApi(
    String currentUserId, {
    List<int>? weekPlanIdHint,
  }) async {
    final allMaps = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final raw = await _userService.getWeekPlans(
        userId: currentUserId,
        limit: _kWeekPlansPageSize,
        offset: offset,
      );
      final batch = UserServiceClient.weekPlanListFromResponse(raw);
      allMaps.addAll(batch);
      if (batch.length < _kWeekPlansPageSize) {
        break;
      }
      offset += _kWeekPlansPageSize;
    }

    final out = <WeekPlanEntity>[];
    final startDates = <int>{};

    for (final m in allMaps) {
      try {
        final w = WeekPlanEntity.fromMap(m);
        out.add(w);
        startDates.add(w.startDate.millisecondsSinceEpoch);
      } on Object catch (err) {
        _logger('Пропуск week plan (fromMap): $err; keys: ${m.keys}');
      }
    }

    if (weekPlanIdHint != null && weekPlanIdHint.isNotEmpty) {
      for (final id in weekPlanIdHint) {
        try {
          final raw = await _userService.getWeekPlanById(
            userId: currentUserId,
            id: id.toString(),
          );
          final m = UserServiceClient.weekPlanSingleFromResponse(raw);
          final ms = WeekPlanEntity.tryParseStartDateEpochMs(m);
          if (ms == null) {
            continue;
          }
          if (startDates.contains(ms)) {
            continue;
          }
          final w = WeekPlanEntity.fromMap(m);
          out.add(w);
          startDates.add(ms);
        } on Object catch (e) {
          _logger('weekPlanIdHint id=$id: $e');
        }
      }
    }

    return out;
  }

  Future<void> saveWeek(WeekPlanEntity week) async {
    // ✅ Отладочные логи для проверки userId
    final currentUserId = userBloc.state.user.directusId;
    _logger('=== СОХРАНЕНИЕ НЕДЕЛЬНОГО ПЛАНА ===');
    _logger('Текущий userId из userBloc: $currentUserId');
    _logger('userId из WeekPlanEntity: ${week.userId}');
    _logger('Пользователь авторизован: ${currentUserId != '-1'}');

    // Проверка принадлежности к текущему пользователю
    if (week.userId != currentUserId) {
      _logger(
        'WARNING: WeekPlan userId mismatch! Expected: $currentUserId, Got: ${week.userId}',
      );
    } else {
      _logger('✅ userId совпадает');
    }

    // При async weekly строка уже создана воркером на бэке; клиентский Directus убран.
    if (kUseAsyncWeeklyMealPlan) {
      _logger(
        'saveWeek: async weekly — план уже на сервере, только состояние bloc.',
      );
    } else {
      throw UnsupportedError(
        'kUseAsyncWeeklyMealPlan=false не поддерживается (нет клиентской записи коллекций).',
      );
    }

    _logger('Недельный план: сохранение state завершено');
  }

  /// Список недель с бэка (офлайн без кэша — пусто, если [GET /week-plans] не удался).
  Future<List<WeekPlanEntity>> getWeeks() async {
    final currentUserId = userBloc.state.user.directusId;
    _logger('=== getWeeks: GET /week-plans ===');
    if (currentUserId == '-1') return [];

    try {
      final fromApi = await _fetchAllWeekPlansFromUserApi(currentUserId);
      fromApi.sort((a, b) => a.startDate.compareTo(b.startDate));
      return fromApi;
    } on Object catch (e) {
      _logger('getWeeks: $e');
      return [];
    }
  }

  void _logger(String message) {
    log(message, name: 'WeekPlanBloc');
  }

  Future<void> _onClear(
    WeekPlanClear event,
    Emitter<WeekPlanState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      emit(
        const WeekPlanState(
          allWeekPlans: [],
          displayWeekPlans: [],
        ),
      );

      // Полный сброс (logout) — вычищаем и кэш Hive.
      await hive.flushWeekPlans();
    } catch (e) {
      _logger('Error clearing week plans state: $e');
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  List<WeekPlanEntity> _applyFilter(
    List<WeekPlanEntity> plans,
    WeekFilterEntity filter,
  ) {
    return plans.where((plan) {
      bool dateMatch = true;
      bool goalMatch = true;
      bool dietMatch = true;

      final filterStart = filter.startDate;
      final filterEnd = filter.endDate;
      final planStart = plan.startDate;
      final planEnd = plan.endDate;

      // Check for date range overlap
      if (filterStart != null && filterEnd != null) {
        // Overlap condition: plan starts on/before filter ends AND plan ends on/after filter starts
        // Using isSameDate extension to ignore time component
        dateMatch = (planStart.isBefore(filterEnd) ||
                planStart.isSameDate(filterEnd)) &&
            (planEnd.isAfter(filterStart) || planEnd.isSameDate(filterStart));
      } else if (filterStart != null) {
        // Overlap if plan ends on or after filter start date
        dateMatch =
            planEnd.isAfter(filterStart) || planEnd.isSameDate(filterStart);
      } else if (filterEnd != null) {
        // Overlap if plan starts on or before filter end date
        dateMatch =
            planStart.isBefore(filterEnd) || planStart.isSameDate(filterEnd);
      }

      if (filter.dietaryPreferences.isNotEmpty) {
        dietMatch = filter.dietaryPreferences
            .any((pref) => plan.dietaryPreferences.contains(pref));
      }

      if (filter.cuisines.isNotEmpty) {
        dietMatch =
            filter.cuisines.any((cuisine) => plan.cuisines.contains(cuisine));
      }

      if (filter.mealsTypes.isNotEmpty) {
        dietMatch = filter.mealsTypes
            .any((mealType) => plan.mealsTypes.contains(mealType));
      }

      if (filter.fitnessGoal.isNotEmpty) {
        goalMatch = filter.fitnessGoal.any((goal) {
          // Используем маппинг для правильного сравнения старых и новых названий
          final normalizedPlanGoal =
              WeekFilterEntity.mapOldFitnessGoalToNew(plan.fitnessGoal);
          final normalizedFilterGoal =
              WeekFilterEntity.mapOldFitnessGoalToNew(goal);
          return normalizedPlanGoal == normalizedFilterGoal;
        });
      }

      return dateMatch && goalMatch && dietMatch;
    }).toList();
  }

  Future<void> _onFilter(
    WeekPlanFilter event,
    Emitter<WeekPlanState> emit,
  ) async {
    final filteredPlans = _applyFilter(state.allWeekPlans, event.filter);
    emit(
      state.copyWith(
        filter: event.filter,
        displayWeekPlans: filteredPlans,
      ),
    );
  }

  Future<void> _onClearFilter(
    WeekPlanClearFilter event,
    Emitter<WeekPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        filter: null,
        displayWeekPlans: state.allWeekPlans,
      ),
    );
  }

  bool get isThereActivePlan {
    if (state.allWeekPlans.isEmpty) {
      return false;
    }
    final last = state.allWeekPlans.last;
    final now = DateTime.now();
    final startDateMinusThreeDays =
        last.startDate.subtract(const Duration(days: 3));
    return (now.isAfter(startDateMinusThreeDays) ||
            now.isSameDate(startDateMinusThreeDays)) &&
        (last.endDate.isAfter(now) || last.endDate.isSameDate(now));
  }
}
