import 'dart:developer';

import 'package:directus/directus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/generate_week_plan_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_filter_entity.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';

part 'week_plan_bloc.freezed.dart';
part 'week_plan_event.dart';
part 'week_plan_state.dart';

final weekPlanBloc = getIt<WeekPlanBloc>();

@injectable
class WeekPlanBloc extends Bloc<WeekPlanEvent, WeekPlanState> {
  WeekPlanBloc(this._generateWeekPlanUsecase)
      : super(
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
      RishSnackbar().showSnackBar('Failed to generate week plan, $failure');
    }, (week) async {
      print(
        'Generated ${week.plans.length} meal plans with dates ${week.startDate} - ${week.endDate}',
      );
      week = week.copyWith(
        fitnessGoal: userBloc.state.user.userGoal!.goal.name.capitalize(),
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
        ),
      );
      await saveWeek(week);
    });
  }

  void _onReset(WeekPlanReset event, Emitter<WeekPlanState> emit) {
    emit(const WeekPlanState(allWeekPlans: [], displayWeekPlans: []));
  }

  Future<void> _onLoad(WeekPlanLoad event, Emitter<WeekPlanState> emit) async {
    emit(state.copyWith(isLoading: true, filter: null));
    final res = await getWeeks();
    emit(
      state.copyWith(
        allWeekPlans: res,
        displayWeekPlans: res,
        isLoading: false,
      ),
    );
  }

  Future<void> saveWeek(WeekPlanEntity week) async {
    await hive.saveWeekPlan(weekPlan: week);
    await directus.createOne(
      collection: weekPlanCollection,
      data: week.toMap(userId: userBloc.state.user.directusId),
    );
  }

  Future<List<WeekPlanEntity>> getWeeks() async {
    final weeks = await hive.retrieveWeekPlan();
    if (weeks != null && weeks.isNotEmpty) {
      _logger('Retrieved ${weeks.length} weeks from hive');
      return weeks;
    } else {
      final weeks = await directus.readMany(
        collection: weekPlanCollection,
        filters: Filters(
          {
            'userId': F.eq(
              userBloc.state.user.directusId,
            ),
          },
        ),
      );
      if (weeks.isNotEmpty) {
        _logger('Retrieved ${weeks.length} weeks from Directus');
        final weekPlans = weeks.map((e) async {
          final weekPlan = WeekPlanEntity.fromMap(e);
          await hive.saveWeekPlan(weekPlan: weekPlan);
          return weekPlan;
        }).toList();

        return Future.wait(weekPlans);
      }
      _logger('No weeks found in Directus or Hive');
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
        goalMatch =
            filter.fitnessGoal.any((goal) => plan.fitnessGoal.contains(goal));
      }

      return dateMatch && goalMatch && dietMatch;
    }).toList();
  }

  Future<void> _onFilter(
    WeekPlanFilter event,
    Emitter<WeekPlanState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, filter: event.filter));
    final filteredPlans = _applyFilter(state.allWeekPlans, event.filter);
    emit(state.copyWith(displayWeekPlans: filteredPlans, isLoading: false));
  }

  Future<void> _onClearFilter(
    WeekPlanClearFilter event,
    Emitter<WeekPlanState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        filter: null,
      ),
    );
    emit(
      state.copyWith(
        displayWeekPlans: state.allWeekPlans,
        isLoading: false,
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
