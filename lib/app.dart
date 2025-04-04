import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rishai/core/key.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/theme/themes.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';

final _routerConfig = appNavigationService.config;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _setupRouterListener();
  }

  void _setupRouterListener() {
    _routerConfig.routeInformationProvider.addListener(() {
      // Получаем текущую локацию
      final String currentPath = appNavigationService.currentPath;
      final String? currentScreenName = _extractScreenName(currentPath);

      if (currentScreenName != null) {
        // Логируем просмотр экрана
        analytics.logScreenView(
          screenName: currentScreenName,
          screenClass: currentScreenName,
        );
      }
    });
  }

  String? _extractScreenName(String path) {
    // Удаляем параметры URL и получаем название экрана
    final uri = Uri.parse(path);
    final cleanPath = uri.path;

    // Возвращаем последний сегмент пути как название экрана
    // Или первый сегмент, если путь состоит только из одного сегмента
    final segments = cleanPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return 'Home';
    return segments.last;
  }

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
