import 'package:flutter/material.dart';
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
  String _getButtonTitle() {
    if (selectedMealsCount == 0) {
      return 'Select meals';
    } else if (selectedMealsCount == 1) {
      return 'Add 1 meal to diary';
    } else {
      return 'Add $selectedMealsCount meals to diary';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 16),
      child: RishButton.primary(
        title: _getButtonTitle(),
        enabled: selectedMealsCount > 0,
        isLoading: isLoading,
        action: () {
          onPressed();
        },
      ),
    );
  }
}
