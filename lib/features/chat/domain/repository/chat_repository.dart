import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';

abstract interface class ChatRepository {
  Future<void> saveChatSnapShot({
    required ChatSnapshotEntity chatSnap,
    DateTime? date,
  });

  /// Новый метод для запроса планов питания с использованием новой структуры API
  Future<Either<Failure, MealPlanEntity>> requestMealPlanV2({
    required RequestPlanParams params,
  });

  Future<Either<Failure, void>> initGpt(String? threadId);
  Future<Either<Failure, String>> sendMessage(String userMessage);
  Future<Either<Failure, ChatSnapshotEntity?>> fetchSavedSnap({
    required String directusId,
    DateTime? targetDate,
  });
  Future<Either<Failure, Meal>> replaceMeal({
    required ReplaceMealParams params,
  });
  Future<Either<Failure, Meal>> replaceIngredient({
    required ReplaceIngredientParams params,
  });

  /// Новые методы для регенерации блюд с использованием новой структуры API V2
  Future<Either<Failure, Meal>> replaceMealV2({
    required ReplaceMealParams params,
  });

  Future<Either<Failure, Meal>> replaceIngredientV2({
    required ReplaceIngredientParams params,
  });

  Future<void> updateChatCache({
    required String directusId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
