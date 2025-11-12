import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DiaryDropDown Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Выпадающий список с анимированным раскрытием контента.
/// Включает плавную анимацию поворота иконки и появления контента.
///
/// Используется для организации контента в секциях на странице дневника.
///
/// **Особенности:**
/// - Плавная анимация раскрытия/закрытия (300ms)
/// - Поворот иконки на 90° при раскрытии
/// - Адаптивный дизайн с использованием ScreenUtil
/// - Следует Apple HIG для анимаций и интерактивности
///
class DiaryDropDown extends StatefulWidget {
  const DiaryDropDown({
    required this.child,
    required this.title,
    super.key,
    this.initiallyExpanded = false,
  });

  /// Контент, который будет раскрываться/скрываться
  final Widget child;

  /// Заголовок дропдауна
  final String title;

  /// Начальное состояние раскрытия
  final bool initiallyExpanded;

  @override
  State<DiaryDropDown> createState() => _DiaryDropDownState();
}

class _DiaryDropDownState extends State<DiaryDropDown>
    with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;

    // ┌─────────────────────────────────────────────────────────────────────┐
    // │ Инициализируем контроллер анимации для плавного поворота иконки     │
    // │ Длительность 300ms соответствует Apple HIG рекомендациям            │
    // └─────────────────────────────────────────────────────────────────────┘
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // ┌─────────────────────────────────────────────────────────────────────┐
    // │ Создаем анимацию поворота иконки от 0 до 90 градусов               │
    // │ 0.25 * 2π = π/2 = 90 градусов                                       │
    // └─────────────────────────────────────────────────────────────────────┘
    _iconRotationAnimation = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // ┌─────────────────────────────────────────────────────────────────────┐
    // │ Создаем анимацию размера для плавного скрытия контента              │
    // │ Используется для предотвращения видимости контента при закрытии     │
    // └─────────────────────────────────────────────────────────────────────┘
    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Если начальное состояние раскрыто, сразу устанавливаем анимацию
    if (isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(DiaryDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Автоматически раскрываем, если initiallyExpanded изменился на true
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded &&
        widget.initiallyExpanded &&
        !isExpanded) {
      setState(() {
        isExpanded = true;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    // [dispose] Освобождаем ресурсы контроллера анимации
    _animationController.dispose();
    super.dispose();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// _toggleExpansion
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Переключает состояние расширения дропдауна с плавной анимацией иконки.
  ///
  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });

    // [_toggleExpansion] Запускаем или останавливаем анимацию поворота иконки
    if (isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: double.infinity,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleExpansion,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: context.styles.boldMedium,
                  ),
                  const Spacer(),
                  // ┌───────────────────────────────────────────────────────┐
                  // │ Анимированная иконка с плавным поворотом              │
                  // └───────────────────────────────────────────────────────┘
                  AnimatedBuilder(
                    animation: _iconRotationAnimation,
                    builder: (context, child) {
                      return RotationTransition(
                        turns: _iconRotationAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: RishColors.textSecondary,
                          size: 24.w,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ┌───────────────────────────────────────────────────────────────┐
          // │ Контент дропдауна с анимированным появлением                  │
          // │ ClipRect с Align и heightFactor обеспечивает плавное скрытие  │
          // │ без видимости остатков контента при закрытии                  │
          // └───────────────────────────────────────────────────────────────┘
          AnimatedBuilder(
            animation: _sizeAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _sizeAnimation.value,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 16.h,
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
