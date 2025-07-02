import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateUser({required UserEntity user});

  Future<Either<Failure, void>> updateDayWithMealPlan({
    required String userId,
    required ChatSnapshotEntity snapshot,
    required MealPlanEntity mealPlan,
  });

  /// Получить все дни пользователя (новая упрощенная архитектура)
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  });
}
