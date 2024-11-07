// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../home_page.dart';

class _MacrosBreakdownWidget extends StatelessWidget {
  final DayEntity day;
  final bool isToday;
  const _MacrosBreakdownWidget({
    super.key,
    required this.day,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final res = whoopBloc.calculatePercentage();

    return _Card(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 140.w,
          child: PieChart(
            PieChartData(
              sectionsSpace: 6,
              sections: [
                PieChartSectionData(
                  value: res.$2,
                  color: RishColors.carbs,
                  radius: 12,
                  showTitle: true,
                  title: "${res.$2.toInt().toString()}%",
                  titlePositionPercentageOffset: -2.3,
                  titleStyle:
                      context.styles.numsS.copyWith(color: RishColors.carbs),
                ),
                PieChartSectionData(
                  value: res.$1,
                  color: RishColors.protein,
                  showTitle: true,
                  radius: 12,
                  title: "${res.$1.toInt().toString()}%",
                  titlePositionPercentageOffset: -2.3,
                  titleStyle:
                      context.styles.numsS.copyWith(color: RishColors.protein),
                ),
                PieChartSectionData(
                  value: res.$3,
                  color: RishColors.fat,
                  showTitle: true,
                  radius: 12,
                  title: "${res.$3.toInt().toString()}%",
                  titlePositionPercentageOffset: -2.3,
                  titleStyle:
                      context.styles.numsS.copyWith(color: RishColors.fat),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 20.w),
        BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, state) {
            final kcals = whoopBloc.calculateMacrosInKcal();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
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
                          ? "${state.day.macros.protein}g "
                          : '${day.macros.protein}g ',
                      style: context.styles.numsM
                          .copyWith(color: RishColors.protein),
                      children: [
                        TextSpan(
                          text: 'Protein\n(${kcals.$2} kcal)',
                          style: context.styles.regularMedium
                              .copyWith(color: RishColors.protein),
                        )
                      ]),
                ),
                SizedBox(height: 12.h),
                Text.rich(
                  TextSpan(
                      text: isToday
                          ? "${state.day.macros.carbs}g "
                          : '${day.macros.carbs}g ',
                      style: context.styles.numsM
                          .copyWith(color: RishColors.carbs),
                      children: [
                        TextSpan(
                            text: 'Carbs\n(${kcals.$1} kcal)',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.carbs))
                      ]),
                ),
                SizedBox(height: 12.h),
                Text.rich(
                  TextSpan(
                      text: isToday
                          ? "${state.day.macros.fat}g "
                          : '${day.macros.fat}g ',
                      style:
                          context.styles.numsM.copyWith(color: RishColors.fat),
                      children: [
                        TextSpan(
                          text: 'Fat\n(${kcals.$3} kcal)',
                          style: context.styles.regularMedium.copyWith(
                            color: RishColors.fat,
                          ),
                        )
                      ]),
                ),
              ],
            );
          },
        )
      ],
    ));
  }
}
