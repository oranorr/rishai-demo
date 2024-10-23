import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:directus/directus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
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
import 'package:rishai/features/user/domain/usecases/update_user_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

import '../../../../core/errors/failure.dart';
import '../../../whoop/presentation/bloc/whoop_bloc.dart';

part 'user_event.dart';

final userBloc = getIt.get<UserBloc>();
int daysPerPage = kDebugMode ? 3 : 5;

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final UpdateUserUsecase updateUserUsecase;
  UserBloc(
    this.updateUserUsecase,
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

  FutureOr<void> _updateUser(
      UpdateUserEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(user: event.user, status: Status.loading));
    final res = await updateUserUsecase.call(event.user);
    res.fold((Failure fail) {
      log(fail.toString());
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar('Updating failed, please try again.');
    }, (_) {
      log('User successfully updated!');
      emit(state.copyWith(status: Status.success));
    });
  }

  FutureOr<void> _checkForSavedUser(
      CheckForSavedUser event, Emitter<UserState> emit) async {
    UserEntity? user = await hive.retrieveSavedUser();
    final watchedOnboard = prefsRepo.checkForWatchedOnboard();

    if (user != null) {
      final rawUser = await directus.readOne(
          collection: usersCollection, id: user.directusId);
      final List<int> ids = List.from(rawUser['days']).cast<int>();
      if (user.daysIds != ids) {
        user = user.copyWith(daysIds: ids);
      }
      emit(state.copyWith(user: user));
      add(const UserCheckForRecomp());
      whoopBloc.add(InitWhoopOnLogin());
      chatBloc.add(InitChatBloc());
      // await _getDays(UserGetDays(), emit);
    } else {
      appNavigationService.go(
        path: !watchedOnboard ? AppRoutes.onboard.path : AppRoutes.login.path,
      );
    }
  }

  FutureOr<void> _createUserOnLogin(
      CreateUserOnLogin event, Emitter<UserState> emit) async {
    emit(state.copyWith(user: event.user));
  }

  FutureOr<void> _deleteAccount(
      UserDeleteAccount event, Emitter<UserState> emit) async {
    await directus.deleteOne(
        collection: usersCollection, id: state.user.directusId);
    loginBloc.add(LogoutEvent());
  }

  FutureOr<void> _checkForRecomp(
      UserCheckForRecomp event, Emitter<UserState> emit) async {
    if (state.user.userGoal?.goal != null &&
        state.user.userGoal?.goal == GoalType.recomp) {
      UserGoal goal = state.user.userGoal!;

      final diff = DateTime.now().difference(goal.updatedAt);

      if (recompDifference(diff)) {
        UserGoal updGoal = goal.copyWith(
            modificator: goal.modificator > 0 ? -0.05 : 0.05,
            updatedAt: DateTime.now());
        UserEntity userUpd = state.user.copyWith(userGoal: updGoal);
        add(UpdateUserEvent(user: userUpd));
      } else {}
    }
  }

  FutureOr<void> _manageDay(
      UserManageDay event, Emitter<UserState> emit) async {
    final day = event.day.copyWith(mealPlanEntity: chatBloc.state.mealPlan);
    final data = day.toDirectus(userId: state.user.directusId);

    final rawUser = await directus.readOne(
        collection: usersCollection, id: state.user.directusId);
    final List<int> ids = List.from(rawUser['days']).cast<int>();

    if (ids.isEmpty) {
      await directus.createOne(collection: daysCollection, data: data);
      log('Day is created');
      return;
    }
    final lastRecord = await directus.readOne(
        collection: daysCollection, id: ids.last.toString());

    final lastDate =
        DateTime.fromMillisecondsSinceEpoch(int.parse(lastRecord['dateTime']));

    if (lastDate.isSameDate(DateTime.now())) {
      final lastEntity = DayEntity.fromMap(lastRecord);

      if ((lastEntity.mealPlanEntity != event.day.mealPlanEntity &&
              event.day.mealPlanEntity != null) ||
          lastEntity.macros != event.day.macros ||
          lastEntity.snap != event.day.snap) {
        log('Day is updating');
        await directus.updateOne(
            collection: daysCollection,
            itemId: lastRecord['id'].toString(),
            updateData: data);
      }
      log('Day is not updating');
      return;
    } else {
      await directus.createOne(collection: daysCollection, data: data);
      log('Day is created');
    }
  }

  FutureOr<void> _getDays(UserGetDays event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading));
    DayEntity currentDay = whoopBloc.state.day;
    final ids = state.user.daysIds;

    if (ids.isEmpty) {
      emit(state.copyWith(status: Status.success, days: [currentDay]));
      return;
    }
    final rawList = await directus.readMany(
        collection: daysCollection, filters: Filters({'id': F.isIn(ids)}));
    final days = rawList.map((map) => DayEntity.fromMap(map)).toList();

    if (days.last.dateTime.isSameDate(DateTime.now())) {
      if (days.last.mealPlanEntity != null) {
        chatBloc.add(ChatFetchLastMealPlan(day: days.last));
      }
      days.removeLast();
    }

    days.add(currentDay);
    emit(state.copyWith(status: Status.success, days: days));
    // chatBloc.add(InitChatBloc(
    //     requestsLeft: currentDay.snap.requestsLeft > days.last.snap.requestsLeft
    //         ? days.last.snap.requestsLeft
    //         : currentDay.snap.requestsLeft));
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
      controller.animateToPage(searchIndex,
          duration: Durations.medium1, curve: Curves.ease);
    }
  }

  Future<void> createMockData(DayEntity day) async {
    // print('hi');
    // await directus.createMany(
    //     collection: daysCollection, data: day.mockDays(length: 60, id: '111'));
    // print('done');
  }
}
