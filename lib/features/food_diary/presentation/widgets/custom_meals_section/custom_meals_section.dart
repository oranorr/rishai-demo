import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/custom_meal_item.dart';

// Экспортируем только главный виджет
export 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/custom_meal_item.dart'
    show CustomMealItem;

/// ═══════════════════════════════════════════════════════════════════════════
/// CustomMealsSection Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Секция для добавления кастомных (пользовательских) блюд.
///
/// **Функциональность:**
/// - Отображает массив кастомных блюд из состояния кубита
/// - Каждое блюдо в отдельной карточке с возможностью expand/collapse
/// - Кнопка "Add more" для добавления новых блюд
/// - Поддержка неограниченного количества блюд
///
/// **UI/UX:**
/// - Минималистичный дизайн в стиле Apple HIG
/// - Анимированный список блюд
/// - Плавные переходы и взаимодействия
///
class CustomMealsSection extends StatelessWidget {
  const CustomMealsSection({super.key});

  /// [_handleAddMore] Обработчик нажатия на "Add more"
  void _handleAddMore(BuildContext context) {
    context.read<FoodDiaryCubit>().add(const CustomMealAdd());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodDiaryCubit, FoodDiaryState>(
      builder: (context, state) {
        // Проверяем, что находимся в правильном состоянии
        if (state is! DiaryEntryPageState) {
          return const SizedBox.shrink();
        }

        // Получаем массив кастомных блюд
        final customMeals = state.customMeals;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ┌───────────────────────────────────────────────────────────────────┐
            // │ Заголовок секции с кнопкой "Add more"                             │
            // └───────────────────────────────────────────────────────────────────┘
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Custom Meals', style: context.styles.boldLarge),
                GestureDetector(
                  onTap: () => _handleAddMore(context),
                  child: Text(
                    'Add more',
                    style: context.styles.boldMedium.copyWith(
                      color: RishColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ┌───────────────────────────────────────────────────────────────────┐
            // │ Список кастомных блюд                                              │
            // └───────────────────────────────────────────────────────────────────┘
            ...customMeals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              final showDeleteButton = customMeals.length > 1;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: CustomMealItem(
                  meal: meal,
                  mealIndex: index + 1,
                  showDeleteButton: showDeleteButton,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
