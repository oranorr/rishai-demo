// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../chat_page.dart';

class _InputAndSend extends StatefulWidget {
  final TextEditingController textEditingController;
  bool sendActive;
  _InputAndSend({
    super.key,
    required this.textEditingController,
    required this.sendActive,
  });

  @override
  State<_InputAndSend> createState() => __InputAndSendState();
}

class __InputAndSendState extends State<_InputAndSend> {
  // bool sendActive = false;

  // @override
  // void initState() {
  //   // wigdet.textEditingController.addListener(() {
  //   //   setState(() {
  //   //     // sendActive =
  //   //     //     controller.text.isNotEmpty && chatBloc.state.mealPlan != null;
  //   //   });
  //   // });
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   controller.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        widget.sendActive =
            widget.textEditingController.text.trim().isNotEmpty &&
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
                enabled: state.status != Status.loading,
                textInputAction: TextInputAction.done,
                controller: widget.textEditingController,
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
              onTap: widget.sendActive
                  ? () {
                      chatBloc.add(ChatSendMessage(
                        text: widget.textEditingController.text.trim(),
                        isRequest: state.mealPlan != null,
                      ));
                      widget.textEditingController.clear();
                    }
                  : () {},
              child: AnimatedContainer(
                duration: Durations.short4,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: !widget.sendActive
                      ? RishColors.stroke
                      : RishColors.primary,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/send.svg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.scaleDown,
                  color: !widget.sendActive ? Colors.black : Colors.white,
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
