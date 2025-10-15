import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

class DiaryEntryPage extends StatefulWidget {
  const DiaryEntryPage({super.key});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final List<Meal> selectedMeals = [];

  /// [_toggleMealSelection] Переключает выбор блюда в списке selectedMeals
  void _toggleMealSelection(Meal meal, bool isSelected) {
    setState(() {
      if (isSelected) {
        // [_toggleMealSelection] Добавляем блюдо в выбранные, если его там нет
        if (!selectedMeals.contains(meal)) {
          selectedMeals.add(meal);
        }
      } else {
        // [_toggleMealSelection] Удаляем блюдо из выбранных
        selectedMeals.remove(meal);
      }
    });
  }

  /// [_isMealSelected] Проверяет, выбрано ли блюдо
  bool _isMealSelected(Meal meal) {
    return selectedMeals.contains(meal);
  }

  /// [_getWeekPlanMealsForToday] Получает блюда из активного недельного плана на сегодня
  List<Meal> _getWeekPlanMealsForToday() {
    final weekPlans = weekPlanBloc.state.allWeekPlans;
    if (weekPlans.isEmpty) {
      print('[DiaryEntryPage] Нет недельных планов');
      return [];
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Ищем активный план, который покрывает сегодняшнюю дату
    WeekPlanEntity? activePlan;
    for (final plan in weekPlans) {
      final startDate = DateTime(
        plan.startDate.year,
        plan.startDate.month,
        plan.startDate.day,
      );
      final endDate = DateTime(
        plan.endDate.year,
        plan.endDate.month,
        plan.endDate.day,
      );

      // Проверяем, попадает ли сегодняшняя дата в диапазон плана
      if ((todayDate.isAfter(startDate) ||
              todayDate.isAtSameMomentAs(startDate)) &&
          (todayDate.isBefore(endDate) ||
              todayDate.isAtSameMomentAs(endDate))) {
        activePlan = plan;
        print('[DiaryEntryPage] Найден активный план: ${plan.formatPeriod()}');
        break;
      }
    }

    if (activePlan == null) {
      print('[DiaryEntryPage] Нет активного плана на сегодня');
      return [];
    }

    // Определяем индекс дня в плане
    final startDate = DateTime(
      activePlan.startDate.year,
      activePlan.startDate.month,
      activePlan.startDate.day,
    );
    final dayIndex = todayDate.difference(startDate).inDays;

    // Проверяем, что индекс в пределах плана
    if (dayIndex < 0 || dayIndex >= activePlan.plans.length) {
      print('[DiaryEntryPage] Индекс дня $dayIndex вне диапазона плана');
      return [];
    }

    final todayPlan = activePlan.plans[dayIndex];
    print(
      '[DiaryEntryPage] Найден план на день $dayIndex с ${todayPlan.meals.length} блюдами',
    );

    return todayPlan.meals;
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'What did you eat today?',
        style: context.styles.h2,
      ),
      leadingAction: () {
        context.pop();
      },
      child: BlocBuilder<WhoopBloc, WhoopState>(
        bloc: whoopBloc,
        builder: (context, whoopState) {
          // [build] Получаем актуальный список блюд из состояния WhoopBloc
          final dailyPlanMeals =
              whoopState.day.mealPlanEntity?.meals ?? <Meal>[];

          // [build] Получаем блюда из недельного плана на сегодня
          final weekPlanMeals = _getWeekPlanMealsForToday();

          // [build] Объединяем блюда из дневного и недельного планов, исключая дубликаты
          final allMealsSet = <String, Meal>{};

          // Добавляем блюда из дневного плана
          for (final meal in dailyPlanMeals) {
            final key = '${meal.title}_${meal.type}';
            allMealsSet[key] = meal;
          }

          // Добавляем блюда из недельного плана, если их еще нет
          for (final meal in weekPlanMeals) {
            final key = '${meal.title}_${meal.type}';
            if (!allMealsSet.containsKey(key)) {
              allMealsSet[key] = meal;
            }
          }

          final allMeals = allMealsSet.values.toList();

          final consumedMeals =
              whoopState.day.welnessEntity?.consumedMeals ?? <DiaryMeal>[];
          print(whoopState.day.welnessEntity);

          // [build] Фильтруем блюда, исключая уже потребленные
          final meals = allMeals.where((meal) {
            final diaryMeal = meal.toDiaryMeal(isGeneratedMeal: true);
            final isConsumed = consumedMeals.any(
              (consumed) =>
                  consumed.title == diaryMeal.title &&
                  consumed.type == diaryMeal.type,
            );
            print(
              '[DiaryEntryPage] Meal ${meal.title} - consumed: $isConsumed',
            );
            return !isConsumed;
          }).toList();

          print(
            '[DiaryEntryPage] Всего блюд: ${allMeals.length} (дневной план: ${dailyPlanMeals.length}, недельный план: ${weekPlanMeals.length})',
          );
          return Column(
            children: [
              // [build] Основной скроллируемый контент
              Expanded(
                child: SingleChildScrollView(
                  //NO PADDING HERE NEVER
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [build] Секция сгенерированных блюд
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Generated Meals',
                            style: context.styles.boldLarge,
                          ),
                          if (meals.isNotEmpty)
                            Text(
                              '${meals.length} available',
                              style: context.styles.regularSmall.copyWith(
                                color: RishColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _DiaryDropDown(
                        title: 'Choose from the list',
                        child: meals.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Text(
                                  'No meals available',
                                  style: context.styles.regularMedium.copyWith(
                                    color: RishColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                children: meals.asMap().entries.map((entry) {
                                  final meal = entry.value;
                                  return Column(
                                    children: [
                                      _MealItem(
                                        meal: meal,
                                        isSelected: _isMealSelected(meal),
                                        onSelectionChanged: (isSelected) {
                                          _toggleMealSelection(
                                            meal,
                                            isSelected,
                                          );
                                        },
                                      ),
                                      if (entry.key < meals.length - 1)
                                        const Divider(
                                          color: RishColors.stroke,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ),
                      SizedBox(height: 24.h),

                      // [build] Секция кастомных блюд
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Custom Meals',
                            style: context.styles.boldLarge,
                          ),
                          Text(
                            'Add more',
                            style: context.styles.boldMedium.copyWith(
                              color: RishColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _DiaryDropDown(
                        title: 'Choose from the list',
                        child: Column(
                          children: [
                            // [build] Форма для добавления кастомного блюда
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: RishColors.formBackgroun,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Add meal description',
                                      style:
                                          context.styles.regularMedium.copyWith(
                                        color: RishColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 48.w,
                                    height: 48.w,
                                    decoration: const BoxDecoration(
                                      color: RishColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 24.w,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // [build] Дополнительный отступ снизу для кнопки
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),

              // [build] Зафиксированная кнопка внизу экрана
              SafeArea(
                child: RishButton.primary(
                  title: selectedMeals.isEmpty
                      ? 'Select meals'
                      : 'Add ${selectedMeals.length} meal${selectedMeals.length > 1 ? 's' : ''} to diary',
                  enabled: selectedMeals.isNotEmpty,
                  isLoading: false,
                  action: () async {
                    // [onTap] Логируем добавляемые блюда
                    for (final meal in selectedMeals) {
                      print('[DiaryEntryPage] Добавлено блюдо: ${meal.title}');
                    }

                    // [onTap] СНАЧАЛА рассчитываем wellness score с выбранными блюдами
                    await foodDiaryCubit.calculateWellnessScore(selectedMeals);

                    // [onTap] ПОТОМ очищаем выбранные блюда после успешного добавления
                    setState(() {
                      selectedMeals.clear();
                    });

                    context.pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryDropDown extends StatefulWidget {
  const _DiaryDropDown({required this.child, required this.title});
  final Widget child;
  final String title;

  @override
  State<_DiaryDropDown> createState() => __DiaryDropDownState();
}

class __DiaryDropDownState extends State<_DiaryDropDown>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    // [initState] Инициализируем контроллер анимации для плавного поворота иконки
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // [initState] Создаем анимацию поворота иконки от 0 до 90 градусов
    _iconRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.25, // 0.25 * 2π = π/2 = 90 градусов
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // [dispose] Освобождаем ресурсы контроллера анимации
    _animationController.dispose();
    super.dispose();
  }

  /// [_toggleExpansion] Переключает состояние расширения дропдауна
  /// с плавной анимацией иконки
  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });

    // [_toggleExpansion] Запускаем или останавливаем анимацию поворота иконки
    if (isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: AnimatedContainer(
        width: double.infinity,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RishColors.formBackgroun,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [build] Заголовок дропдауна с кликабельной областью
            Container(
              width: double.infinity,
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: context.styles.boldMedium,
                  ),
                  const Spacer(),
                  // [build] Анимированная иконка с поворотом
                  AnimatedBuilder(
                    animation: _iconRotationAnimation,
                    builder: (context, child) {
                      return RotationTransition(
                        turns: _iconRotationAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: RishColors.textSecondary,
                          size: 24.w,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // [build] Контент дропдауна с анимированным появлением
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                ),
                child: widget.child,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// [_MealItem] Виджет для отображения элемента блюда с информацией о питательности
class _MealItem extends StatefulWidget {
  const _MealItem({
    required this.meal,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  final Meal meal;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  State<_MealItem> createState() => _MealItemState();
}

class _MealItemState extends State<_MealItem> {
  /// [_toggleSelection] Переключает состояние выбора блюда
  /// и вызывает callback для обновления родительского состояния
  void _toggleSelection() {
    widget.onSelectionChanged(!widget.isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSelection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: RishColors.formBackgroun,
          borderRadius: BorderRadius.circular(12),
          // border: widget.isSelected
          //     ? Border.all(color: RishColors.primary, width: 2)
          //     : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [build] Заголовок блюда и статус выбора
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.meal.title,
                    style: context.styles.boldMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // SizedBox(width: 12.w),
              ],
            ),

            // [build] Информация о питательности
            Row(
              children: [
                Text(
                  'Protein ${widget.meal.macros.protein}',
                  style: context.styles.regularSmall,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Fats ${widget.meal.macros.fat}',
                  style: context.styles.regularSmall,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Carbs ${widget.meal.macros.carbs}',
                  style: context.styles.regularSmall,
                ),
                const Spacer(),
                Text(
                  '${widget.meal.macros.kcal} Kcals',
                  style: context.styles.regularMedium,
                ),
                SizedBox(width: 8.w),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? RishColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected
                          ? RishColors.primary
                          : RishColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: widget.isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 16.w,
                        )
                      : null,
                ),
              ],
            ),
            // [build] Тип приема пищи
            Text(
              widget.meal.type,
              style: context.styles.regularSmall.copyWith(
                color: RishColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
