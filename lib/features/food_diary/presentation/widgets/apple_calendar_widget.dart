import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

/// [AppleCalendarWidget] Календарь в стиле Apple с темным дизайном
///
/// Следует Apple Human Interface Guidelines для создания современного,
/// сексуального и минималистичного интерфейса с плавными анимациями
/// и интуитивной навигацией. Отображает галочки для дней с consumedMeals.
class AppleCalendarWidget extends StatefulWidget {
  const AppleCalendarWidget({
    required this.selectedDate,
    required this.availableDays,
    required this.onDateSelected,
    required this.onCancel,
    super.key,
  });

  /// [selectedDate] Текущая выбранная дата
  final DateTime selectedDate;

  /// [availableDays] Список доступных дней с данными
  final List<DayEntity> availableDays;

  /// [onDateSelected] Колбэк при выборе даты
  final Function(DateTime) onDateSelected;

  /// [onCancel] Колбэк при отмене
  final VoidCallback onCancel;

  @override
  State<AppleCalendarWidget> createState() => _AppleCalendarWidgetState();
}

class _AppleCalendarWidgetState extends State<AppleCalendarWidget>
    with TickerProviderStateMixin {
  late DateTime _focusedMonth;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _focusedMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);

    // [initState] Инициализируем контроллеры анимации для плавных переходов в стиле Apple
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Создаем анимации с кривыми в стиле Apple для естественного движения
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic, // Apple-style easing
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Запускаем анимацию появления
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// [_hasConsumedMeals] Проверяет, есть ли у дня записи о потребленной пище
  bool _hasConsumedMeals(DateTime date) {
    try {
      final dayEntity = widget.availableDays.firstWhere(
        (day) => day.dateTime.isSameDate(date),
      );
      final consumedMeals = dayEntity.welnessEntity?.consumedMeals ?? [];
      return consumedMeals.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// [_isDateAvailable] Проверяет, доступна ли дата для выбора
  bool _isDateAvailable(DateTime date) {
    return widget.availableDays.any((day) => day.dateTime.isSameDate(date));
  }

  /// [_getDaysInMonth] Получает все дни месяца для отображения в календаре
  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month);

    // Находим первый понедельник для отображения (может быть из предыдущего месяца)
    final startDate =
        firstDay.subtract(Duration(days: (firstDay.weekday - 1) % 7));

    final days = <DateTime>[];
    var current = startDate;

    // Генерируем 42 дня (6 недель) для полного календаря
    for (int i = 0; i < 42; i++) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// [_navigateMonth] Навигация между месяцами с анимацией
  void _navigateMonth(int direction) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + direction,
      );
    });
  }

  /// [_handleDateTap] Обработка нажатия на дату
  void _handleDateTap(DateTime date) {
    if (_isDateAvailable(date)) {
      // Анимация закрытия перед вызовом колбэка
      _fadeController.reverse().then((_) {
        _slideController.reverse().then((_) {
          widget.onDateSelected(date);
        });
      });
    }
  }

  /// [_handleCancel] Обработка отмены с анимацией
  void _handleCancel() {
    _fadeController.reverse().then((_) {
      _slideController.reverse().then((_) {
        widget.onCancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: RishColors.formBackgroun,
                  ),
                  child: SafeArea(
                    bottom: true,
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // [build] Заголовок с кнопками Cancel и Today в стиле Apple
                          _buildHeader(),
                          SizedBox(height: 30.h),

                          // [build] Навигация по месяцам с названием месяца
                          _buildMonthNavigation(),
                          // SizedBox(height: 25.h),

                          // [build] Заголовки дней недели
                          _buildWeekdayHeaders(),
                          // SizedBox(height: 15.h),

                          // [build] Сетка календаря
                          _buildCalendarGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// [_buildHeader] Создает заголовок с кнопками Cancel и Today
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel button в стиле Apple
        GestureDetector(
          onTap: _handleCancel,
          child: Container(
            padding: EdgeInsets.all(10.h),
            child: Text(
              'Cancel',
              style: context.styles.regularMedium,
            ),
          ),
        ),

        // Today button в стиле Apple
        GestureDetector(
          onTap: () => _handleDateTap(DateTime.now()),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'Today',
              style: context.styles.regularMedium,
            ),
          ),
        ),
      ],
    );
  }

  /// [_buildMonthNavigation] Создает навигацию по месяцам
  Widget _buildMonthNavigation() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Название месяца и года
        Text(
          _getMonthYearString(_focusedMonth),
          style: context.styles.boldLarge,
        ),

        const Spacer(),
        // Кнопка предыдущего месяца
        GestureDetector(
          onTap: () => _navigateMonth(-1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              child: Icon(
                Icons.chevron_left,
                color: RishColors.textPrimary,
                size: 24.sp,
              ),
            ),
          ),
        ),

        // Кнопка следующего месяца
        GestureDetector(
          onTap: () => _navigateMonth(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              child: Icon(
                Icons.chevron_right,
                color: RishColors.textPrimary,
                size: 24.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// [_buildWeekdayHeaders] Создает заголовки дней недели
  Widget _buildWeekdayHeaders() {
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: context.styles.boldSmall.copyWith(
                color: RishColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// [_buildCalendarGrid] Создает сетку календаря с днями
  Widget _buildCalendarGrid() {
    final days = _getDaysInMonth(_focusedMonth);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        return _buildDayCell(date);
      },
    );
  }

  /// [_buildDayCell] Создает ячейку для отдельного дня
  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth = date.month == _focusedMonth.month;
    final isSelected = date.isSameDate(widget.selectedDate);
    final isToday = date.isSameDate(DateTime.now());
    final isAvailable = _isDateAvailable(date);
    final hasConsumedMeals = _hasConsumedMeals(date);

    return GestureDetector(
      onTap: () => _handleDateTap(date),
      child: Container(
        margin: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: isSelected
              ? RishColors.primary
              : isToday
                  ? RishColors.formBackgroun.withOpacity(0.8)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: isToday && !isSelected
              ? Border.all(color: RishColors.primary.withOpacity(0.5))
              : null,
        ),
        child: Stack(
          children: [
            // Основной контент дня
            Center(
              child: Text(
                '${date.day}',
                style: context.styles.regularMedium.copyWith(
                  color: isSelected
                      ? Colors.black
                      : isCurrentMonth
                          ? isAvailable
                              ? RishColors.textPrimary
                              : RishColors.textSecondary.withOpacity(0.5)
                          : RishColors.textSecondary.withOpacity(0.3),
                  fontWeight:
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 16.sp,
                ),
              ),
            ),

            // Галочка для дней с consumedMeals
            if (hasConsumedMeals && isCurrentMonth)
              Align(
                alignment: Alignment.bottomCenter,
                child: Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 10.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// [_getMonthYearString] Получает строку месяца и года
  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}
