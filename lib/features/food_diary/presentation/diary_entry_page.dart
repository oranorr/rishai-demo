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
  @override
  void initState() {
    super.initState();
    // [initState] Инициализируем страницу при создании виджета
    foodDiaryCubit.add(const DiaryEntryPageInitialize());
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
            print(
              '[DiaryEntryPage] Некорректное состояние: ${foodDiaryState.runtimeType}',
            );
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // [build] Извлекаем данные из состояния cubit
          final meals = foodDiaryState.availableMeals;
          final selectedMeals = foodDiaryState.selectedMeals;
          final selectedCustomMealsCount = foodDiaryState.selectedCustomMealsCount;
          final isLoading = foodDiaryState.isLoading;

          // Общее количество выбранных блюд (обычные + кастомные)
          final totalSelectedMealsCount = selectedMeals.length + selectedCustomMealsCount;

          print(
            '[DiaryEntryPage] Доступных блюд: ${meals.length}, выбранных обычных: ${selectedMeals.length}, выбранных кастомных: $selectedCustomMealsCount, всего: $totalSelectedMealsCount',
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  //NO PADDING HERE NEVER
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GeneratedMealsSection(
                        meals: meals,
                        selectedMeals: selectedMeals,
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
                      const CustomMealsSection(),

                      // [build] Дополнительный отступ снизу для кнопки
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),

              // ┌───────────────────────────────────────────────────────────────┐
              // │ Зафиксированная кнопка добавления внизу экрана                │
              // └───────────────────────────────────────────────────────────────┘
              AddMealsButton(
                selectedMealsCount: totalSelectedMealsCount,
                isLoading: isLoading,
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
