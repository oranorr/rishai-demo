part of '../home_page.dart';

class _CaloriesWidget extends StatelessWidget {
  const _CaloriesWidget({
    required this.day,
  });
  final DayEntity day;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, userState) {
        return BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, whoopState) {
            // [FIX] Всегда рассчитываем модификатор на основе данных дня
            // Это гарантирует актуальность отображения после обновления цели
            final currentDay = day.isToday ? whoopState.day : day;
            final mod =
                (currentDay.macros.kcal / currentDay.weekTdeeAverage) - 1;

            bool isPositive = mod > 0;
            int kcal = currentDay.macros.kcal;
            return SizedBox(
              height: 225.h,
              child: Row(
                children: [
                  SizedBox(
                    // height: 200.h,
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
                                  style: context.styles.numsS,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _SimpleBarChart(
                              xValue: kcal.toDouble(),
                              yValue: currentDay.weekTdeeAverage.toDouble(),
                            ),
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
                                    "Today's consumption goal",
                                    style: context.styles.regularSmall
                                        .copyWith(fontSize: 13),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  '${kcal.comaThisNumber()} kcal',
                                  style: context.styles.numsM
                                      .copyWith(color: RishColors.primary),
                                ),
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
                                  '${currentDay.weekTdeeAverage.comaThisNumber()} kcal',
                                  style: context.styles.numsM
                                      .copyWith(color: RishColors.protein),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
  const _SimpleBarChart({
    required this.xValue,
    required this.yValue,
  });
  final double xValue;
  final double yValue;

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
            show: false,
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(
            enabled: false,
          ),
        ),
      ),
    );
  }
}
