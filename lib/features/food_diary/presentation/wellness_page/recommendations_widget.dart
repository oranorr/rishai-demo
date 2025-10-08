part of 'wellness_page.dart';

/// Виджет с рекомендациями по питанию
class _RecommendationsWidget extends StatelessWidget {
  const _RecommendationsWidget();

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
          padding: EdgeInsets.all(16.w).copyWith(bottom: 4.h),
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой информации
              Row(
                children: [
                  Text(
                    'Recommendations',
                    style: context.styles.boldLarge,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => () {},
                    child: SvgPicture.asset('assets/icons/info_round.svg'),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // AI рекомендации (плейсхолдер)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: RishColors.stroke,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Go lower-carb next meal; add 150g\nchicken/fish, non-starchy veg.',
                  style: context.styles.regularMedium
                      .copyWith(color: RishColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20.h),

              // Макросы с прогресс-барами
              ..._buildMacroWidgets(context, targetMacros, consumedMacros),
            ],
          ),
        );
      },
    );
  }

  /// Создает виджеты для отображения макросов
  List<Widget> _buildMacroWidgets(
    BuildContext context,
    MacrosBreakdown targetMacros,
    MacrosBreakdown consumedMacros,
  ) {
    final macrosData = [
      _MacrosData(
        title: 'Calories',
        status: _getCaloriesStatus(targetMacros.kcal, consumedMacros.kcal),
        text: _getCaloriesText(targetMacros.kcal, consumedMacros.kcal),
        color: RishColors.calories,
        consumed: consumedMacros.kcal.toDouble(),
        target: targetMacros.kcal.toDouble(),
      ),
      _MacrosData(
        title: 'Proteins',
        status: _getProteinStatus(targetMacros.protein, consumedMacros.protein),
        text: _getProteinText(targetMacros.protein, consumedMacros.protein),
        color: RishColors.protein,
        consumed: consumedMacros.protein.toDouble(),
        target: targetMacros.protein.toDouble(),
      ),
      _MacrosData(
        title: 'Carbs',
        status: _getCarbsStatus(targetMacros.carbs, consumedMacros.carbs),
        text: _getCarbsText(targetMacros.carbs, consumedMacros.carbs),
        color: RishColors.carbs,
        consumed: consumedMacros.carbs.toDouble(),
        target: targetMacros.carbs.toDouble(),
      ),
      _MacrosData(
        title: 'Fats',
        status: _getFatsStatus(targetMacros.fat, consumedMacros.fat),
        text: _getFatsText(targetMacros.fat, consumedMacros.fat),
        color: RishColors.fat,
        consumed: consumedMacros.fat.toDouble(),
        target: targetMacros.fat.toDouble(),
      ),
    ];

    return macrosData.map((macro) => _MacroWidget(macro: macro)).toList();
  }

  // Методы для определения статуса калорий
  String _getCaloriesStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getCaloriesText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return 'You are in a deficit and need to consume $deficit more kcals.';
    } else {
      final surplus = consumed - target;
      return 'You are eating in a surplus and have consumed $surplus more than your daily target.';
    }
  }

  // Методы для определения статуса белков
  String _getProteinStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getProteinText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You are under-eating protein and need to consume $deficit grams to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your protein target by $surplus grams for today.';
    }
  }

  // Методы для определения статуса углеводов
  String _getCarbsStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getCarbsText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You can still consume $deficit grams of carbs to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your carbs target by $surplus grams for today.';
    }
  }

  // Методы для определения статуса жиров
  String _getFatsStatus(int target, int consumed) {
    return consumed < target ? 'Deficit' : 'Surplus';
  }

  String _getFatsText(int target, int consumed) {
    if (consumed < target) {
      final deficit = target - consumed;
      return "You can still consume $deficit grams of fats to meet today's target.";
    } else {
      final surplus = consumed - target;
      return 'You have surpassed your fats target by $surplus grams for today.';
    }
  }
}

/// Модель данных для макроса
class _MacrosData {
  _MacrosData({
    required this.title,
    required this.status,
    required this.text,
    required this.color,
    required this.consumed,
    required this.target,
  });

  final String title;
  final String status;
  final String text;
  final Color color;
  final double consumed;
  final double target;
}

/// Виджет для отображения одного макроса с прогресс-баром
class _MacroWidget extends StatelessWidget {
  const _MacroWidget({
    required this.macro,
  });

  final _MacrosData macro;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RishColors.stroke,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и статус
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                macro.title,
                style: context.styles.boldLarge.copyWith(
                  color: macro.color,
                ),
              ),
              Text(
                macro.status,
                style: context.styles.boldLarge.copyWith(
                  color: macro.color,
                ),
              ),
            ],
          ),

          // Описание
          Text(
            macro.text,
            style: context.styles.regularMedium,
          ),
        ],
      ),
    );
  }
}
