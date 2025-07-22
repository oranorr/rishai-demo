// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'whoop_bloc.dart';

sealed class WhoopEvent extends Equatable {
  const WhoopEvent();

  @override
  List<Object> get props => [];
}

class WhoopConnectEvent extends WhoopEvent {
  final BuildContext context;
  const WhoopConnectEvent(
    this.context,
  );
}

class WhoopGetUserData extends WhoopEvent {
  final Gender gender;
  final UserGoal goal;
  final bool isInitializing;

  const WhoopGetUserData(
    this.gender,
    this.goal, {
    this.isInitializing = false,
  });
}

class InitWhoopOnLogin extends WhoopEvent {
  const InitWhoopOnLogin();
}

class WhoopUserCalibrating extends WhoopEvent {
  final bool? needsRedirect;
  const WhoopUserCalibrating({
    this.needsRedirect,
  });
}

class WhoopRetrieveBodyData extends WhoopEvent {}

class WhoopChangeModificatorOrSex extends WhoopEvent {
  final double modificator;
  final Gender gender;
  final BuildContext context;
  const WhoopChangeModificatorOrSex({
    required this.modificator,
    required this.gender,
    required this.context,
  });
}

class WhoopCheckDietChange extends WhoopEvent {
  final List<String> newDiets;
  final List<String> previousDiets;
  final BuildContext context;

  const WhoopCheckDietChange({
    required this.newDiets,
    required this.previousDiets,
    required this.context,
  });

  @override
  List<Object> get props => [newDiets, previousDiets, context];
}

class WhoopUpdateDayByMealPlan extends WhoopEvent {
  final MealPlanEntity mealPlanEntity;
  final ChatSnapshotEntity? snapshot;
  const WhoopUpdateDayByMealPlan({
    required this.mealPlanEntity,
    this.snapshot,
  });
}

class WhoopDisconnect extends WhoopEvent {}

class WhoopCheckForRefresh extends WhoopEvent {
  final bool needsErrorSnack;
  const WhoopCheckForRefresh({
    required this.needsErrorSnack,
  });
}

class WhoopUpdateCurrentDay extends WhoopEvent {
  final DayEntity day;
  const WhoopUpdateCurrentDay({required this.day});

  @override
  List<Object> get props => [day];
}
