import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/food_diary/presentation/widgets/diary_dropdown.dart';
import 'package:rishai/features/food_diary/presentation/widgets/meal_item.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GeneratedMealsSection Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Секция для отображения сгенерированных блюд из дневного и недельного планов.
///
/// **Функциональность:**
/// - Отображает список сгенерированных блюд в выпадающем списке
/// - Показывает количество доступных блюд
/// - Поддерживает множественный выбор блюд
/// - Отображает кнопку создания индивидуального плана, если блюд нет
///
/// **UI/UX:**
/// - Заголовок секции с счетчиком
/// - Разделители между элементами
/// - Плавные анимации взаимодействия
/// - Следует Apple HIG для списков и выбора элементов
///
class GeneratedMealsSection extends StatelessWidget {
  const GeneratedMealsSection({
    required this.meals,
    required this.allMealsFromPlan,
    required this.selectedMeals,
    required this.onMealSelectionChanged,
    super.key,
  });

  /// Список доступных блюд для выбора
  final List<Meal> meals;

  /// Список всех блюд из плана (до фильтрации потребленных)
  /// Используется для определения, есть ли план вообще и все ли блюда добавлены
  final List<Meal> allMealsFromPlan;

  /// Список выбранных блюд
  final List<Meal> selectedMeals;

  /// Callback для изменения состояния выбора блюда
  final void Function(Meal meal, bool isSelected) onMealSelectionChanged;

  /// ═══════════════════════════════════════════════════════════════════════
  /// _isMealSelected
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Проверяет, выбрано ли блюдо в текущем списке выбранных блюд.
  ///
  bool _isMealSelected(Meal meal) {
    return selectedMeals.contains(meal);
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// _areAllMealsLogged
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Проверяет, все ли блюда из плана были добавлены в дневник.
  ///
  /// **Логика:**
  /// - Если есть план (allMealsFromPlan.isNotEmpty) и нет доступных блюд
  ///   (meals.isEmpty), значит все блюда из плана уже добавлены в дневник.
  ///
  bool _areAllMealsLogged() {
    return allMealsFromPlan.isNotEmpty && meals.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ┌───────────────────────────────────────────────────────────────────┐
        // │ Заголовок секции с счетчиком доступных блюд                       │
        // └───────────────────────────────────────────────────────────────────┘
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Generated Meals',
              style: context.styles.boldLarge,
            ),
            if (meals.isNotEmpty)
              Text(
                '${meals.length} available',
                style: context.styles.regularSmall.copyWith(
                  color: RishColors.textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),

        // ┌───────────────────────────────────────────────────────────────────┐
        // │ Выпадающий список с блюдами, кнопка создания плана или сообщение   │
        // │ о том, что все блюда добавлены                                      │
        // └───────────────────────────────────────────────────────────────────┘
        if (meals.isEmpty)
          Column(
            children: [
              // Если все блюда из плана добавлены - показываем сообщение
              if (_areAllMealsLogged())
                Text(
                  'You have logged all your generated meals for the day',
                  style: context.styles.regularMedium.copyWith(
                    color: RishColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                // Иначе показываем кнопку создания индивидуального плана питания
                RishButton.primary(
                  title: 'Create Individual Meal Plan',
                  enabled: true,
                  isLoading: false,
                  action: () async {
                    appNavigationService.pop(path: AppRoutes.chat.path);
                    await homePageControllerService.navigateToPage(page: 2);
                  },
                ),
            ],
          )
        else
          DiaryDropDown(
            title: 'Choose from the list',
            child: Column(
              children: meals.asMap().entries.map((entry) {
                final index = entry.key;
                final meal = entry.value;

                return Column(
                  children: [
                    MealItem(
                      meal: meal,
                      isSelected: _isMealSelected(meal),
                      onSelectionChanged: (isSelected) {
                        onMealSelectionChanged(meal, isSelected);
                      },
                    ),
                    // Разделитель между элементами (кроме последнего)
                    if (index < meals.length - 1)
                      const Divider(
                        color: RishColors.stroke,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
