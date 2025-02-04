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
  const WhoopGetUserData(
    this.gender,
    this.goal,
  );
}

class InitWhoopOnLogin extends WhoopEvent {}

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

class WhoopUpdateDayByMealPlan extends WhoopEvent {
  final MealPlanEntity mealPlanEntity;
  const WhoopUpdateDayByMealPlan({
    required this.mealPlanEntity,
  });
}

class WhoopDisconnect extends WhoopEvent {}

class WhoopCheckForRefresh extends WhoopEvent {}
