import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/login/presentation/bloc/login_state.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

class EnterOtp extends StatefulWidget {
  const EnterOtp({
    super.key,
  });

  @override
  State<EnterOtp> createState() => _EnterOtpState();
}

class _EnterOtpState extends State<EnterOtp> {
  final formKey = GlobalKey<FormState>();
  bool buttonAvailable = false;
  bool isError = false;

  /// Последний введённый код (для Submit); проверка — только на сервере.
  String _lastSubmittedCode = '';

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: true,
      needsBottomPadding: false,
      child: BlocBuilder<LoginBloc, LoginState>(
        bloc: loginBloc,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your code here',
                style: context.styles.h3,
              ),
              SizedBox(
                height: 4.h,
              ),
              Text.rich(
                TextSpan(
                  text: 'We sent 4-digit code to ',
                  style: context.styles.regularLarge
                      .copyWith(color: RishColors.textSecondary),
                  children: [
                    TextSpan(
                      text: state.loginEntity!.email,
                      style: context.styles.regularLarge
                          .copyWith(color: RishColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24.h,
              ),
              SizedBox(
                width: 343.w,
                child: OtpTextField(
                  textStyle: context.styles.numsM,
                  autoFocus: true,
                  fieldWidth: 65.w,
                  fieldHeight: 55.h,
                  showFieldAsBox: true,
                  clearText: !isError && !buttonAvailable,
                  borderRadius: BorderRadius.circular(24),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  borderWidth: 1,
                  focusedBorderColor: isError
                      ? context.theme.colorScheme.error
                      : RishColors.primary,
                  enabledBorderColor: isError
                      ? context.theme.colorScheme.error
                      : RishColors.stroke,
                  onSubmit: (value) {
                    final check = otpValidator(value);
                    if (check == '') {
                      setState(() {
                        isError = true;
                        buttonAvailable = false;
                        Future.delayed(const Duration(seconds: 1), () {
                          setState(() {
                            isError = false;
                            buttonAvailable = false;
                          });
                        });
                      });
                    } else if (check == null) {
                      setState(() {
                        _lastSubmittedCode = value;
                        buttonAvailable = true;
                        isError = false;
                      });
                    }
                  },
                ),
              ),
              // Используем Expanded вместо Spacer для стабильности верстки
              Expanded(
                child: Container(),
              ),
              BlocBuilder<WhoopBloc, WhoopState>(
                bloc: whoopBloc,
                builder: (context, whoopState) {
                  return RishButton.primary(
                    title: 'Submit',
                    enabled: buttonAvailable,
                    isLoading: state.status == Status.loading ||
                        whoopState.status == Status.loading,
                    action: () {
                      loginBloc.add(
                        LoginSubmitEmailOtp(code: _lastSubmittedCode),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// `''` — слишком короткий код; `null` — можно нажать Submit (валидация на сервере).
  String? otpValidator(String? inputCode) {
    if (inputCode == null || inputCode.length < 4) {
      return '';
    }
    return null;
  }
}
