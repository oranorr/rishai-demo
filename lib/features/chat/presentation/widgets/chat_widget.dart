part of '../chat_page.dart';

class _ChatWidget extends StatefulWidget {
  const _ChatWidget();

  @override
  State<_ChatWidget> createState() => _ChatWidgetState();
}

// List<MessageWidget> dummy = List.generate(
//     50,
//     (index) => MessageWidget(
//           text: lorem.substring(1, math.Random().nextInt(100)),
//           isMe: math.Random().nextBool(),
//           isLast: index == 50,
//         ));

class _ChatWidgetState extends State<_ChatWidget> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ChatBloc, ChatState>(
        bloc: chatBloc,
        builder: (context, state) {
          return ListView.builder(
            shrinkWrap: true,
            reverse: true,
            padding: EdgeInsets.zero,
            itemCount: state.messages.length,
            itemBuilder: (BuildContext context, int index) {
              final msg = state.messages.reversed.toList()[index];
              return msg.buildMessage(
                isLast: state.messages.last == msg,
              );
            },
          );
        },
      ),
    );
  }
}
