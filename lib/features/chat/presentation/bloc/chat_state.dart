// ignore: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:equatable/equatable.dart';

const int defaultRequestsLimit = 5;

@immutable
abstract class ChatState extends Equatable {
  const ChatState({
    required this.status,
    required this.messages,
    required this.requestsLeft,
  });

  final Status status;
  final List<MessageEntity> messages;
  final int requestsLeft;

  ChatState copyWith({
    Status? status,
    List<MessageEntity>? messages,
    int? requestsLeft,
  });

  @override
  List<Object?> get props => [status, messages, requestsLeft];
}

class ChatMainState extends ChatState {
  const ChatMainState({
    required super.status,
    required super.messages,
    required super.requestsLeft,
  });

  @override
  ChatMainState copyWith({
    Status? status,
    List<MessageEntity>? messages,
    int? requestsLeft,
  }) {
    return ChatMainState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      requestsLeft: requestsLeft ?? this.requestsLeft,
    );
  }
}
