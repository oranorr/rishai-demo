import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/services/pdf/pdf_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'servings_selector.dart';
part 'loading_widget.dart';
part 'week_plan_widget.dart';
part 'week_plan_mixin.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> with WeekPlanMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        if (state.isLoading) {
          return const _LoadingState();
        }
        if (decide(state)) {
          final plans = state.weekPlans
              .where((plan) => plan != null)
              .map((plan) => plan!)
              .toList();
          return Column(
            children: [
              Row(
                children: [
                  Text(
                    'Meal prep',
                    style: context.styles.h3,
                  ),
                  // const Spacer(),
                  if (kDebugMode)
                    IconButton(
                      onPressed: () {
                        weekPlanBloc.add(const WeekPlanClear());
                      },
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        child: Opacity(
                          opacity: currentPage > 0 ? 1.0 : 0.0,
                          child: IconButton(
                            onPressed: currentPage > 0
                                ? () => pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: RishColors.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${plans[currentPage].startDate.formatAsWeekString()} - ${plans[currentPage].endDate.formatAsWeekString()}',
                        style: context.styles.regularMedium,
                      ),
                      SizedBox(
                        width: 36,
                        child: Opacity(
                          opacity: currentPage < plans.length - 1 ? 1.0 : 0.0,
                          child: IconButton(
                            onPressed: currentPage < plans.length - 1
                                ? () => pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: RishColors.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (page) {
                    final plans = state.weekPlans
                        .where((plan) => plan != null)
                        .map((plan) => plan!)
                        .toList();
                    final today = DateTime.now();
                    final (currentPlanIndex, todayIndex) =
                        _findTargetPlan(plans, today);

                    setState(() {
                      currentPage = page;
                      // Если это текущий план (где есть сегодняшний день) - показываем сегодняшний день
                      // Иначе показываем первый день плана
                      selectedIndex = page == currentPlanIndex ? todayIndex : 0;
                    });
                  },
                  itemCount: plans.length,
                  itemBuilder: (context, pageIndex) {
                    final plan = plans[pageIndex];
                    return Column(
                      children: [
                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 16.h),
                        //   child:
                        // ),
                        SizedBox(
                          height: 36.h,
                          child: ListView.builder(
                            key: const PageStorageKey<String>('days_list'),
                            shrinkWrap: true,
                            itemCount: plan.plans.length,
                            scrollDirection: Axis.horizontal,
                            controller: daysController,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final isSelected = selectedIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    selectedIndex = index;
                                  }),
                                  child: Container(
                                    width: 80.w,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? RishColors.primary
                                          : null,
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: RishColors.primary,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Day ${index + 1}',
                                        style: context.styles.regularSmall
                                            .copyWith(
                                          color: isSelected
                                              ? Colors.black
                                              : RishColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _MealPlanWidget(
                          plan: plan.plans[selectedIndex],
                          isToday: false,
                        ),
                        if (_isCurrentActivePlan(plan))
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: RishButton.primary(
                              title: 'Export shopping list',
                              enabled: true,
                              isLoading: false,
                              action: () async {
                                final allIngredients =
                                    _collectAllIngredients(plan);
                                final pdfService = PdfService();
                                await pdfService
                                    .generateShoppingList(allIngredients);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return const _ServingsSelector();
        }
      },
    );
  }

  bool _isCurrentActivePlan(WeekPlanEntity plan) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final startDate = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );

    return currentDate.isBefore(startDate);
  }
}
