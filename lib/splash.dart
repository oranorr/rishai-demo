import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/widgets/cpi.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
// import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> initStuff() async {
    Future.delayed(Durations.medium2, () async {
      userBloc.add(CheckForSavedUser());
    });
  }

  @override
  Widget build(BuildContext context) {
    initStuff();
    return RishScaffold(
      needsAppBar: false,
      needsBottomPadding: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36.w,
            ),
            Expanded(
              child:
                  SizedBox(width: 190.w, child: Image.asset('assets/logo.png')),
            ),
            const RishCPI(),
            SizedBox(
              height: 36.w,
            ),
          ],
        ),
      ),
    );
  }
}
