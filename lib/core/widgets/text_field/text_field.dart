import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/input_decoration_theme.dart';
import 'package:rishai/core/theme/theme_colors.dart';

part 'text_input_size.dart';
part 'text_input_state.dart';

typedef OnEditText = void Function(String? value);

class RishTextField extends StatelessWidget {
  // final FormFieldValidator(String v) validator;

  const RishTextField({
    required this.state,
    required this.needsCounter,
    required this.onChanged,
    super.key,
    this.borderColor,
    this.validator,
    this.maxLengthEnforcement,
    this.maxLines = 1,
    this.onSubmitted,
    this.errorText,
    this.maxLength,
    this.focusNode,
    this.hintText,
    this.controller,
    this.suffixIcon,
    this.textStyle,
    this.contentPadding,
    this.fillColor,
    this.keyboardType,
    this.textAlign,
    this.labelText,
    this.height,
    this.needsErrorText,
    this.formatters,
  });
  final RishTextInputState state;
  final int? maxLines;
  final bool needsCounter;
  final OnEditText onChanged;
  final OnEditText? onSubmitted;
  final String? errorText;
  final int? maxLength;
  final FocusNode? focusNode;
  final String? hintText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final TextInputType? keyboardType;
  final TextAlign? textAlign;
  final String? labelText;
  final List<TextInputFormatter>? formatters;
  final double? height;
  final bool? needsErrorText;
  final String? Function(String?)? validator;
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final inputTheme = theme.inputDecorationTheme;
    bool needsBottomPadding;
    if (maxLines! > 1) {
      needsBottomPadding = true;
    } else {
      needsBottomPadding = false;
    }

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: state.resolve(inputTheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText?.isNotEmpty ?? false) ...[
            Text(
              labelText ?? '',
              style: context.styles.regularMedium
                  .copyWith(color: RishColors.textSecondary),
            ),
            SizedBox(
              height: 8.h,
            ),
          ],
          SizedBox(
            // color: Colors.amber,
            height: height,
            child: TextFormField(
              maxLengthEnforcement: maxLengthEnforcement,
              validator: validator,
              controller: controller,
              enabled: state.isEnabled,
              focusNode: focusNode,
              maxLength: maxLength,
              maxLines: maxLines ?? 1,
              style: textStyle,
              // expands: true,
              onChanged: onChanged,
              onSaved: onSubmitted,
              keyboardType: keyboardType,
              textAlign: textAlign ?? TextAlign.start,
              inputFormatters: formatters,
              cursorColor: context.theme.colorScheme.primary,
              decoration: InputDecoration(
                counter: needsCounter ? null : const SizedBox.shrink(),
                counterStyle: context.styles.regularSmall
                    .copyWith(color: RishColors.textSecondary),
                filled: fillColor != null,
                fillColor: fillColor,
                contentPadding: EdgeInsets.only(
                  left: textAlign == TextAlign.center ? 0 : 16,
                  bottom: needsBottomPadding ? 40 : 0,
                ),
                hintText: hintText,
                hintStyle: context.styles.regularMedium
                    .copyWith(color: RishColors.textSecondary),
                alignLabelWithHint: true,
                helperText: needsErrorText ?? false ? '' : null,
                suffixIcon: suffixIcon,
                errorText: errorText,
                errorMaxLines: 2,
                errorStyle: errorText != ''
                    ? context.styles.regularMedium.copyWith(
                        color: darkColorScheme.error,
                      )
                    : const TextStyle(height: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if the new value contains any spaces
    if (newValue.text.contains(' ')) {
      // If it does, return the old value
      return oldValue;
    }
    // Otherwise, return the new value
    return newValue;
  }
}
