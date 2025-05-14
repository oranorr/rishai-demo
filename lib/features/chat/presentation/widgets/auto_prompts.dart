// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    4,
  ];
  List<ServingEntity> selectedMeals = [];

  @override
  void initState() {
    _checkForDate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _checkForDate();
    super.build(context);
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        // print(currentStep);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 12),
          child: SizedBox(
            // height: 350.h,
            // color: RishColors.textSecondary,
            child: state.status == Status.loading
                ? const CircularProgressIndicator()
                : state.requestsLeft == 0
                    ? const SizedBox.shrink()
                    // : whoopBloc.state.day.mealPlanEntity != null ||
                    //         currentStep == 3
                    : _buildStep(currentStep),
            // : _buildStep(steps.length - 1),
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
        return MealSelectionWidget(
          callback: (list) {
            List<String> names = List.from(
              list.map((serv) => '${serv.comment ?? ''} ${serv.type.name}'),
            );
            setState(() {
              selectedMeals = list;
              snackToday =
                  selectedMeals.any((meal) => meal.type == ServingType.snack);
              currentStep++;
            });
            chatBloc
              ..add(
                ChatSendMessage(
                  text: 'Would like to have ${names.join(', ')} today',
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
        return _buildViewMealPlanButton();
      case 4:
        return const _PromptQuestions(isVisible: true);
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

  Widget _buildWorkoutButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(2, (i) {
        return Expanded(
          child: Padding(
            padding: i == 0
                ? const EdgeInsets.only(right: 5)
                : const EdgeInsets.only(left: 5),
            child: RishButton.primary(
              title: i == 0 ? 'Yes' : 'No',
              height: 48.h,
              enabled: true,
              isLoading: false,
              action: () {
                chatBloc
                  ..add(
                    ChatSendMessage(text: i == 0 ? 'Yes' : 'No', isMe: true),
                  )
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
          ),
        );
      }),
    );
  }

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
                  widget.controller.rAnimate(0);
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
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _checkForDate() {
    final now = DateTime.now();
    final currentDay = whoopBloc.state.day;
    final isToday = currentDay.dateTime.isSameDate(now);
    final isYesterday =
        currentDay.dateTime.isSameDate(now.subtract(const Duration(days: 1)));
    final isFuture = currentDay.dateTime.isAfter(now);
    final isPast =
        currentDay.dateTime.isBefore(now.subtract(const Duration(days: 1)));
    final hasMealPlan = currentDay.mealPlanEntity != null;

    if (isToday) {
      // Если сегодня и нет плана - можно создать
      if (!hasMealPlan) {
        setState(() {
          currentStep = 0;
        });
      } else {
        // Если план уже есть - показываем вопросы
        setState(() {
          currentStep = 4;
        });
      }
    } else if (isYesterday) {
      // Если вчера и нет плана - можно создать
      if (!hasMealPlan) {
        setState(() {
          currentStep = 0;
        });
      } else {
        // Если план уже был - показываем вопросы
        setState(() {
          currentStep = 4;
        });
      }
    } else if (isFuture) {
      // Для будущих дат показываем вопросы
      setState(() {
        currentStep = 4;
      });
    } else if (isPast) {
      // Для прошедших дат (позавчера и раньше) показываем вопросы
      setState(() {
        currentStep = 4;
      });
    }

    print(currentStep);
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

  // bool bodyVisible = true; // This state seems unused now

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        // Assuming state has askedQuestions: Set<String>
        // TODO: Ensure ChatState has 'askedQuestions' field of type Set<String>
        final askedQuestions = state.askedQuestions;

        // Filter out questions that have already been asked
        final availableQuestions =
            questions.where((q) => !askedQuestions.contains(q)).toList();

        // If there are no available questions left, show nothing
        if (availableQuestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedOpacity(
          opacity: 1,
          duration: Durations.short4,
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              // Map only available questions
              children: availableQuestions
                  .map((q) => _QuestionPromptButton(text: q))
                  .toList(),
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
    // isAsked parameter is no longer needed
  });
  final String text;
  // isAsked parameter is no longer needed

  @override
  Widget build(BuildContext context) {
    // Revert to original colors and behavior as only active buttons are shown
    const textColor = RishColors.textPrimary;
    const borderColor = RishColors.primary;
    const backgroundColor = RishColors.formBackgroun;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: GestureDetector(
        // onTap is always active now
        onTap: () {
          chatBloc.add(
            ChatSendMessage(text: text, isRequest: true, isMe: true),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: context.styles.regularMedium.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class MealSelectionWidget extends StatefulWidget {
  const MealSelectionWidget({
    required this.callback,
    super.key,
  });
  final Function(List<ServingEntity>) callback;
  @override
  MealSelectionWidgetState createState() => MealSelectionWidgetState();
}

class MealSelectionWidgetState extends State<MealSelectionWidget> {
  final List<ServingEntity> mealOrder = [
    ServingEntity(
      type: ServingType.breakfast,
      weight: 0,
      prompt: '',
    ),
    ServingEntity(
      type: ServingType.lunch,
      weight: 1,
      prompt: '',
    ),
    ServingEntity(
      type: ServingType.dinner,
      weight: 2,
      prompt: '',
    ),
    ServingEntity(
      type: ServingType.supper,
      weight: 3,
      prompt: '',
    ),
    ServingEntity(
      type: ServingType.snack,
      weight: 4,
      prompt: '',
    ),
  ];

  List<ServingEntity> selectedMeals = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        Text(
          'Choose meals',
          style:
              context.styles.boldLarge.copyWith(color: RishColors.textPrimary),
        ),
        ...mealOrder.map((meal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Чекбокс для выбора приема пищи
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  meal.type.name,
                  style: context.styles.regularLarge
                      .copyWith(color: RishColors.textPrimary),
                ),
                visualDensity: VisualDensity.compact,
                value: _isMealSelected(meal.type),
                onChanged: (bool? value) {
                  setState(() {
                    if (value!) {
                      _addOrUpdateMeal(meal);
                    } else {
                      _removeMeal(meal.type);
                    }
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isMealSelected(meal.type) &&
                        (meal.type == ServingType.breakfast ||
                            meal.type == ServingType.snack)
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
                              groupValue: _getMealPreference(meal.type),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              onChanged: (String? value) {
                                setState(() {
                                  _updateMealPreference(meal.type, value);
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
                              groupValue: _getMealPreference(meal.type),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              onChanged: (String? value) {
                                setState(() {
                                  _updateMealPreference(meal.type, value);
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
          enabled: _isNextButtonEnabled(),
          isLoading: false,
          action: () {
            // print(selectedMeals);
            if (_isNextButtonEnabled()) {
              selectedMeals.sort((a, b) => a.weight.compareTo(b.weight));
              // print(selectedMeals);
              widget.callback(selectedMeals);
            }
          },
        ),
      ],
    );
  }

  bool _isNextButtonEnabled() {
    // Подсчитываем количество приемов пищи без учета снеков
    final mealsWithoutSnacks = selectedMeals
        .where(
          (meal) => meal.type != ServingType.snack,
        )
        .length;

    return mealsWithoutSnacks >=
            2 && // Минимум 2 приема пищи (без учета снеков)
        selectedMeals.every(
          (meal) =>
              !(meal.type == ServingType.breakfast ||
                  meal.type == ServingType.snack) ||
              meal.comment != null,
        );
  }

  bool _isMealSelected(ServingType type) {
    return selectedMeals.any((meal) => meal.type == type);
  }

  void _addOrUpdateMeal(ServingEntity meal) {
    final index = selectedMeals.indexWhere((m) => m.type == meal.type);
    if (index != -1) {
      selectedMeals[index] =
          meal.copyWith(comment: selectedMeals[index].comment);
    } else {
      selectedMeals.add(meal);
    }
  }

  /// Удаляет приём пищи
  void _removeMeal(ServingType type) {
    selectedMeals.removeWhere((meal) => meal.type == type);
  }

  /// Получает предпочтение для приёма пищи (Savoury/Sweet)
  String? _getMealPreference(ServingType type) {
    final meal = selectedMeals.firstWhere(
      (meal) => meal.type == type,
      orElse: () => ServingEntity(type: type, weight: 0, prompt: ''),
    );
    return meal.comment;
  }

  /// Обновляет предпочтение для приёма пищи
  void _updateMealPreference(ServingType type, String? preference) {
    final index = selectedMeals.indexWhere((meal) => meal.type == type);
    if (index != -1) {
      selectedMeals[index] = selectedMeals[index].copyWith(comment: preference);
    }
  }
}
