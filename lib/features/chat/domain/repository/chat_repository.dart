import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';

abstract interface class ChatRepository {
  Future<void> saveChatSnapShot({required ChatSnapshotEntity chatSnap});
  Future<Either<Failure, MealPlanEntity>> requestMealPlan({
    required RequestPlanParams params,
  });
  Future<Either<Failure, void>> initGpt(String? threadId);
  Future<Either<Failure, String>> sendMessage(String userMessage);
  Future<Either<Failure, ChatSnapshotEntity?>> fetchSavedSnap({
    required String directusId,
  });
}
