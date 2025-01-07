// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../home_page.dart';

class _MacrosBreakdownWidget extends StatelessWidget {
  const _MacrosBreakdownWidget({
    required this.day,
    required this.isToday,
  });
  final bool isToday;
  final DayEntity day;

  @override
  Widget build(BuildContext context) {
    final res = whoopBloc.calculatePercentage();

    return _Card(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 140.w,
            child: PieChart(
              PieChartData(
                sectionsSpace: 6,
                sections: [
                  PieChartSectionData(
                    value: res.$1,
                    color: RishColors.protein,
                    showTitle: true,
                    radius: 12,
                    title: '${res.$1.toInt()}%',
                    titlePositionPercentageOffset: -2.3,
                    titleStyle: context.styles.numsS
                        .copyWith(color: RishColors.protein),
                  ),
                  PieChartSectionData(
                    value: res.$2,
                    color: RishColors.carbs,
                    radius: 12,
                    showTitle: true,
                    title: '${res.$2.toInt()}%',
                    titlePositionPercentageOffset: -2.3,
                    titleStyle:
                        context.styles.numsS.copyWith(color: RishColors.carbs),
                  ),
                  PieChartSectionData(
                    value: res.$3,
                    color: RishColors.fat,
                    showTitle: true,
                    radius: 12,
                    title: '${res.$3.toInt()}%',
                    titlePositionPercentageOffset: -2.3,
                    titleStyle:
                        context.styles.numsS.copyWith(color: RishColors.fat),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 26.w),
          Expanded(
            child: BlocBuilder<WhoopBloc, WhoopState>(
              bloc: whoopBloc,
              builder: (context, state) {
                final kcals = whoopBloc.calculateMacrosInKcal();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row(
                    //   children: [
                    //     Text(
                    //       isToday
                    //           ? "${state.day.macros.protein}g "
                    //           : '${day.macros.protein}g ',
                    //       style: context.styles.numsM
                    //           .copyWith(color: RishColors.protein),
                    //     ), Column(
                    //       children: [
                    //         Text('123'),
                    //         Text
                    //       ],
                    //     )
                    //   ],
                    // ),
                    // Row(
                    //   children: [
                    //     Text(
                    //       isToday
                    //           ? "${state.day.macros.carbs}g "
                    //           : '${day.macros.carbs}g ',
                    //       style: context.styles.numsM
                    //           .copyWith(color: RishColors.carbs),
                    //     )
                    //   ],
                    // ),
                    // Row(
                    //   children: [
                    //     Text(
                    //       isToday
                    //           ? "${state.day.macros.fat}g "
                    //           : '${day.macros.fat}g ',
                    //       style:
                    //           context.styles.numsM.copyWith(color: RishColors.fat),
                    //     )
                    //   ],
                    // ),
                    Text.rich(
                      TextSpan(
                        text: isToday
                            ? '${state.day.macros.protein.comaThisNumber()}g '
                            : '${day.macros.protein.comaThisNumber()}g ',
                        style: context.styles.numsM
                            .copyWith(color: RishColors.protein),
                        children: [
                          TextSpan(
                            text:
                                'Protein\n(${kcals.$2.comaThisNumber()} kcal)',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.protein),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text.rich(
                      TextSpan(
                        text: isToday
                            ? '${state.day.macros.carbs.comaThisNumber()}g '
                            : '${day.macros.carbs.comaThisNumber()}g ',
                        style: context.styles.numsM
                            .copyWith(color: RishColors.carbs),
                        children: [
                          TextSpan(
                            text: 'Carbs\n(${kcals.$1.comaThisNumber()} kcal)',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.carbs),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text.rich(
                      TextSpan(
                        text: isToday
                            ? '${state.day.macros.fat.comaThisNumber()}g '
                            : '${day.macros.fat.comaThisNumber()}g ',
                        style: context.styles.numsM
                            .copyWith(color: RishColors.fat),
                        children: [
                          TextSpan(
                            text: 'Fat\n(${kcals.$3.comaThisNumber()} kcal)',
                            style: context.styles.regularMedium.copyWith(
                              color: RishColors.fat,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
