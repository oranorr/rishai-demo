// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';

@injectable
class ReplaceMealUsecase implements UseCase<Meal, ReplaceMealParams> {
  ReplaceMealUsecase(this.chatRepository);
  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, Meal>> call(ReplaceMealParams params) async {
    return chatRepository.replaceMeal(params: params);
  }
}

class ReplaceMealParams {
  final Meal meal;
  final FoodPreferences foodPreferences;
  ReplaceMealParams({
    required this.meal,
    required this.foodPreferences,
  });
}
