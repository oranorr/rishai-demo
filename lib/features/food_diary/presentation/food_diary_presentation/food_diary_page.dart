import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/presentation/widgets/apple_calendar_widget.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

part 'dairy_page_content.dart';
part 'consumed_meals_widget.dart';

class FoodDiaryPage extends StatefulWidget {
  const FoodDiaryPage({super.key});

  @override
  State<FoodDiaryPage> createState() => _FoodDiaryPageState();
}

class _FoodDiaryPageState extends State<FoodDiaryPage> {
  /// [_selectedDay] Текущий выбранный день для отображения
  /// По умолчанию null, что означает показ последнего дня (сегодня)
  DayEntity? _selectedDay;

  /// [_getDisplayDay] Получает день для отображения
  /// Если выбран конкретный день (_selectedDay != null), возвращает его
  /// Иначе возвращает последний день из списка (сегодня)
  DayEntity _getDisplayDay(List<DayEntity> days) {
    if (_selectedDay != null) {
      // Проверяем, что выбранный день всё ещё есть в списке дней
      final dayExists =
          days.any((day) => day.dateTime.isSameDate(_selectedDay!.dateTime));
      if (dayExists) {
        // Обновляем _selectedDay актуальными данными из state
        _selectedDay = days.firstWhere(
          (day) => day.dateTime.isSameDate(_selectedDay!.dateTime),
        );
        return _selectedDay!;
      }
    }
    // Если выбранный день не найден или не установлен, возвращаем последний день
    return days.reversed.toList().first;
  }

  /// [_onDateSelected] Обработчик выбора даты в календаре
  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      // Находим день по выбранной дате
      final day = userBloc.state.days.firstWhere(
        (day) => day.dateTime.isSameDate(selectedDate),
      );
      _selectedDay = day;
      print(
        '[FoodDiaryPage] Выбран день: ${selectedDate.formatAsDayString()}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Food Diary',
          style: context.styles.h2,
        ),
        SizedBox(height: 20.h),
        BlocBuilder<UserBloc, UserState>(
          bloc: userBloc,
          builder: (context, state) {
            // Получаем день для отображения (выбранный или последний)
            final day = _getDisplayDay(state.days);

            if (day.welnessEntity != null) {
              return Expanded(
                child: _DiaryPageContent(
                  day: day,
                  onDateSelected: _onDateSelected,
                ),
              );
            } else {
              // Определяем, является ли выбранный день сегодняшним
              final isToday = day.dateTime.isSameDate(DateTime.now());

              return Expanded(
                child: Column(
                  children: [
                    // [build] Заголовок с датой и иконкой календаря (как в _DiaryPageContent)
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Text(
                          day.dateTime.formatAsDayString(),
                          style: context.styles.h2,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            // [onTap] Показываем красивый календарь в стиле Apple
                            await _showAppleCalendar(
                              context,
                              day,
                              _onDateSelected,
                            );
                          },
                          child: SvgPicture.asset('assets/icons/calendar.svg'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // [build] Центрированное сообщение о пустом состоянии
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday
                                ? 'You havent consumed any meals today'
                                : 'No meals recorded for this day',
                            textAlign: TextAlign.center,
                            style: context.styles.h2,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            isToday
                                ? 'Please capture a meal to get started'
                                : 'Select another day or return to today',
                            textAlign: TextAlign.center,
                            style: context.styles.regularMedium,
                          ),
                          SizedBox(height: 42.h),
                          if (isToday)
                            RishButton.primary(
                              isLoading: false,
                              enabled: true,
                              title: 'Capture Meal',
                              action: () {
                                appNavigationService.push(
                                  path: AppRoutes.diaryEntryPage.path,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),

        // Дебажная кнопка для очистки записей за сегодня (только в debug режиме)
        // if (kDebugMode) ...[
        //   SizedBox(height: 24.h),
        //   Container(
        //     padding: EdgeInsets.all(16.w),
        //     margin: EdgeInsets.symmetric(horizontal: 16.w),
        //     decoration: BoxDecoration(
        //       color: RishColors.error.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(12.r),
        //       border: Border.all(
        //         color: RishColors.error.withOpacity(0.3),
        //         width: 1.w,
        //       ),
        //     ),
        //     child: Column(
        //       children: [
        //         Row(
        //           children: [
        //             Icon(
        //               Icons.bug_report,
        //               color: RishColors.error,
        //               size: 20.w,
        //             ),
        //             SizedBox(width: 8.w),
        //             Text(
        //               'DEBUG РЕЖИМ',
        //               style: context.styles.boldSmall.copyWith(
        //                 color: RishColors.error,
        //                 letterSpacing: 1.2,
        //               ),
        //             ),
        //           ],
        //         ),
        //         SizedBox(height: 12.h),
        //         Text(
        //           'Дебажные инструменты для разработки',
        //           style: context.styles.regularSmall.copyWith(
        //             color: RishColors.textSecondary,
        //           ),
        //           textAlign: TextAlign.center,
        //         ),
        //         SizedBox(height: 16.h),
        //         BlocBuilder<FoodDiaryCubit, FoodDiaryState>(
        //           bloc: foodDiaryCubit,
        //           builder: (context, state) {
        //             final isLoading = state is FoodDiaryMainState &&
        //                 state.status == Status.loading;

        //             return ElevatedButton(
        //               style: ElevatedButton.styleFrom(
        //                 backgroundColor: RishColors.error,
        //                 foregroundColor: Colors.white,
        //                 minimumSize: Size(double.infinity, 48.h),
        //               ),
        //               onPressed: isLoading
        //                   ? null
        //                   : () => _showClearConfirmationDialog(context),
        //               child: Text(
        //                 isLoading
        //                     ? 'Очищаем...'
        //                     : '🧹 Очистить записи за сегодня',
        //                 style: context.styles.boldMedium,
        //               ),
        //             );
        //           },
        //         ),
        //         SizedBox(height: 8.h),
        //         Text(
        //           'Очищает все записи дневника питания за сегодня\n(локально и в Directus)',
        //           style: context.styles.regularSmall.copyWith(
        //             color: RishColors.textSecondary,
        //           ),
        //           textAlign: TextAlign.center,
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }
}
