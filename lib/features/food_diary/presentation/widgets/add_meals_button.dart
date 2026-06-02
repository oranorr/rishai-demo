import 'package:flutter/material.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AddMealsButton Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Кнопка для добавления выбранных блюд в дневник питания.
/// Динамически изменяет текст в зависимости от количества выбранных блюд.
///
/// **Функциональность:**
/// - Отображает количество выбранных блюд
/// - Автоматически отключается при отсутствии выбора
/// - Поддерживает состояние загрузки
/// - Правильная плюрализация ("meal" vs "meals")
///
/// **UI/UX:**
/// - Зафиксирована внизу экрана в SafeArea
/// - Четкая визуальная обратная связь о состоянии
/// - Следует Apple HIG для primary actions
///
class AddMealsButton extends StatelessWidget {
  const AddMealsButton({
    required this.selectedMealsCount,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  /// Количество выбранных блюд
  final int selectedMealsCount;

  /// Callback при нажатии на кнопку
  final VoidCallback onPressed;

  /// Состояние загрузки
  final bool isLoading;

  /// ═══════════════════════════════════════════════════════════════════════
  /// _getButtonTitle
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Генерирует текст кнопки в зависимости от количества выбранных блюд.
  ///
  /// **Возвращаемые значения:**
  /// - "Select meals" - когда ничего не выбрано
  /// - "Add 1 meal to diary" - когда выбрано 1 блюдо
  /// - "Add X meals to diary" - когда выбрано несколько блюд
  ///

  @override
  Widget build(BuildContext context) {
    // [build] Нижний safe area даёт RishScaffold; здесь только отступ сверху.
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: RishButton.primary(
        title: selectedMealsCount == 0 ? 'Select meals' : 'Add to diary',
        enabled: selectedMealsCount > 0 || isLoading,
        isLoading: isLoading,
        action: () {
          // [unfocus] Убираем фокус с поля ввода перед открытием диалога
          // Это предотвращает автоматическую прокрутку к полю ввода после закрытия диалога
          FocusScope.of(context).unfocus();

          // [delay] Небольшая задержка для гарантированного снятия фокуса
          // перед открытием диалога
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!context.mounted) return;

            // [action] Показываем диалог подтверждения перед добавлением блюд
            // Используем готовое решение из RishiDialog
            RishiDialog.showAddMealsConfirmationDialog(
              context,
              mealsCount: selectedMealsCount,
              action: () {
                // [action] Вызываем оригинальный callback только после подтверждения
                onPressed();
              },
            );
          });
        },
      ),
    );
  }
}
