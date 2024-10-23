// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../chat_page.dart';

class _AutoPrompts extends StatefulWidget {
  final PageController controller;
  const _AutoPrompts({
    super.key,
    required this.controller,
  });

  @override
  State<_AutoPrompts> createState() => __AutoPromptsState();
}

class __AutoPromptsState extends State<_AutoPrompts>
    with AutomaticKeepAliveClientMixin {
  int mealsAmount = 0;
  bool snackToday = false;
  bool trainingToday = false;

  int currentStep = 0;
  // List<String> options = ['Morning', 'Afternoon', 'Evening', 'No workout'];

  // bool scenarioCompleted = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List steps = [
      //start
      RishButton.primary(
          height: 48.h,
          title: 'Create meal plan',
          enabled: true,
          isLoading: false,
          action: () {
            chatBloc.add(
                const ChatSendMessage(text: 'Create meal plan', isMe: true));
            chatBloc.add(const ChatSendMessage(
                text: 'How many meals would you like to have today?',
                isMe: false));
            setState(() {
              currentStep++;
            });
          }),
      //amount
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < 3; i++)
            SizedBox(
              width: 110.w,
              child: RishButton.primary(
                title: '${i + 2}',
                height: 48.h,
                enabled: true,
                isLoading: false,
                action: () {
                  chatBloc.add(ChatSendMessage(text: '${i + 2}', isMe: true));
                  chatBloc.add(const ChatSendMessage(
                      text: 'Would you also like to add a snack?',
                      isMe: false));
                  setState(() {
                    mealsAmount = i + 2;
                    currentStep++;
                  });
                },
              ),
            ),
        ],
      ),
      //snack
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < 2; i++)
            Expanded(
              child: RishButton.primary(
                title: i == 0 ? 'Yes' : 'No',
                height: 48.h,
                enabled: true,
                isLoading: false,
                action: () {
                  chatBloc.add(
                      ChatSendMessage(text: i == 0 ? 'Yes' : 'No', isMe: true));
                  chatBloc.add(const ChatSendMessage(
                      text: 'Do you plan to exercise today?', isMe: false));
                  setState(() {
                    snackToday = i == 0;
                    currentStep++;
                  });
                },
              ),
            ),
        ],
      ),
      //workoutTime
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < 2; i++)
            Expanded(
              child: RishButton.primary(
                title: i == 0 ? 'Yes' : 'No',
                enabled: true,
                isLoading: false,
                height: 48.h,
                action: () {
                  chatBloc.add(
                      ChatSendMessage(text: i == 0 ? 'Yes' : 'No', isMe: true));
                  chatBloc.add(const ChatSendMessage(
                      text:
                          'Hold on, I\'m creating a personalized meal plan for you',
                      isMe: false));
                  setState(() {
                    trainingToday = i == 0 ? true : false;
                    // currentStep = 0;
                    currentStep++;
                    chatBloc.add(CreateMealPlan(
                      trainingToday: trainingToday,
                      // workoutTime:
                      //     workoutTime == 'No Workout' ? 'NONE' : workoutTime,
                      mealsAmount: mealsAmount,
                      snackToday: snackToday,
                    ));
                  });
                },
              ),
            )
        ],
      ),
      //View Meal Plan
      BlocBuilder<ChatBloc, ChatState>(
        bloc: chatBloc,
        builder: (context, state) {
          if (state.status == Status.success) {
            return SizedBox(
              height: 45.h,
              child: RishButton.primary(
                title: 'View meal plan',
                enabled: true,
                isLoading: false,
                action: () {
                  setState(() {
                    currentStep++;
                    widget.controller.rAnimate(1);
                  });
                },
                height: 48.h,
              ),
            );
          } else if (state.status == Status.error) {
            return Text.rich(
              TextSpan(
                  text: 'Error occured while generating. It\'s ok.',
                  style: context.styles.regularMedium,
                  children: [
                    TextSpan(
                        text: '\nJust try again.',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            chatBloc.add(CreateMealPlan(
                              trainingToday: trainingToday,
                              mealsAmount: mealsAmount,
                              snackToday: snackToday,
                            ));
                          },
                        style: context.styles.boldMedium
                            .copyWith(color: RishColors.primary))
                  ]),
              textAlign: TextAlign.center,
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      const SizedBox.shrink(),
    ];

    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 12),
          child: SizedBox(
            child: state.status == Status.loading
                ? const CircularProgressIndicator()
                : currentStep == 0
                    ? state.mealPlan == null
                        ? steps[currentStep]
                        : const SizedBox.shrink()
                    : steps[currentStep],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
