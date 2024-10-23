import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rishai/features/chat/presentation/chat_page.dart';

part 'message_entity.g.dart';

@HiveType(typeId: 5)
class MessageEntity {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final bool isMe;
  MessageEntity({
    required this.text,
    required this.isMe,
  });

  MessageEntity copyWith({
    String? text,
    bool? isMe,
  }) {
    return MessageEntity(
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
    );
  }

  @override
  String toString() => 'MessageEntity(text: $text, isMe: $isMe)';

  Widget buildMessage({required bool isLast}) => MessageWidget(
        text: text,
        isMe: isMe,
        isLast: isLast,
      );

  // OpenAIChatCompletionChoiceMessageModel toGPTMessage() {
  //   return OpenAIChatCompletionChoiceMessageModel(
  //     role: isMe ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
  //     content: [],
  //   );
  // }
}
