part of '../home_page.dart';

class DailyWellnessWidget extends StatefulWidget {
  const DailyWellnessWidget({super.key});

  @override
  State<DailyWellnessWidget> createState() => _DailyWellnessWidgetState();
}

class _DailyWellnessWidgetState extends State<DailyWellnessWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  // [centerAnimation] Контроллер анимации для центрального текста
  late AnimationController _centerAnimationController;
  late Animation<double> _centerScaleAnimation;

  // Данные для колец (в реальном приложении будут приходить из состояния)
  final List<RingData> _ringData = [
    RingData(
      label: 'Kcals',
      current: 1596,
      target: 1956, // 81.6% от цели
      color: RishColors.calories,
      unit: '',
    ),
    RingData(
      label: 'Protein',
      current: 98,
      target: 167, // 58.7% от цели
      color: RishColors.protein,
      unit: 'g',
    ),
    RingData(
      label: 'Carbs',
      current: 124,
      target: 162, // 76.5% от цели
      color: RishColors.carbs,
      unit: 'g',
    ),
    RingData(
      label: 'Fats',
      current: 38,
      target: 71, // 53.5% от цели
      color: RishColors.fat,
      unit: 'g',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Создаем контроллеры анимации для каждого кольца
    _animationControllers = List.generate(
      _ringData.length,
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

    // [centerAnimation] Создаем анимацию для центрального текста
    _centerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Быстрая анимация
      vsync: this,
    );

    // [centerScaleAnimation] Анимация масштаба: норма -> увеличение -> норма
    _centerScaleAnimation = TweenSequence<double>([
      // Первая половина: увеличиваемся от 1.0 до 1.3
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      // Вторая половина: уменьшаемся от 1.3 до 1.0
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_centerAnimationController);

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

    // [centerAnimation] Запускаем анимацию центрального текста с небольшой задержкой
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _centerAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    // [dispose] Освобождаем ресурсы контроллера анимации центрального текста
    _centerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                SizedBox(height: 24.h),
                // Фитнесс кольца в центре
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 300
                        .h, // Обновленная высота для колец с промежутками 2px
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Рисуем кольца от внешнего к внутреннему
                        for (int i = 0; i < _ringData.length; i++)
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
                              final ringIndex = _ringData.length -
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
                                  progress: _animations[i].value *
                                      (_ringData[i].current /
                                          _ringData[i].target),
                                  color: _ringData[i].color,
                                  strokeWidth:
                                      strokeWidth, // Используем вычисленную толщину
                                ),
                              );
                            },
                          ),
                        // Центральный градиентный круг с процентом
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
                                Color(0xFF511A5A), // Темно-фиолетовый
                                Color(0xFFB54ADA), // Средний фиолетовый
                                Color(0xFFEFC9ED), // Светло-розовый в центре
                              ],
                              stops: [0.0, 0.3, 0.6, 1.0],
                            ),
                          ),
                          child: Center(
                            // [AnimatedBuilder] Анимированный центральный текст
                            child: AnimatedBuilder(
                              animation: _centerScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  // [scale] Используем 1.0 как базовое значение, если анимация не началась
                                  scale: _centerAnimationController.status ==
                                          AnimationStatus.dismissed
                                      ? 1.0
                                      : _centerScaleAnimation.value,
                                  child: Text(
                                    '${_calculateOverallProgress()}%',
                                    style: context.styles.numsL.copyWith(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _ringData.map((ring) {
        final progress = (ring.current / ring.target * 100).clamp(0, 100);
        return Expanded(
          child: Column(
            children: [
              // Процент крупным шрифтом с цветом кольца
              Text(
                '${progress.toInt()}%',
                style: context.styles.boldLarge.copyWith(color: ring.color),
              ),
              SizedBox(height: 4.h),
              // Значения
              Text(
                ring.unit.isEmpty
                    ? '${ring.current.toInt()} ${ring.label}'
                    : '${ring.current.toInt()}${ring.unit} ${ring.label}',
                style: context.styles.regularSmall.copyWith(
                  color: RishColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _calculateOverallProgress() {
    double totalProgress = 0;
    for (final ring in _ringData) {
      totalProgress += (ring.current / ring.target).clamp(0, 1);
    }
    return ((totalProgress / _ringData.length) * 100).round();
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
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0, // Начинаем справа (3 часа на циферблате)
        2 * pi * progress.clamp(0.0, 1.0), // Прогресс от 0 до 1
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
