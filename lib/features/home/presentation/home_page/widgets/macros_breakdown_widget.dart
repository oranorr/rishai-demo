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
                  showTitle: false,
                  radius: 12,
                  // borderSide:
                ),
                PieChartSectionData(
                  value: res.$1,
                  color: RishColors.protein,
                  showTitle: false,
                  radius: 12,
                ),
                PieChartSectionData(
                  value: res.$3,
                  color: RishColors.fat,
                  showTitle: false,
                  radius: 12,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 20.w),
        BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                      text: isToday
                          ? "${state.day.macros.protein}g "
                          : '${day.macros.protein}g ',
                      style: context.styles.numsM
                          .copyWith(color: RishColors.protein),
                      children: [
                        TextSpan(
                            text: 'Protein',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.protein))
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
                            text: 'Carbs',
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
                            text: 'Fat',
                            style: context.styles.regularMedium
                                .copyWith(color: RishColors.fat))
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
