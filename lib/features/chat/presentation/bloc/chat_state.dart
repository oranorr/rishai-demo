import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';

part 'chat_state.freezed.dart';

@freezed
sealed class ChatState with _$ChatState {
  const factory ChatState.mainState({
    required final Status status,
    required final List<MessageEntity> messages,
    required final int requestsLeft,
    required final MealPlanEntity? mealPlan,
  }) = ChatMainState;

  // List<MessageEntity> get chat => messages.reversed.toList();
}
