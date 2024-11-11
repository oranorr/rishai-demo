part of '../home_page.dart';

class _CaloriesWidget extends StatelessWidget {
  final DayEntity day;

  const _CaloriesWidget({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, userState) {
        final mod = day.isToday
            ? userState.user.userGoal!.modificator
            : ((day.macros.kcal / day.weekTdeeAverage) - 1);

        bool isPositive = mod > 0;
        return BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, whoopState) {
            int kcal =
                day.isToday ? whoopState.day.macros.kcal : day.macros.kcal;
            return SizedBox(
              height: 200.h,
              child: Row(
                children: [
                  SizedBox(
                    height: 200.h,
                    width: 150.w,
                    child: _Card(
                      child: Column(
                        children: [
                          Text.rich(
                            TextSpan(
                                text: 'Goal Setting ',
                                style: context.styles.regularSmall,
                                children: [
                                  TextSpan(
                                      text:
                                          '${isPositive ? '+' : ''}${(mod * 100).round()}%',
                                      style: context.styles.numsS)
                                ]),
                          ),
                          Expanded(
                            child: _SimpleBarChart(
                                xValue: kcal.toDouble(),
                                yValue: day.weekTdeeAverage),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    'Today\'s consumption goal',
                                    style: context.styles.regularSmall
                                        .copyWith(fontSize: 13),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  '$kcal kcal',
                                  style: context.styles.numsM
                                      .copyWith(color: RishColors.primary),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15.w,
                        ),
                        Expanded(
                          child: _Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    'Average weekly burn',
                                    style: context.styles.regularSmall
                                        .copyWith(fontSize: 13),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  '${day.weekTdeeAverage.round()} kcal',
                                  style: context.styles.numsM
                                      .copyWith(color: RishColors.protein),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final double xValue;
  final double yValue;

  const _SimpleBarChart({
    super.key,
    required this.xValue,
    required this.yValue,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (xValue > yValue ? xValue : yValue) *
              1.2, // Оставляем немного места сверху
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: xValue,
                  color: RishColors.primary,
                  width: 15,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: yValue,
                  color: RishColors.protein,
                  width: 15,
                ),
              ],
            ),
          ],
          titlesData: const FlTitlesData(
            show: false, // Отключаем все заголовки
          ),
          borderData: FlBorderData(show: false), // Отключаем рамки
          gridData: const FlGridData(show: false), // Отключаем сетку
        ),
      ),
    );
  }
}


  //    Row(
        // children: [
        //   SizedBox.square(
        //     dimension: 140.w,
        //     child: BlocBuilder<UserBloc, UserState>(
        //       bloc: userBloc,
        //       builder: (context, userState) {
        //         final mod = day.isToday
        //             ? userState.user.userGoal!.modificator
        //             : ((day.macros.kcal / day.weekTdeeAverage) - 1);
        //         return Container();
        //         // tack(
        //         //   children: [
        //         //     Positioned.fill(
        //         //       child: CircularProgressIndicator(
        //         //         value: mod < 0 ? 1 + mod : 1,
        //         //         strokeWidth: 9,
        //         //         strokeCap: StrokeCap.round,
        //         //         backgroundColor: RishColors.stroke,
        //         //       ),
        //         //     ),
        //         //     Positioned.fill(
        //         //       right: 12.w,
        //         //       left: 12.w,
        //         //       top: 12.w,
        //         //       bottom: 12.w,
        //         //       child: CircularProgressIndicator(
        //         //         value: mod > 0 ? 1 - mod : 1,
        //         //         strokeWidth: 9,
        //         //         color: RishColors.protein,
        //         //         backgroundColor: RishColors.stroke,
        //         //         strokeCap: StrokeCap.round,
        //         //       ),
        //         //     )
        //         //   ],
        //         // );
        //       },
        //     ),
        //   ),
        //   // SizedBox(width: 20.w),
        //   // Expanded(
        //   //   child: Column(
        //   //     crossAxisAlignment: CrossAxisAlignment.start,
        //   //     children: [
        //   //       BlocBuilder<WhoopBloc, WhoopState>(
        //   //         bloc: whoopBloc,
        //   //         builder: (context, state) {
        //   //           int kcal =
        //   //               day.isToday ? state.day.macros.kcal : day.macros.kcal;
        //   //           return Text(
        //   //             '$kcal kcal',
        //   //             style: context.styles.numsM
        //   //                 .copyWith(color: RishColors.primary),
        //   //           );
        //   //         },
        //   //       ),
        //   //       Text(
        //   //         'Daily Calorie Goal',
        //   //         style: context.styles.regularMedium
        //   //             .copyWith(color: RishColors.primary),
        //   //       ),
        //   //       SizedBox(height: 12.h),
        //   //       FittedBox(
        //   //         fit: BoxFit.scaleDown,
        //   //         child: Text(
        //   //           '${day.weekTdeeAverage.round()} kcal',
        //   //           style:
        //   //               context.styles.numsM.copyWith(color: RishColors.protein),
        //   //         ),
        //   //       ),
        //   //       Text(
        //   //         'Calories Burned (TDEE) - 7 Days Average',
        //   //         style: context.styles.regularMedium
        //   //             .copyWith(color: RishColors.protein),
        //   //         softWrap: true,
        //   //       ),
        //   //     ],
        //   //   ),
        //   // ),
        // ],
        // )