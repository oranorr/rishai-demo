import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/features/food_diary/presentation/diary_entry_page.dart';
import 'package:rishai/features/food_diary/presentation/wellness_page/wellness_page.dart';
import 'package:rishai/features/settings/presentation/settings_pages/contact_page.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
import 'package:rishai/core/services/adapty_service/presentation/paywall.dart';
import 'package:rishai/splash.dart';

final appNavigationService = getIt<AppNavigationService>();

@LazySingleton()
class AppNavigationService {
  const AppNavigationService(this._navigatorKeyProvider);
  final NavigatorKeyProvider _navigatorKeyProvider;
  static BuildContext? get ctx =>
      appNavigationService.config.routerDelegate.navigatorKey.currentContext;

  GoRouter get config => GoRouter(
        navigatorKey: _navigatorKeyProvider.rootNavigatorKey,
        initialLocation: AppRoutes.splah.path,
        observers: [SentryNavigatorObserver()],
        routes: [
          GoRoute(
            name: AppRoutes.login.name,
            path: AppRoutes.login.path,
            pageBuilder: (_, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const LoginScreen(),
            ),
          ),
          GoRoute(
            name: AppRoutes.enterOtp.name,
            path: AppRoutes.enterOtp.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const EnterOtp(),
            ),
          ),
          GoRoute(
            name: AppRoutes.homeScreen.name,
            path: AppRoutes.homeScreen.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            name: AppRoutes.onboard.name,
            path: AppRoutes.onboard.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const Onboard(),
            ),
          ),
          GoRoute(
            name: AppRoutes.whoopConnect.name,
            path: AppRoutes.whoopConnect.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const WhoopConnectPage(),
            ),
          ),
          GoRoute(
            name: AppRoutes.redirect.name,
            path: AppRoutes.redirect.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const Redirect(),
            ),
          ),
          GoRoute(
            name: AppRoutes.questionary.name,
            path: AppRoutes.questionary.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const Questionary(),
            ),
          ),
          GoRoute(
            name: AppRoutes.profileSettings.name,
            path: AppRoutes.profileSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const ProfileSettings(),
            ),
          ),
          GoRoute(
            name: AppRoutes.connectionSettings.name,
            path: AppRoutes.connectionSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const ConnectionSettings(),
            ),
          ),
          GoRoute(
            name: AppRoutes.notificationsSettings.name,
            path: AppRoutes.notificationsSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const NotificationsSettings(),
            ),
          ),
          GoRoute(
            name: AppRoutes.otherSettings.name,
            path: AppRoutes.otherSettings.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const OtherSettings(),
            ),
          ),
          GoRoute(
            name: AppRoutes.splah.name,
            path: AppRoutes.splah.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const SplashScreen(),
            ),
          ),
          GoRoute(
            name: AppRoutes.calibratingScreen.name,
            path: AppRoutes.calibratingScreen.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const CalibratingScreen(),
            ),
          ),
          GoRoute(
            name: AppRoutes.paywall.name,
            path: AppRoutes.paywall.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const Paywall(),
            ),
          ),
          GoRoute(
            name: AppRoutes.contactPage.name,
            path: AppRoutes.contactPage.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const ContactPage(),
            ),
          ),
          GoRoute(
            name: AppRoutes.diaryEntryPage.name,
            path: AppRoutes.diaryEntryPage.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const DiaryEntryPage(),
            ),
          ),
          GoRoute(
            name: AppRoutes.wellnessPage.name,
            path: AppRoutes.wellnessPage.path,
            pageBuilder: (context, state) => _buildPageWithDefaultTransition(
              state: state,
              child: const WellnessPage(),
            ),
          ),
        ],
      );

  void go({required String path}) {
    ctx!.go(path);
  }

  void pop({required String? path, Object? state}) {
    ctx!.pop(path);
  }

  Future<void> push({required String path, Object? state}) async {
    await ctx!.push(path);
  }

  /// Выполняет pop до тех пор, пока не достигнет указанного пути.
  ///
  /// [path] - путь, до которого нужно делать pop.
  /// Если путь не найден в стеке навигации, будет выполнен pop до корня.
  ///
  /// Пример использования:
  /// ```dart
  /// appNavigationService.popUntil(path: AppRoutes.homeScreen.path);
  /// ```
  void popUntil({required String path}) {
    final context = ctx;
    if (context == null) return;

    final navigator = Navigator.of(context);

    // Нормализуем путь (убираем trailing slash для сравнения)
    final normalizedTargetPath = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;

    // Используем popUntil с предикатом, который проверяет текущий путь
    navigator.popUntil((route) {
      // Проверяем, является ли это первым маршрутом (корнем стека)
      // Если да, останавливаемся, чтобы не удалить корневой маршрут
      if (route.isFirst) {
        return true;
      }

      // Пытаемся получить путь из route.settings.name
      // В GoRouter путь может храниться в name
      final routeName = route.settings.name;
      if (routeName != null) {
        final normalizedRouteName =
            routeName.endsWith('/') && routeName.length > 1
                ? routeName.substring(0, routeName.length - 1)
                : routeName;

        // Если путь совпадает, останавливаемся
        if (normalizedRouteName == normalizedTargetPath) {
          return true;
        }
      }

      // Также проверяем текущий путь через routeInformationProvider
      // Это полезно, если путь не хранится в route.settings.name
      try {
        final currentUri = config.routeInformationProvider.value.uri;
        final currentPath = currentUri.path;
        final normalizedCurrentPath =
            currentPath.endsWith('/') && currentPath.length > 1
                ? currentPath.substring(0, currentPath.length - 1)
                : currentPath;

        if (normalizedCurrentPath == normalizedTargetPath) {
          return true;
        }
      } catch (e) {
        // Игнорируем ошибки при получении пути
      }

      // Продолжаем pop, если путь не совпадает
      return false;
    });
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
