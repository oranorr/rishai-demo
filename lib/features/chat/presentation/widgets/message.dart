// ignore_for_file: use_named_constants

part of '../chat_page.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    required this.text,
    required this.isMe,
    required this.isLast,
    super.key,
  });
  final String text;
  final bool isMe;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMe ? context.theme.colorScheme.primary : RishColors.stroke,
            borderRadius: BorderRadius.circular(25).copyWith(
              topRight: isMe ? const Radius.circular(0) : null,
              bottomLeft: isMe ? null : const Radius.circular(0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              style: context.styles.regularMedium
                  .copyWith(color: isMe ? RishColors.surface : null),
              maxLines: 100,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
