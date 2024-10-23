import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

class MealScreen extends StatelessWidget {
  final Meal meal;
  const MealScreen({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      needsAppBar: true,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            meal.title,
            style: context.styles.h1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Text(
            meal.description,
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textSecondary),
          ),
          SizedBox(height: 20.h),
          Text('Macros breakdown', style: context.styles.h3),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  meal.buildPieChart(dimension: 48.h),
                  SizedBox(width: 25.w),
                  meal.macros.buildTextMacros(context: context)
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text('Ingredients', style: context.styles.h3),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meal.ingredients.length,
                itemBuilder: (context, index) {
                  return meal.ingredients[index]
                      .buildIngredientTile(context: context);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
