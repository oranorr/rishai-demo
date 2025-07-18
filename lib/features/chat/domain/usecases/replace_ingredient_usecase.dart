// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';

@injectable
class ReplaceIngredientUsecase
    implements UseCase<Meal, ReplaceIngredientParams> {
  final ChatRepository repository;
  ReplaceIngredientUsecase(this.repository);

  @override
  Future<Either<Failure, Meal>> call(
    ReplaceIngredientParams params,
  ) async {
    return repository.replaceIngredient(params: params);
  }
}

class ReplaceIngredientParams {
  final Meal meal;
  final List<Ingredient> ingredients;
  final FoodPreferences preferences;

  ReplaceIngredientParams({
    required this.ingredients,
    required this.meal,
    required this.preferences,
  });
}

/// Новый UseCase для замены ингредиентов с использованием новой структуры API V2
@injectable
class ReplaceIngredientUsecaseV2
    implements UseCase<Meal, ReplaceIngredientParams> {
  ReplaceIngredientUsecaseV2(this.repository);
  final ChatRepository repository;

  @override
  Future<Either<Failure, Meal>> call(
    ReplaceIngredientParams params,
  ) async {
    return repository.replaceIngredientV2(params: params);
  }
}
