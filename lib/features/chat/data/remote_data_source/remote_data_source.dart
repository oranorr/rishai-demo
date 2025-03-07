import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';

abstract class ChatRemoteDataSource {
  Future<bool> initGpt(String? savedThreadId);
  Future<Map<String, dynamic>> requestMealPlan(
    List<Map<ServingType, String>> prompts,
    bool isWeekPlan,
  );

  Future<String?> sendMessage(String userMessage);
  Future<Map<String, dynamic>?> fetchLastChatSnap(String directusId,
      {DateTime? date});
  String? get threadId;
  set threadId(String? value);
  Future<void> closeGpt();
  Future<Meal?> replaceMeal(ReplaceMealParams params);
  Future<Meal?> replaceIngredient(ReplaceIngredientParams params);
}
