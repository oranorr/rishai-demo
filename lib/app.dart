import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rishai/core/key.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/theme/themes.dart';

final _routerConfig = appNavigationService.config;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MaterialApp.router(
          title: 'Pivot App',
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: _routerConfig,
          scaffoldMessengerKey: scaffoldKey,
        );
      },
    );
  }
}
