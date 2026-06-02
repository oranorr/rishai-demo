import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/accounts_whitelist/accounts_whitelist_service.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/data/models/user_model.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/update_user_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'user_event.dart';

final userBloc = getIt.get<UserBloc>();
// int daysPerPage = kDebugMode ? 3 : 5;

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(
    this.updateUserUsecase,
    this.getUserDaysUsecase,
    this.accountsWhiteListService,
    this.userServiceClient,
  ) : super(
          UserMainState(
            status: Status.initial,
            user: UserEntity.unauthorized(),
            days: [],
          ),
        ) {
    on<UpdateUserEvent>(_updateUser);
    on<CheckForSavedUser>(_checkForSavedUser);
    on<CreateUserOnLogin>(_createUserOnLogin);
    on<UserDeleteAccount>(_deleteAccount);
    on<UserManageDay>(_manageDay);
    on<UserGetDays>(_getDays); // Используем новую архитектуру
    on<UserUpdateDay>(_updateDay);
    on<UserRemoveDayByDirectusId>(_removeDayByDirectusId);
    on<UserAddHistoryDays>(_addHistoryDays);
  }

  final UpdateUserUsecase updateUserUsecase;
  final GetUserDaysUsecase getUserDaysUsecase;
  final AccountsWhiteListService accountsWhiteListService;
  final UserServiceClient userServiceClient;

  /// Защита от параллельных [UserGetDays] (HomePage + DayManager).
  Future<void>? _getDaysInFlight;

  /// Убираем дубликаты Hive перед показом (box раздувается из-за cycleId merge).
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

    return [...byId.values, ...withoutId]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Сравнение [weekPlanIds] для решения, нужно ли писать Hive после getUser.
  static bool _sameWeekPlanIdLists(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  FutureOr<void> _updateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    void completeSync(bool success) {
      final completion = event.completion;
      if (completion != null && !completion.isCompleted) {
        completion.complete(success);
      }
    }

    UserEntity user = event.user;
    // До emit — для решения, нужен ли повторный GET /week-plans.
    final previousWeekPlanIds = state.user.weekPlanIds;
    log('user.userGoal: ${user.userGoal}', name: 'UserBloc');

    if (user.adaptyId == null) {
      user = user.copyWith(
        adaptyId: adapty.generateAdaptyId(directusId: user.directusId),
      );
    }

    try {
      log('Обновление пользователя: ${user.directusId}', name: 'UserBloc');

      // [DEBUG] Логируем Pivot Life Score при обновлении
      if (user.pivotLifeScore != null) {
        log(
          '📊 Обновление Pivot Life Score: ${user.pivotLifeScore!.score.toStringAsFixed(2)}%',
          name: 'UserBloc',
        );
      }

      // [FIX] Всегда обновляем локальное состояние сразу
      // Убрали промежуточный emit с UserEntity.unauthorized() чтобы избежать race condition
      // когда другие части кода читают состояние между emit'ами
      log(
        '[UserBloc] 🔄 Emit: обновляем состояние с directusId=${user.directusId}, UserBloc instance=${hashCode}',
        name: 'UserBloc',
      );
      emit(state.copyWith(user: user));
      log(
        '[UserBloc] ✅ State обновлен: directusId=${state.user.directusId}, email=${state.user.email}, UserBloc instance=${hashCode}',
        name: 'UserBloc',
      );
      log('state: ${state.user.userGoal}', name: 'UserBloc');
      // Пытаемся синхронизировать с backend в фоновом режиме
      final res = await updateUserUsecase.call(user);
      res.fold((l) {
        log('Ошибка синхронизации с backend: ${l.message}', name: 'UserBloc');
        // Не показываем snackbar для ошибок сети - пользователь может не знать о проблеме
        // Данные уже сохранены локально и будут синхронизированы позже
        completeSync(false);
      }, (r) {
        log('Пользователь успешно синхронизирован с backend', name: 'UserBloc');
        completeSync(true);
        // Профиль User Service с [weekPlanIds] может обновиться раньше списка
        // week-plans — догружаем только если id реально изменились (новый prep),
        // а не на каждый UpdateUser (pivot score, WHOOP body data и т.д.).
        if (user.weekPlanIds.isNotEmpty &&
            !_sameWeekPlanIdLists(previousWeekPlanIds, user.weekPlanIds)) {
          log(
            'weekPlanIds изменились $previousWeekPlanIds -> ${user.weekPlanIds}, WeekPlanLoad',
            name: 'UserBloc',
          );
          weekPlanBloc.add(
            WeekPlanLoad(weekPlanIdHint: List<int>.from(user.weekPlanIds)),
          );
        }
      });
    } on Exception catch (e) {
      log('Ошибка обновления пользователя: $e', name: 'UserBloc');
      // Локальное состояние уже обновлено, просто логируем ошибку
      completeSync(false);
    }
  }

  FutureOr<void> _checkForSavedUser(
    CheckForSavedUser event,
    Emitter<UserState> emit,
  ) async {
    try {
      log('Проверка сохраненного пользователя', name: 'UserBloc');
      final user = await hive.retrieveSavedUser();
      final watchedOnboard = prefsRepo.checkForWatchedOnboard();
      if (user != null && user.directusId != '-1') {
        log(
          'Найден сохраненный пользователь: ${user.directusId}',
          name: 'UserBloc',
        );

        // Обновляем пользователя (дни будут загружены при необходимости)
        emit(state.copyWith(user: user));

        // [FIX] Дожидаемся полного завершения identify и восстановления подписки
        try {
          await adapty.identify(adaptyId: user.adaptyId!);
          log(
            'Adapty identify завершен. Статус подписки: ${adapty.isActive}',
            name: 'UserBloc',
          );
        } catch (e) {
          log('Ошибка при identify, но продолжаем: $e', name: 'UserBloc');
          // Даже если identify упал, пытаемся восстановить покупки
          try {
            final restoreResult = await adapty.restorePurchases();
            log(
              'Результат восстановления покупок: $restoreResult',
              name: 'UserBloc',
            );
          } catch (restoreError) {
            log(
              'Ошибка при восстановлении покупок: $restoreError',
              name: 'UserBloc',
            );
          }
        }

        // Проверяем белый список аккаунтов для автоматической активации подписки
        await _checkWhiteListAndActivateSubscription(user.email);

        // Обновляем состояние после завершения всех операций с Adapty
        emit(state.copyWith(user: user));

        // [weekPlanIds] в Hive часто пусты/устарели; User Service отдаёт актуальные
        // id планов — передаём в [WeekPlanLoad] как [weekPlanIdHint], иначе гонка:
        // таска читает [userBloc.state] с устаревшим [6] вместо свежих [8] с API.
        List<int>? weekPlanIdHint;
        try {
          final raw = await userServiceClient.getUser(user.directusId);
          final fromApi = UserModel.fromMap(raw).toEntity();
          if (fromApi.weekPlanIds.isNotEmpty) {
            weekPlanIdHint = List<int>.from(fromApi.weekPlanIds);
            if (user.weekPlanIds.isEmpty ||
                !_sameWeekPlanIdLists(user.weekPlanIds, fromApi.weekPlanIds)) {
              final merged = user.copyWith(weekPlanIds: fromApi.weekPlanIds);
              await hive.saveUser(user: merged);
              emit(state.copyWith(user: merged));
            }
            log(
              'Профиль: weekPlanIds с бэка -> $weekPlanIdHint',
              name: 'UserBloc',
            );
          }
        } on Object catch (e) {
          log('getUser при старте (weekPlanIds): $e', name: 'UserBloc');
        }

        // Теперь запускаем другие блоки, когда статус подписки уже определен
        weekPlanBloc.add(WeekPlanLoad(weekPlanIdHint: weekPlanIdHint));
        whoopBloc.add(const InitWhoopOnLogin());
        log(
          'Пользователь загружен из кэша. Финальный статус подписки: ${adapty.isActive}',
          name: 'UserBloc',
        );
      } else {
        log('Сохраненный пользователь не найден', name: 'UserBloc');
        appNavigationService.go(
          path: !watchedOnboard ? AppRoutes.onboard.path : AppRoutes.login.path,
        );
      }
    } on Exception catch (e) {
      log(
        'Ошибка при проверке сохраненного пользователя: $e',
        name: 'UserBloc',
      );
    }
  }

  FutureOr<void> _createUserOnLogin(
    CreateUserOnLogin event,
    Emitter<UserState> emit,
  ) async {
    await hive.saveUser(user: event.user);

    // Если пользователь не авторизован (логаут), очищаем список дней
    if (event.user.directusId == '-1') {
      emit(state.copyWith(user: event.user, days: []));
    } else {
      emit(state.copyWith(user: event.user));
    }

    // Если флаг установлен, создаем исторические дни СИНХРОННО
    if (event.shouldCreateHistoryDays) {
      log(
        'Начинаем создание 200 дней истории для нового пользователя',
        name: 'UserBloc',
      );

      try {
        // Вызываем метод создания истории напрямую, дожидаемся завершения
        await _createHistoryDaysSync(event.user);

        log(
          'Завершено создание 200 дней истории для нового пользователя',
          name: 'UserBloc',
        );
      } catch (e) {
        log(
          'Ошибка при создании истории дней: $e. Продолжаем регистрацию без истории.',
          name: 'UserBloc',
        );
        // Не прерываем процесс регистрации, если создание истории не удалось
      }
    }
  }

  FutureOr<void> _deleteAccount(
    UserDeleteAccount event,
    Emitter<UserState> emit,
  ) async {
    try {
      await userServiceClient.deleteUser(state.user.directusId);
    } catch (e) {
      log('Ошибка при удалении аккаунта: $e', name: 'UserBloc');
      // Продолжаем с logout даже при ошибке — локальные данные должны быть очищены
    }
    loginBloc.add(LogoutEvent());
  }

  FutureOr<void> _manageDay(
    UserManageDay event,
    Emitter<UserState> emit,
  ) async {
    final day = event.day;

    await dayManager.createOrUpdateDay(day: day);

    // // Проверяем, действительно ли изменился день
    // final existingDay = state.days.firstWhere(
    //   (d) => d.dateTime.isSameDate(day.dateTime),
    //   orElse: () => DayEntity.empty(requestsLeft: 0),
    // );

    // if (existingDay == day) {
    //   log('No changes detected in day, skipping update');
    //   return;
    // }

    // final data = day.toDirectus(userId: state.user.directusId);

    // await manageDayUsecase.call(
    //   ManageDayParams(
    //     userId: state.user.directusId,
    //     dayMap: data,
    //     incomingDay: event.day,
    //   ),
    // );

    // // Обновляем список дней только если день действительно изменился
    // add(UserGetDays(newDay: day));
  }

  FutureOr<void> _getDays(UserGetDays event, Emitter<UserState> emit) async {
    if (_getDaysInFlight != null) {
      log('[_getDays] Уже идёт — ждём завершения', name: 'UserBloc');
      await _getDaysInFlight;
      return;
    }

    _getDaysInFlight = _getDaysImpl(event, emit);
    try {
      await _getDaysInFlight;
    } finally {
      _getDaysInFlight = null;
    }
  }

  Future<void> _getDaysImpl(UserGetDays event, Emitter<UserState> emit) async {
    log(
      '[_getDays] Начинаем загрузку дней',
      name: 'UserBloc',
    );

    final DayEntity currentDay = event.newDay;

    // ─────────────────────────────────────────────────────────────────────
    // Фаза 1 — Stale-While-Revalidate (мгновенный отклик):
    //
    // Читаем Hive до любого сетевого запроса и сразу показываем пользователю
    // то, что уже есть на телефоне. Если кэш пустой (первый вход) —
    // показываем хотя бы сегодняшний день (currentDay), чтобы не было
    // чёрного экрана пока история грузится в фоне.
    // ─────────────────────────────────────────────────────────────────────
    final cachedDays = _dedupeDaysByDirectusId(await hive.retrieveSavedDays());

    final initialList = cachedDays.isNotEmpty ? cachedDays : <DayEntity>[];
    final initialDays = _mergeCurrentDay(days: initialList, currentDay: currentDay);

    log(
      '[_getDays] Фаза 1 (кэш): ${initialDays.length} дней — emit loading',
      name: 'UserBloc',
    );
    emit(state.copyWith(status: Status.loading, days: initialDays));

    // ─────────────────────────────────────────────────────────────────────
    // Фаза 2 — Умный sync (пропуск полной загрузки если кэш актуален).
    // ─────────────────────────────────────────────────────────────────────
    log(
      '[_getDays] Фаза 2 (сеть): getUserDaysUsecase',
      name: 'UserBloc',
    );
    final res = await getUserDaysUsecase
        .call(GetUserDaysParams(userId: state.user.directusId));

    await res.fold((l) async {
      log(
        '[_getDays] Ошибка сети: ${l.message} — оставляем кэш (${state.days.length} дней)',
        name: 'UserBloc',
      );
      // Сеть недоступна — кэш уже в state.days из фазы 1, просто меняем статус.
      emit(state.copyWith(status: Status.success));
    }, (List<DayEntity> r) async {
      log(
        '[_getDays] Фаза 2: sync вернул ${r.length} дней',
        name: 'UserBloc',
      );

      final daysList = _mergeCurrentDay(
        days: List<DayEntity>.from(r),
        currentDay: currentDay,
      );
      daysList.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      log(
        '[_getDays] Итого ${daysList.length} дней, статус -> success',
        name: 'UserBloc',
      );
      emit(state.copyWith(status: Status.success, days: daysList));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  /// Вставляет / обновляет [currentDay] в [days], сохраняя [welnessEntity]
  /// из уже существующей записи (Directus-источник правды).
  ///
  /// - Если день с той же датой уже есть — мёрджим, не затираем wellness-данные.
  /// - Если дня нет — добавляем в конец.
  // ─────────────────────────────────────────────────────────────────────────
  List<DayEntity> _mergeCurrentDay({
    required List<DayEntity> days,
    required DayEntity currentDay,
  }) {
    final result = List<DayEntity>.from(days);
    final existingIndex = result.indexWhere(
      (d) => d.dateTime.isSameDate(currentDay.dateTime),
    );

    if (existingIndex == -1) {
      log('[_mergeCurrentDay] Добавляем сегодняшний день в список', name: 'UserBloc');
      result.add(currentDay);
      return result;
    }

    final existing = result[existingIndex];

    log(
      '[_mergeCurrentDay] existingDay.welnessEntity: ${existing.welnessEntity != null ? "есть (${existing.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
      name: 'UserBloc',
    );
    log(
      '[_mergeCurrentDay] currentDay.welnessEntity: ${currentDay.welnessEntity != null ? "есть (${currentDay.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
      name: 'UserBloc',
    );

    // КРИТИЧЕСКИ ВАЖНО: welnessEntity берём из existingDay (Directus),
    // чтобы не потерять дневник питания при вторичном входе.
    final finalWelnessEntity =
        existing.welnessEntity ?? currentDay.welnessEntity;

    log(
      '[_mergeCurrentDay] Финальный welnessEntity: ${finalWelnessEntity != null ? "есть (${finalWelnessEntity.consumedMeals.length} блюд)" : "нет"}',
      name: 'UserBloc',
    );

    // Если currentDay пришёл «пустым» (инициализация без WHOOP-данных) —
    // не затираем нулями сохранённые метрики из базы.
    final isCurrentDayEmpty =
        currentDay.macros.kcal == 0 && currentDay.weekTdeeAverage == 0;

    if (isCurrentDayEmpty) {
      log(
        '[_mergeCurrentDay] ⚠️ currentDay пустой — оставляем метрики из базы',
        name: 'UserBloc',
      );
    }

    result[existingIndex] = existing.copyWith(
      healthMetrics: isCurrentDayEmpty
          ? existing.healthMetrics
          : currentDay.healthMetrics,
      macros: isCurrentDayEmpty ? existing.macros : currentDay.macros,
      weekTdeeAverage: isCurrentDayEmpty
          ? existing.weekTdeeAverage
          : currentDay.weekTdeeAverage,
      welnessEntity: finalWelnessEntity,
    );

    log(
      '[_mergeCurrentDay] Обновлённый день: wellness=${result[existingIndex].welnessEntity?.welnessPercentage}%, блюд=${result[existingIndex].welnessEntity?.consumedMeals.length ?? 0}',
      name: 'UserBloc',
    );

    return result;
  }

  Future<void> showDataPicker({
    required BuildContext context,
    required DateTime initalDate,
    required PageController controller,
  }) async {
    List<DateTime> dates = state.days.map((day) => day.dateTime).toList();

    final date = await showDatePicker(
      context: context,
      firstDate: state.days.first.dateTime,
      lastDate: state.days.last.dateTime,
      initialDate: initalDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (day) {
        return dates.any((date) => date.isSameDate(day));
      },
    );

    if (date != null) {
      final searchDay =
          state.days.firstWhere((day) => day.dateTime.isSameDate(date));
      final searchIndex = state.days.reversed.toList().indexOf(searchDay);
      await controller.animateToPage(
        searchIndex,
        duration: Durations.medium1,
        curve: Curves.ease,
      );
    }
  }

  void _updateDay(UserUpdateDay event, Emitter<UserState> emit) {
    final days = List<DayEntity>.from(state.days);
    final sameDateIndex = days.indexWhere(
      (d) => d.dateTime.isSameDate(event.day.dateTime),
    );

    if (sameDateIndex != -1) {
      days[sameDateIndex] = event.day;
      emit(state.copyWith(days: days));
      return;
    }

    if (!days.any((d) => d.cycleId == event.day.cycleId)) {
      log(
        '[_updateDay] Добавляем день directusId=${event.day.directusId}, cycleId=${event.day.cycleId}',
        name: 'UserBloc',
      );
      days.add(event.day);
      emit(state.copyWith(days: days));
    }
  }

  void _removeDayByDirectusId(
    UserRemoveDayByDirectusId event,
    Emitter<UserState> emit,
  ) {
    if (event.directusId <= 0) {
      return;
    }

    final days = state.days
        .where((d) => d.directusId != event.directusId)
        .toList();

    log(
      '[_removeDayByDirectusId] Удалён день id=${event.directusId}, осталось ${days.length}',
      name: 'UserBloc',
    );
    emit(state.copyWith(days: days));
  }

  FutureOr<void> _addHistoryDays(
    UserAddHistoryDays event,
    Emitter<UserState> emit,
  ) async {
    try {
      log(
        'Начинаю добавление 200 дней истории (POST /debug/days/seed-history)',
        name: 'UserBloc',
      );

      final currentUser = state.user;
      if (currentUser.directusId == '-1') {
        log('Пользователь не авторизован', name: 'UserBloc');
        RishSnackbar().showSnackBar('Пользователь должен быть авторизован');
        return;
      }

      final seedResult = await userServiceClient.seedDebugHistoryDays(
        userId: currentUser.directusId,
      );

      // Перезагружаем дни
      if (state.days.isNotEmpty) {
        add(UserGetDays(newDay: state.days.last));
      }

      log(
        'История добавлена: created=${seedResult.created}, userId=${seedResult.userId}',
        name: 'UserBloc',
      );
      RishSnackbar().showSnackBar(
        'Добавлено дней в историю: ${seedResult.created}',
      );
    } catch (e, stackTrace) {
      log('Ошибка при добавлении истории дней: $e', name: 'UserBloc');
      log('Stack trace: $stackTrace', name: 'UserBloc');
      RishSnackbar().showSnackBar(
        'Ошибка при добавлении истории дней. Попробуйте снова.',
      );
    }
  }

  /// Синхронный вызов debug seed для нового пользователя (_createUserOnLogin).
  Future<void> _createHistoryDaysSync(UserEntity user) async {
    try {
      log(
        '[UserBloc] Синхронный seed 200 дней (POST /debug/days/seed-history)',
        name: 'UserBloc',
      );

      if (user.directusId == '-1') {
        throw Exception('Пользователь не авторизован');
      }

      final seedResult = await userServiceClient.seedDebugHistoryDays(
        userId: user.directusId,
      );

      log(
        '[UserBloc] Backend seed дней: created=${seedResult.created}, '
        'userId=${seedResult.userId} (local user id=${user.directusId})',
        name: 'UserBloc',
      );
    } catch (e, stackTrace) {
      log('Ошибка при синхронном создании истории дней: $e', name: 'UserBloc');
      log('Stack trace: $stackTrace', name: 'UserBloc');
      rethrow; // Пробрасываем ошибку выше
    }
  }

  /// Проверяет белый список аккаунтов и активирует подписку для пользователей из списка
  /// Это основная фича для автоматической активации подписки при старте приложения
  Future<void> _checkWhiteListAndActivateSubscription(String email) async {
    try {
      log(
        '[UserBloc] Проверяем email $email в белом списке при старте приложения',
        name: 'UserBloc',
      );

      final bool isInWhiteList =
          await accountsWhiteListService.isEmailInWhiteList(email);

      if (isInWhiteList) {
        log(
          '[UserBloc] ✅ Email $email найден в белом списке! Активируем подписку автоматически',
          name: 'UserBloc',
        );

        // Активируем подписку для пользователя из белого списка
        adapty.activateWhiteListSubscription();

        log(
          '[UserBloc] ✅ Подписка активирована для пользователя из белого списка при старте. '
          'Статус: isActive=${adapty.isActive}, isTrialActive=${adapty.isTrialActive}',
          name: 'UserBloc',
        );
      } else {
        log(
          '[UserBloc] Email $email не найден в белом списке при старте. '
          'Используем стандартную логику подписки',
          name: 'UserBloc',
        );
      }
    } catch (e, stackTrace) {
      log(
        '[UserBloc] Ошибка при проверке белого списка при старте: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'UserBloc',
      );
      // Не прерываем процесс запуска приложения при ошибке проверки белого списка
    }
  }

  // Старый метод _getUserDaysNew удалён - используем обновлённый _getDays
}
