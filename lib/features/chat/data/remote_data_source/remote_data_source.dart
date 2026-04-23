import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';

abstract class ChatRemoteDataSource {
  Future<bool> initGpt(String? savedThreadId);

  /// Legacy путь генерации плана питания (клиентская оркестрация LLM).
  ///
  /// Для дневного плана предпочтительнее async tasks на backend
  /// (см. `FRONTEND_DAILY_MEAL_PLAN_MIGRATION.md`).
  @Deprecated(
    'Legacy client-side orchestration. Use async daily meal plan tasks on backend.',
  )
  Future<Map<String, dynamic>> requestMealPlanV2(
    List<LlmMealRequest> requests,
    bool isWeekPlan,
  );

  Future<String?> sendMessage(String userMessage);
  Future<Map<String, dynamic>?> fetchLastChatSnap(
    String directusId,
    DateTime date,
  );
  String? get threadId;
  set threadId(String? value);
  Future<void> closeGpt();
  Future<Meal?> replaceMeal(ReplaceMealParams params);
  Future<Meal?> replaceIngredient(ReplaceIngredientParams params);

  /// Новые методы для регенерации блюд с использованием новой структуры API V2
  Future<Meal?> replaceMealV2(ReplaceMealParams params);
  Future<Meal?> replaceIngredientV2(ReplaceIngredientParams params);

  /// Добавляет текущий план питания в контекст чата ассистента.
  ///
  /// Нужен для миграции на async генерацию (meal plan создаётся на backend),
  /// чтобы сохранить паритет с предыдущим пайплайном, где этот шаг выполнялся
  /// внутри `requestMealPlanV2`.
  Future<void> sendMealPlanToAssistantChat(MealPlanEntity mealPlan);
}
