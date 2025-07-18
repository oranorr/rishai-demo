import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';

abstract class ChatRemoteDataSource {
  Future<bool> initGpt(String? savedThreadId);

  /// Новый метод для запроса планов питания с использованием новой структуры API
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
}
