// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../home_page.dart';

class _MacrosBreakdownWidget extends StatelessWidget {
  const _MacrosBreakdownWidget({
    required this.day,
    required this.isToday,
  });
  final bool isToday;
  final DayEntity day;

  // Локальный метод для расчета процентов макросов для конкретного дня
  (double proteinPer, double carbsPer, double fatsPer)
      _calculatePercentageForDay(DayEntity dayData) {
    int proteinKcal = dayData.macros.protein * 4;
    int carbsKcal = dayData.macros.carbs * 4;
    int fatsKcal = dayData.macros.fat * 9;

    final totalKcal = dayData.macros.kcal;

    double proteinPerc = (proteinKcal / totalKcal) * 100;
    double carbsPerc = (carbsKcal / totalKcal) * 100;
    double fatsPerc = (fatsKcal / totalKcal) * 100;

    int proteinRounded = proteinPerc.round();
    int carbsRounded = carbsPerc.round();
    int fatsRounded = fatsPerc.round();

    int totalRounded = proteinRounded + carbsRounded + fatsRounded;
    if (totalRounded != 100) {
      int difference = 100 - totalRounded;

      if (proteinRounded >= carbsRounded && proteinRounded >= fatsRounded) {
        proteinRounded += difference;
      } else if (carbsRounded >= proteinRounded &&
          carbsRounded >= fatsRounded) {
        carbsRounded += difference;
      } else {
        fatsRounded += difference;
      }
    }

    return (
      proteinRounded.toDouble(),
      carbsRounded.toDouble(),
      fatsRounded.toDouble(),
    );
  }

  // Локальный метод для расчета калорий макросов для конкретного дня
  (int carbsKcal, int proteinKcal, int fatKcal) _calculateMacrosInKcalForDay(
    DayEntity dayData,
  ) {
    int proteinKcal = dayData.macros.protein * 4;
    int carbsKcal = dayData.macros.carbs * 4;
    int fatsKcal = dayData.macros.fat * 9;
    return (carbsKcal, proteinKcal, fatsKcal);
  }

  @override
  Widget build(BuildContext context) {
    // Используем макросы для правильного дня
    final currentDay = isToday ? whoopBloc.state.day : day;
    final res = _calculatePercentageForDay(currentDay);

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Today's targets",
                style: context.styles.boldLarge,
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () async => RishiDialog.infoPopup(
                  context,
                  'Your daily consumption goal of calories is broken up into its macronutrient constituents of proteins, carbs, and fats. This gives you individualised targets for each macronutrient, and they sum up to your daily calorie consumption goal.',
                  title: "Today's targets",
                ),
                child: SvgPicture.asset('assets/icons/info_round.svg'),
              ),
              const Spacer(),
              Text(
                '${day.macros.kcal.comaThisNumber()} kcals',
                style: context.styles.boldLarge,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Круговая диаграмма по центру
          Center(
            child: SizedBox.square(
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
                      titleStyle: context.styles.numsS
                          .copyWith(color: RishColors.carbs),
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
          ),
          SizedBox(height: 20.h),
          // Показатели макросов в горизонтальной строке как на изображении
          BlocBuilder<WhoopBloc, WhoopState>(
            bloc: whoopBloc,
            builder: (context, state) {
              // Используем калории для правильного дня
              final kcals = _calculateMacrosInKcalForDay(currentDay);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Protein
                  Expanded(
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            text:
                                '${currentDay.macros.protein.comaThisNumber()}g ',
                            style: context.styles.boldLarge
                                .copyWith(color: RishColors.protein),
                            children: [
                              TextSpan(
                                text: 'Protein',
                                style: context.styles.boldLarge
                                    .copyWith(color: RishColors.protein),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${kcals.$2.comaThisNumber()} kcals',
                          style: context.styles.regularMedium
                              .copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Carbs
                  Expanded(
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            text:
                                '${currentDay.macros.carbs.comaThisNumber()}g ',
                            style: context.styles.boldLarge
                                .copyWith(color: RishColors.carbs),
                            children: [
                              TextSpan(
                                text: 'Carbs',
                                style: context.styles.boldLarge
                                    .copyWith(color: RishColors.carbs),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${kcals.$1.comaThisNumber()} kcals',
                          style: context.styles.regularMedium
                              .copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Fat
                  Expanded(
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            text: '${currentDay.macros.fat.comaThisNumber()}g ',
                            style: context.styles.boldLarge
                                .copyWith(color: RishColors.fat),
                            children: [
                              TextSpan(
                                text: 'Fats',
                                style: context.styles.boldLarge
                                    .copyWith(color: RishColors.fat),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${kcals.$3.comaThisNumber()} kcals',
                          style: context.styles.regularMedium
                              .copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
