import 'package:flutter/foundation.dart';
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
  // final email = 'thereIsEmail@gmail.com';
  final formKey = GlobalKey<FormState>();
  bool buttonAvailable = false;
  bool isError = false;
  // late TextEditingController controller0;
  // late TextEditingController controller1;
  // late TextEditingController controller2;
  // late TextEditingController controller3;

  // FocusNode node0 = FocusNode();
  // FocusNode node1 = FocusNode();
  // FocusNode node2 = FocusNode();
  // FocusNode node3 = FocusNode();

  // List<TextEditingController> controllers = [];
  // List<FocusNode> nodes = [];

  @override
  void initState() {
    // controller0 = TextEditingController();
    // controller1 = TextEditingController();
    // controller2 = TextEditingController();
    // controller3 = TextEditingController();

    // controllers = [controller0, controller1, controller2, controller3];
    // nodes = [node0, node1, node2, node3];
    super.initState();
  }

  @override
  void dispose() {
    // controller0.dispose();
    // controller1.dispose();
    // controller2.dispose();
    // controller3.dispose();

    super.dispose();
  }

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
                    dynamic check = otpValidator(value, state);
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
                        buttonAvailable = true;
                        isError = false;
                      });
                    }
                  },
                ),
                // Form(
                //   key: formKey,
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       for (int i = 0; i < 4; i++)
                //         SizedBox(
                //           width: 76.75.w,
                //           // height: 100.h,
                //           child: RishTextField(
                //             state: RishTextInputState.enabled,
                //             focusNode: nodes[i],
                //             controller: controllers[i],
                //             needsCounter: false,
                //             maxLength: 1,
                //             maxLines: 1,
                //             onChanged: (t) {
                //               onChanged(t, i);
                //             },
                //             fillColor: RishColors.inputField,
                //             textAlign: TextAlign.center,
                //             keyboardType: TextInputType.number,
                //             hintText: '•',
                //             textStyle: context.styles.numsM,
                //             validator: (t) {
                //               return otpValidator(t, state);
                //             },
                //             needsErrorText: false,
                //           ),
                //         ),
                //     ],
                //   ),
                // ),
              ),
              // Debug информация (если нужно)
              if (kDebugMode) ...[
                SizedBox(height: 32.h),
                Center(
                  child: Text(
                    loginBloc.state.otp!,
                    style: context.styles.regularMedium.copyWith(
                      color: RishColors.textSecondary,
                    ),
                  ),
                ),
              ],
              // Используем Expanded вместо Spacer для стабильности верстки
              // const Spacer(),
              Expanded(
                child: Container(),
              ),
              // Нижняя секция с кнопкой - фиксированная позиция без "дергания"
              BlocBuilder<WhoopBloc, WhoopState>(
                bloc: whoopBloc,
                builder: (context, whoopState) {
                  return RishButton.primary(
                    title: 'Submit',
                    enabled: buttonAvailable,
                    isLoading: state.status == Status.loading ||
                        whoopState.status == Status.loading,
                    action: () {
                      loginBloc.add(const LoginOtpCorrect());
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

  // void onChanged(String? t, int i) {
  //   if (t != null) {
  //     if (t.length == 1 && i != 3) {
  //       nodes[i + 1].requestFocus();
  //     }
  //     if (t.isEmpty && i != 0) {
  //       if (controllers.every(
  //         (t) {
  //           return t.text.isEmpty;
  //         },
  //       )) {
  //         node0.requestFocus();
  //       } else {
  //         nodes[i - 1].requestFocus();
  //       }
  //     }
  //   }
  //   String code = controller0.text +
  //       controller1.text +
  //       controller2.text +
  //       controller3.text;

  //   setState(() {
  //     buttonAvailable = code.length == 4;
  //   });
  // }

  String? otpValidator(String? inputCode, LoginState state) {
    // String code = controller0.text +
    //     controller1.text +
    //     controller2.text +
    //     controller3.text;

    if (inputCode!.length < 4 || inputCode != state.otp) {
      return '';
    } else if (inputCode == state.otp) {
      return null;
    }
    return null;
  }
}
