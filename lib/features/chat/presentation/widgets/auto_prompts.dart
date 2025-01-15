part of '../chat_page.dart';

class _AutoPrompts extends StatefulWidget {
  const _AutoPrompts({
    required this.controller,
    required this.isThereText,
  });
  final PageController controller;
  final bool isThereText;

  @override
  State<_AutoPrompts> createState() => __AutoPromptsState();
}

class __AutoPromptsState extends State<_AutoPrompts>
    with AutomaticKeepAliveClientMixin {
  // int mealsAmount = 0;
  bool snackToday = false;
  bool trainingToday = false;
  int currentStep = 0;
  final List<int> steps = [
    0,
    1,
    2,
    3,
  ];
  List<String> selectedMeals = [];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 12),
          child: SizedBox(
            child: state.status == Status.loading
                ? const CircularProgressIndicator()
                : state.requestsLeft == 0
                    ? const SizedBox.shrink()
                    : state.mealPlan == null || currentStep == 4
                        ? _buildStep(currentStep)
                        : _buildStep(steps.length - 1),
          ),
        );
      },
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildCreateMealPlanButton();
      case 1:
        // return _buildMealAmountButtons();
        return _MealSelectionWidget(
          callback: (list) {
            setState(() {
              selectedMeals = list;
              snackToday = selectedMeals.contains('Savoury Snack') ||
                  selectedMeals.contains('Sweet Snack');
              currentStep++;
            });
            chatBloc
              ..add(
                ChatSendMessage(
                  text: 'Would like to have ${list.join(', ')} today',
                  isMe: true,
                ),
              )
              ..add(
                const ChatSendMessage(
                  text: 'Are you planning to exercise today?',
                  isMe: false,
                ),
              );
          },
        );
      case 2:
        return _buildWorkoutButtons();
      case 3:
        // return _buildTrainingButtons();
        return _buildViewMealPlanButton();
      // case 4:
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCreateMealPlanButton() {
    return RishButton.primary(
      height: 48.h,
      title: 'Create meal plan',
      enabled: true,
      isLoading: false,
      action: () {
        chatBloc
          ..add(const ChatSendMessage(text: 'Create meal plan', isMe: true))
          ..add(
            const ChatSendMessage(
              text: 'What would you like to have today?',
              isMe: false,
            ),
          );
        setState(() {
          currentStep++;
        });
      },
    );
  }

  // Widget _buildMealAmountButtons() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceAround,
  //     children: List.generate(3, (i) {
  //       return SizedBox(
  //         width: 110.w,
  //         child: RishButton.primary(
  //           title: '${i + 2}',
  //           height: 48.h,
  //           enabled: true,
  //           isLoading: false,
  //           action: () {
  //             chatBloc
  //               ..add(ChatSendMessage(text: '${i + 2}', isMe: true))
  //               ..add(
  //                 const ChatSendMessage(
  //                   text: 'Would you also like to add a snack?',
  //                   isMe: false,
  //                 ),
  //               );
  //             setState(() {
  //               mealsAmount = i + 2;
  //               currentStep++;
  //             });
  //           },
  //         ),
  //       );
  //     }),
  //   );
  // }

  Widget _buildWorkoutButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(2, (i) {
        return Expanded(
          child: RishButton.primary(
            title: i == 0 ? 'Yes' : 'No',
            height: 48.h,
            enabled: true,
            isLoading: false,
            action: () {
              chatBloc
                ..add(ChatSendMessage(text: i == 0 ? 'Yes' : 'No', isMe: true))
                ..add(
                  const ChatSendMessage(
                    text:
                        "Hold on, I'm creating a personalized meal plan for you",
                    isMe: false,
                  ),
                );
              setState(() {
                trainingToday = i == 0;
                currentStep++;
              });
              chatBloc.add(
                CreateMealPlan(
                  trainingToday: trainingToday,
                  meals: selectedMeals,
                  snackToday: snackToday,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // Widget _buildTrainingButtons() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: List.generate(2, (i) {
  //       return Expanded(
  //         child: RishButton.primary(
  //           title: i == 0 ? 'Yes' : 'No',
  //           enabled: true,
  //           isLoading: false,
  //           height: 48.h,
  //           action: () {
  //             chatBloc
  //               ..add(ChatSendMessage(text: i == 0 ? 'Yes' : 'No', isMe: true))
  //               ..add(
  //                 const ChatSendMessage(
  //                   text:
  //                       "Hold on, I'm creating a personalized meal plan for you",
  //                   isMe: false,
  //                 ),
  //               );
  //             setState(() {
  //               trainingToday = i == 0;
  //               currentStep++;
  //               chatBloc.add(
  //                 CreateMealPlan(
  //                   trainingToday: trainingToday,
  //                   mealsAmount: mealsAmount,
  //                   snackToday: snackToday,
  //                 ),
  //               );
  //             });
  //           },
  //         ),
  //       );
  //     }),
  //   );
  // }

  Widget _buildViewMealPlanButton() {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        if (state.status == Status.success) {
          return SizedBox(
            height: 45.h,
            child: RishButton.primary(
              title: 'View meal plan',
              enabled: true,
              isLoading: false,
              action: () async {
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
              text: "Error occured while generating. It's ok.",
              style: context.styles.regularMedium,
              children: [
                TextSpan(
                  text: '\nJust try again.',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      chatBloc.add(
                        CreateMealPlan(
                          trainingToday: trainingToday,
                          meals: selectedMeals,
                          snackToday: snackToday,
                        ),
                      );
                    },
                  style: context.styles.boldMedium
                      .copyWith(color: RishColors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _PromptQuestions extends StatefulWidget {
  const _PromptQuestions({
    required this.isVisible,
  });
  final bool isVisible;

  @override
  State<_PromptQuestions> createState() => _PromptQuestionsState();
}

class _PromptQuestionsState extends State<_PromptQuestions> {
  final List<String> questions = [
    'Is protein essential to build muscle and lose fat?',
    'What are good sources of fats?',
    'Does intermittent fasting help with body composition?',
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
              children:
                  questions.map((q) => _QuestionPromptButton(text: q)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _QuestionPromptButton extends StatelessWidget {
  const _QuestionPromptButton({
    required this.text,
  });
  final String text;

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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: RishColors.primary),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _MealSelectionWidget extends StatefulWidget {
  const _MealSelectionWidget({required this.callback});
  final Function(List<String>) callback;
  @override
  _MealSelectionWidgetState createState() => _MealSelectionWidgetState();
}

class _MealSelectionWidgetState extends State<_MealSelectionWidget> {
  final List<String> mealOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Supper',
    'Snack',
  ];
  final List<String> selectedMeals = [];
  final Map<String, String> mealPreferences = {};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          Text(
            'Choose meals',
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textPrimary),
          ),
          ...mealOptions.map((meal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    meal,
                    style: context.styles.regularLarge
                        .copyWith(color: RishColors.textPrimary),
                  ),
                  visualDensity: VisualDensity.compact,
                  value: selectedMeals.contains(meal),
                  onChanged: (bool? value) {
                    setState(() {
                      if (selectedMeals.contains(meal)) {
                        selectedMeals.remove(meal);
                        mealPreferences.remove(meal);
                      } else {
                        selectedMeals.add(meal);
                      }
                    });
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: selectedMeals.contains(meal) &&
                          (meal == 'Breakfast' || meal == 'Snack')
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RadioListTile<String>(
                                title: Text(
                                  'Savoury',
                                  style: context.styles.regularMedium
                                      .copyWith(color: RishColors.textPrimary),
                                ),
                                value: 'Savoury',
                                groupValue: mealPreferences[meal],
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onChanged: (String? value) {
                                  setState(() {
                                    mealPreferences[meal] = value!;
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: Text(
                                  'Sweet',
                                  style: context.styles.regularMedium
                                      .copyWith(color: RishColors.textPrimary),
                                ),
                                value: 'Sweet',
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                groupValue: mealPreferences[meal],
                                onChanged: (String? value) {
                                  setState(() {
                                    mealPreferences[meal] = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
          RishButton.primary(
            height: 48.h,
            title: 'Next',
            enabled: selectedMeals.length >= 2 &&
                selectedMeals.every(
                  (meal) =>
                      !(meal == 'Breakfast' || meal == 'Snack') ||
                      mealPreferences.containsKey(meal),
                ),
            isLoading: false,
            action: () {
              if (selectedMeals.length >= 2 &&
                  selectedMeals.every(
                    (meal) =>
                        !(meal == 'Breakfast' || meal == 'Snack') ||
                        mealPreferences.containsKey(meal),
                  )) {
                final List<String> finalMeals = selectedMeals.map((meal) {
                  if (mealPreferences.containsKey(meal)) {
                    return '${mealPreferences[meal]} $meal';
                  }
                  return meal;
                }).toList();
                widget.callback(finalMeals);
              }
            },
          ),
        ],
      ),
    );
  }
}
