// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../chat_page.dart';

class _AutoPrompts extends StatefulWidget {
  final PageController controller;
  final bool isThereText;
  const _AutoPrompts({
    super.key,
    required this.controller,
    required this.isThereText,
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
      //is there workout
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
                    FocusManager.instance.primaryFocus?.unfocus();
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
      _PromptQuestions(
        isVisible: widget.isThereText,
      ),
      // const SizedBox.shrink(),
    ];

    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 12),
          child: SizedBox(
              child: state.status == Status.loading
                  ? const CircularProgressIndicator()
                  : !adapty.isActive
                      ? buildSubButton(context)
                      : state.requestsLeft == 0
                          ? const SizedBox.shrink()
                          : state.mealPlan == null || currentStep == 4
                              ? steps[currentStep]
                              : steps.last),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget buildSubButton(BuildContext context) {
    return RishButton.primary(
        title: 'Purchase Subscription',
        enabled: true,
        isLoading: false,
        action: () => context.go(AppRoutes.paywall.path));
  }
}

class _PromptQuestions extends StatefulWidget {
  final bool isVisible;
  const _PromptQuestions({
    super.key,
    required this.isVisible,
  });

  @override
  State<_PromptQuestions> createState() => _PromptQuestionsState();
}

class _PromptQuestionsState extends State<_PromptQuestions> {
  final List<String> questions = [
    'Is protein essential to build muscle and lose fat?',
    'What are good sources of fats?',
    'Does intermittent fasting help with body compostition?'
  ];

  bool bodyVisible = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        return AnimatedOpacity(
            opacity: !widget.isVisible &&
                    state.status != Status.loading &&
                    state.requestsLeft != 0
                ? 1
                : 0,
            duration: Durations.short4,
            onEnd: () {
              setState(() {
                bodyVisible = !bodyVisible;
              });
            },
            child: AnimatedContainer(
              duration: Durations.short4,
              height: bodyVisible ? null : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: questions
                    .map((q) => _QuestionPromptButton(text: q))
                    .toList(),
              ),
            ));
      },
    );
  }
}

class _QuestionPromptButton extends StatelessWidget {
  final String text;
  const _QuestionPromptButton({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.w),
        child: GestureDetector(
          onTap: () {
            chatBloc.add(
              ChatSendMessage(text: text, isRequest: true, isMe: true),
            );
          },
          child: Container(
            decoration: BoxDecoration(
                color: RishColors.formBackgroun,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(width: 1, color: RishColors.primary)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
              child: Text(
                text,
                textAlign: TextAlign.end,
                style: context.styles.regularMedium
                    .copyWith(color: RishColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
