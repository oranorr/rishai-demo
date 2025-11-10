part of '../home_page.dart';

class DailyWellnessWidget extends StatefulWidget {
  const DailyWellnessWidget({required this.day, super.key});
  final DayEntity day;

  @override
  State<DailyWellnessWidget> createState() => _DailyWellnessWidgetState();
}

class _DailyWellnessWidgetState extends State<DailyWellnessWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  // [rippleAnimation] Контроллер анимации для ripple эффекта контейнера
  late AnimationController _rippleAnimationController;
  late Animation<double> _rippleAnimation;

  // [_showTooltip] Флаг для показа подсказки при первом открытии
  bool _showTooltip = true;

  // [_tooltipAnimationController] Контроллер анимации для появления подсказки
  late AnimationController _tooltipAnimationController;
  late Animation<double> _tooltipAnimation;

  // [_getRingData] Получаем данные для колец из переданного day
  List<RingData> _getRingData() {
    final targetMacros = widget.day.macros;

    // [consumedMacros] Получаем потребленные макросы или используем нули
    final consumedMacros = widget.day.welnessEntity?.consumedMacros;

    return [
      // [Calories] Калории - внешнее кольцо
      RingData(
        label: 'Kcals',
        current: consumedMacros?.kcal.toDouble() ?? 0.0,
        target: targetMacros.kcal.toDouble(),
        color: RishColors.calories,
        unit: '',
      ),
      // [Protein] Белки - второе кольцо
      RingData(
        label: 'Protein',
        current: consumedMacros?.protein.toDouble() ?? 0.0,
        target: targetMacros.protein.toDouble(),
        color: RishColors.protein,
        unit: 'g',
      ),
      // [Carbs] Углеводы - третье кольцо
      RingData(
        label: 'Carbs',
        current: consumedMacros?.carbs.toDouble() ?? 0.0,
        target: targetMacros.carbs.toDouble(),
        color: RishColors.carbs,
        unit: 'g',
      ),
      // [Fats] Жиры - внутреннее кольцо
      RingData(
        label: 'Fats',
        current: consumedMacros?.fat.toDouble() ?? 0.0,
        target: targetMacros.fat.toDouble(),
        color: RishColors.fat,
        unit: 'g',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    // [_showTooltip] Проверяем, видел ли пользователь подсказку ранее
    _showTooltip = !prefsRepo.hasViewedWellnessTooltip();

    // [_getRingData] Получаем данные для колец
    final ringData = _getRingData();

    // Создаем контроллеры анимации для каждого кольца
    _animationControllers = List.generate(
      ringData.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        vsync: this,
      ),
    );

    // Создаем анимации с кривой в стиле Apple
    _animations = _animationControllers
        .map(
          (controller) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeOutCubic, // Кривая в стиле Apple
            ),
          ),
        )
        .toList();

    // [rippleAnimation] Создаем анимацию для ripple эффекта контейнера
    _rippleAnimationController = AnimationController(
      duration:
          const Duration(milliseconds: 2000), // Длительная плавная анимация
      vsync: this,
    );

    // [rippleAnimation] Анимация для ripple эффекта - от 0 до 1
    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _rippleAnimationController,
        curve: Curves.easeOutCubic, // Плавная кривая в стиле Apple
      ),
    );

    // [_tooltipAnimationController] Создаем анимацию для подсказки
    _tooltipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // [_tooltipAnimation] Анимация появления подсказки (масштаб и прозрачность)
    _tooltipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _tooltipAnimationController,
        curve: Curves.easeOutBack, // Эффектная кривая появления
      ),
    );

    // Запускаем анимации с задержкой
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _animationControllers[i].forward();
        }
      });
    }

    // [tooltipAnimation] Запускаем анимацию подсказки с задержкой после колец
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _showTooltip) {
        _tooltipAnimationController.forward();
      }
    });

    // [rippleAnimation] Не запускаем ripple анимацию если показываем подсказку
    // Она запустится только после закрытия подсказки
    if (!_showTooltip) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _rippleAnimationController.repeat(); // Повторяем анимацию бесконечно
        }
      });
    }
  }

  @override
  void didUpdateWidget(DailyWellnessWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // [didUpdateWidget] Проверяем, изменились ли данные wellness entity
    if (oldWidget.day.welnessEntity != widget.day.welnessEntity) {
      // Сбрасываем анимации и запускаем заново
      for (final controller in _animationControllers) {
        controller.reset();
      }
      _rippleAnimationController.reset();

      // Запускаем анимации заново
      _startAnimations();
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    // [dispose] Освобождаем ресурсы контроллера ripple анимации
    _rippleAnimationController.dispose();
    // [dispose] Освобождаем ресурсы контроллера анимации подсказки
    _tooltipAnimationController.dispose();
    super.dispose();
  }

  // [updateAnimations] Метод для обновления анимаций при изменении данных
  void _updateAnimations() {
    final ringData = _getRingData();

    // Если количество колец изменилось, пересоздаем контроллеры
    if (_animationControllers.length != ringData.length) {
      // Освобождаем старые контроллеры
      for (final controller in _animationControllers) {
        controller.dispose();
      }

      // Создаем новые контроллеры
      _animationControllers = List.generate(
        ringData.length,
        (index) => AnimationController(
          duration: Duration(milliseconds: 1500 + (index * 200)),
          vsync: this,
        ),
      );

      // Создаем новые анимации
      _animations = _animationControllers
          .map(
            (controller) => Tween<double>(
              begin: 0,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: controller,
                curve: Curves.easeOutCubic,
              ),
            ),
          )
          .toList();

      // Запускаем анимации
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    // [updateAnimations] Обновляем анимации при каждом rebuild
    _updateAnimations();

    return Column(
      children: [
        Text('Daily Nutritional Wellness', style: context.styles.h2),
        SizedBox(height: 16.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Consumption",
                  style: context.styles.boldLarge,
                ),
                // [ringDisplay] Фитнесс кольца в центре
                Center(
                  child: () {
                    final ringData = _getRingData();

                    // [ringsDisplay] Показываем кольца с данными
                    return SizedBox(
                      width: double.infinity,
                      height: 350
                          .h, // Увеличенная высота для подсказки над кольцами
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip
                            .none, // Позволяем содержимому выходить за границы
                        children: [
                          // Рисуем кольца от внешнего к внутреннему
                          for (int i = 0; i < ringData.length; i++)
                            AnimatedBuilder(
                              animation: _animations[i],
                              builder: (context, child) {
                                // [ringSize] Рассчитываем размеры для колец с промежутком 2px
                                // Центральный круг: 80w диаметр (40w радиус)
                                // Каждое кольцо имеет толщину 22w + промежуток 2px между кольцами
                                final strokeWidth = 22.w;
                                final centerRadius =
                                    52.w; // Радиус центрального круга
                                final ringSpacing =
                                    2.w; // Промежуток между кольцами

                                // Рассчитываем радиус для каждого кольца от центра наружу
                                // Жиры (i=3): радиус = centerRadius + strokeWidth/2 + (strokeWidth + spacing) * 0
                                // Углеводы (i=2): радиус = centerRadius + strokeWidth/2 + (strokeWidth + spacing) * 1
                                // Протеин (i=1): радиус = centerRadius + strokeWidth/2 + (strokeWidth + spacing) * 2
                                // Калории (i=0): радиус = centerRadius + strokeWidth/2 + (strokeWidth + spacing) * 3
                                final ringIndex = ringData.length -
                                    1 -
                                    i; // Инвертируем индекс
                                final ringRadius = centerRadius +
                                    strokeWidth / 2 +
                                    (strokeWidth + ringSpacing) * ringIndex;
                                final ringSize =
                                    ringRadius * 2; // Диаметр = радиус * 2

                                return CustomPaint(
                                  size: Size(ringSize, ringSize),
                                  painter: FitnessRingPainter(
                                    // [progress] Убираем ограничение clamp(0.0, 1.0) для показа переедания в кольцах
                                    progress: _animations[i].value *
                                        (ringData[i].target > 0
                                            ? (ringData[i].current /
                                                    ringData[i].target)
                                                .clamp(0.0, double.infinity)
                                            : 0.0),
                                    color: ringData[i].color,
                                    strokeWidth:
                                        strokeWidth, // Используем вычисленную толщину
                                  ),
                                );
                              },
                            ),
                          // [rippleContainer] Центральный контейнер с ripple анимацией
                          GestureDetector(
                            onTap: !widget.day.isToday
                                ? null
                                : () async {
                                    // [hideTooltip] Скрываем подсказку при нажатии и сохраняем состояние
                                    if (_showTooltip) {
                                      setState(() {
                                        _showTooltip = false;
                                      });
                                      _tooltipAnimationController.reverse();

                                      // [saveTooltipState] Сохраняем, что пользователь видел подсказку
                                      await prefsRepo
                                          .setWellnessTooltipViewed();

                                      // Запускаем ripple анимацию
                                      Future.delayed(
                                        const Duration(milliseconds: 300),
                                        () {
                                          if (mounted) {
                                            _rippleAnimationController.repeat();
                                          }
                                        },
                                      );
                                    }
                                    // Переходим на страницу wellness
                                    appNavigationService.push(
                                      path: AppRoutes.wellnessPage.path,
                                    );
                                  },
                            child: AnimatedBuilder(
                              animation: _rippleAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // [centerContainer] Основной центральный контейнер
                                    Container(
                                      width: 80.w, // Размер центрального круга
                                      height: 80.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        // [border] Белая граница как на изображении
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.w,
                                        ),
                                        // [gradient] Радиальный градиент от краев к центру как на изображении
                                        gradient: const RadialGradient(
                                          radius: 0.8,
                                          colors: [
                                            Color(
                                              0xFF242239,
                                            ), // Очень темный фиолетовый по краям
                                            Color(
                                              0xFF511A5A,
                                            ), // Темно-фиолетовый
                                            Color(
                                              0xFFB54ADA,
                                            ), // Средний фиолетовый
                                            Color(
                                              0xFFEFC9ED,
                                            ), // Светло-розовый в центре
                                          ],
                                          stops: [0.0, 0.3, 0.6, 1.0],
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_calculateOverallProgress().toStringAsFixed(1)}%',
                                          style: context.styles.numsL.copyWith(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // [tooltip] Показываем подсказку если она активна - в основном Stack
                          if (_showTooltip) _buildTooltip(),
                        ],
                      ),
                    );
                  }(),
                ),
                // Легенда с данными
                _buildLegend(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final ringData = _getRingData();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ringData.map((ring) {
        // [progress] Убираем ограничение clamp(0, 100) чтобы показывать переедание
        final progress = ring.target > 0
            ? (ring.current / ring.target * 100).clamp(0, double.infinity)
            : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2.w,
            ), // Небольшой отступ между элементами
            child: Column(
              children: [
                // [percentage] Процент крупным шрифтом с цветом кольца с одной десятичной
                AutoSizeText(
                  '${progress.toStringAsFixed(1)}%',
                  style: context.styles.boldLarge.copyWith(color: ring.color),
                  maxLines: 1,
                  minFontSize: 10, // Минимальный размер шрифта
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                // [values] Значение с единицей измерения
                AutoSizeText(
                  ring.unit.isEmpty
                      ? '${ring.current.toInt()}'
                      : '${ring.current.toInt()}${ring.unit}',
                  style: context.styles.regularSmall.copyWith(
                    color: RishColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 8, // Минимальный размер шрифта для значений
                  overflow: TextOverflow.ellipsis,
                ),
                // [label] Название макроса
                AutoSizeText(
                  ring.label,
                  style: context.styles.regularSmall.copyWith(
                    color: RishColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // [_buildTooltip] Создает подсказку над центральным кругом
  Widget _buildTooltip() {
    return AnimatedBuilder(
      animation: _tooltipAnimation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: 100.h,
          ), // Отступ снизу чтобы поднять над центром
          child: Transform.scale(
            scale: _tooltipAnimation.value,
            child: Opacity(
              // [clampOpacity] Ограничиваем opacity от 0.0 до 1.0 так как easeOutBack может давать значения > 1.0
              opacity: _tooltipAnimation.value.clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // [tooltipContainer] Контейнер с текстом подсказкиi
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      // [tooltipBackground] Розово-фиолетовый градиент как на дизайне
                      color: RishColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                      // [tooltipShadow] Легкая тень для глубины
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE879F9).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tap here for details on your Wellness Score.',
                      style: context.styles.regularSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // [tooltipArrow] Стрелка вниз к центральному кругу
                  CustomPaint(
                    size: Size(12.w, 8.h),
                    painter: _TooltipArrowPainter(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateOverallProgress() {
    // [_calculateOverallProgress] Используем готовый DWS_final из WelnessEntity
    // вместо пересчета, чтобы учесть штрафы за переедание
    final welnessPercentage = widget.day.welnessEntity?.welnessPercentage;

    if (welnessPercentage != null) {
      // Если есть сохраненный DWS_final, используем его
      return welnessPercentage;
    }

    // Если WelnessEntity отсутствует, рассчитываем на основе макросов
    final ringData = _getRingData();

    double totalProgress = 0;
    for (final ring in ringData) {
      final ringProgress = ring.target > 0
          ? (ring.current / ring.target).clamp(0, double.infinity)
          : 0.0;
      totalProgress += ringProgress;
    }
    return (totalProgress / ringData.length) * 100;
  }
}

/// Модель данных для кольца прогресса
class RingData {
  RingData({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
}

/// Кастомный painter для рисования фитнесс-колец в стиле Apple
class FitnessRingPainter extends CustomPainter {
  FitnessRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });
  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Фоновое кольцо (неактивная часть)
    final backgroundPaint = Paint()
      ..color = RishColors.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Активное кольцо (прогресс) - чистый цвет без эффектов
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // [drawArc] Рисуем дугу прогресса начиная справа (0 радиан = 3 часа)
      // При переедании кольцо может делать больше одного оборота
      final clampedProgress = progress.clamp(0.0, double.infinity);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0, // Начинаем справа (3 часа на циферблате)
        2 *
            pi *
            clampedProgress, // Прогресс может быть больше 1 для показа переедания
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FitnessRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// [_TooltipArrowPainter] CustomPainter для рисования стрелки подсказки
class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE879F9), // Светло-розовый
          Color(0xFFC084FC), // Фиолетовый
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // [trianglePath] Рисуем треугольник стрелки
    final path = Path()
      ..moveTo(size.width / 2, size.height) // Нижняя точка (острие)
      ..lineTo(0, 0) // Верхний левый угол
      ..lineTo(size.width, 0) // Верхний правый угол
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TooltipArrowPainter oldDelegate) => false;
}
