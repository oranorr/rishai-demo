import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/domain/usecases/get_days_usecase.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/user/domain/usecases/update_user_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'user_event.dart';

final userBloc = getIt.get<UserBloc>();
// int daysPerPage = kDebugMode ? 3 : 5;

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(
    this.updateUserUsecase,
    this.getDaysUsecase,
    this.manageDayUsecase,
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
    on<UserGetDays>(_getDays);
  }

  final UpdateUserUsecase updateUserUsecase;
  final GetDaysUsecase getDaysUsecase;
  final ManageDayUsecase manageDayUsecase;

  FutureOr<void> _updateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    UserEntity user = event.user;
    if (user.adaptyId == null) {
      user = user.copyWith(
        adaptyId: adapty.generateAdaptyId(directusId: user.directusId),
      );
    }

    emit(state.copyWith(user: user, status: Status.loading));
    final res = await updateUserUsecase.call(user);
    await res.fold((Failure fail) async {
      log(fail.toString());
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar('Updating failed, please try again.');
    }, (_) async {
      log('User successfully updated!');
      emit(state.copyWith(status: Status.success));
      await adapty.identify(adaptyId: user.adaptyId!);
    });
  }

  FutureOr<void> _checkForSavedUser(
    CheckForSavedUser event,
    Emitter<UserState> emit,
  ) async {
    UserEntity? user = await hive.retrieveSavedUser();
    final watchedOnboard = prefsRepo.checkForWatchedOnboard();

    if (user != null) {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: user.directusId,
      );
      final List<int> ids = List.from(rawUser['days']).cast<int>();
      if (user.daysIds != ids) {
        user = user.copyWith(daysIds: ids);
      }
      await adapty.identify(adaptyId: user.adaptyId!);
      emit(state.copyWith(user: user));
      add(const UserCheckForRecomp());
      whoopBloc.add(InitWhoopOnLogin());
      chatBloc.add(const InitChatBloc());
      // await _getDays(UserGetDays(), emit);
    } else {
      appNavigationService.go(
        path: !watchedOnboard ? AppRoutes.onboard.path : AppRoutes.login.path,
      );
    }
  }

  FutureOr<void> _createUserOnLogin(
    CreateUserOnLogin event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(user: event.user));
  }

  FutureOr<void> _deleteAccount(
    UserDeleteAccount event,
    Emitter<UserState> emit,
  ) async {
    await directus.deleteOne(
      collection: usersCollection,
      id: state.user.directusId,
    );
    loginBloc.add(LogoutEvent());
  }

  FutureOr<void> _checkForRecomp(
    UserCheckForRecomp event,
    Emitter<UserState> emit,
  ) async {
    if (state.user.userGoal?.goal != null &&
        state.user.userGoal?.goal == GoalType.recomp) {
      UserGoal goal = state.user.userGoal!;

      final diff = DateTime.now().difference(goal.updatedAt);

      if (recompDifference(diff)) {
        UserGoal updGoal = goal.copyWith(
          modificator: goal.modificator > 0 ? -0.05 : 0.05,
          updatedAt: DateTime.now(),
        );
        UserEntity userUpd = state.user.copyWith(userGoal: updGoal);
        add(UpdateUserEvent(user: userUpd));
      } else {
        return;
      }
    }
  }

  FutureOr<void> _manageDay(
    UserManageDay event,
    Emitter<UserState> emit,
  ) async {
    final day = event.day.copyWith(mealPlanEntity: chatBloc.state.mealPlan);
    final data = day.toDirectus(userId: state.user.directusId);

    await manageDayUsecase.call(
      ManageDayParams(
        userId: state.user.directusId,
        dayMap: data,
        incomingDay: event.day,
      ),
    );
  }

  FutureOr<void> _getDays(UserGetDays event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading));
    DayEntity currentDay = whoopBloc.state.day;
    final ids = state.user.daysIds;

    if (ids.isEmpty) {
      emit(state.copyWith(status: Status.success, days: [currentDay]));
      return;
    }
    final res = await getDaysUsecase
        .call(GetDaysParams(daysIds: ids, userId: state.user.directusId));

    res.fold((l) {
      RishSnackbar()
          .showSnackBar('Error occured while fetching days. Please, restart.');
    }, (r) {
      emit(state.copyWith(status: Status.success, days: r));
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
}
