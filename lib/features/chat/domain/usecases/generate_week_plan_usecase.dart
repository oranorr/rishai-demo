import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';

@injectable
class GenerateWeekPlanUsecase
    implements UseCase<WeekPlanEntity, WeekPlanParams> {
  GenerateWeekPlanUsecase(this.chatRepository, this.requestPlanUsecase);
  final ChatRepository chatRepository;
  final RequestPlanUsecase requestPlanUsecase;

  @override
  Future<Either<Failure, WeekPlanEntity>> call(WeekPlanParams params) async {
    try {
      final List<MealPlanEntity> weekPlans = [];
      final Map<String, List<String>> generatedMeals = {
        'breakfasts': [],
        'mains': [],
        'snacks': [],
      };

      for (int i = 0; i < 5; i++) {
        final dayParams = RequestPlanParams(
          dietary: params.dietary,
          cuisines: params.cuisines,
          restrictions: params.restrictions,
          calorieTarget: params.calorieTarget,
          macros: params.macros,
          trainingToday: params.hasTraining,
          servings: params.servings,
          snackForToday: params.hasSnack,
          isWeekPlan: true,
          excludedMeals: generatedMeals,
        );

        final result = await requestPlanUsecase(dayParams);

        final plan = result.fold(
          (failure) =>
              throw Exception('Failed to generate meal plan for day ${i + 1}'),
          (success) => success,
        );

        // Добавляем названия блюд в список исключений
        for (final meal in plan.meals) {
          switch (meal.servingType) {
            case ServingType.breakfast:
              generatedMeals['breakfasts']!.add(meal.title);
            case ServingType.snack:
              generatedMeals['snacks']!.add(meal.title);
            case ServingType.lunch:
            case ServingType.dinner:
            case ServingType.supper:
              generatedMeals['mains']!.add(meal.title);
          }
        }

        weekPlans.add(plan);

        if (i < 4) await Future.delayed(const Duration(seconds: 2));
      }

      return Right(
        WeekPlanEntity.create(plans: weekPlans, startDate: params.startDate),
      );
    } catch (e) {
      return const Left(
        WeekPlanGenerationFailure('Failed to generate week plan'),
      );
    }
  }

  // List<Map<ServingType, String>> _generatePrompts({
  //   required List<String> dietary,
  //   required List<String> cuisines,
  //   required List<String> restrictions,
  //   required int calorieTarget,
  //   required MacrosBreakdown macros,
  //   required bool hasTraining,
  //   required List<ServingEntity> servings,
  //   required bool hasSnack,
  // }) {
  //   final RequestPlanParams params = RequestPlanParams(
  //     dietary: dietary,
  //     cuisines: cuisines,
  //     restrictions: restrictions,
  //     calorieTarget: calorieTarget,
  //     macros: macros,
  //     trainingToday: hasTraining,
  //     servings: servings,
  //     snackForToday: hasSnack,
  //   );

  //   return params.generatePrompt();
  // }
}

class WeekPlanParams extends Equatable {
  const WeekPlanParams({
    required this.dietary,
    required this.cuisines,
    required this.restrictions,
    required this.calorieTarget,
    required this.macros,
    required this.hasTraining,
    required this.hasSnack,
    required this.servings,
    required this.startDate,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final List<String> restrictions;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool hasTraining;
  final bool hasSnack;
  final List<ServingEntity> servings;
  final DateTime startDate;

  @override
  List<Object?> get props => [
        dietary,
        cuisines,
        restrictions,
        calorieTarget,
        macros,
        hasTraining,
        hasSnack,
        servings,
        startDate,
      ];
}
