import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/config/feature_flags.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/domain/params/week_plan_params.dart';

/// Новая версия UseCase для генерации недельного плана с использованием новой структуры API
@injectable
class GenerateWeekPlanUsecaseV2
    implements UseCase<WeekPlanEntity, WeekPlanParams> {
  GenerateWeekPlanUsecaseV2(this.chatRepository, this.requestPlanUsecaseV2);
  final ChatRepository chatRepository;
  final RequestPlanUsecaseV2 requestPlanUsecaseV2;

  @override
  Future<Either<Failure, WeekPlanEntity>> call(WeekPlanParams params) async {
    if (kUseAsyncWeeklyMealPlan) {
      return chatRepository.requestWeeklyMealPlanViaTask(params: params);
    }

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

        // Используем новый UseCase с новой структурой API
        final result = await requestPlanUsecaseV2(dayParams);

        final plan = result.fold(
          (failure) => throw Exception(
            'Failed to generate meal plan for day ${i + 1}: $failure',
          ),
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

      // Проверяем полноту плана и добиваем недостающие блюда
      final completedPlans = await _completeIncompletePlansV2(
        weekPlans,
        params,
        generatedMeals,
      );

      // ✅ Отладочные логи для проверки userId
      final currentUserId = userBloc.state.user.directusId;
      print(
          '[GenerateWeekPlanUsecaseV2] Создание WeekPlanEntity с userId: $currentUserId');
      print(
          '[GenerateWeekPlanUsecaseV2] Пользователь авторизован: ${currentUserId != '-1'}');

      return Right(
        WeekPlanEntity.create(
          userId: currentUserId,
          plans: completedPlans,
          startDate: params.startDate,
        ),
      );
    } catch (e) {
      return Left(
        WeekPlanGenerationFailure('Failed to generate week plan: $e'),
      );
    }
  }

  Future<List<MealPlanEntity>> _completeIncompletePlansV2(
    List<MealPlanEntity> plans,
    WeekPlanParams params,
    Map<String, List<String>> generatedMeals,
  ) async {
    final List<MealPlanEntity> completedPlans = [];

    for (int i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final expectedMealsCount = params.servings.length;

      if (plan.meals.length < expectedMealsCount) {
        print(
          '[GenerateWeekPlanUsecaseV2] Found incomplete plan for day ${i + 1}. Expected $expectedMealsCount meals, got ${plan.meals.length}',
        );

        // Создаем новый план для добивки
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

        final result = await requestPlanUsecaseV2(dayParams);

        final newPlan = result.fold(
          (failure) {
            print(
              '[GenerateWeekPlanUsecaseV2] Failed to complete plan for day ${i + 1}: $failure',
            );
            return plan; // Если не удалось сгенерировать новый план, оставляем старый
          },
          (success) {
            // Обновляем список исключений
            for (final meal in success.meals) {
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
            return success;
          },
        );

        completedPlans.add(newPlan);
      } else {
        completedPlans.add(plan);
      }
    }

    return completedPlans;
  }
}
