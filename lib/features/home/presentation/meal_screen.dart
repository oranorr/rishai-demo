import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({
    required this.meal,
    super.key,
  });
  final Meal meal;
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
          FittedBox(
            fit: BoxFit.fitWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: RishColors.formBackgroun,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    meal.buildPieChart(dimension: 48.h),
                    SizedBox(width: 25.w),
                    meal.macros.buildTextMacros(context: context),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text('Ingredients', style: context.styles.h3),
          SizedBox(height: 12.h),
          DecoratedBox(
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
          ),
          SizedBox(height: 20.h),
          Text('Cooking instructions', style: context.styles.h3),
          SizedBox(height: 12.h),
          ...meal.cookingInstructions.map(
            (step) => Text(
              '$step\n',
              style: context.styles.regularMedium
                  .copyWith(color: RishColors.textSecondary),
            ),
          ),
          SizedBox(height: 20.h),
          RishButton.primary(
            title: 'I want a replacement',
            enabled: chatBloc.isRegenAvailable,
            isLoading: false,
            action: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                backgroundColor: RishColors.formBackgroun,
                builder: (BuildContext context) {
                  return ReplacementWidget(meal: meal);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReplacementWidget extends StatefulWidget {
  const ReplacementWidget({
    required this.meal,
    super.key,
  });
  final Meal meal;

  @override
  State<ReplacementWidget> createState() => _ReplacementWidgetState();
}

class _ReplacementWidgetState extends State<ReplacementWidget> {
  bool firstButtonEnabled = true;
  bool secondButtonEnabled = true;
  bool isExpanded = false;
  List<Ingredient>? selectedIngredients = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16).copyWith(top: 0),
          child: AnimatedContainer(
            duration: Durations.short4,
            // height: isExpanded ? 600.h : 180.h,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'What do you want to replace?',
                  style: context.styles.h3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                RishButton.primary(
                  title: 'I want a new meal',
                  enabled: firstButtonEnabled,
                  isLoading:
                      state.status == Status.loading && firstButtonEnabled,
                  action: () {
                    setState(() {
                      secondButtonEnabled = false;
                      selectedIngredients = [];
                      isExpanded = false;
                    });
                    chatBloc.add(ChatReplaceMeal(meal: widget.meal));
                  },
                ),
                if (!isExpanded) ...[
                  SizedBox(height: 12.h),
                  RishButton.primary(
                    title: 'I want to change an ingredient',
                    enabled: secondButtonEnabled,
                    isLoading:
                        state.status == Status.loading && secondButtonEnabled,
                    action: () {
                      setState(() {
                        isExpanded = true;
                      });
                    },
                  ),
                ],
                SizedBox(height: 12.h),
                if (isExpanded)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.meal.ingredients.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Row(
                          children: [
                            Text(
                              '${widget.meal.ingredients[index].emojiCode} ',
                            ),
                            Text(
                              widget.meal.ingredients[index].title,
                              style: context.styles.regularMedium
                                  .copyWith(color: RishColors.textPrimary),
                            ),
                          ],
                        ),
                        value: selectedIngredients!.contains(
                          widget.meal.ingredients[index],
                        ),
                        onChanged: (bool? value) {
                          final Ingredient ingredient =
                              widget.meal.ingredients[index];
                          setState(() {
                            if (value!) {
                              selectedIngredients!.add(ingredient);
                            } else {
                              selectedIngredients!.remove(ingredient);
                            }
                          });
                        },
                      );
                    },
                  ),
                if (isExpanded) ...[
                  SizedBox(height: 12.h),
                  RishButton.primary(
                    title: 'Confirm ingredients to change',
                    enabled: selectedIngredients!.isNotEmpty,
                    isLoading: state.status == Status.loading,
                    action: () {
                      setState(() {
                        firstButtonEnabled = false;
                      });
                      chatBloc.add(
                        ChatReplaceIngredient(
                          meal: widget.meal,
                          ingredients: selectedIngredients!,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
