import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';

class Redirect extends StatelessWidget {
  const Redirect({super.key});

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      implyLeading: false,
      needsAppBar: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 50.h),
            Text(
              "Please stand by, fetching WHOOP data\n\nDon't close the app",
              style: context.styles.h2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
