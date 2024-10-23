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
  final int mealsAmount;
  final bool snackToday;
  final bool trainingToday;
  const CreateMealPlan({
    required this.mealsAmount,
    required this.snackToday,
    required this.trainingToday,
  });

  @override
  String toString() =>
      'CreateMealPlan(mealsAmount: $mealsAmount, snackToday: $snackToday, trainingToday: $trainingToday)';
}

class InitChatBloc extends ChatEvent {
  int? requestsLeft;
  InitChatBloc({
    this.requestsLeft,
  });
}

class ChatSaveSnap extends ChatEvent {}

class ChatDeleteMealPlan extends ChatEvent {}

class ChatFetchLastMealPlan extends ChatEvent {
  final DayEntity day;
  const ChatFetchLastMealPlan({
    required this.day,
  });
}

class ChatOnLogout extends ChatEvent {}
