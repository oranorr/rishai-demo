part of '../chat_page.dart';

class _InputAndSend extends StatefulWidget {
  const _InputAndSend({super.key});

  @override
  State<_InputAndSend> createState() => __InputAndSendState();
}

class __InputAndSendState extends State<_InputAndSend> {
  late TextEditingController controller;
  bool sendActive = false;

  @override
  void initState() {
    controller = TextEditingController()
      ..addListener(() {
        setState(() {
          sendActive =
              controller.text.isNotEmpty && chatBloc.state.mealPlan != null;
        });
      });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        sendActive = controller.text.trim().isNotEmpty &&
            state.mealPlan != null &&
            state.status != Status.loading;
        if (state.requestsLeft <= 0) {
          return Text(
            'You run out of free requests. Please, come back tomorrow',
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textSecondary),
            textAlign: TextAlign.center,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.text,
                minLines: 1,
                maxLines: 5,
                controller: controller,
                decoration: InputDecoration(
                  hintText:
                      'Write message (${state.requestsLeft} requests left)',
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: RishColors.stroke,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: sendActive
                  ? () {
                      chatBloc.add(ChatSendMessage(
                        text: controller.text.trim(),
                        isRequest: state.mealPlan != null,
                      ));
                      controller.clear();
                    }
                  : () {},
              child: AnimatedContainer(
                duration: Durations.short4,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: !sendActive ? RishColors.stroke : RishColors.primary,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/send.svg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.scaleDown,
                  color: !sendActive ? Colors.black : Colors.white,
                  // fit: BoxFit.fitHeight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
