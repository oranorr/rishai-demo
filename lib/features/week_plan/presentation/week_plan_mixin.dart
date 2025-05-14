part of 'week_plan_screen.dart';

mixin WeekPlanMixin on State<WeekPlanContent> {
  int selectedIndex = 0;
  late PageController pageController;
  late ScrollController daysController;
  int currentPage = 0;
  bool needsCreateFresh = false;

  // Флаг для контроля первоначальной инициализации скролла
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController();

    // Инициализируем ScrollController без немедленной анимации
    daysController = ScrollController();

    // Вызываем инициализацию выбора дня
    initializeSelectedDay();
  }

  @override
  void dispose() {
    daysController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void initializeSelectedDay() {
    final plan = widget.plan;
    if (plan.plans.isEmpty) return;

    final today = DateTime.now();

    // Проверяем, находится ли текущая дата в пределах плана
    final todayDate = DateTime(today.year, today.month, today.day);
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

    // Если сегодняшняя дата после окончания плана, оставляем первый день по умолчанию
    if (todayDate.isAfter(endDate)) return;

    final todayIndex = findTodayIndexInPlan(plan, today);

    if (todayIndex != -1) {
      setState(() {
        selectedIndex = todayIndex;
      });

      // Используем WidgetsBinding для гарантированного выполнения после построения виджета
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Рассчитываем позицию скролла
        double targetScroll = 0;

        // Установка начального положения без анимации
        if (daysController.hasClients) {
          final maxScroll = daysController.position.maxScrollExtent;

          if (todayIndex <= 1) {
            // Для первых двух дней - начало списка
            targetScroll = 0.0;
          } else if (todayIndex >= plan.plans.length - 2) {
            // Для последних двух дней - конец списка
            targetScroll = maxScroll;
          } else {
            // Центрируем день
            targetScroll = (todayIndex * 86.w - 100.w).clamp(0.0, maxScroll);
          }

          // Мгновенный переход к нужной позиции без анимации
          daysController.jumpTo(targetScroll);
          _initialScrollDone = true;
        }
      });
    }
  }

  int findTodayIndexInPlan(WeekPlanEntity plan, DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);

    // Приводим даты плана к формату без времени для корректного сравнения
    final startDate = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );

    // Определяем, сколько дней прошло с начала плана
    final differenceInDays = todayDate.difference(startDate).inDays;

    // Если день отрицательный (сегодня раньше, чем начало плана), возвращаем 0
    if (differenceInDays < 0) return 0;

    // Если день больше, чем длина плана, возвращаем последний день
    if (differenceInDays >= plan.plans.length) return plan.plans.length - 1;

    // Иначе возвращаем индекс дня в плане
    return differenceInDays;
  }

  void updateSelectedIndexes(
    int planIndex,
    int dayIndex,
    WeekPlanEntity plan,
  ) {
    setState(() {
      currentPage = planIndex;
      selectedIndex = dayIndex.clamp(0, plan.plans.length - 1);
    });

    // Используем микротаск для более надежной инициализации
    Future.microtask(() {
      if (!mounted) return;

      if (pageController.hasClients) {
        pageController.jumpToPage(planIndex);
      }

      if (selectedIndex >= 3) {
        // Даем немного времени на инициализацию ListView
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted || !daysController.hasClients) return;

          try {
            // Мгновенный переход к нужной позиции без анимации
            daysController.jumpTo(selectedIndex * 105.w);
          } catch (e) {
            log('Ошибка при прокрутке дней: $e');
          }
        });
      }
    });
  }

  bool decide(WeekPlanState state) {
    // Если есть планы и последний план не null
    if (state.allWeekPlans.isNotEmpty) {
      final currentDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final plan = state.allWeekPlans.last;
      final endDate = DateTime(
        plan.endDate.year,
        plan.endDate.month,
        plan.endDate.day,
      );

      // Если сегодня после окончания плана - не показываем план
      return !currentDate.isAfter(endDate);
    }

    // Если нет планов или последний план null - показываем план
    return false;
  }

  List<Ingredient> collectAllIngredients(WeekPlanEntity weekPlan) {
    final Map<String, List<Ingredient>> ingredientGroups = {};

    for (final dayPlan in weekPlan.plans) {
      for (final meal in dayPlan.meals) {
        for (final ingredient in meal.ingredients) {
          // Нормализуем название ингредиента (приводим к нижнему регистру)
          final normalizedTitle = ingredient.title.toLowerCase();
          // Группируем по нормализованному названию и единице измерения
          final key = '${normalizedTitle}_${ingredient.unit}';
          ingredientGroups.putIfAbsent(key, () => []).add(ingredient);
        }
      }
    }

    // Объединяем ингредиенты по группам
    final List<Ingredient> result = ingredientGroups.entries.map((entry) {
      final ingredients = entry.value;
      if (ingredients.isEmpty) return ingredients.first;

      final firstIngredient = ingredients.first;
      double totalQuantity = 0;

      // Суммируем количество ингредиентов с одинаковой единицей измерения
      for (final ing in ingredients) {
        totalQuantity += ing.quantity;
      }

      return firstIngredient.copyWith(
        quantity: totalQuantity,
      );
    }).toList();

    // Сортируем по алфавиту
    result
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return result;
  }
}
