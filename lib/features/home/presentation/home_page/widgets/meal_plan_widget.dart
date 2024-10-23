// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../home_page.dart';

class _MealPlanWidget extends StatelessWidget {
  final PageController controller;
  final MealPlanEntity? plan;
  final bool isToday;
  const _MealPlanWidget({
    super.key,
    required this.controller,
    this.plan,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      if (isToday) {
        return RishButton.primary(
          title: 'Create Meal Plan',
          enabled: true,
          isLoading: false,
          action: () {
            controller.rAnimate(0);
          },
        );
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
                List<int> kcals = [];
                List<MacrosBreakdown> macros = [];

                for (var meal in plan!.meals) {
                  if (meal.type != 'Snack') {
                    kcals.add(meal.macros.kcal);
                    macros.add(meal.macros);
                  }
                }

                final biggest = kcals.reduce(math.max);

                int indexOfBiggest = kcals.indexOf(biggest);

                bool areEqualCKals = kcals.every((cal) => cal == biggest);

                bool areEuqalMacros = plan!.meals
                    .every((meal) => meal.macros == macros[indexOfBiggest]);

                bool areEqual = areEuqalMacros || areEqualCKals;
                return _MealTile(
                  meal: plan!.meals[index],
                  isPostWorkout: areEqual ? false : indexOfBiggest == index,
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: RishColors.stroke,
                );
              },
            ),
            // if (kDebugMode) ...[
            //   SizedBox(height: 20.h),
            //   RishButton.primary(
            //       title: 'Clear Meal plan',
            //       enabled: true,
            //       isLoading: false,
            //       action: () => chatBloc.add(ChatDeleteMealPlan())),
            // ]
          ],
        ),
      );
    }
  }
}

class _MealTile extends StatelessWidget {
  final Meal meal;
  final bool isPostWorkout;
  const _MealTile({
    super.key,
    required this.meal,
    required this.isPostWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MealScreen(
              meal: meal,
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
                Text(
                  isPostWorkout ? '💪 Post-Workout Meal 💪' : meal.type,
                  style: context.styles.regularSmall
                      .copyWith(color: RishColors.primary),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                    fit: BoxFit.fitWidth,
                    child: meal.macros.buildTextMacros(context: context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
