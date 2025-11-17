import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/food_diary/presentation/widgets/add_meals_button.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/custom_meals_section.dart';
import 'package:rishai/features/food_diary/presentation/widgets/generated_meals_section.dart';

class DiaryEntryPage extends StatefulWidget {
  const DiaryEntryPage({super.key});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  // [expandedDropdownId] ID раскрытого dropdown'а
  // null - нет раскрытых, 'generated' - раскрыт GeneratedMealsSection,
  // 'custom_<mealId>' - раскрыт CustomMealItem с указанным ID
  String? expandedDropdownId;

  @override
  void initState() {
    super.initState();
    // [initState] Инициализируем страницу при создании виджета
    foodDiaryCubit.add(const DiaryEntryPageInitialize());
  }

  /// [handleGeneratedMealsExpansion] Обработчик раскрытия/закрытия GeneratedMealsSection
  void handleGeneratedMealsExpansion(bool isExpanded) {
    setState(() {
      if (isExpanded) {
        // [handleGeneratedMealsExpansion] Раскрываем GeneratedMealsSection, закрываем все остальные
        expandedDropdownId = 'generated';
      } else {
        // [handleGeneratedMealsExpansion] Закрываем GeneratedMealsSection
        if (expandedDropdownId == 'generated') {
          expandedDropdownId = null;
        }
      }
    });
  }

  /// [handleCustomMealExpansion] Обработчик раскрытия/закрытия CustomMealItem
  void handleCustomMealExpansion(String mealId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        // [handleCustomMealExpansion] Раскрываем CustomMealItem, закрываем все остальные
        expandedDropdownId = 'custom_$mealId';
      } else {
        // [handleCustomMealExpansion] Закрываем CustomMealItem
        if (expandedDropdownId == 'custom_$mealId') {
          expandedDropdownId = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'What did you eat today?',
        style: context.styles.h2,
      ),
      leadingAction: () {
        context.pop();
      },
      child: BlocBuilder<FoodDiaryCubit, FoodDiaryState>(
        bloc: foodDiaryCubit,
        builder: (context, foodDiaryState) {
          // [build] Проверяем, что состояние соответствует странице DiaryEntryPage
          if (foodDiaryState is! DiaryEntryPageState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // [build] Извлекаем данные из состояния cubit
          final meals = foodDiaryState.availableMeals;
          final allMealsFromPlan = foodDiaryState.allMealsFromPlan;
          final selectedMeals = foodDiaryState.selectedMeals;
          final selectedCustomMealsCount =
              foodDiaryState.selectedCustomMealsCount;
          final isLoading = foodDiaryState.isLoading;

          // Общее количество выбранных блюд (обычные + кастомные)
          final totalSelectedMealsCount =
              selectedMeals.length + selectedCustomMealsCount;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // [keyboardDismissBehavior] Предотвращаем автоматическую прокрутку
                  // при закрытии клавиатуры/диалога
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  //NO PADDING HERE NEVER
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GeneratedMealsSection(
                        meals: meals,
                        allMealsFromPlan: allMealsFromPlan,
                        selectedMeals: selectedMeals,
                        isExpanded: expandedDropdownId == 'generated',
                        onExpansionChanged: handleGeneratedMealsExpansion,
                        onMealSelectionChanged: (meal, isSelected) {
                          // [onMealSelectionChanged] Отправляем событие в cubit для переключения выбора блюда
                          foodDiaryCubit.add(
                            DiaryEntryToggleMealSelection(
                              meal: meal,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // [CustomMealsSection] Секция кастомных блюд
                      // Управляется полностью через cubit с массивом customMeals
                      CustomMealsSection(
                        expandedMealId:
                            expandedDropdownId?.startsWith('custom_') ?? false
                                ? expandedDropdownId!
                                    .substring(7) // Убираем префикс 'custom_'
                                : null,
                        onMealExpansionChanged: handleCustomMealExpansion,
                      ),

                      // [build] Дополнительный отступ снизу для кнопки
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
              ),

              // ┌───────────────────────────────────────────────────────────────┐
              // │ Зафиксированная кнопка добавления внизу экрана                │
              // └───────────────────────────────────────────────────────────────┘
              AddMealsButton(
                selectedMealsCount: totalSelectedMealsCount,
                // [isLoading] Кнопка неактивна если идет загрузка или регенерация блюда
                // Регенерация блокирует кнопку, чтобы предотвратить добавление блюд
                // во время обновления анализа
                isLoading: isLoading || foodDiaryState.isRegenerating,
                onPressed: () async {
                  // [onPressed] Отправляем событие в cubit для добавления выбранных блюд
                  foodDiaryCubit.add(const DiaryEntryAddSelectedMeals());

                  // [onPressed] Ждем завершения операции
                  await Future.delayed(const Duration(milliseconds: 500));

                  // [onPressed] Закрываем страницу после успешного добавления
                  if (context.mounted) {
                    context.pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
