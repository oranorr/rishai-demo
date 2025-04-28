// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../week_plan_screen.dart';

class WeekContentWrap extends StatelessWidget {
  final WeekPlanEntity plan;
  const WeekContentWrap({
    required this.plan,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      appBar: AppBar(
        title: Text(
          plan.formatPeriod(),
          style: context.styles.h2,
        ),
      ),
      child: WeekPlanContent(plan: plan),
    );
  }
}

class WeekPlanContent extends StatefulWidget {
  const WeekPlanContent({
    required this.plan,
    super.key,
  });

  final WeekPlanEntity plan;

  @override
  State<WeekPlanContent> createState() => _WeekPlanContentState();
}

class _WeekPlanContentState extends State<WeekPlanContent> with WeekPlanMixin {
  // final int selectedIndex;
  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Column(
      children: [
        // Row(
        //   children: [
        //     Text(
        //       'Meal prep',
        //       style: context.styles.h3,
        //     ),
        //     if (kDebugMode)
        //       IconButton(
        //         onPressed: onClearPressed,
        //         icon: const Icon(
        //           Icons.delete_forever,
        //           color: Colors.red,
        //           size: 20,
        //         ),
        //       ),
        //     const Spacer(),
        //     Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         _PlanArrow(
        //           callback: () => pageController.previousPage(
        //             duration: const Duration(milliseconds: 300),
        //             curve: Curves.easeInOut,
        //           ),
        //           isForward: false,
        //           isEnabled: !(currentPage > 0),
        //         ),
        //         const SizedBox(width: 8),
        //         Text(
        //           '${plans[currentPage].startDate.formatAsWeekString()} - ${plans[currentPage].endDate.formatAsWeekString()}',
        //           style: context.styles.regularMedium,
        //         ),
        //         const SizedBox(width: 8),
        //         _PlanArrow(
        //           callback: () => pageController.nextPage(
        //             duration: const Duration(milliseconds: 300),
        //             curve: Curves.easeInOut,
        //           ),
        //           isForward: true,
        //           isEnabled: !(currentPage < plans.length - 1),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
        // SizedBox(height: 16.h),
        Expanded(
          child: PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            onPageChanged: (page) {
              // final today = DateTime.now();
              // final (currentPlanIndex, todayIndex) =
              //     findTargetPlan(widget.plans, today);

              // onCurrentPageChanged(page);
              // // Если это текущий план (где есть сегодняшний день) - показываем сегодняшний день
              // // Иначе показываем первый день плана
              // onSelectedIndexChanged(page == currentPlanIndex ? todayIndex : 0);
            },
            itemCount: plan.plans.length,
            itemBuilder: (context, pageIndex) {
              final plan = widget.plan;
              return Column(
                children: [
                  SizedBox(
                    height: 36.h,
                    child: ListView.builder(
                      key: const PageStorageKey<String>('days_list'),
                      shrinkWrap: true,
                      itemCount: plan.plans.length,
                      scrollDirection: Axis.horizontal,
                      controller: daysController,
                      // physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => {
                              setState(() {
                                selectedIndex = index;
                              }),
                            },
                            child: Container(
                              width: 80.w,
                              decoration: BoxDecoration(
                                color: isSelected ? RishColors.primary : null,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: RishColors.primary,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Day ${index + 1}',
                                  style: context.styles.regularSmall.copyWith(
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
                            'timestamp': DateTime.now().millisecondsSinceEpoch,
                          },
                        );

                        final allIngredients = collectAllIngredients(plan);
                        final pdfService = PdfService();
                        await pdfService.generateShoppingList(allIngredients);
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
  }
}

// class _PlanArrow extends StatelessWidget {
//   const _PlanArrow({
//     required this.callback,
//     required this.isForward,
//     required this.isEnabled,
//   });
//   final VoidCallback callback;
//   final bool isForward;
//   final bool isEnabled;
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isEnabled ? null : callback,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: 30.h,
//         width: 30.w,
//         decoration: BoxDecoration(
//           color: isEnabled ? Colors.transparent : RishColors.primary,
//           shape: BoxShape.circle,
//           boxShadow: isEnabled
//               ? null
//               : [
//                   BoxShadow(
//                     color: RishColors.primary.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Icon(
//           isForward ? Icons.chevron_right : Icons.chevron_left,
//           color: isEnabled ? Colors.transparent : RishColors.stroke,
//           size: 25.w,
//         ),
//       ),
//     );
//   }
// }
