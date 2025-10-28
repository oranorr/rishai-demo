part of 'text_field.dart';

enum RishTextInputState {
  enabled,
  disabled,
  error;

  bool get isEnabled => this != RishTextInputState.disabled;
  bool get isError => this == RishTextInputState.error;

  // [resolve] Метод для получения InputDecorationThemeData в зависимости от состояния
  // Возвращает InputDecorationThemeData с измененными border'ами в зависимости от состояния
  InputDecorationThemeData resolve(InputDecorationThemeData inputTheme) {
    return switch (this) {
      // Enabled состояние - используем стандартный border
      RishTextInputState.enabled => InputDecorationThemeData(
          border: RishInputDecorationTheme.voyBorderDefault,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: inputTheme.errorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
        ),
      // Disabled состояние - используем стандартный border
      RishTextInputState.disabled => InputDecorationThemeData(
          border: RishInputDecorationTheme.voyBorderDefault,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: inputTheme.errorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
        ),
      // Error состояние - используем error border
      RishTextInputState.error => InputDecorationThemeData(
          border: RishInputDecorationTheme.voyErrorBorder,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: RishInputDecorationTheme.voyErrorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
        ),
    };
  }
}
