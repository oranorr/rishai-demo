import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/core/key.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/domain/usecases/change_modificatorOrSex_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/connect_whoop_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_body_data_usecase.dart';
import 'package:rishai/features/whoop/domain/usecases/get_data_usecase.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';
import '../../../../core/di/injectable.dart';

part 'whoop_event.dart';

final whoopBloc = getIt.get<WhoopBloc>();

@injectable
class WhoopBloc extends Bloc<WhoopEvent, WhoopState> {
  final ConnectWhoopUsecase connectWhoopUsecase;
  final WhoopGetDataUsecase getDataUsecase;
  final WhoopGetBodyData getBodyUsecase;
  final ChangeModificatorOrSexUsecase changeModificatorOrSexUsecase;
  WhoopBloc(
    this.connectWhoopUsecase,
    this.getDataUsecase,
    this.getBodyUsecase,
    this.changeModificatorOrSexUsecase,
  ) : super(WhoopMainState(
          status: Status.initial,
          day: DayEntity(
            snap: ChatSnapshotEntity(
              messages: [],
              date: DateTime.now(),
              requestsLeft: chatBloc.state.requestsLeft,
            ),
            directusId: 0,
            dateTime: DateTime.now(),
            weekTdeeAverage: 0,
            macros: MacrosBreakdown(kcal: 0, protein: 0, carbs: 0, fat: 0),
            healthMetrics: HealthMetricsEntity(
                bmi: 0, lastTdee: 0, bmr: 0, bodyFatPerc: 0),
          ),
          whoopConnected: false,
        )) {
    on<WhoopConnectEvent>(_connectWhoop);
    on<WhoopGetUserData>(_getUserData);
    on<InitWhoopOnLogin>(_initWhoopOnLogin);
    on<WhoopUserCalibrating>(_userCalibrating);
    on<WhoopRetrieveBodyData>(_getBodyData);
    on<WhoopChangeModificatorOrSex>(_changedModificatorOrSex);
    on<WhoopUpdateDayByMealPlan>(_updateDayByMeal);
  }

  FutureOr<void> _connectWhoop(
      WhoopConnectEvent event, Emitter<WhoopState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final res = await connectWhoopUsecase.call(const NoParams());
    bool success = false;

    res.fold((fail) {
      RishSnackbar().showSnackBar(fail.message);
      emit(state.copyWith(status: Status.error));
    }, (_) async {
      success = true;
    });

    if (success) {
      await _getBodyData(WhoopRetrieveBodyData(), emit);

      appNavigationService.go(
          path: userBloc.state.user.needsQuestionary
              ? AppRoutes.questionary.path
              : AppRoutes.homeScreen.path);
      emit(state.copyWith(status: Status.initial));
    }
  }

  FutureOr<void> _getUserData(
      WhoopGetUserData event, Emitter<WhoopState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final res = await getDataUsecase.call(GetDataParams(
        gender: event.gender,
        goal: event.goal,
        userId: userBloc.state.user.directusId));

    res.fold((l) async {
      emit(state.copyWith(status: Status.error));
      if (l.runtimeType == WhoopNoDataFailure) {
        add(const WhoopUserCalibrating(needsRedirect: true));
        emit(state.copyWith(status: Status.initial));
        if (state.calibratingCompleteDate != null) {
          return;
        }
        return;
      } else {
        RishSnackbar().showSnackBar(l.message.toString());
        emit(state.copyWith(status: Status.initial));
      }
    }, (r) {
      log('GET USER DATA RES: $r');
      emit(
        state.copyWith(
          day: state.day.copyWith(
              macros: r.macros,
              weekTdeeAverage: r.weekTdeeAverage,
              healthMetrics: calcHealthMetrics(r.lastTdee)),
          status: Status.success,
        ),
      );
      print('is it here?!');
      // userBloc.add(
      //   UserManageDay(
      //     day: state.day.copyWith(
      //       snap: ChatSnapshotEntity(
      //         messages: [],
      //         date: DateTime.now(),
      //         requestsLeft: chatBloc.state.requestsLeft,
      //       ),
      //     ),
      //   ),
      // );
    });
  }

  FutureOr<void> _initWhoopOnLogin(
      InitWhoopOnLogin event, Emitter<WhoopState> emit) async {
    try {
      emit(state.copyWith(status: Status.loading));
      UserEntity user = userBloc.state.user;
      final isTokenOk = await wTokenService.initService();
      log('INIT TOKEN SERVICE RES: $isTokenOk');

      if (!isTokenOk) {
        appNavigationService.go(path: AppRoutes.whoopConnect.path);
        emit(state.copyWith(status: Status.initial));
        return;
      }

      if (user.bodyMeasurements == null) {
        log('retrieveing body data');
        await _getBodyData(WhoopRetrieveBodyData(), emit);
      }

      if (!user.needsQuestionary) {
        log('retrieveing data');
        appNavigationService.go(path: AppRoutes.redirect.path);

        await _getUserData(
            WhoopGetUserData(user.gender!, user.userGoal!), emit);

        if (state.status != Status.loading && state.status != Status.error) {
          userBloc.add(UserGetDays());
          appNavigationService.go(path: AppRoutes.homeScreen.path);
          emit(state.copyWith(status: Status.success));
          return;
        }
      } else {
        appNavigationService.go(path: AppRoutes.questionary.path);
        emit(state.copyWith(status: Status.initial));
      }
    } on Exception catch (e) {
      RishSnackbar().showSnackBar(e.toString());
    }
  }

