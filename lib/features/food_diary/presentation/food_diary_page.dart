import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

class FoodDiaryPage extends StatefulWidget {
  const FoodDiaryPage({super.key});

  @override
  State<FoodDiaryPage> createState() => _FoodDiaryPageState();
}

class _FoodDiaryPageState extends State<FoodDiaryPage> {
  /// [_showClearConfirmationDialog] Показывает диалог подтверждения очистки записей за сегодня
  Future<void> _showClearConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: RishColors.surface,
          title: Text(
            '🧹 Дебаг: Очистка записей',
            style: context.styles.h3.copyWith(color: RishColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Вы уверены, что хотите очистить все записи дневника питания за сегодня?',
                  style: context.styles.regularMedium
                      .copyWith(color: RishColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Это действие:',
                  style: context.styles.boldMedium
                      .copyWith(color: RishColors.textPrimary),
                ),
                SizedBox(height: 8.h),
                Text(
                  '• Очистит локальные записи в Hive\n• Удалит записи из Directus\n• Сбросит WelnessEntity за сегодня',
                  style: context.styles.regularSmall
                      .copyWith(color: RishColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: RishColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border:
                        Border.all(color: RishColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⚠️ ВНИМАНИЕ: Это действие необратимо!',
                    style: context.styles.boldSmall
                        .copyWith(color: RishColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Отмена',
                style: context.styles.boldMedium
                    .copyWith(color: RishColors.textSecondary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RishColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Отправляем событие очистки записей за сегодня
                foodDiaryCubit.add(const FoodDiaryClearTodayEntries());

                // Показываем снекбар с подтверждением
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🧹 Очистка записей за сегодня запущена...',
                      style: context.styles.regularMedium
                          .copyWith(color: Colors.white),
                    ),
                    backgroundColor: RishColors.primary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Food Diary',
          style: context.styles.h2,
        ),
        BlocBuilder<UserBloc, UserState>(
          bloc: userBloc,
          builder: (context, state) {
            final day = state.days.reversed.toList().first;
            return Center(
              child:
                  Text(whoopBloc.state.day.welnessEntity.toString() ?? 'hello'),
            );
          },
        ),

        // Дебажная кнопка для очистки записей за сегодня (только в debug режиме)
        if (kDebugMode) ...[
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: RishColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: RishColors.error.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: RishColors.error,
                      size: 20.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'DEBUG РЕЖИМ',
                      style: context.styles.boldSmall.copyWith(
                        color: RishColors.error,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Дебажные инструменты для разработки',
                  style: context.styles.regularSmall.copyWith(
                    color: RishColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                BlocBuilder<FoodDiaryCubit, FoodDiaryState>(
                  bloc: foodDiaryCubit,
                  builder: (context, state) {
                    final isLoading = state is FoodDiaryMainState &&
                        state.status == Status.loading;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RishColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48.h),
                      ),
                      onPressed: isLoading
                          ? null
                          : () => _showClearConfirmationDialog(context),
                      child: Text(
                        isLoading
                            ? 'Очищаем...'
                            : '🧹 Очистить записи за сегодня',
                        style: context.styles.boldMedium,
                      ),
                    );
                  },
                ),
                SizedBox(height: 8.h),
                Text(
                  'Очищает все записи дневника питания за сегодня\n(локально и в Directus)',
                  style: context.styles.regularSmall.copyWith(
                    color: RishColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
