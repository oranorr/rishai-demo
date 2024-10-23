// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/router/navigator_key_provider.dart';
import 'package:rishai/features/home/presentation/home_screen.dart';
import 'package:rishai/features/login/presentation/pages/enter_otp_page.dart';
import 'package:rishai/features/login/presentation/pages/login_screen.dart';
import 'package:rishai/features/onboard/presentation/onboard.dart';
import 'package:rishai/features/onboard/presentation/questionary.dart';
import 'package:rishai/features/settings/presentation/settings_pages/connection_settings.dart';
import 'package:rishai/features/settings/presentation/settings_pages/notifications_settings.dart';
import 'package:rishai/features/settings/presentation/settings_pages/other.dart';
import 'package:rishai/features/settings/presentation/settings_pages/profile_settings.dart';
import 'package:rishai/features/whoop/presentation/calibrating_screen.dart';
import 'package:rishai/features/whoop/presentation/fetching_data_screen.dart';
import 'package:rishai/features/whoop/presentation/whoop_connect_page.dart';
import 'package:rishai/splash.dart';

final appNavigationService = getIt<AppNavigationService>();

@LazySingleton()
class AppNavigationService {
  final NavigatorKeyProvider _navigatorKeyProvider;

  const AppNavigationService(this._navigatorKeyProvider);
  static BuildContext? get ctx =>
      appNavigationService.config.routerDelegate.navigatorKey.currentContext;

  GoRouter get config => GoRouter(
        navigatorKey: _navigatorKeyProvider.rootNavigatorKey,
        initialLocation: AppRoutes.splah.path,
        debugLogDiagnostics: false,
        routes: [
          GoRoute(
            name: AppRoutes.login.name,
            path: AppRoutes.login.path,
            pageBuilder: (_, __) => _buildPageWithDefaultTransition(
                state: __, child: const LoginScreen()),
          ),
          GoRoute(
            name: AppRoutes.enterOtp.name,
            path: AppRoutes.enterOtp.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const EnterOtp()),
          ),
          GoRoute(
            name: AppRoutes.homeScreen.name,
            path: AppRoutes.homeScreen.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const HomeScreen()),
          ),
          GoRoute(
            name: AppRoutes.onboard.name,
            path: AppRoutes.onboard.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const Onboard()),
          ),
          GoRoute(
            name: AppRoutes.whoopConnect.name,
            path: AppRoutes.whoopConnect.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const WhoopConnectPage()),
          ),
          GoRoute(
            name: AppRoutes.redirect.name,
            path: AppRoutes.redirect.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const Redirect()),
          ),
          GoRoute(
            name: AppRoutes.questionary.name,
            path: AppRoutes.questionary.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const Questionary()),
          ),
          GoRoute(
            name: AppRoutes.profileSettings.name,
            path: AppRoutes.profileSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const ProfileSettings()),
          ),
          GoRoute(
            name: AppRoutes.connectionSettings.name,
            path: AppRoutes.connectionSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const ConnectionSettings()),
          ),
          GoRoute(
            name: AppRoutes.notificationsSettings.name,
            path: AppRoutes.notificationsSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const NotificationsSettings()),
          ),
          GoRoute(
            name: AppRoutes.otherSettings.name,
            path: AppRoutes.otherSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const OtherSettings()),
          ),
          GoRoute(
            name: AppRoutes.splah.name,
            path: AppRoutes.splah.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const SplashScreen()),
          ),
          GoRoute(
            name: AppRoutes.calibratingScreen.name,
            path: AppRoutes.calibratingScreen.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
                state: state, child: const CalibratingScreen()),
          ),
        ],
      );

  void go({required String path}) {
    ctx!.go(path);
  }

  void pop({required String? path, Object? state}) {
    ctx!.pop(path);
  }

  void push({required String path, Object? state}) {
    ctx!.push(path);
  }

  String get currentPath =>
      config.routeInformationProvider.value.uri.toString();
}

CustomTransitionPage _buildPageWithDefaultTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
