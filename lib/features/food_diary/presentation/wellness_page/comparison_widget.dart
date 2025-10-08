part of 'wellness_page.dart';

/// Виджет для сравнения показателей wellness
class _ComparisonWidget extends StatelessWidget {
  const _ComparisonWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        final welnessEntity = state.day.welnessEntity;
        final targetMacros = state.day.macros; // Целевые макросы
        final consumedMacros = welnessEntity?.consumedMacros ??
            MacrosBreakdown(
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
            ); // Потребленные макросы

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Consumption vs. Targets",
                style: context.styles.boldLarge,
              ),
              SizedBox(height: 8.h),

              // Калории
              _MacroProgressWidget(
                title: 'Calories',
                consumed: consumedMacros.kcal.toDouble(),
                target: targetMacros.kcal.toDouble(),
                color: RishColors.calories,
                unit: ' kcals',
                showKcals:
                    false, // Для калорий не показываем дополнительные kcals
              ),
              SizedBox(height: 24.h),

              // Белки
              _MacroProgressWidget(
                title: 'Protein',
                consumed: consumedMacros.protein.toDouble(),
                target: targetMacros.protein.toDouble(),
                color: RishColors.protein,
                unit: 'g',
                kcals: consumedMacros.protein * 4, // 1г белка = 4 kcals
              ),
              SizedBox(height: 24.h),

              // Углеводы
              _MacroProgressWidget(
                title: 'Carbs',
                consumed: consumedMacros.carbs.toDouble(),
                target: targetMacros.carbs.toDouble(),
                color: RishColors.carbs,
                unit: 'g',
                kcals: consumedMacros.carbs * 4, // 1г углеводов = 4 kcals
              ),
              SizedBox(height: 24.h),

              // Жиры
              _MacroProgressWidget(
                title: 'Fats',
                consumed: consumedMacros.fat.toDouble(),
                target: targetMacros.fat.toDouble(),
                color: RishColors.fat,
                unit: 'g',
                kcals: consumedMacros.fat * 9, // 1г жиров = 9 kcals
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Виджет для отображения одного макроса с прогресс-баром
class _MacroProgressWidget extends StatelessWidget {
  const _MacroProgressWidget({
    required this.title,
    required this.consumed,
    required this.target,
    required this.color,
    required this.unit,
    this.kcals,
    this.showKcals = true,
  });

  final String title;
  final double consumed;
  final double target;
  final Color color;
  final String unit;
  final int? kcals;
  final bool showKcals;

  @override
  Widget build(BuildContext context) {
    // Вычисляем прогресс (может быть больше 100%)
    final progress = target > 0 ? consumed / target : 0.0;
    final progressClamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Text(
          title,
          style: context.styles.regularMedium,
        ),
        SizedBox(height: 8.h),

        // Значения потребления/цели
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatNumber(consumed.toInt())}/${_formatNumber(target.toInt())}$unit',
              style: context.styles.h3,
            ),
            if (showKcals && kcals != null)
              Text(
                '${_formatNumber(kcals!)} kcals',
                style: context.styles.regularMedium,
              ),
          ],
        ),
        SizedBox(height: 12.h),

        // Прогресс-бар
        Container(
          width: double.infinity,
          height: 8.h,
          decoration: BoxDecoration(
            color: RishColors.stroke,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Основной прогресс-бар
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressClamped,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Форматирует числа с запятыми (например, 1596 -> 1,596)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        );
  }
}
