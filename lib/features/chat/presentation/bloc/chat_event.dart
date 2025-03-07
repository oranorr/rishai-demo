// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatSendMessage extends ChatEvent {
  final String text;
  final bool? isMe;
  final bool? isRequest;
  const ChatSendMessage({
    required this.text,
    this.isMe,
    this.isRequest,
  });
}

class CreateMealPlan extends ChatEvent {
  final List<ServingEntity> meals;
  final bool snackToday;
  final bool trainingToday;
  const CreateMealPlan({
    required this.meals,
    required this.snackToday,
    required this.trainingToday,
  });

  @override
  String toString() =>
      'CreateMealPlan(meals: $meals, snackToday: $snackToday, trainingToday: $trainingToday)';
}

class InitChatBloc extends ChatEvent {
  final String directusId;
  const InitChatBloc({required this.directusId});
}

class ChatSaveSnap extends ChatEvent {
  final String directusId;
  const ChatSaveSnap({required this.directusId});
}

class ChatDeleteMealPlan extends ChatEvent {}

class ChatFetchLastMealPlan extends ChatEvent {
  final DayEntity day;
  const ChatFetchLastMealPlan({
    required this.day,
  });
}

class ChatOnLogout extends ChatEvent {
  final bool needsCounterClear;
  const ChatOnLogout({
    required this.needsCounterClear,
  });
}

class ChatRefreshChat extends ChatEvent {
  final bool needsRequestsAmountRefresh;
  final bool messagesRefresh;
  const ChatRefreshChat({
    required this.needsRequestsAmountRefresh,
    required this.messagesRefresh,
  });
}

class ChatReplaceMeal extends ChatEvent {
  final Meal meal;
  const ChatReplaceMeal({
    required this.meal,
  });
}

class ChatReplaceIngredient extends ChatEvent {
  final Meal meal;
  final List<Ingredient> ingredients;
  const ChatReplaceIngredient({
    required this.meal,
    required this.ingredients,
  });
}

class ChatSyncWithSelectedDate extends ChatEvent {}
