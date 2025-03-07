part of 'week_plan_screen.dart';

mixin WeekPlanMixin on State<WeekPlanScreen> {
  int selectedIndex = 0;
  late PageController pageController;
  late ScrollController daysController;
  int currentPage = 0;
  bool needsCreateFresh = false;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    daysController = ScrollController();
    initializeSelectedDay();
  }

  @override
  void dispose() {
    daysController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void initializeSelectedDay() {
    final state = weekPlanBloc.state;
    if (state.weekPlans.isEmpty || state.weekPlans.last == null) return;

    final plans = state.weekPlans
        .where((plan) => plan != null)
        .map((plan) => plan!)
        .toList();

    final today = DateTime.now();
    final (targetIndex, dayIndex) = _findTargetPlan(plans, today);

    if (targetIndex != -1) {
      _updateSelectedIndexes(targetIndex, dayIndex, plans[targetIndex]);
    }
  }

  // Находит индекс нужного плана и дня
  (int, int) _findTargetPlan(List<WeekPlanEntity> plans, DateTime today) {
    // Убираем время из даты
    final currentDate = DateTime(today.year, today.month, today.day);

    // Поиск текущего активного плана
    for (int i = 0; i < plans.length; i++) {
      final plan = plans[i];
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

      // Проверяем, входит ли текущая дата в диапазон плана (включительно)
      if (!currentDate.isBefore(startDate) && !currentDate.isAfter(endDate)) {
        final dayIndex = currentDate.difference(startDate).inDays;
        return (i, dayIndex);
      }
    }

    // Если сегодняшний день не входит ни в один план
    if (currentDate.isBefore(
      DateTime(
        plans.first.startDate.year,
        plans.first.startDate.month,
        plans.first.startDate.day,
      ),
    )) {
      return (0, 0);
    }

    // Если дата после последнего плана
    if (currentDate.isAfter(
      DateTime(
        plans.last.endDate.year,
        plans.last.endDate.month,
        plans.last.endDate.day,
      ),
    )) {
      return (plans.length - 1, plans.last.plans.length - 1);
    }

    // Если дата между планами, находим ближайший следующий план
    for (int i = 0; i < plans.length - 1; i++) {
      final currentEndDate = DateTime(
        plans[i].endDate.year,
        plans[i].endDate.month,
        plans[i].endDate.day,
      );
      final nextStartDate = DateTime(
        plans[i + 1].startDate.year,
        plans[i + 1].startDate.month,
        plans[i + 1].startDate.day,
      );

      if (currentDate.isAfter(currentEndDate) &&
          currentDate.isBefore(nextStartDate)) {
        return (i + 1, 0);
      }
    }

    return (-1, -1);
  }

  void _updateSelectedIndexes(
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
    if (state.weekPlans.isNotEmpty && state.weekPlans.last != null) {
      final currentDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final plan = state.weekPlans.last!;
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

  List<Ingredient> _collectAllIngredients(WeekPlanEntity weekPlan) {
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
