part of '../home_page.dart';

class PivotLifeWidget extends StatefulWidget {
  const PivotLifeWidget({
    required this.progress,
    super.key,
  });
  final double progress;

  @override
  State<PivotLifeWidget> createState() => _PivotLifeWidgetState();
}

class _PivotLifeWidgetState extends State<PivotLifeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  Color _currentColor = Colors.red;
  Color _targetColor = Colors.red;

  @override
  void initState() {
    super.initState();
    // [initState] Инициализируем контроллер анимации для плавной смены цвета
    _colorAnimationController = AnimationController(
      duration:
          const Duration(milliseconds: 500), // Длительность анимации 500мс
      vsync: this,
    );

    // [initState] Устанавливаем начальный цвет на основе текущего прогресса
    _currentColor = getColor(widget.progress);
    _targetColor = _currentColor;

    // [initState] Создаем ColorTween для анимации между цветами
    _colorAnimation = ColorTween(
      begin: _currentColor,
      end: _targetColor,
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut, // Плавная кривая анимации
      ),
    );
  }

  @override
  void didUpdateWidget(PivotLifeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [didUpdateWidget] Проверяем, изменился ли цвет при обновлении прогресса
    final newColor = getColor(widget.progress);
    if (newColor != _targetColor) {
      // [didUpdateWidget] Запускаем анимацию смены цвета
      _animateToNewColor(newColor);
    }
  }

  /// [_animateToNewColor] Анимирует переход к новому цвету
  void _animateToNewColor(Color newColor) {
    _currentColor = _targetColor; // Текущий цвет становится предыдущим целевым
    _targetColor = newColor; // Устанавливаем новый целевой цвет

    // [_animateToNewColor] Обновляем ColorTween с новыми цветами
    _colorAnimation = ColorTween(
      begin: _currentColor,
      end: _targetColor,
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // [_animateToNewColor] Сбрасываем и запускаем анимацию
    _colorAnimationController.reset();
    _colorAnimationController.forward();
  }

  @override
  void dispose() {
    // [dispose] Освобождаем ресурсы контроллера анимации
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Pivot Life',
                  style: context.styles.boldLarge,
                ),
                SizedBox(
                  width: 8.w,
                ),
                GestureDetector(
                  onTap: () async => RishiDialog.infoPopup(
                    context,
                    'Your Pivot Life score is a running average of your daily Wellness score since its inception',
                    title: 'Pivot Life Score',
                  ),
                  child: SvgPicture.asset('assets/icons/info_round.svg'),
                ),
                const Spacer(),
                Text(
                  '${widget.progress.toStringAsFixed(0)}%',
                  style: context.styles.regularMedium,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // [LinearProgressIndicator] Используем AnimatedBuilder для плавной анимации цвета
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: widget.progress / 100,
                  backgroundColor: RishColors.stroke,
                  borderRadius: BorderRadius.circular(16),
                  // [valueColor] Анимированный цвет с плавным переходом
                  valueColor: AlwaysStoppedAnimation(
                    _colorAnimation.value ?? _targetColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// [getColor] Определяет цвет прогресс-бара на основе процента прогресса
  /// 
  /// Цветовое распределение:
  /// - 0-29%: Красный (RishColors.error)
  /// - 30-54%: Оранжевый (#FA8F3E)
  /// - 55-79%: Желтый (RishColors.warning)
  /// - 80-100%: Зеленый (RishColors.success)
  /// 
  /// **Примечание:** Если progress приходит как доля (0.0-1.0), 
  /// функция автоматически конвертирует в проценты (0-100)
  Color getColor(double progress) {
    // [getColor] Проверяем, пришел ли progress как доля (0.0-1.0) или проценты (0-100)
    // Если значение меньше 1, значит это доля - конвертируем в проценты
    final progressInPercent = progress < 1.0 ? progress * 100 : progress;
    
    // [getColor] Используем строгие границы для правильного определения цвета
    // Округляем до целого для точного сравнения
    final roundedProgress = progressInPercent.round();
    
    if (roundedProgress <= 29) {
      // [getColor] 0-29%: Красный цвет для низкого прогресса
      return RishColors.error;
    } else if (roundedProgress >= 30 && roundedProgress <= 54) {
      // [getColor] 30-54%: Оранжевый цвет для среднего-низкого прогресса
      return const Color(0xffFA8F3E);
    } else if (roundedProgress >= 55 && roundedProgress <= 79) {
      // [getColor] 55-79%: Желтый цвет для среднего-высокого прогресса
      return RishColors.warning;
    } else {
      // [getColor] 80-100%: Зеленый цвет для высокого прогресса
      return RishColors.success;
    }
  }
}
