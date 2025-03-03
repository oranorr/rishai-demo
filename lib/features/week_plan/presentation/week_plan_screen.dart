// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  int selectedIndex = 0;
  bool needsCreateFresh = false;

  @override
  void initState() {
    super.initState();
    _initializeSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        if (state.isLoading) {
          return const _LoadingState();
        }
        if (decide(state)) {
          final plan = state.weekPlans.last!;
          return Column(
            children: [
              Row(
                children: [
                  Text(
                    'Prep',
                    style: context.styles.h2,
                  ),
                  const Spacer(),
                  Text(
                    '${plan.startDate.formatAsWeekString()} - ${plan.endDate.formatAsWeekString()}',
                    style: context.styles.h2,
                  ),
                ],
              ),
              SizedBox(
                height: 20.h,
              ),
              SizedBox(
                height: 40.h,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: plan.plans.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selectedIndex = index;
                        }),
                        child: Container(
                          width: 97.w,
                          decoration: BoxDecoration(
                            color: isSelected ? RishColors.primary : null,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: RishColors.primary,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Day ${index + 1}',
                              style: context.styles.regularMedium.copyWith(
                                color: isSelected
                                    ? Colors.black
                                    : RishColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              _MealPlanWidget(
                plan: plan.plans[selectedIndex],
                isToday: false,
              ),
              SizedBox(
                height: 10.h,
              ),
              RishButton.primary(
                title: 'Export shopping list',
                enabled: true,
                isLoading: false,
                action: () {},
              ),
            ],
          );
        } else {
          return const _ServingsSelector();
        }
      },
    );
  }

  bool decide(WeekPlanState state) {
    // Если есть планы и последний план не null
    if (state.weekPlans.isNotEmpty && state.weekPlans.last != null) {
      final today = DateTime.now();
      final plan = state.weekPlans.last!;

      // Если сегодня до начала плана - показываем план
      if (today.isBefore(plan.startDate)) {
        return true;
      }

      // Если сегодня после окончания плана - не показываем план
      if (today.isAfter(plan.endDate)) {
        return false;
      }

      // Если сегодня в промежутке - показываем план
      return true;
    }

    // Если нет планов или последний план null - показываем план
    return false;
  }

  void _initializeSelectedDay() {
    final state = weekPlanBloc.state;
    if (state.weekPlans.isEmpty || state.weekPlans.last == null) return;

    final plan = state.weekPlans.last!;
    final today = DateTime.now();

    // План еще не начался
    if (today.isBefore(plan.startDate)) {
      selectedIndex = 0;
      return;
    }

    // План уже закончился
    if (today.isAfter(plan.endDate)) {
      needsCreateFresh = true;
      return;
    }

    // Находим индекс текущего дня в плане
    for (int i = 0; i < plan.plans.length; i++) {
      final planDate = plan.startDate.add(Duration(days: i));
      if (planDate.year == today.year &&
          planDate.month == today.month &&
          planDate.day == today.day) {
        setState(() {
          selectedIndex = i;
        });
        return;
      }
    }
  }
}

class _ServingsSelector extends StatefulWidget {
  const _ServingsSelector();

  @override
  State<_ServingsSelector> createState() => __ServingsSelectorState();
}

class __ServingsSelectorState extends State<_ServingsSelector> {
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      // shrinkWrap: true,
      // padding: EdgeInsets.zero,
      children: [
        Text(
          'Choose meals for your week',
          style: context.styles.h2.copyWith(color: RishColors.textPrimary),
        ),
        SizedBox(
          height: 10.h,
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
                    ),
                  );
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

class _MealPlanWidget extends StatelessWidget {
  const _MealPlanWidget({
    required this.plan,
    required this.isToday,
  });
  final MealPlanEntity plan;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: plan.meals.length,
        itemBuilder: (context, index) {
          final meal = plan.meals[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.type,
                style: context.styles.boldLarge,
              ),
              SizedBox(
                height: 10.h,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => MealScreen(
                        meal: meal,
                        isToday: isToday,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  color: RishColors.stroke,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title,
                          style: context.styles.boldLarge,
                        ),
                        SizedBox(
                          height: 5.h,
                        ),
                        Text(
                          meal.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Generating your week plan...',
          style: context.styles.h2,
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }
}
