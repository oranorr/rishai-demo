import 'dart:developer';

import 'package:directus/directus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/chat/domain/usecases/generate_week_plan_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';

part 'week_plan_event.dart';
part 'week_plan_state.dart';
part 'week_plan_bloc.freezed.dart';

final weekPlanBloc = getIt<WeekPlanBloc>();

@injectable
class WeekPlanBloc extends Bloc<WeekPlanEvent, WeekPlanState> {
  WeekPlanBloc(this._generateWeekPlanUsecase)
      : super(
          const WeekPlanState(
            weekPlans: [],
          ),
        ) {
    on<WeekPlanGenerate>(_onGenerate);
    on<WeekPlanReset>(_onReset);
    on<WeekPlanLoad>(_onLoad);
    on<WeekPlanClear>(_onClear);
  }

  final GenerateWeekPlanUsecase _generateWeekPlanUsecase;

  Future<void> _onGenerate(
    WeekPlanGenerate event,
    Emitter<WeekPlanState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
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
      List<WeekPlanEntity> weekPlans = List.from(state.weekPlans)..add(week);
      emit(state.copyWith(weekPlans: weekPlans, isLoading: false));
      await saveWeek(week);
    });
  }

  void _onReset(WeekPlanReset event, Emitter<WeekPlanState> emit) {
    emit(const WeekPlanState(weekPlans: []));
  }

  Future<void> _onLoad(WeekPlanLoad event, Emitter<WeekPlanState> emit) async {
    emit(state.copyWith(isLoading: true));
    final res = await getWeeks();
    emit(
      state.copyWith(
        weekPlans: res,
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
          await hive.saveWeekPlan(weekPlan: WeekPlanEntity.fromMap(e));
          return WeekPlanEntity.fromMap(e);
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

  void _onClear(WeekPlanClear event, Emitter<WeekPlanState> emit) {
    emit(const WeekPlanState(weekPlans: []));
  }
}
