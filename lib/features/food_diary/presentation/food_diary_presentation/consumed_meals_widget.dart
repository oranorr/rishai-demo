part of 'food_diary_page.dart';

/// Виджет для отображения одного потребленного блюда
class _ConsumedMealsWidget extends StatelessWidget {
  const _ConsumedMealsWidget({
    required this.meal,
    this.showMealType = true,
  });
  final DiaryMeal meal;
  final bool showMealType;

  @override
  Widget build(BuildContext context) {
    final map = {
      'Type:': '${meal.isGeneratedMeal ? 'Generated' : 'Custom'} Meal',
      'Meal Name:': meal.title,
      'Calories:': '${meal.macros.kcal} kcals',
      'Macros:':
          '${meal.macros.protein}g Protein, ${meal.macros.carbs}g Carbs, ${meal.macros.fat}g Fat',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Показываем заголовок типа блюда только если showMealType = true
        if (showMealType) ...[
          Text(
            meal.type,
            style: context.styles.boldLarge,
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < map.entries.length; i++) ...[
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          map.entries.elementAt(i).key,
                          style: context.styles.regularMedium,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          map.entries.elementAt(i).value,
                          style: context.styles.regularMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < map.entries.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: RishColors.stroke,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
