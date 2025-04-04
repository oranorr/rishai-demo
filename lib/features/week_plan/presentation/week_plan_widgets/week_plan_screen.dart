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
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';

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
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Трекинг просмотра 5-дневного плана питания
    analytics.logScreenView(
      screenName: 'week_plan_screen',
      screenClass: 'WeekPlanScreen',
    );
    analytics.logCustomEvent(
      name: 'view_5days_meal_plan',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

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
                      _PlanArrow(
                        callback: () => pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        isForward: false,
                        isEnabled: !(currentPage > 0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${plans[currentPage].startDate.formatAsWeekString()} - ${plans[currentPage].endDate.formatAsWeekString()}',
                        style: context.styles.regularMedium,
                      ),
                      const SizedBox(width: 8),
                      _PlanArrow(
                        callback: () => pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        isForward: true,
                        isEnabled: !(currentPage < plans.length - 1),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: PageView.builder(
                  physics: const NeverScrollableScrollPhysics(),
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
                        // if (_isCurrentActivePlan(plan))
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: RishButton.primary(
                            title: 'Export grocery list',
                            enabled: true,
                            isLoading: false,
                            action: () async {
                              // Трекинг экспорта списка покупок из недельного плана
                              await analytics.logCustomEvent(
                                name: 'export_grocery_list_from_week_plan',
                                parameters: {
                                  'day_index': selectedIndex,
                                  'timestamp':
                                      DateTime.now().millisecondsSinceEpoch,
                                },
                              );

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

  // bool _isCurrentActivePlan(WeekPlanEntity plan) {
  //   final today = DateTime.now();
  //   final currentDate = DateTime(today.year, today.month, today.day);
  //   final startDate = DateTime(
  //     plan.startDate.year,
  //     plan.startDate.month,
  //     plan.startDate.day,
  //   );
  //   final endDate = DateTime(
  //     plan.endDate.year,
  //     plan.endDate.month,
  //     plan.endDate.day,
  //   );

  //   // План активен если:
  //   // 1. Текущая дата совпадает с датой начала
  //   // 2. Текущая дата находится между началом и концом плана
  //   // 3. Текущая дата до начала плана (чтобы можно было экспортировать список покупок)
  //   return currentDate.isAtSameMomentAs(startDate) ||
  //       (currentDate.isAfter(startDate) && currentDate.isBefore(endDate)) ||
  //       currentDate.isBefore(startDate);
  // }
}

class _PlanArrow extends StatelessWidget {
  const _PlanArrow({
    required this.callback,
    required this.isForward,
    required this.isEnabled,
  });
  final VoidCallback callback;
  final bool isForward;
  final bool isEnabled;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? null : callback,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30.h,
        width: 30.w,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.transparent : RishColors.primary,
          shape: BoxShape.circle,
          boxShadow: isEnabled
              ? null
              : [
                  BoxShadow(
                    color: RishColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          isForward ? Icons.chevron_right : Icons.chevron_left,
          color: isEnabled ? Colors.transparent : RishColors.stroke,
          size: 25.w,
        ),
      ),
    );
  }
}
