part of '../week_plan_screen.dart';

class _ServingsSelector extends StatefulWidget {
  const _ServingsSelector();

  @override
  State<_ServingsSelector> createState() => __ServingsSelectorState();
}

class __ServingsSelectorState extends State<_ServingsSelector> {
  // В дебаг режиме разрешаем выбор с сегодняшнего дня, в продакшене - с завтрашнего
  DateTime startDate =
      kDebugMode ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
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
  bool trainingToday = false;
  List<ServingEntity> selectedMeals = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Choose meals for your week',
          style: context.styles.h2.copyWith(color: RishColors.textPrimary),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              // В дебаг режиме разрешаем выбор с сегодняшнего дня, в продакшене - с завтрашнего
              firstDate: kDebugMode ? DateTime.now() : startDate,
              lastDate: startDate.add(const Duration(days: 2)),
              initialDate: startDate,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
            );
            if (date != null) {
              setState(() {
                startDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: RishColors.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Start date: ${startDate.formatAsWeekString()}',
                  style: context.styles.regularLarge,
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, color: RishColors.primary),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Do you plan to train this week?',
              style: context.styles.regularMedium,
            ),
            const Spacer(),
            Switch(
              inactiveThumbColor: Colors.black,
              inactiveTrackColor: Colors.grey,
              value: trainingToday,
              onChanged: (value) {
                setState(() {
                  trainingToday = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        BlocBuilder<WeekPlanBloc, WeekPlanState>(
          bloc: weekPlanBloc,
          builder: (context, state) {
            return RishButton.primary(
              height: 48.h,
              title: 'Generate',
              enabled: _isNextButtonEnabled(),
              isLoading: state.isLoading,
              action: () {
                final prefs = userBloc.state.user.foodPreferences!;
                // print(selectedMeals);
                if (_isNextButtonEnabled()) {
                  selectedMeals.sort((a, b) => a.weight.compareTo(b.weight));
                  weekPlanBloc.add(
                    WeekPlanGenerate(
                      restrictions: prefs.restrictions,
                      dietary: prefs.diets,
                      cuisines: prefs.cuisines,
                      calorieTarget: whoopBloc.state.day.macros.kcal,
                      macros: whoopBloc.state.day.macros,
                      hasTraining: trainingToday,
                      hasSnack: selectedMeals
                          .any((meal) => meal.type == ServingType.snack),
                      servings: selectedMeals,
                      startDate: startDate,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
            );
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

    return mealsWithoutSnacks >= 2 &&
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
