part of 'text_field.dart';

enum RishTextInputState {
  enabled,
  disabled,
  error;

  bool get isEnabled => this != RishTextInputState.disabled;
  bool get isError => this == RishTextInputState.error;

  InputDecorationTheme resolve(InputDecorationTheme inputTheme) {
    return switch (this) {
      RishTextInputState.enabled => InputDecorationTheme(
          border: RishInputDecorationTheme.voyBorderDefault,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: inputTheme.errorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
          filled: inputTheme.filled,
          fillColor: inputTheme.fillColor,
          hintStyle: inputTheme.hintStyle,
          labelStyle: inputTheme.labelStyle,
          errorStyle: inputTheme.errorStyle,
          counterStyle: inputTheme.counterStyle,
          contentPadding: inputTheme.contentPadding,
        ),
      RishTextInputState.disabled => InputDecorationTheme(
          border: RishInputDecorationTheme.voyBorderDefault,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: inputTheme.errorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
          filled: inputTheme.filled,
          fillColor: inputTheme.fillColor,
          hintStyle: inputTheme.hintStyle,
          labelStyle: inputTheme.labelStyle,
          errorStyle: inputTheme.errorStyle,
          counterStyle: inputTheme.counterStyle,
          contentPadding: inputTheme.contentPadding,
        ),
      RishTextInputState.error => InputDecorationTheme(
          border: RishInputDecorationTheme.voyErrorBorder,
          enabledBorder: inputTheme.enabledBorder,
          focusedBorder: inputTheme.focusedBorder,
          disabledBorder: inputTheme.disabledBorder,
          errorBorder: RishInputDecorationTheme.voyErrorBorder,
          focusedErrorBorder: inputTheme.focusedErrorBorder,
          filled: inputTheme.filled,
          fillColor: inputTheme.fillColor,
          hintStyle: inputTheme.hintStyle,
          labelStyle: inputTheme.labelStyle,
          errorStyle: inputTheme.errorStyle,
          counterStyle: inputTheme.counterStyle,
          contentPadding: inputTheme.contentPadding,
        ),
    };
  }
}
