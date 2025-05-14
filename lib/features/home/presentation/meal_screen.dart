// ignore_for_file: public_member_api_docs, sort_constructors_first
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
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({
    required this.meal,
    required this.isToday,
    super.key,
  });
  final Meal meal;
  final bool isToday;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  @override
  void initState() {
    super.initState();
    // Трекинг просмотра страницы с блюдом
    analytics.logScreenView(
      screenName: 'meal_details_screen',
      screenClass: 'MealScreen',
    );
    analytics.logCustomEvent(
      name: 'view_meal_details',
      parameters: {
        'meal_type': widget.meal.type,
        'meal_title': widget.meal.title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      needsAppBar: true,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            widget.meal.title,
            style: context.styles.h1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Text(
            widget.meal.description,
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
                    widget.meal.buildPieChart(dimension: 48.h),
                    SizedBox(width: 25.w),
                    widget.meal.macros.buildTextMacros(context: context),
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
                itemCount: widget.meal.ingredients.length,
                itemBuilder: (context, index) {
                  return widget.meal.ingredients[index]
                      .buildIngredientTile(context: context);
                },
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text('Cooking instructions', style: context.styles.h3),
          SizedBox(height: 12.h),
          DecoratedBox(
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16).copyWith(bottom: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.meal.cookingInstructions.map(
                    (step) => Text(
                      step,
                      style: context.styles.regularMedium.copyWith(
                        color: RishColors.textSecondary,
                        // height: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isToday) ...[
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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  builder: (BuildContext context) {
                    return ReplacementWidget(meal: widget.meal);
                  },
                );
              },
            ),
          ],
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
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: isExpanded ? 0.1 : 0.24,
          minChildSize: 0.24,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure?',
                    style: context.styles.h3,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  RishButton.primary(
                    title: 'Yes, go ahead',
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
                    // SizedBox(height: 12.h),
                    // RishButton.primary(
                    //   title: 'I want to change an ingredient',
                    //   // enabled: secondButtonEnabled,
                    //   enabled: false,
                    //   isLoading:
                    //       state.status == Status.loading && secondButtonEnabled,
                    //   action: () {
                    //     setState(() {
                    //       isExpanded = true;
                    //     });
                    //   },
                    // ),
                  ],
                  if (isExpanded) ...[
                    SizedBox(height: 12.h),
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.only(bottom: 100.h),
                            itemCount: widget.meal.ingredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = widget.meal.ingredients[index];
                              return CheckboxListTile(
                                title: Row(
                                  children: [
                                    Text('${ingredient.emojiCode} '),
                                    Expanded(
                                      child: Text(
                                        ingredient.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.styles.regularMedium
                                            .copyWith(
                                          color: RishColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                value:
                                    selectedIngredients!.contains(ingredient),
                                onChanged: (bool? value) {
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
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: RishColors.formBackgroun,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: RishButton.primary(
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
