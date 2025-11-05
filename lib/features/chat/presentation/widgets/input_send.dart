part of '../chat_page.dart';

// ignore: must_be_immutable
class _InputAndSend extends StatefulWidget {
  _InputAndSend({
    required this.textEditingController,
    required this.sendActive,
  });
  final TextEditingController textEditingController;
  bool sendActive;

  @override
  State<_InputAndSend> createState() => __InputAndSendState();
}

class __InputAndSendState extends State<_InputAndSend> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        // [_InputAndSend] Для подписчиков убираем проверку наличия плана питания
        // Кнопка активна если: есть текст И (подписка активна ИЛИ есть план) И не идет загрузка
        widget.sendActive = widget.textEditingController.text
                .trim()
                .isNotEmpty &&
            (adapty.isActive || whoopBloc.state.day.mealPlanEntity != null) &&
            state.status != Status.loading;

        // [_InputAndSend] Для подписчиков не показываем сообщение об исчерпании запросов
        if (state.requestsLeft <= 0 && !adapty.isActive) {
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
                  hintText: kDebugMode
                      ? 'Write message (${state.requestsLeft} requests left)'
                      : '',
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
                      // [_InputAndSend] Отправляем запрос как isRequest если подписка активна ИЛИ есть план
                      chatBloc.add(
                        ChatSendMessage(
                          text: widget.textEditingController.text.trim(),
                          isRequest: adapty.isActive ||
                              whoopBloc.state.day.mealPlanEntity != null,
                        ),
                      );
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
                  // ignore: deprecated_member_use
                  color: !widget.sendActive ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
