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
    this.isExpanded,
    this.onExpansionChanged,
  });

  /// Контент, который будет раскрываться/скрываться
  final Widget child;

  /// Заголовок дропдауна
  final String title;

  /// Начальное состояние раскрытия
  final bool initiallyExpanded;

  /// Управляемое состояние раскрытия (если null, используется внутреннее состояние)
  final bool? isExpanded;

  /// Callback для изменения состояния раскрытия
  final void Function(bool isExpanded)? onExpansionChanged;

  @override
  State<DiaryDropDown> createState() => _DiaryDropDownState();
}

class _DiaryDropDownState extends State<DiaryDropDown>
    with SingleTickerProviderStateMixin {
  late bool _internalExpanded;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _sizeAnimation;

  /// [isExpanded] Получает текущее состояние раскрытия
  /// Если widget.isExpanded != null, используется управляемое состояние
  /// Иначе используется внутреннее состояние
  bool get isExpanded => widget.isExpanded ?? _internalExpanded;

  @override
  void initState() {
    super.initState();
    // [initState] Инициализируем внутреннее состояние
    _internalExpanded = widget.initiallyExpanded;

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
      end: 0.5,
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

    // [didUpdateWidget] Если используется управляемое состояние и оно изменилось
    if (widget.isExpanded != null) {
      final newExpanded = widget.isExpanded!;
      final oldExpanded = oldWidget.isExpanded ?? _internalExpanded;
      if (newExpanded != oldExpanded) {
        // [didUpdateWidget] Обновляем состояние без уведомления родителя,
        // так как изменение пришло от родителя
        _updateExpansion(newExpanded, notifyParent: false);
      }
    } else if (widget.initiallyExpanded != oldWidget.initiallyExpanded &&
        widget.initiallyExpanded &&
        !_internalExpanded) {
      // Автоматически раскрываем, если initiallyExpanded изменился на true
      _updateExpansion(true);
    }
  }

  @override
  void dispose() {
    // [dispose] Освобождаем ресурсы контроллера анимации
    _animationController.dispose();
    super.dispose();
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// _updateExpansion
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Обновляет состояние расширения дропдауна с плавной анимацией иконки.
  ///
  /// [newExpanded] - новое состояние раскрытия
  /// [notifyParent] - нужно ли уведомлять родителя через callback (по умолчанию true)
  void _updateExpansion(bool newExpanded, {bool notifyParent = true}) {
    // [updateExpansion] Если используется управляемое состояние, не обновляем внутреннее
    if (widget.isExpanded == null) {
      setState(() {
        _internalExpanded = newExpanded;
      });
    }

    // [updateExpansion] Запускаем или останавливаем анимацию поворота иконки
    if (newExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    // [onExpansionChanged] Вызываем callback для уведомления родителя только если нужно
    if (notifyParent) {
      widget.onExpansionChanged?.call(newExpanded);
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// _toggleExpansion
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Переключает состояние расширения дропдауна с плавной анимацией иконки.
  ///
  void _toggleExpansion() {
    _updateExpansion(!isExpanded);
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
