part of '../week_plan_screen.dart';

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
                meal.type.capitalize(),
                style: context.styles.boldLarge,
              ),
              SizedBox(
                height: 10.h,
              ),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
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
                            // 'short',
                            style: context.styles.boldLarge,
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          Text(
                            meal.description,
                            // 'short',
                            maxLines: 2,
                            style: context.styles.regularMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          Text(
                            'View',
                            style: context.styles.regularLarge
                                .copyWith(color: RishColors.primary),
                          ),
                        ],
                      ),
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
