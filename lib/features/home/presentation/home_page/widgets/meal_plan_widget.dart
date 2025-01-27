part of '../home_page.dart';

class _MealPlanWidget extends StatelessWidget {
  const _MealPlanWidget({
    required this.controller,
    required this.isToday,
    required this.enoughRequests,
    this.plan,
  });
  final PageController controller;
  final MealPlanEntity? plan;
  final bool isToday;
  final bool enoughRequests;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      if (isToday) {
        if (enoughRequests) {
          return RishButton.primary(
            title: 'Create Meal Plan',
            enabled: true,
            isLoading: false,
            action: () async {
              await controller.rAnimate(0);
            },
          );
        } else {
          return Text(
            'You already run out of requests for today. Come again tomorrow.',
            style: context.styles.regularLarge,
            textAlign: TextAlign.center,
          );
        }
      } else {
        return Text(
          'No meal plan was created that day.',
          style: context.styles.regularLarge,
          textAlign: TextAlign.center,
        );
      }
    } else {
      return _Card(
        child: Column(
          children: [
            ListView.separated(
              itemCount: plan!.meals.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, int index) {
                final meals = plan!.meals;
                return _MealTile(
                  meal: meals[index],
                  isToday: isToday,
                  // isPostWorkout: false,
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: RishColors.stroke,
                );
              },
            ),
            if (kDebugMode) ...[
              SizedBox(
                height: 20.h,
              ),
              RishButton.primary(
                title: 'Clear plan',
                enabled: true,
                isLoading: false,
                action: () {
                  chatBloc.add(ChatDeleteMealPlan());
                },
              ),
            ],
          ],
        ),
      );
    }
  }

  (bool areEqual, int? indexOfBiggest) areMealsEqual(List<Meal> mealEntities) {
    if (mealEntities.isEmpty) {
      return (true, null);
    }

    final nonSnackMeals = [
      for (int i = 0; i < mealEntities.length; i++)
        if (mealEntities[i].type != 'Snack') (i, mealEntities[i]),
    ];

    if (nonSnackMeals.isEmpty) {
      return (true, null);
    }

    int maxMacrosIndex = nonSnackMeals[0].$1;
    var maxMacrosMeal = nonSnackMeals[0].$2;

    for (var i = 1; i < nonSnackMeals.length; i++) {
      final (index, meal) = nonSnackMeals[i];
      if (meal.macros.kcal > maxMacrosMeal.macros.kcal) {
        maxMacrosIndex = index;
        maxMacrosMeal = meal;
      }
    }

    for (var (_, meal) in nonSnackMeals) {
      final caloriesDiff = (maxMacrosMeal.macros.kcal - meal.macros.kcal).abs();
      final fatsDiff = (maxMacrosMeal.macros.fat - meal.macros.fat).abs();
      final carbsDiff = (maxMacrosMeal.macros.carbs - meal.macros.carbs).abs();

      if (caloriesDiff > 10) {
        return (false, maxMacrosIndex);
      }
      if (fatsDiff > 5 || carbsDiff > 5) {
        return (false, null);
      }
    }
    return (true, maxMacrosIndex);
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.isToday,
  });
  final Meal meal;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MealScreen(
              meal: meal,
              isToday: isToday,
            ),
          ),
        );
      },
      child: Row(
        children: [
          meal.buildPieChart(dimension: 48.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: context.styles.boldMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      meal.type,
                      style: context.styles.regularSmall
                          .copyWith(color: RishColors.primary),
                    ),
                    const Spacer(),
                    if (meal.isRegenerated)
                      Text(
                        '(regen)',
                        style: context.styles.regularSmall
                            .copyWith(color: Colors.amber),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.fitWidth,
                  child: meal.macros.buildTextMacros(context: context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