  Future<void> _userCalibrating(
      WhoopUserCalibrating event, Emitter<WhoopState> emit) async {
    emit(state.copyWith(status: Status.initial));
    final remaining = await prefsRepo.calibratingDate();
    // Ожидание паузы
    await Future.delayed(Durations.short1);
    emit(state.copyWith(calibratingCompleteDate: remaining));

    if (event.needsRedirect! && remaining != null) {
      appNavigationService.go(path: AppRoutes.calibratingScreen.path);
    } else {
      print('hei');
    }
  }

  FutureOr<void> _getBodyData(
      WhoopRetrieveBodyData event, Emitter<WhoopState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final bodyRes = await getBodyUsecase.call(const NoParams());
    bodyRes.fold((l) async {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(
          'Failed to retrieve body data: ${l.message}, retrying...');
      add(WhoopRetrieveBodyData());
    }, (r) async {
      UserEntity user = userBloc.state.user;
      final upd = user.copyWith(bodyMeasurements: r);
      emit(state.copyWith(
        status: Status.success,
      ));
      userBloc.add(UpdateUserEvent(user: upd));
    });
  }

  FutureOr<void> _changedModificatorOrSex(
      WhoopChangeModificatorOrSex event, Emitter<WhoopState> emit) async {
    final res = await changeModificatorOrSexUsecase.call(
        ChangeModificatorOrSexParams(
            modificator: event.modificator,
            gender: event.gender,
            weekTdeeAverage: state.day.weekTdeeAverage,
            userId: userBloc.state.user.directusId,
            lastTdee: state.day.healthMetrics.lastTdee));

    res.fold((failure) {
      if (failure.runtimeType == WhoopDataDueToRefresh) {
        // RishiDialog.showCustomDialog(
        //   event.context,
        //   type: DialogType.info,
        //   actionDialogType: ActionDialogType.warning,
        //   text: failure.message,
        //   action: () {
        //     // event.context.pop();
        //     // event.context.pop();
        //     // event.context.pushReplacement(AppRoutes.splah.path);
        //     // appNavigationService.go(path: AppRoutes.splah.path);
        //   },
        // );
      }
    }, (macros) {
      emit(state.copyWith(day: state.day.copyWith(macros: macros)));
      userBloc.add(UserManageDay(day: state.day));
    });
  }

  HealthMetricsEntity calcHealthMetrics(int lastTdee) {
    int calcBMI() {
      BodyMeasurementsEntity bm = userBloc.state.user.bodyMeasurements!;
      return (bm.weight / (bm.height * bm.height)).round();
    }

    int calcBMR() {
      final user = userBloc.state.user;
      final s = user.gender == Gender.male ? 5 : -161;
      final res = (10 * user.bodyMeasurements!.weight) +
          (6.25 * (user.bodyMeasurements!.height * 100)) -
          (5 * user.age!) +
          s;

      return res.round();
    }

    return HealthMetricsEntity(
      bmi: calcBMI(),
      lastTdee: lastTdee,
      bmr: calcBMR(),
      bodyFatPerc: 0,
    );
  }

  (double proteinPer, double carbsPer, double fatsPar) calculatePercentage() {
    //proteinKcal * 100 / kcal
    int proteinKcal = state.day.macros.protein * 4;
    int carbsKcal = state.day.macros.carbs * 4;
    int fatsKcal = state.day.macros.fat * 9;

    final proteinPerc = proteinKcal / state.day.macros.kcal;
    final carbsPerc = carbsKcal / state.day.macros.kcal;
    final fatsPerc = fatsKcal / state.day.macros.kcal;

    return (
      proteinPerc.toPrecision(),
      carbsPerc.toPrecision(),
      fatsPerc.toPrecision()
    );
  }

  FutureOr<void> _updateDayByMeal(
      WhoopUpdateDayByMealPlan event, Emitter<WhoopState> emit) {
    emit(state.copyWith(
        day: state.day.copyWith(mealPlanEntity: event.mealPlanEntity)));
    userBloc.add(UserManageDay(
        day: state.day.copyWith(
            snap: ChatSnapshotEntity(
      messages: [],
      date: DateTime.now(),
      requestsLeft: chatBloc.state.requestsLeft,
    ))));
  }
}
