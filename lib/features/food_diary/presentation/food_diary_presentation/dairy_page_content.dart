part of 'food_diary_page.dart';

/// [_showAppleCalendar] Показывает календарь в стиле Apple с блюром
///
/// [onDateSelected] - callback, вызываемый при выборе даты
Future<void> _showAppleCalendar(
  BuildContext context,
  DayEntity currentDay,
  Function(DateTime) onDateSelected,
) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.3), // Темный оверлей
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Stack(
          children: [
            // [_showAppleCalendar] Блюр эффект в стиле Apple за модальным окном
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),

            // [_showAppleCalendar] Календарь по центру экрана
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AppleCalendarWidget(
                  selectedDate: currentDay.dateTime,
                  availableDays: userBloc.state.days,
                  onDateSelected: (DateTime selectedDate) {
                    Navigator.of(context).pop();
                    // [_showAppleCalendar] Вызываем callback для обновления отображаемого дня
                    onDateSelected(selectedDate);
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // [_showAppleCalendar] Плавная анимация появления с масштабированием в стиле Apple
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // Apple-style bounce effect
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class _DiaryPageContent extends StatelessWidget {
  const _DiaryPageContent({
    required this.day,
    required this.onDateSelected,
  });
  final DayEntity day;
  final Function(DateTime) onDateSelected;

  /// [_groupConsumedMealsByType] Группирует потребленные блюда по типам
  /// с правильными заголовками во множественном числе
  Map<String, List<DiaryMeal>> _groupConsumedMealsByType(
    List<DiaryMeal> consumedMeals,
  ) {
    final Map<String, List<DiaryMeal>> groupedMeals = {};

    for (final meal in consumedMeals) {
      final mealType = meal.type.toLowerCase();
      String groupKey;

      // Определяем группу для блюда с обработкой разных вариантов названий
      if (mealType.contains('breakfast') ||
          mealType.contains('завтрак') ||
          mealType.contains('meal 1')) {
        groupKey = 'Breakfasts';
      } else if (mealType.contains('lunch') ||
          mealType.contains('обед') ||
          mealType.contains('meal 2')) {
        groupKey = 'Lunches';
      } else if (mealType.contains('dinner') ||
          mealType.contains('ужин') ||
          mealType.contains('meal 3')) {
        groupKey = 'Dinners';
      } else if (mealType.contains('supper') ||
          mealType.contains('поздний ужин') ||
          mealType.contains('meal 4')) {
        groupKey = 'Suppers';
      } else if (mealType.contains('snack') ||
          mealType.contains('перекус') ||
          mealType.contains('полдник') ||
          mealType.contains('meal 5')) {
        groupKey = 'Snacks';
      } else {
        // [skip] Типы блюд зафиксированы, если тип не распознан - пропускаем блюдо
        // Это не должно происходить в нормальной работе приложения
        continue;
      }

      // Добавляем блюдо в соответствующую группу
      if (!groupedMeals.containsKey(groupKey)) {
        groupedMeals[groupKey] = [];
      }
      groupedMeals[groupKey]!.add(meal);
    }

    return groupedMeals;
  }

  /// [_getSortedMealGroups] Возвращает группы блюд в правильном порядке
  List<MapEntry<String, List<DiaryMeal>>> _getSortedMealGroups(
    Map<String, List<DiaryMeal>> groupedMeals,
  ) {
    // Определяем порядок отображения групп: завтраки, ланчи, обеды, ужины, перекусы
    const groupOrder = [
      'Breakfasts', // завтраки
      'Lunches', // ланчи
      'Dinners', // обеды
      'Suppers', // ужины
      'Snacks', // перекусы
    ];

    final sortedEntries = <MapEntry<String, List<DiaryMeal>>>[];

    // Добавляем группы в заданном порядке
    for (final groupName in groupOrder) {
      if (groupedMeals.containsKey(groupName)) {
        sortedEntries.add(MapEntry(groupName, groupedMeals[groupName]!));
      }
    }

    return sortedEntries;
  }

  /// [_getGroupTitle] Возвращает заголовок группы с правильным числом
  ///
  /// Если в группе одно блюдо, возвращает заголовок в единственном числе.
  /// Если блюд несколько, возвращает заголовок во множественном числе.
  ///
  /// **Параметры:**
  /// - groupName: Название группы во множественном числе (например, 'Breakfasts')
  /// - mealsCount: Количество блюд в группе
  ///
  /// **Возвращает:**
  /// Заголовок в единственном или множественном числе в зависимости от количества блюд
  String _getGroupTitle(String groupName, int mealsCount) {
    // Если блюд несколько, возвращаем множественное число
    if (mealsCount > 1) {
      return groupName;
    }

    // Если блюдо одно, преобразуем в единственное число
    switch (groupName) {
      case 'Breakfasts':
        return 'Breakfast';
      case 'Lunches':
        return 'Lunch';
      case 'Dinners':
        return 'Dinner';
      case 'Suppers':
        return 'Supper';
      case 'Snacks':
        return 'Snack';
      default:
        // Если группа не распознана, возвращаем как есть
        // Это не должно происходить, так как типы зафиксированы
        return groupName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        SizedBox(height: 20.h),
        Row(
          children: [
            Text(
              day.dateTime.formatAsDayString(),
              style: context.styles.h2,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                // [onTap] Показываем красивый календарь в стиле Apple
                await _showAppleCalendar(context, day, onDateSelected);
              },
              child: SvgPicture.asset('assets/icons/calendar.svg'),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        DecoratedBox(
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Text(
                  'Daily Nutritional Wellness',
                  style: context.styles.regularMedium,
                ),
                const Spacer(),
                Text(
                  '${day.welnessEntity?.welnessPercentage.toStringAsFixed(0)}%',
                  style: context.styles.regularMedium,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // [build] Группируем и отображаем потребленные блюда по типам
        ...() {
          final consumedMeals = day.welnessEntity?.consumedMeals ?? [];
          if (consumedMeals.isEmpty) return <Widget>[];

          final groupedMeals = _groupConsumedMealsByType(consumedMeals);
          final sortedGroups = _getSortedMealGroups(groupedMeals);

          return sortedGroups.map((entry) {
            final groupName = entry.key;
            final mealsInGroup = entry.value;

            // [getGroupTitle] Получаем заголовок с правильным числом
            // Если в группе одно блюдо - единственное число, иначе - множественное
            final displayTitle = _getGroupTitle(groupName, mealsInGroup.length);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [build] Заголовок группы с правильным числом
                Text(
                  displayTitle,
                  style: context.styles.boldLarge,
                ),
                SizedBox(height: 8.h),

                // Блюда в группе
                ...mealsInGroup.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    final isLast = index == mealsInGroup.length - 1;

                    return Column(
                      children: [
                        _ConsumedMealsWidget(meal: meal, showMealType: false),
                        if (!isLast) SizedBox(height: 12.h),
                      ],
                    );
                  },
                ),

                SizedBox(height: 20.h),
              ],
            );
          }).toList();
        }(),
        SizedBox(height: 35.h),
      ],
    );
  }
}
