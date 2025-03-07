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
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
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
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart'
    show whoopRemote;
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificator_or_sex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/disconnect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'whoop_event.dart';

final whoopBloc = getIt.get<WhoopBloc>();
final chatRemoteSrc = chat_remote.chatRemoteSrc;
final chatRepo = chat_repo.chatRepo;

@injectable
class WhoopBloc extends Bloc<WhoopEvent, WhoopState> {
  WhoopBloc(
    this.connectWhoopUsecase,
    this.getDataUsecase,
    this.getBodyUsecase,
    this.changeModificatorOrSexUsecase,
    this.disconnectWhoopUsecase,
    this.manageDayUsecase,
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
    on<WhoopChangeModificatorOrSex>(_changedModificatorOrSex);
    on<WhoopUpdateDayByMealPlan>(_updateDayByMealPlan);
    on<WhoopDisconnect>(_disconnect);
    on<WhoopCheckForRefresh>(_checkForRefresh);
    on<WhoopUpdateCurrentDay>(_updateCurrentDay);
  }
  final ConnectWhoopUsecase connectWhoopUsecase;
  final WhoopGetDataUsecase getDataUsecase;
  final WhoopGetBodyData getBodyUsecase;
  final ChangeModificatorOrSexUsecase changeModificatorOrSexUsecase;
  final DisconnectWhoopUsecase disconnectWhoopUsecase;
  final ManageDayUsecase manageDayUsecase;

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
      await _getBodyData(WhoopRetrieveBodyData(), emit);
      if (!needsQuestionary) {
        await _initWhoopOnLogin(InitWhoopOnLogin(), emit);
      }
      await Future.delayed(Durations.medium1, () {
        appNavigationService.go(
          path: needsQuestionary
              ? AppRoutes.questionary.path
              // : adapty.isActive
              : true
                  ? AppRoutes.homeScreen.path
                  : AppRoutes.paywall.path,
        );
        emit(state.copyWith(status: Status.initial));
      });
    }
  }

  FutureOr<void> _getUserData(
    WhoopGetUserData event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    final res = await getDataUsecase.call(
      GetDataParams(
        gender: event.gender,
        goal: event.goal,
        userId: userBloc.state.user.directusId,
      ),
    );

    await res.fold((l) async {
      emit(state.copyWith(status: Status.error));
      if (l.runtimeType == WhoopNoDataFailure) {
        add(const WhoopUserCalibrating(needsRedirect: true));
        emit(state.copyWith(status: Status.initial));
        if (state.calibratingCompleteDate != null) {
          return;
        }
        return;
      } else {
        RishSnackbar().showSnackBar(l.message);
        emit(state.copyWith(status: Status.initial));
      }
    }, (r) async {
      log('GET USER DATA RES: $r');

      // Обновляем состояние
      emit(
        state.copyWith(
          day: r,
          status: Status.success,
        ),
      );

      // Обновляем кэш чата за последние 7 дней только если это не инициализация
      if (!event.isInitializing) {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        await chatRepo.updateChatCache(
          directusId: userBloc.state.user.directusId,
          startDate: sevenDaysAgo,
          endDate: now,
        );
      }

      return;
    });
    return;
  }

  FutureOr<void> _initWhoopOnLogin(
    InitWhoopOnLogin event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      emit(state.copyWith(status: Status.loading));
      UserEntity user = userBloc.state.user;
      final isTokenOk = await wTokenService.initService();

      emit(state.copyWith(whoopConnected: isTokenOk));
      log('INIT TOKEN SERVICE RES: $isTokenOk');

      if (!isTokenOk) {
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
        emit(state.copyWith(status: Status.initial));
        return;
      }

      log('retrieveing BODY data');
      await _getBodyData(WhoopRetrieveBodyData(), emit);

      if (!user.needsQuestionary) {
        log('retrieveing data');
        appNavigationService.go(path: AppRoutes.redirect.path);

        await _getUserData(
          WhoopGetUserData(
            user.gender!,
            user.userGoal!,
            isInitializing: true,
          ),
          emit,
        );

        if (state.status != Status.loading && state.status != Status.error) {
          // Инициализируем чат и получаем дни в правильном порядке
          chatBloc.add(InitChatBloc(directusId: user.directusId));
          userBloc.add(UserGetDays(newDay: state.day));

          appNavigationService.go(
            path: true ? AppRoutes.homeScreen.path : AppRoutes.paywall.path,
          );
          emit(state.copyWith(status: Status.success));
          return;
        }
      } else {
        appNavigationService.go(path: AppRoutes.questionary.path);
        emit(state.copyWith(status: Status.initial));
        return;
      }
    } on Exception catch (e) {
      RishSnackbar().showSnackBar(e.toString());
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
      RishSnackbar().showSnackBar(
        'Failed to retrieve body data: ${l.message}, retrying...',
      );
      add(WhoopRetrieveBodyData());
    }, (r) async {
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

  FutureOr<void> _changedModificatorOrSex(
    WhoopChangeModificatorOrSex event,
    Emitter<WhoopState> emit,
  ) async {
    final user = userBloc.state.user;
    bool success = false;
    String errorMessage = 'Error happened. Please, try again';
    final res = await changeModificatorOrSexUsecase.call(
      ChangeModificatorOrSexParams(
        modificator: event.modificator,
        gender: event.gender,
        weekTdeeAverage: state.day.weekTdeeAverage,
        userId: user.directusId,
        lastTdee: state.day.healthMetrics.lastTdee,
      ),
    );

    await res.fold((failure) async {
      if (failure.runtimeType == WhoopDataDueToRefresh) {
        success = false;
        errorMessage = failure.message;
      }
    }, (macros) {
      success = true;
      emit(state.copyWith(day: state.day.copyWith(macros: macros)));
      userBloc.add(UserManageDay(day: state.day));
    });

    if (!success) {
      await RishiDialog.showCustomDialog(
        event.context,
        isDissmissable: false,
        type: DialogType.info,
        actionDialogType: ActionDialogType.warning,
        text: errorMessage,
        action: () async {
          appNavigationService.go(path: AppRoutes.redirect.path);
        },
      );
      await _initWhoopOnLogin(InitWhoopOnLogin(), emit);
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
      final data =
          updatedDay.toDirectus(userId: userBloc.state.user.directusId);
      await manageDayUsecase.call(
        ManageDayParams(
          userId: userBloc.state.user.directusId,
          dayMap: data,
          incomingDay: updatedDay,
        ),
      );

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
        emit(state.copyWith(status: Status.success));
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
      });
    } on Exception catch (e) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(
        'Error disconnecting your WHOOP account. Please, try again. Error: $e',
      );
    }
  }

  FutureOr<void> _checkForRefresh(
    WhoopCheckForRefresh event,
    Emitter<WhoopState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    final isThereFreshData =
        await whoopRemote.pingLastCycle(cycleId: state.day.cycleId);

    if (isThereFreshData) {
      // Сначала делаем редирект на экран загрузки
      appNavigationService.go(path: AppRoutes.redirect.path);

      final result = await getDataUsecase.call(
        GetDataParams(
          gender: userBloc.state.user.gender!,
          goal: userBloc.state.user.userGoal!,
          userId: userBloc.state.user.directusId,
        ),
      );

      await result.fold(
        (failure) {
          emit(state.copyWith(status: Status.error));
          appNavigationService.go(path: AppRoutes.homeScreen.path);
        },
        (newDay) async {
          // Сохраняем существующий план питания и снапшот
          final existingMealPlan = state.day.mealPlanEntity;
          final existingSnap = state.day.snap;

          // Обновляем день, сохраняя существующие данные
          final updatedDay = newDay.copyWith(
            mealPlanEntity: existingMealPlan,
            snap: existingSnap,
          );

          // Обновляем состояние блока
          emit(state.copyWith(day: updatedDay));

          // Обновляем список дней
          userBloc.add(UserGetDays(newDay: updatedDay));

          // Синхронизируем состояние чата с выбранной датой
          chatBloc.add(ChatSyncWithSelectedDate());

          // Обновляем кэш чата за последние 7 дней
          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          await chatRepo.updateChatCache(
            directusId: userBloc.state.user.directusId,
            startDate: sevenDaysAgo,
            endDate: now,
          );

          // Завершаем загрузку и возвращаемся на главный экран
          emit(state.copyWith(status: Status.success));
          appNavigationService.go(path: AppRoutes.homeScreen.path);

          // Показываем уведомление об успешном обновлении
          RishSnackbar().showSnackBar('Your data has been updated');
        },
      );
    } else {
      if (event.needsErrorSnack) {
        RishSnackbar().showWarningSnackBar(message: 'Your data is up to date');
      }
      emit(state.copyWith(status: Status.initial));
    }
  }

  FutureOr<void> _updateCurrentDay(
    WhoopUpdateCurrentDay event,
    Emitter<WhoopState> emit,
  ) async {
    try {
      // Обновляем текущий день
      emit(state.copyWith(day: event.day));

      // Если план питания был очищен, обновляем в Directus
      if (state.day.mealPlanEntity != null &&
          event.day.mealPlanEntity == null) {
        final data =
            event.day.toDirectus(userId: userBloc.state.user.directusId);
        await manageDayUsecase.call(
          ManageDayParams(
            userId: userBloc.state.user.directusId,
            dayMap: data,
            incomingDay: event.day,
          ),
        );
      }

      // Синхронизируем чат с новым днем
      chatBloc.add(ChatSyncWithSelectedDate());
    } catch (e) {
      log('Error updating current day: $e');
      RishSnackbar().showSnackBar('Failed to update day. Please try again.');
    }
  }
}
