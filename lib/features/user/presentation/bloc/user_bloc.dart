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
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/update_user_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
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
    on<UserCheckForRecomp>(_checkForRecomp);
    on<UserManageDay>(_manageDay);
    on<UserGetDays>(_getDays); // Используем новую архитектуру
    on<UserUpdateDay>(_updateDay);
    on<UserAddHistoryDays>(_addHistoryDays);
  }

  // Удаляем таймер - больше не нужен
  // Timer? _recompCheckTimer;
  final UpdateUserUsecase updateUserUsecase;
  // Удаляем старый use case, оставляем только новый
  final GetUserDaysUsecase getUserDaysUsecase;
  final AccountsWhiteListService accountsWhiteListService;
  final UserServiceClient userServiceClient;

  // Удаляем метод инициализации таймера
  // void _initRecompCheckTimer() { ... }

  @override
  Future<void> close() {
    // Убираем отмену таймера
    // _recompCheckTimer?.cancel();
    return super.close();
  }

  FutureOr<void> _updateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    UserEntity user = event.user;
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
      }, (r) {
        log('Пользователь успешно синхронизирован с backend', name: 'UserBloc');
      });
    } on Exception catch (e) {
      log('Ошибка обновления пользователя: $e', name: 'UserBloc');
      // Локальное состояние уже обновлено, просто логируем ошибку
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

        // Теперь запускаем другие блоки, когда статус подписки уже определен
        weekPlanBloc.add(const WeekPlanLoad());
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

  FutureOr<void> _checkForRecomp(
    UserCheckForRecomp event,
    Emitter<UserState> emit,
  ) async {
    try {
      if (state.user.userGoal?.goal != null &&
          state.user.userGoal?.goal == GoalType.recomp) {
        UserGoal goal = state.user.userGoal!;

        log(
          'Checking recomp modifier change:\n'
          'Last updated: ${goal.updatedAt}\n'
          'Current time: ${DateTime.now()}\n'
          'Days since update: ${DateTime.now().difference(goal.updatedAt).inDays}\n'
          'Current modifier: ${goal.modificator}',
          name: 'UserBloc',
        );

        if (goal.updatedAt
            .isBefore(DateTime.now().subtract(const Duration(days: 14)))) {
          log('Initiating recomp modifier change', name: 'UserBloc');

          final oldModifier = goal.modificator;
          goal = goal.copyWith(
            modificator: goal.modificator > 0 ? -0.05 : 0.05,
            updatedAt: DateTime.now(),
          );

          final user = state.user.copyWith(userGoal: goal);

          // Сначала обновляем локальное состояние
          emit(state.copyWith(user: user));

          // Затем пытаемся синхронизировать с бэкендом
          final updateResult = await updateUserUsecase.call(user);

          await updateResult.fold(
            (failure) async {
              log(
                'Failed to update recomp modifier:\n'
                'Error: ${failure.message}\n'
                'Old modifier: $oldModifier\n'
                'Attempted new modifier: ${goal.modificator}',
                name: 'UserBloc',
                error: failure,
              );

              // Откатываем изменения в локальном состоянии при ошибке
              emit(
                state.copyWith(
                  user: state.user.copyWith(
                    userGoal: state.user.userGoal!.copyWith(
                      modificator: oldModifier,
                      updatedAt: goal.updatedAt,
                    ),
                  ),
                ),
              );

              // Показываем уведомление пользователю
              RishSnackbar().showSnackBar(
                'Не удалось обновить настройки фитнес-цели. Пожалуйста, попробуйте снова.',
              );
            },
            (_) {
              log(
                'Successfully updated recomp modifier:\n'
                'Old modifier: $oldModifier\n'
                'New modifier: ${goal.modificator}',
                name: 'UserBloc',
              );
            },
          );
        } else {
          log(
            'Recomp modifier change not needed yet:\n'
            'Days until next change: ${14 - DateTime.now().difference(goal.updatedAt).inDays}',
            name: 'UserBloc',
          );
        }
      }
    } catch (e, stackTrace) {
      log(
        'Unexpected error in recomp modifier check:\n'
        'Error: $e\n'
        'Stack trace: $stackTrace',
        name: 'UserBloc',
        error: e,
      );

      // Показываем уведомление пользователю о неожиданной ошибке
      RishSnackbar().showSnackBar(
        'Произошла неожиданная ошибка при обновлении фитнес-цели. Пожалуйста, попробуйте перезапустить приложение.',
      );
    }
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
    log(
      '[_getDays] Начинаем загрузку дней, статус -> loading',
      name: 'UserBloc',
    );
    emit(state.copyWith(status: Status.loading));
    DayEntity currentDay = event.newDay;

    log(
      '[_getDays] Получаем дни через новую архитектуру getUserDaysUsecase',
      name: 'UserBloc',
    );
    final res = await getUserDaysUsecase
        .call(GetUserDaysParams(userId: state.user.directusId));

    await res.fold((l) async {
      log(
        '[_getDays] Ошибка при получении дней: ${l.message}',
        name: 'UserBloc',
      );

      // Если не удалось загрузить дни, возвращаем только текущий день
      log(
        '[_getDays] Возвращаем только текущий день из-за ошибки',
        name: 'UserBloc',
      );
      emit(state.copyWith(status: Status.success, days: [currentDay]));
    }, (List<DayEntity> r) async {
      log(
        '[_getDays] Дни успешно получены, обрабатываем ${r.length} дней',
        name: 'UserBloc',
      );

      // Создаём копию списка для изменения
      final daysList = List<DayEntity>.from(r);

      // Ищем существующий день с той же датой
      final existingDayIndex = daysList.indexWhere(
        (day) => day.dateTime.isSameDate(currentDay.dateTime),
      );

      if (existingDayIndex != -1) {
        // Обновляем существующий день
        final existingDay = daysList[existingDayIndex];
        log(
          '[_getDays] Обновляем существующий день на индексе $existingDayIndex',
          name: 'UserBloc',
        );
        
        // [FIX] Детальное логирование для отладки потери welnessEntity
        log(
          '[_getDays] existingDay.welnessEntity: ${existingDay.welnessEntity != null ? "есть (${existingDay.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
          name: 'UserBloc',
        );
        log(
          '[_getDays] currentDay.welnessEntity: ${currentDay.welnessEntity != null ? "есть (${currentDay.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
          name: 'UserBloc',
        );

        // [FIX] Исправлен баг потери welnessEntity при входе после логаута
        // КРИТИЧЕСКИ ВАЖНО: Используем existingDay (из Directus) как основу полностью,
        // так как он содержит все сохраненные данные, включая welnessEntity
        // НЕ обновляем существующий день данными из currentDay, чтобы не потерять welnessEntity
        // currentDay может не содержать welnessEntity, если он создан заново при входе
        final finalWelnessEntity = existingDay.welnessEntity ?? currentDay.welnessEntity;
        
        log(
          '[_getDays] Финальный welnessEntity: ${finalWelnessEntity != null ? "есть (${finalWelnessEntity.consumedMeals.length} блюд)" : "нет"}',
          name: 'UserBloc',
        );
        
        // [FIX] Проверяем, содержит ли currentDay валидные данные (не пустые/нулевые)
        // Если currentDay пустой (например, при инициализации), не перезаписываем данные из базы нулями
        final isCurrentDayEmpty = currentDay.macros.kcal == 0 && 
                                 currentDay.weekTdeeAverage == 0;

        if (isCurrentDayEmpty) {
          log(
            '[_getDays] ⚠️ currentDay пустой (инициализация), оставляем данные из базы (healthMetrics, macros)',
            name: 'UserBloc',
          );
        }

        // Используем existingDay полностью, обновляя только метрики из currentDay,
        // но сохраняя welnessEntity из existingDay (Directus)
        daysList[existingDayIndex] = existingDay.copyWith(
          // Обновляем актуальные метрики здоровья и макросы из currentDay,
          // только если они валидны. Иначе оставляем данные из базы.
          healthMetrics: isCurrentDayEmpty ? existingDay.healthMetrics : currentDay.healthMetrics,
          macros: isCurrentDayEmpty ? existingDay.macros : currentDay.macros,
          weekTdeeAverage: isCurrentDayEmpty ? existingDay.weekTdeeAverage : currentDay.weekTdeeAverage,
          // КРИТИЧЕСКИ ВАЖНО: Сохраняем welnessEntity из загруженного дня (Directus)
          // Это гарантирует, что данные дневника питания не потеряются
          welnessEntity: finalWelnessEntity,
        );

        log(
          '[_getDays] Обновленный день: wellness=${daysList[existingDayIndex].welnessEntity?.welnessPercentage}%, блюд=${daysList[existingDayIndex].welnessEntity?.consumedMeals.length ?? 0}',
          name: 'UserBloc',
        );
      } else {
        // Добавляем новый день
        log('[_getDays] Добавляем новый день в список', name: 'UserBloc');
        daysList.add(currentDay);
      }

      // Сортируем дни по дате
      daysList.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      log(
        '[_getDays] Успешно загружено ${daysList.length} дней, статус -> success',
        name: 'UserBloc',
      );
      emit(state.copyWith(status: Status.success, days: daysList));
    });
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

  Future<void> createMockData(DayEntity day) async {
    // print('hi');
    await directus.createMany(
      collection: daysCollection,
      data: day.mockDays(length: 30, id: '139'),
    );
    // print('done');
  }

  FutureOr<void> _updateDay(UserUpdateDay event, Emitter<UserState> emit) {
    List<DayEntity> days = List.from(state.days);
    if (!state.days.any((d) => d.cycleId == event.day.cycleId)) {
      print('DAY ADDED!!!');
      days.add(event.day);
      emit(state.copyWith(days: days));
    }
  }

  FutureOr<void> _addHistoryDays(
    UserAddHistoryDays event,
    Emitter<UserState> emit,
  ) async {
    try {
      log('Начинаю добавление 200 дней истории пользователю', name: 'UserBloc');

      // Получаем текущего пользователя
      final currentUser = state.user;
      if (currentUser.directusId == '-1') {
        log('Пользователь не авторизован', name: 'UserBloc');
        RishSnackbar().showSnackBar('Пользователь должен быть авторизован');
        return;
      }

      // Создаем реалистичный базовый день для истории
      final baseDay = state.days.isNotEmpty
          ? state.days.last
          : DayEntity(
              directusId: 0,
              weekTdeeAverage: 2200,
              macros: MacrosBreakdown(
                kcal: 2000,
                protein: 150,
                carbs: 200,
                fat: 67,
              ),
              healthMetrics: const HealthMetricsEntity(
                bmi: 23,
                lastTdee: 2200,
                bmr: 1800,
                bodyFatPerc: 15,
              ),
              snap: ChatSnapshotEntity(
                messages: [],
                date: DateTime.now(),
                requestsLeft: 13,
              ),
              dateTime: DateTime.now(),
            );

      // Создаем список дней для добавления в Directus
      final List<Map<String, dynamic>> daysToCreate = [];

      // Генерируем 200 дней, начиная со вчера и уходя в прошлое
      for (int i = 0; i < 200; i++) {
        // Вычисляем дату для каждого дня (вчера - i дней)
        final dayDate = DateTime.now().subtract(Duration(days: i + 1));

        // Создаем день с уникальными данными
        final historyDay = DayEntity(
          directusId: 0, // Будет установлен Directus
          weekTdeeAverage: baseDay.weekTdeeAverage + (i % 100), // Вариация TDEE
          macros: MacrosBreakdown(
            kcal: baseDay.macros.kcal + (i % 50),
            protein: baseDay.macros.protein + (i % 10),
            carbs: baseDay.macros.carbs + (i % 15),
            fat: baseDay.macros.fat + (i % 8),
          ),
          healthMetrics: baseDay.healthMetrics,
          snap: ChatSnapshotEntity(
            messages: [],
            date: dayDate,
            requestsLeft: 13,
          ),
          dateTime: dayDate,
          cycleId: baseDay.cycleId != null
              ? baseDay.cycleId! + i
              : i + 1, // Уникальный cycleId
        );

        // Добавляем день в список для создания
        daysToCreate.add(historyDay.toDirectus(userId: currentUser.directusId));
      }

      log('Создаю ${daysToCreate.length} дней в Directus', name: 'UserBloc');

      // Создаем все дни в Directus одним запросом
      await directus.createMany(
        collection: daysCollection,
        data: daysToCreate,
      );

      log('Создано ${daysToCreate.length} дней в Directus', name: 'UserBloc');

      // Перезагружаем дни
      if (state.days.isNotEmpty) {
        add(UserGetDays(newDay: state.days.last));
      }

      log(
        'История из 200 дней успешно добавлена пользователю',
        name: 'UserBloc',
      );
      RishSnackbar().showSnackBar('История из 200 дней успешно добавлена!');
    } catch (e, stackTrace) {
      log('Ошибка при добавлении истории дней: $e', name: 'UserBloc');
      log('Stack trace: $stackTrace', name: 'UserBloc');
      RishSnackbar().showSnackBar(
        'Ошибка при добавлении истории дней. Попробуйте снова.',
      );
    }
  }

  /// Синхронное создание исторических дней для нового пользователя
  /// (без emit-ов и снекбаров, используется в _createUserOnLogin)
  Future<void> _createHistoryDaysSync(UserEntity user) async {
    try {
      log('Начинаю синхронное создание 200 дней истории', name: 'UserBloc');

      if (user.directusId == '-1') {
        throw Exception('Пользователь не авторизован');
      }

      // Создаем реалистичный базовый день для истории
      final baseDay = DayEntity(
        directusId: 0,
        weekTdeeAverage: 2200, // Реалистичный TDEE для среднего взрослого
        macros: MacrosBreakdown(
          kcal: 2000, // Базовое количество калорий
          protein: 150, // ~30% калорий от белков
          carbs: 200, // ~40% калорий от углеводов
          fat: 67, // ~30% калорий от жиров
        ),
        healthMetrics: const HealthMetricsEntity(
          bmi: 23, // Нормальный ИМТ
          lastTdee: 2200, // Соответствует weekTdeeAverage
          bmr: 1800, // Базальный метаболизм
          bodyFatPerc: 15, // Средний процент жира
        ),
        snap: ChatSnapshotEntity(
          messages: [],
          date: DateTime.now(),
          requestsLeft: 13,
        ),
        dateTime: DateTime.now(),
      );

      // Создаем список дней для добавления в Directus
      final List<Map<String, dynamic>> daysToCreate = [];

      // Генерируем 200 дней, начиная со вчера и уходя в прошлое
      for (int i = 0; i < 200; i++) {
        // Вычисляем дату для каждого дня (вчера - i дней)
        final dayDate = DateTime.now().subtract(Duration(days: i + 1));

        // Создаем день с уникальными данными
        final historyDay = DayEntity(
          directusId: 0, // Будет установлен Directus
          weekTdeeAverage: baseDay.weekTdeeAverage + (i % 100), // Вариация TDEE
          macros: MacrosBreakdown(
            kcal: baseDay.macros.kcal + (i % 50),
            protein: baseDay.macros.protein + (i % 10),
            carbs: baseDay.macros.carbs + (i % 15),
            fat: baseDay.macros.fat + (i % 8),
          ),
          healthMetrics: baseDay.healthMetrics,
          snap: ChatSnapshotEntity(
            messages: [],
            date: dayDate,
            requestsLeft: 13,
          ),
          dateTime: dayDate,
          cycleId: i + 1, // Уникальный cycleId
        );

        // Добавляем день в список для создания
        daysToCreate.add(historyDay.toDirectus(userId: user.directusId));
      }

      log('Создаю ${daysToCreate.length} дней в Directus', name: 'UserBloc');

      // Создаем все дни в Directus одним запросом
      await directus.createMany(
        collection: daysCollection,
        data: daysToCreate,
      );

      log(
        'Синхронно создано ${daysToCreate.length} дней в Directus',
        name: 'UserBloc',
      );
    } catch (e, stackTrace) {
      log('Ошибка при синхронном создании истории дней: $e', name: 'UserBloc');
      log('Stack trace: $stackTrace', name: 'UserBloc');
      rethrow; // Пробрасываем ошибку выше
    }
  }

  /// Упрощенная проверка recomp при создании нового дня
  /// Вызывается только когда создается НОВЫЙ день (не обновляется существующий)
  /// Возвращает обновленный модификатор (или текущий, если изменения не нужны)
  Future<double> checkRecompForNewDay() async {
    try {
      // Проверяем, что у пользователя установлена цель recomp
      if (state.user.userGoal?.goal != null &&
          state.user.userGoal?.goal == GoalType.recomp) {
        final goal = state.user.userGoal!;
        final daysSinceUpdate =
            DateTime.now().difference(goal.updatedAt).inDays;

        log(
          'Checking recomp for new day:\n'
          'Last updated: ${goal.updatedAt}\n'
          'Current time: ${DateTime.now()}\n'
          'Days since update: $daysSinceUpdate\n'
          'Current modifier: ${goal.modificator}',
          name: 'UserBloc',
        );

        // Если прошло 14 или больше дней, меняем модификатор
        if (daysSinceUpdate >= 14) {
          log('Changing recomp modifier for new day', name: 'UserBloc');

          final oldModifier = goal.modificator;
          final newModifier = goal.modificator > 0 ? -0.05 : 0.05;

          final updatedGoal = goal.copyWith(
            modificator: newModifier,
            updatedAt: DateTime.now(),
          );

          final updatedUser = state.user.copyWith(userGoal: updatedGoal);

          // Обновляем локальное состояние через событие
          add(UpdateUserEvent(user: updatedUser));

          // Сохраняем локально
          await hive.saveUser(user: updatedUser);

          // Пытаемся синхронизировать с бэкендом (без отката при ошибке)
          try {
            await updateUserUsecase.call(updatedUser);
            log(
              'Successfully updated recomp modifier:\n'
              'Old modifier: $oldModifier\n'
              'New modifier: $newModifier',
              name: 'UserBloc',
            );
          } catch (e) {
            log(
              'Failed to sync recomp modifier with backend, but local state is updated:\n'
              'Error: $e\n'
              'Old modifier: $oldModifier\n'
              'New modifier: $newModifier',
              name: 'UserBloc',
            );
            // Не откатываем локальные изменения - они сохранятся при следующей синхронизации
          }

          // Возвращаем новый модификатор
          return newModifier;
        } else {
          log(
            'Recomp modifier change not needed yet:\n'
            'Days until next change: ${14 - daysSinceUpdate}',
            name: 'UserBloc',
          );

          // Возвращаем текущий модификатор
          return goal.modificator;
        }
      } else {
        log(
          'User goal is not recomp or userGoal is null',
          name: 'UserBloc',
        );

        // Возвращаем текущий модификатор или 0.0 по умолчанию
        return state.user.userGoal?.modificator ?? 0.0;
      }
    } catch (e, stackTrace) {
      log(
        'Unexpected error in recomp check for new day:\n'
        'Error: $e\n'
        'Stack trace: $stackTrace',
        name: 'UserBloc',
        error: e,
      );

      // В случае ошибки возвращаем текущий модификатор
      return state.user.userGoal?.modificator ?? 0.0;
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
