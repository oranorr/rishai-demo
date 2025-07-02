import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/text_field/text_field.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/login/presentation/bloc/login_state.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';
import 'package:url_launcher/url_launcher.dart';

part '../pages/widgets/create_account.dart';
part '../pages/widgets/login_account.dart';
part '../pages/widgets/lower_part.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKeyCreate = GlobalKey<FormState>();
  final _formKeyLogin = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;

  late TextEditingController emailController2;
  late TabController tabController;

  /// Флаг для создания исторических дней (только в debug режиме)
  bool shouldCreateHistoryDays = false;

  @override
  void initState() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    emailController2 = TextEditingController();
    tabController = TabController(length: 2, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    emailController2.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      needsAppBar: true,
      child: BlocBuilder<LoginBloc, LoginState>(
        bloc: loginBloc,
        builder: (context, state) {
          return TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              CreateAccountPage(
                formKey: _formKeyCreate,
                nameController: nameController,
                emailController: emailController,
                tabController: tabController,
                buttonAction: createAccountAction,
                shouldCreateHistoryDays: shouldCreateHistoryDays,
                onHistoryDaysChanged: (value) {
                  setState(() {
                    shouldCreateHistoryDays = value;
                  });
                },
              ),
              LoginPage(
                formKey: _formKeyLogin,
                tabController: tabController,
                buttonAction: loginAction,
                emailController: emailController2,
              ),
            ],
          );
        },
      ),
    );
  }

  void createAccountAction() {
    final isok = _formKeyCreate.currentState!.validate();
    if (isok) {
      loginBloc.add(
        CreateAccountEvent(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          shouldCreateHistoryDays: shouldCreateHistoryDays,
        ),
      );
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        _formKeyCreate.currentState!.reset();
      });
    }
  }

  void loginAction() {
    final isok = _formKeyLogin.currentState!.validate();
    if (isok) {
      loginBloc.add(
        LoginViaEmail(
          email: emailController2.text.trim(),
        ),
      );
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        _formKeyLogin.currentState!.reset();
      });
    }
  }
}

String? _emailValidator(String? value) {
  final val = value?.trim();

  if (val == null || val.isEmpty) {
    return 'We do need your email here';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  if (!emailRegex.hasMatch(val)) {
    return 'Enter correct email';
  }
  return null;
}

String? _validateName(String? value) {
  final val = value?.trim();

  if (val == null || val.isEmpty) {
    return 'There is nothing up there.';
  }
  if (val.length == 1) {
    return "It's way too short name.";
  }
  final nameRegex = RegExp(r'^[a-zA-Zа-яА-Я\s-]+$');
  if (!nameRegex.hasMatch(val)) {
    return 'The name can only contain letters, spaces and hyphens.';
  }
  return null;
}
