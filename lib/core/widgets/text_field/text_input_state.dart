part of 'text_field.dart';

enum RishTextInputState {
  enabled,
  disabled,
  error;

  bool get isEnabled => this != RishTextInputState.disabled;
  bool get isError => this == RishTextInputState.error;

  InputDecorationTheme resolve(InputDecorationTheme inputTheme) {
    return switch (this) {
      RishTextInputState.enabled =>
        inputTheme.copyWith(border: RishInputDecorationTheme.voyBorderDefault),
      RishTextInputState.disabled =>
        inputTheme.copyWith(border: RishInputDecorationTheme.voyBorderDefault),
      RishTextInputState.error =>
        inputTheme.copyWith(border: RishInputDecorationTheme.voyErrorBorder),
    };
  }
}
