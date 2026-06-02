import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart'
    show adapty;
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/data/chat_repository_impl.dart'
    as chat_repo;
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart'
    as chat_remote;
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart'
    show whoopRemote;
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';
import 'package:rishai/features/food_diary/domain/services/wellness_score_calculator.dart';
part 'whoop_event.dart';

final whoopBloc = getIt.get<WhoopBloc>();
final chatRemoteSrc = chat_remote.chatRemoteSrc;
final chatRepo = chat_repo.chatRepo;

/// [navigateHomeAndInitWhoopIfNeeded] После paywall: home + InitWhoop без /redirect.
void navigateHomeAndInitWhoopIfNeeded() {
  final shouldInit = prefsRepo.getShouldRedirectAfterPaywall();
  appNavigationService.go(path: AppRoutes.homeScreen.path);
  if (shouldInit) {
    unawaited(prefsRepo.setShouldRedirectAfterPaywall(false));
    whoopBloc.add(const InitWhoopOnLogin());
  }
}

@injectable
class WhoopBloc extends Bloc<WhoopEvent, WhoopState> {
  WhoopBloc(
    this.connectWhoopUsecase,
    this.getDataUsecase,
    this.getBodyUsecase,
    this.disconnectWhoopUsecase,
  ) : super(
          WhoopMainState(
            status: Status.initial,
            day: DayEntity.empty(requestsLeft: chatBloc.state.requestsLeft),
            whoopConnected: false,
          ),
        ) {
    on<WhoopConnectEvent>(_connectWhoop);
    on<WhoopGetUserData>(_getUserData);
    on<InitWhoopOnLogin>(_initWhoopOnLogin);
    on<WhoopUserCalibrating>(_userCalibrating);
    on<WhoopRetrieveBodyData>(_getBodyData);
    on<WhoopRefreshAfterProfileChange>(_refreshAfterProfileChange);
    on<WhoopUpdateDayByMealPlan>(_updateDayByMealPlan);
    on<WhoopDisconnect>(_disconnect);
    on<WhoopCheckForRefresh>(_checkForRefresh);
    on<WhoopUpdateCurrentDay>(_updateCurrentDay);
    on<WhoopResetState>(_resetState);
    on<WhoopHideSyncBanner>(_hideSyncBanner);
  }

  Timer? _syncBannerHideTimer;

  /// Prevents parallel force-disconnect calls during a burst of 403 responses.
  bool _whoopAuthRecoveryInProgress = false;

  /// Caps body-measurement retries (previously retried indefinitely).
  int _bodyDataRetryCount = 0;
  static const int _maxBodyDataRetries = 3;

  final ConnectWhoopUsecase connectWhoopUsecase;
  final WhoopGetDataUsecase getDataUsecase;
  final WhoopGetBodyData getBodyUsecase;
  final DisconnectWhoopUsecase disconnectWhoopUsecase;

  @override
  Future<void> close() {
    _cancelSyncBannerHideTimer();
    return super.close();
  }

  void _cancelSyncBannerHideTimer() {
    _syncBannerHideTimer?.cancel();
    _syncBannerHideTimer = null;
  }

  /// [_ensureOnHomeForSync] Домашний таб — единственное место, где видна плашка sync.
  void _ensureOnHomeForSync() {
    // Do not pull the user back to home while WHOOP reconnect is required.
    if (!state.whoopConnected) {
      return;
    }
    final currentPath = appNavigationService.currentPath;
    if (!currentPath.contains(AppRoutes.homeScreen.path)) {
      appNavigationService.go(path: AppRoutes.homeScreen.path);
    }
  }

  void _emitSyncBannerCatchingUp(Emitter<WhoopState> emit) {
    _cancelSyncBannerHideTimer();
    emit(state.copyWith(syncBannerPhase: WhoopSyncBannerPhase.catchingUp));
  }

  void _emitSyncBannerSuccess({
    required Emitter<WhoopState> emit,
    required bool dataUnchanged,
  }) {
    _cancelSyncBannerHideTimer();
    final now = DateTime.now();
    emit(
      state.copyWith(
        lastSyncedAt: now,
        syncBannerPhase: dataUnchanged
            ? WhoopSyncBannerPhase.syncedFresh
            : WhoopSyncBannerPhase.syncedUpdated,
      ),
    );
    _scheduleSyncBannerHide();
  }

