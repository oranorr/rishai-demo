part of '../home_page.dart';

class _HealthMetricsWidget extends StatelessWidget {
  const _HealthMetricsWidget({
    required this.day,
  });
  final DayEntity day;

  @override
  Widget build(BuildContext context) {
    HealthMetricsEntity health = day.healthMetrics;

    // Goal Setting: (kcal / среднесуточный TDEE недели - 1) * 100.
    // У только что созданного дня [weekTdeeAverage] часто 0 (ещё нет WHOOP-данных)
    // — деление даёт Infinity, а [.round()] бросает UnsupportedError.
    final weekTdeeAvg = day.weekTdeeAverage;
    late final int goalSettingPercent;
    if (weekTdeeAvg <= 0) {
      goalSettingPercent = 0;
    } else {
      final mod = (day.macros.kcal / weekTdeeAvg) - 1;
      final pct = mod * 100;
      goalSettingPercent = pct.isFinite ? pct.round() : 0;
    }

    // Создаем расширенные списки с дополнительными метриками в правильном порядке
    // Порядок согласно дизайну: Goal Setting, BMI, BMR, 24h Cal Burn, Weekly Burn
    List<String> extendedNames = [
      'Goal Setting',
      'BMI',
      'BMR',
      '24h Cal Burn',
      'Average Weekly Burn',
    ];

    List<dynamic> extendedValues = [
      '${goalSettingPercent >= 0 ? '+' : ''}$goalSettingPercent%', // Goal Setting percentage
      health.bmi, // BMI
      health.bmr, // BMR
      health.lastTdee, // 24h Cal Burn
      '${day.weekTdeeAverage.comaThisNumber()} kcals', // Average weekly burn with units
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health metrics', style: context.styles.boldLarge),
          SizedBox(height: 8.h),
          Column(
            children: [
              // Верхняя строка: Goal Setting, BMI, BMR
              Row(
                children: [
                  // Goal Setting
                  Expanded(
                    child: _MetricCard(
                      title: extendedNames[0], // Goal Setting
                      value: extendedValues[0].toString(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // BMI
                  Expanded(
                    child: _MetricCard(
                      title: extendedNames[1], // BMI
                      value: (extendedValues[1] as int).comaThisNumber(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // BMR
                  Expanded(
                    child: _MetricCard(
                      title: extendedNames[2], // BMR
                      value: (extendedValues[2] as int).comaThisNumber(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              // Нижняя строка: 24h Cal Burn, Average Weekly Burn
              Row(
                children: [
                  // 24h Cal Burn
                  Expanded(
                    child: _MetricCard(
                      title: extendedNames[3], // 24h Cal Burn
                      value: (extendedValues[3] as int).comaThisNumber(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Average Weekly Burn
                  Expanded(
                    child: _MetricCard(
                      title: extendedNames[4], // Average Weekly Burn
                      value: extendedValues[4].toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Виджет для отдельной карточки метрики
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          60.h, // [HealthMetricsWidget] Фиксированная высота для всех карточек
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RishColors.stroke),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заголовок с автоматическим масштабированием
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: context.styles.regularMedium
                        .copyWith(color: RishColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Значение с автоматическим масштабированием
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: context.styles.numsS,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