  void _scheduleSyncBannerHide() {
    _cancelSyncBannerHideTimer();
    _syncBannerHideTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed) {
        add(const WhoopHideSyncBanner());
      }
    });
  }

  void _emitSyncBannerHidden(Emitter<WhoopState> emit) {
    _cancelSyncBannerHideTimer();
    emit(state.copyWith(syncBannerPhase: WhoopSyncBannerPhase.hidden));
  }

  bool _isWhoopReconnectFailure(Failure failure) {
    return failure is WhoopFailedToReturnAccessToken ||
        failure is WhoopAuthenticationFailure;
  }

  /// [_forceDisconnectWhoopForReconnect] Clears WHOOP on backend and locally
  /// so the user must complete OAuth again (invalid or blocked refresh).
  Future<void> _forceDisconnectWhoopForReconnect(
    Emitter<WhoopState> emit, {
    required String logReason,
  }) async {
    if (_whoopAuthRecoveryInProgress) {
      log(
        '[WhoopBloc] Force disconnect already in progress, skipping: $logReason',
        name: 'WhoopBloc',
      );
      return;
    }
    _whoopAuthRecoveryInProgress = true;
    _bodyDataRetryCount = 0;

    try {
      log(
        '[WhoopBloc] Force disconnect WHOOP: $logReason',
        name: 'WhoopBloc',
      );
      emit(
        state.copyWith(
          whoopConnected: false,
          status: Status.loading,
          syncBannerPhase: WhoopSyncBannerPhase.hidden,
        ),
      );

      final userId = userBloc.state.user.directusId;
      final res = await disconnectWhoopUsecase.call(
        DisconnecWhoopParams(userId: userId),
      );

      res.fold(
        (failure) {
          log(
            '[WhoopBloc] Force disconnect failed: ${failure.message}',
            name: 'WhoopBloc',
          );
        },
        (_) {
          add(WhoopResetState());
        },
      );

      RishSnackbar().showSnackBar(
        'Your WHOOP connection is no longer valid. Please connect WHOOP again.',
      );
      emit(state.copyWith(status: Status.initial, whoopConnected: false));
      // Navigate after emit so [_initWhoopOnLogin] sees whoopConnected == false
      // and does not call [_ensureOnHomeForSync] back to /home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          appNavigationService.go(path: AppRoutes.whoopConnect.path);
        }
      });
    } finally {
      _whoopAuthRecoveryInProgress = false;
    }
  }

  /// [_isWhoopPayloadUnchanged] Сравнивает WHOOP-поля до merge meal plan / snap.
  bool _isWhoopPayloadUnchanged(DayEntity before, DayEntity after) {
    return before.healthMetrics == after.healthMetrics &&
        before.macros == after.macros &&
        before.weekTdeeAverage == after.weekTdeeAverage &&
        before.cycleId == after.cycleId &&
        before.welnessEntity == after.welnessEntity;
  }

  Future<void> _migrateLegacyWhoopRefreshTokenIfNeeded(String userId) async {
    final legacyRefreshToken = prefsRepo.fetchSavedRefreshToken();
    if (legacyRefreshToken.isEmpty) {
      return;
    }

    try {
      // [Whoop migration] Одноразово переносим legacy refresh token на backend,
      // после чего полностью очищаем локальное хранилище WHOOP токенов.
      await getIt.get<UserServiceClient>().updateUser(
        userId,
        {'whoopRefreshToken': legacyRefreshToken},
      );
      await prefsRepo.clearTokens();
      log(
        '[WhoopBloc] Legacy WHOOP refresh token migrated to backend',
        name: 'WhoopBloc',
      );
    } catch (e, stackTrace) {
      log(
        '[WhoopBloc] Failed to migrate legacy WHOOP refresh token: $e',
        name: 'WhoopBloc',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  FutureOr<void> _connectWhoop(
    WhoopConnectEvent event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    if (!await prefsRepo.checkForWhoopDisclaimerAccpeted()) {
      await RishiDialog.whoopDisclaimer(event.context);
      return;
    }
    final res = await connectWhoopUsecase.call(const NoParams());
    bool success = false;
    final needsQuestionary = userBloc.state.user.needsQuestionary;

    await res.fold((fail) {
      RishSnackbar().showSnackBar(fail.message);
      emit(state.copyWith(status: Status.error));
    }, (_) async {
      success = true;
    });

    if (success) {
      // [FIX] Убираем race condition - _getBodyData вызывается только один раз
      // Если пользователь нуждается в опроснике, данные будут загружены после его завершения
      if (!needsQuestionary) {
        await _initWhoopOnLogin(const InitWhoopOnLogin(), emit);
      } else {
        // Для пользователей с опросником загружаем только body данные
        await _getBodyData(WhoopRetrieveBodyData(), emit);
      }
      await Future.delayed(Durations.medium1, () {
        appNavigationService.go(
          path: needsQuestionary
              ? AppRoutes.questionary.path
              : AppRoutes.homeScreen.path,
        );
        emit(state.copyWith(status: Status.initial));
      });
    }
  }

  FutureOr<void> _getUserData(
    WhoopGetUserData event,
    Emitter<WhoopState> emit,
  ) async {
    if (!event.isInitializing) {
      emit(state.copyWith(status: Status.loading));
    }

    try {
      final result = await getDataUsecase.call(
        GetDataParams(
          gender: event.gender,
          goal: event.goal,
          userId: userBloc.state.user.directusId,
        ),
      );

      await result.fold(
        (failure) async {
          log('Failed to get user data: ${failure.message}', name: 'WhoopBloc');
          emit(state.copyWith(status: Status.error));

          if (_isWhoopReconnectFailure(failure)) {
            await _forceDisconnectWhoopForReconnect(
              emit,
              logReason: failure.message,
            );
            return;
          }

          if (!event.isInitializing) {
            RishSnackbar().showSnackBar(
              'Failed to get WHOOP data: ${failure.message}. Please try reconnecting.',
            );
          }
        },
        (day) {
          emit(
            state.copyWith(
              status: Status.success,
              day: day,
              whoopConnected: true,
            ),
          );
        },
      );
    } on Exception catch (e) {
      log('Error getting user data: $e', name: 'WhoopBloc');
      emit(state.copyWith(status: Status.error));

      if (!event.isInitializing) {
        RishSnackbar().showSnackBar(
          'Failed to get WHOOP data. Please check your internet connection and try again.',
        );
      }
    }
  }

  FutureOr<void> _initWhoopOnLogin(
    InitWhoopOnLogin event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      log('[WhoopBloc] _initWhoopOnLogin начат', name: 'WhoopBloc');
      emit(state.copyWith(status: Status.loading));
      UserEntity user = userBloc.state.user;
      log(
        '[WhoopBloc] Пользователь: ${user.directusId}, needsQuestionary: ${user.needsQuestionary}',
        name: 'WhoopBloc',
      );
      await _migrateLegacyWhoopRefreshTokenIfNeeded(user.directusId);
      final isWhoopConnected = await whoopRemote.isWhoopConnected();
      await adapty.initAdapty();
      emit(state.copyWith(whoopConnected: isWhoopConnected));
      log('WHOOP backend status: $isWhoopConnected', name: 'WhoopBloc');

      if (!isWhoopConnected) {
        RishSnackbar().showSnackBar(
          'Unable to connect to WHOOP. Please reconnect your account.',
        );
        emit(state.copyWith(status: Status.initial));
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
        return;
      }

      log('retrieveing BODY data');
      await _getBodyData(WhoopRetrieveBodyData(), emit);

      // Stop init if body fetch failed or we forced disconnect for reconnect.
      if (!state.whoopConnected || state.status == Status.error) {
        log(
          '[WhoopBloc] Init aborted after body fetch '
          '(whoopConnected=${state.whoopConnected}, status=${state.status})',
          name: 'WhoopBloc',
        );
        _emitSyncBannerHidden(emit);
        return;
      }

      // Свежий профиль после body/опросника — не опираемся на [user] с начала метода
      final userForFlow = userBloc.state.user;

      if (!userForFlow.needsQuestionary) {
        log('retrieveing data');
        // [SyncBanner] Остаёмся на home, плашка вместо полноэкранного /redirect.
        _ensureOnHomeForSync();
        final dayBeforeInit = state.day;
        _emitSyncBannerCatchingUp(emit);

        await _getUserData(
          WhoopGetUserData(
            userForFlow.gender!,
            userForFlow.userGoal!,
            isInitializing: true,
          ),
          emit,
        );

        if (state.status != Status.loading && state.status != Status.error) {
          chatBloc.add(InitChatBloc(directusId: userForFlow.directusId));

          // Используем централизованную логику инициализации дней из DayManager
          log(
            'Инициализация загрузки дней через DayManager',
            name: 'WhoopBloc',
          );
          final initResult = await dayManager.initializeUserDaysOnLogin(
            userId: userForFlow.directusId,
            newDay: state.day,
          );

          // Обработка результата инициализации
          if (!initResult.success) {
            // Показываем сообщение об ошибке только если загрузка полностью провалилась
            RishSnackbar().showSnackBar(
              initResult.errorMessage ?? 'Failed to load user data',
            );
            emit(state.copyWith(status: Status.error));
            _emitSyncBannerHidden(emit);
            return;
          } else if (initResult.partialSuccess) {
            // Частичная загрузка - не показываем ошибку
            log(
              'Частичная загрузка: ${initResult.daysLoaded} дней',
              name: 'WhoopBloc',
            );
          } else {
            log(
              'Все дни загружены успешно: ${initResult.daysLoaded} дней',
              name: 'WhoopBloc',
            );
          }

          // ─────────────────────────────────────────────────────────────────
          // Stale-While-Revalidate: UserBloc уже emitнул фазу 1 (кэш/сегодня),
          // поэтому дни в state гарантированно не пустые — ждать Status.success
          // больше не нужно. Навигируем сразу; фаза 2 (полная история) придёт
          // в фоне и обновит PageView автоматически.
          // ─────────────────────────────────────────────────────────────────
          log(
            '[WhoopBloc] Готовимся к навигации, days=${userBloc.state.days.length}',
            name: 'WhoopBloc',
          );

          // [DaysRecovery] Страховочный путь: если по какой-то причине фаза 1
          // не отработала и список всё ещё пуст — добиваем через /days/current.
          var finalUserState = userBloc.state;
          if (finalUserState.days.isEmpty &&
              finalUserState.user.directusId != '-1') {
            log(
              '[WhoopBloc] Список дней пуст — recovery через GET /days/current',
              name: 'WhoopBloc',
            );
            await _recoverUserBlocDays(state.day);
            finalUserState = userBloc.state;
          }

          // Обновляем state.day в WhoopBloc актуальным сегодняшним днём из
          // UserBloc (он уже содержит welnessEntity из кэша/Directus).
          if (finalUserState.days.isNotEmpty) {
            final lastDayFromUserBloc =
                finalUserState.days.reversed.toList().first;
            log(
              '[WhoopBloc] Обновляем state.day из UserBloc: wellness=${lastDayFromUserBloc.welnessEntity != null ? "есть (${lastDayFromUserBloc.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
              name: 'WhoopBloc',
            );

            final updatedDay = lastDayFromUserBloc.copyWith(
              // Сохраняем mealPlan и snap из текущего state.day, если они есть
              mealPlanEntity:
                  state.day.mealPlanEntity ?? lastDayFromUserBloc.mealPlanEntity,
              snap: state.day.snap,
            );

            emit(state.copyWith(day: updatedDay));

            log(
              '[WhoopBloc] ✅ state.day обновлён: wellness=${state.day.welnessEntity != null ? "есть (${state.day.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
              name: 'WhoopBloc',
            );
          } else {
            log(
              '[WhoopBloc] ⚠️ Дней нет даже после recovery — навигируем с пустым списком',
              name: 'WhoopBloc',
            );
          }

          // [SyncBanner] Успех init: сравниваем WHOOP-данные до/после загрузки.
          _emitSyncBannerSuccess(
            emit: emit,
            dataUnchanged: _isWhoopPayloadUnchanged(dayBeforeInit, state.day),
          );
          _ensureOnHomeForSync();
          log('Навигация на главный экран', name: 'WhoopBloc');
          emit(state.copyWith(status: Status.success));
          return;
        } else if (state.status == Status.error) {
          _emitSyncBannerHidden(emit);
        }
      } else {
        appNavigationService.go(path: AppRoutes.questionary.path);
        emit(state.copyWith(status: Status.initial));
        return;
      }
    } on Exception catch (e) {
      log('Error during WHOOP initialization: $e');
      RishSnackbar().showSnackBar(
        'Unable to connect to WHOOP. Please try again later.',
      );
      _emitSyncBannerHidden(emit);
      emit(state.copyWith(status: Status.initial));
    }
  }

  /// Догрузка дней в [UserBloc]: сначала `/days/current`, иначе fallback на день из WHOOP.
  Future<void> _recoverUserBlocDays(DayEntity whoopDay) async {
    final userId = userBloc.state.user.directusId;
    if (userId == '-1') {
      return;
    }

    try {
      final lastRes =
          await dayManager.getLastDayWithCycleStatus(userId: userId);
      final seed = lastRes?.day ?? whoopDay;
      log(
        '[WhoopBloc._recoverUserBlocDays] UserGetDays, hasLastRes=${lastRes != null}, '
        'seedCycle=${seed.cycleId}',
        name: 'WhoopBloc',
      );
      userBloc.add(UserGetDays(newDay: seed));

      final started = DateTime.now();
      while (DateTime.now().difference(started) < const Duration(seconds: 8)) {
        if (userBloc.state.days.isNotEmpty) {
          log(
            '[WhoopBloc._recoverUserBlocDays] ok, count=${userBloc.state.days.length}',
            name: 'WhoopBloc',
          );
          return;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      log(
        '[WhoopBloc._recoverUserBlocDays] retry with whoop state.day',
        name: 'WhoopBloc',
      );
      userBloc.add(UserGetDays(newDay: whoopDay));
      await Future.delayed(const Duration(milliseconds: 400));
    } on Exception catch (e, st) {
      log(
        '[WhoopBloc._recoverUserBlocDays] $e',
        name: 'WhoopBloc',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _userCalibrating(
    WhoopUserCalibrating event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.initial));
    final remaining = await prefsRepo.calibratingDate();
    await Future.delayed(Durations.short1);
    emit(state.copyWith(calibratingCompleteDate: remaining));

    if (event.needsRedirect! && remaining != null) {
      appNavigationService.go(path: AppRoutes.calibratingScreen.path);
    } else {
      log('Calibrating done.');
    }
  }

  FutureOr<void> _getBodyData(
    WhoopRetrieveBodyData event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final bodyRes = await getBodyUsecase.call(const NoParams());

    await bodyRes.fold((l) async {
      emit(state.copyWith(status: Status.error));

      if (_isWhoopReconnectFailure(l)) {
        await _forceDisconnectWhoopForReconnect(
          emit,
          logReason: l.message,
        );
        return;
      }

      if (_bodyDataRetryCount < _maxBodyDataRetries) {
        _bodyDataRetryCount++;
        log(
          '[WhoopBloc] Body data retry $_bodyDataRetryCount/$_maxBodyDataRetries',
          name: 'WhoopBloc',
        );
        RishSnackbar().showSnackBar(
          'Failed to retrieve body data: ${l.message}, retrying...',
        );
        add(WhoopRetrieveBodyData());
        return;
      }

      _bodyDataRetryCount = 0;
      // Exhausted retries — treat as broken WHOOP session (same as null/403 body).
      await _forceDisconnectWhoopForReconnect(
        emit,
        logReason: 'body_data_retries_exhausted: ${l.message}',
      );
    }, (r) async {
      _bodyDataRetryCount = 0;
      UserEntity user = userBloc.state.user;
      final upd = user.copyWith(bodyMeasurements: r);
      emit(
        state.copyWith(
          status: Status.success,
        ),
      );
      userBloc.add(UpdateUserEvent(user: upd));
    });
  }

  FutureOr<void> _refreshAfterProfileChange(
    WhoopRefreshAfterProfileChange event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    await _fetchCurrentDayFromBackend(
      emit,
      forceRefresh: true,
      showLoadingRoute: false,
      showSuccessSnack: false,
    );
  }

  Future<void> _fetchCurrentDayFromBackend(
    Emitter<WhoopState> emit, {
    required bool forceRefresh,
    required bool showLoadingRoute,
    required bool showSuccessSnack,
  }) async {
    final dayBefore = state.day;
    _emitSyncBannerCatchingUp(emit);
    if (showLoadingRoute) {
      _ensureOnHomeForSync();
    }

    final result = await getDataUsecase.call(
      GetDataParams(
        gender: userBloc.state.user.gender!,
        goal: userBloc.state.user.userGoal!,
        userId: userBloc.state.user.directusId,
        forceRefresh: forceRefresh,
      ),
    );

    await result.fold(
      (failure) async {
        log('Failed to refresh current day: ${failure.message}', name: 'WhoopBloc');
        _emitSyncBannerHidden(emit);
        emit(state.copyWith(status: Status.error));

        if (_isWhoopReconnectFailure(failure)) {
          await _forceDisconnectWhoopForReconnect(
            emit,
            logReason: failure.message,
          );
          return;
        }

        if (showLoadingRoute) {
          _ensureOnHomeForSync();
        }

        RishSnackbar().showSnackBar(
          'Failed to refresh WHOOP day: ${failure.message}',
        );
      },
      (newDay) async {
        final existingSnap = state.day.snap;
        final mealPlanToUse = shouldKeepExistingMealPlan(state.day, newDay)
            ? state.day.mealPlanEntity
            : newDay.mealPlanEntity;

        final updatedDay = newDay.copyWith(
          mealPlanEntity: mealPlanToUse,
          snap: existingSnap,
        );

        emit(
          state.copyWith(
            day: updatedDay,
            whoopConnected: true,
          ),
        );

        await _recalculateWellnessIfNeeded(updatedDay, emit);

        final syncedDay = state.day;
        userBloc.add(UserGetDays(newDay: syncedDay));
        chatBloc.add(ChatSyncWithSelectedDate());

        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        await chatRepo.updateChatCache(
          directusId: userBloc.state.user.directusId,
          startDate: sevenDaysAgo,
          endDate: now,
        );

        emit(state.copyWith(status: Status.success));

        _emitSyncBannerSuccess(
          emit: emit,
          dataUnchanged: _isWhoopPayloadUnchanged(dayBefore, newDay),
        );

        if (showLoadingRoute) {
          _ensureOnHomeForSync();
        }
      },
    );
  }

  Future<void> _recalculateWellnessIfNeeded(
    DayEntity day,
    Emitter<WhoopState> emit,
  ) async {
    try {
      final existingWelness = day.welnessEntity;
      if (existingWelness == null || existingWelness.consumedMeals.isEmpty) {
        return;
      }

      log(
        '[WhoopBloc] 🔄 Recalculating Daily Wellness Score after backend day refresh',
        name: 'WhoopBloc',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      final wellnessScoreCalculator = getIt.get<WellnessScoreCalculator>();
      final updatedDayWithWellness =
          await wellnessScoreCalculator.recalculateWellnessScoreForExistingMeals(
        day,
      );

      emit(state.copyWith(day: updatedDayWithWellness));
    } catch (e, stackTrace) {
      log(
        '[WhoopBloc] ❌ Failed to recalculate Daily Wellness Score: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'WhoopBloc',
      );
    }
  }

  (double proteinPer, double carbsPer, double fatsPer) calculatePercentage() {
    int proteinKcal = state.day.macros.protein * 4;
    int carbsKcal = state.day.macros.carbs * 4;
    int fatsKcal = state.day.macros.fat * 9;

    final totalKcal = state.day.macros.kcal;

    double proteinPerc = (proteinKcal / totalKcal) * 100;
    double carbsPerc = (carbsKcal / totalKcal) * 100;
    double fatsPerc = (fatsKcal / totalKcal) * 100;

    int proteinRounded = proteinPerc.round();
    int carbsRounded = carbsPerc.round();
    int fatsRounded = fatsPerc.round();

    int totalRounded = proteinRounded + carbsRounded + fatsRounded;
    if (totalRounded != 100) {
      int difference = 100 - totalRounded;

      if (proteinRounded >= carbsRounded && proteinRounded >= fatsRounded) {
        proteinRounded += difference;
      } else if (carbsRounded >= proteinRounded &&
          carbsRounded >= fatsRounded) {
        carbsRounded += difference;
      } else {
        fatsRounded += difference;
      }
    }

    return (
      proteinRounded.toDouble(),
      carbsRounded.toDouble(),
      fatsRounded.toDouble()
    );
  }

  (int carbsKcal, int proteinKcal, int fatKcal) calculateMacrosInKcal() {
    int proteinKcal = state.day.macros.protein * 4;
    int carbsKcal = state.day.macros.carbs * 4;
    int fatsKcal = state.day.macros.fat * 9;
    return (carbsKcal, proteinKcal, fatsKcal);
  }

  FutureOr<void> _updateDayByMealPlan(
    WhoopUpdateDayByMealPlan event,
    Emitter<WhoopState> emit,
  ) async {
    log('Updating day by meal:');
    log('Event meal plan: ${event.mealPlanEntity}');
    log('Current state meal plan: ${state.day.mealPlanEntity}');

    // Создаем обновленный день
    final updatedDay = state.day.copyWith(
      mealPlanEntity: event.mealPlanEntity.copyWith(
        cycleId: state.day.cycleId,
      ),
      snap: ChatSnapshotEntity(
        messages: chatBloc.state.messages,
        date: DateTime.now(),
        requestsLeft: chatBloc.state.requestsLeft,
        mealPlan: event.mealPlanEntity.copyWith(
          cycleId: state.day.cycleId,
        ),
        threadId: chatRemoteSrc.threadId,
      ),
    );

    // Проверяем необходимость обновления в Directus
    bool needsDirectusUpdate = false;
    if (state.day.mealPlanEntity != event.mealPlanEntity ||
        !listEquals(state.day.snap.messages, chatBloc.state.messages) ||
        state.day.snap.requestsLeft != chatBloc.state.requestsLeft) {
      needsDirectusUpdate = true;
    }

    // Обновляем состояние локально
    emit(state.copyWith(day: updatedDay));

    // Если нужно, синхронизируем с бэкендом
    if (needsDirectusUpdate) {
      // final data =
      //     updatedDay.toDirectus(userId: userBloc.state.user.directusId);
      await dayManager.createOrUpdateDay(day: updatedDay);

      // await manageDayUsecase.call(
      //   ManageDayParams(
      //     userId: userBloc.state.user.directusId,
      //     dayMap: data,
      //     incomingDay: updatedDay,
      //   ),
      // );

      // Обновляем кэш чата
      await chatRepo.saveChatSnapShot(chatSnap: updatedDay.snap);
    }
  }

  FutureOr<void> _disconnect(
    WhoopDisconnect event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final res = await disconnectWhoopUsecase
          .call(DisconnecWhoopParams(userId: userBloc.state.user.directusId));
      res.fold((l) {
        emit(state.copyWith(status: Status.error));
        RishSnackbar().showSnackBar(
          'Error disconnecting your WHOOP account. Please, try again.',
        );
      }, (r) {
        add(WhoopResetState());
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
      });
    } on Exception catch (e) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(
        'Error disconnecting your WHOOP account. Please, try again. Error: $e',
      );
    }
  }

  bool shouldKeepExistingMealPlan(DayEntity currentDay, DayEntity newDay) {
    // Проверяем, что дни относятся к одному и тому же дню
    final isSameDay = currentDay.dateTime.year == newDay.dateTime.year &&
        currentDay.dateTime.month == newDay.dateTime.month &&
        currentDay.dateTime.day == newDay.dateTime.day;

    // Проверяем, что у нас есть существующий план
    final hasExistingPlan = currentDay.mealPlanEntity != null;

    // Проверяем, что новый план не содержит более свежих данных
    final newPlanIsEmpty = newDay.mealPlanEntity == null;

    // Проверяем cycleId для определения актуальности данных
    final isSameCycle = currentDay.cycleId == newDay.cycleId;

    // Проверяем, что новый день не более свежий
    final isNewerDay = newDay.dateTime.isAfter(currentDay.dateTime);

    if (kDebugMode) {
      log(
        'Meal plan update decision:\n'
        'Current day: ${currentDay.dateTime}\n'
        'New day: ${newDay.dateTime}\n'
        'Same day: $isSameDay\n'
        'Has existing plan: $hasExistingPlan\n'
        'New plan is empty: $newPlanIsEmpty\n'
        'Same cycle: $isSameCycle\n'
        'Current cycle: ${currentDay.cycleId}\n'
        'New cycle: ${newDay.cycleId}\n'
        'Is newer day: $isNewerDay',
        name: 'WhoopBloc',
      );
    }

    // Сохраняем существующий план только если:
    // 1. Дни совпадают
    // 2. Есть существующий план
    // 3. Новый план пустой
    // 4. Циклы совпадают
    // 5. Новый день не более свежий
    return isSameDay &&
        hasExistingPlan &&
        newPlanIsEmpty &&
        isSameCycle &&
        !isNewerDay;
  }

  FutureOr<void> _checkForRefresh(
    WhoopCheckForRefresh event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    // PTR на домашнем экране: плашка sync вместо полноэкранного standby.
    await _fetchCurrentDayFromBackend(
      emit,
      forceRefresh: true,
      showLoadingRoute: false,
      showSuccessSnack: false,
    );
  }

  FutureOr<void> _hideSyncBanner(
    WhoopHideSyncBanner event,
    Emitter<WhoopState> emit,
  ) {
    _emitSyncBannerHidden(emit);
  }

  FutureOr<void> _updateCurrentDay(
    WhoopUpdateCurrentDay event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      log(
        '[WhoopBloc] 📥 incoming welness: ${event.day.welnessEntity}',
        name: 'WhoopBloc',
      );

      // Сохраняем старое состояние для сравнения
      final oldDay = state.day;
      print(oldDay == event.day);
      // Обновляем текущий день
      emit(
        state.copyWith(
          day: event.day,
        ),
      );

      log(
        '[WhoopBloc] ✅ Состояние WhoopBloc обновлено, welness: ${state.day.welnessEntity}',
        name: 'WhoopBloc',
      );

      // Проверяем нужно ли обновить в Directus
      bool needsDirectusUpdate = false;

      // Если план питания был очищен
      if (oldDay.mealPlanEntity != null && event.day.mealPlanEntity == null) {
        needsDirectusUpdate = true;
        log(
          '[WhoopBloc] План питания очищен - обновляем в Directus',
          name: 'WhoopBloc',
        );
      }

      // [FIX] НЕ сохраняем для welnessEntity, так как это уже делается в FoodDiaryCubit
      // Это предотвращает задвойку дня при обновлении дневника питания
      // Если обновилась wellness entity - сохранение уже произошло в FoodDiaryCubit
      // if (oldDay.welnessEntity != event.day.welnessEntity) {
      //   needsDirectusUpdate = true;
      //   log(
      //     '[WhoopBloc] Wellness entity обновлена - обновляем в Directus',
      //     name: 'WhoopBloc',
      //   );
      // }

      if (needsDirectusUpdate) {
        await dayManager.createOrUpdateDay(day: event.day);
        log(
          '[WhoopBloc] ✅ День успешно обновлен в Directus',
          name: 'WhoopBloc',
        );
      }

      // Обновляем список дней в UserBloc
      log(
        '[WhoopBloc] 🔄 Обновляем список дней в UserBloc. Wellness: ${event.day.welnessEntity?.welnessPercentage}%, блюд: ${event.day.welnessEntity?.consumedMeals.length ?? 0}',
        name: 'WhoopBloc',
      );
      userBloc.add(UserGetDays(newDay: event.day));

      // Синхронизируем чат с новым днем
      chatBloc.add(ChatSyncWithSelectedDate());
    } catch (e) {
      log('Error updating current day: $e');
      RishSnackbar().showSnackBar('Failed to update day. Please try again.');
    }
  }

  FutureOr<void> _resetState(
    WhoopResetState event,
    Emitter<WhoopState> emit,
  ) {
    emit(
      WhoopMainState(
        status: Status.initial,
        day: DayEntity.empty(requestsLeft: chatBloc.state.requestsLeft),
        whoopConnected: false,
        syncBannerPhase: WhoopSyncBannerPhase.hidden,
        lastSyncedAt: null,
      ),
    );
  }
}
