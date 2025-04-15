import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:rishai/app.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/analytics/analytics_event_tracker.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';

import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/version_check/version_check_service.dart';
import 'package:rishai/core/widgets/update_dialog.dart';
import 'package:rishai/core/theme/themes.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://5119bdddc7ff73b5231d2a825080823a@o4508957542318080.ingest.us.sentry.io/4508957543890944';
      options
        ..tracesSampleRate = 1.0
        ..sendDefaultPii = true
        ..attachScreenshot = true
        ..attachViewHierarchy = true;
    },
    appRunner: () async {
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await Firebase.initializeApp();

      await configureDependencies();

      await dotenv.load();

      await analytics.init();

      AnalyticsEventTracker().init();

      await adapty.initAdapty();

      await hive.initHive();

      await prefsRepo.init();

      await directus.initDirectus();

      await notes.initNotificationsService();

      await notes.requestPermissions();

      FlutterNativeSplash.remove();

      final versionCheckService = getIt<VersionCheckService>();
      final bool updateRequired = await versionCheckService.isUpdateRequired();

      if (updateRequired) {
        final storeUrl = await versionCheckService.getStoreUrl();
        if (storeUrl != null) {
          runApp(
            ScreenUtilInit(
              designSize: const Size(375, 812),
              child: MaterialApp(
                theme: AppTheme.dark,
                home: UpdateRequiredScreen(storeUrl: storeUrl),
              ),
            ),
          );
        } else {
          // TODO: Решить, что делать, если URL магазина не найден, но обновление требуется.
          // Возможно, показать ошибку или запустить приложение с предупреждением?
          // Пока просто запускаем приложение.
          runApp(const RishAi());
        }
      } else {
        runApp(const RishAi());
      }
    },
  );
}

class RishAi extends StatelessWidget {
  const RishAi({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => loginBloc,
        ),
        BlocProvider(
          create: (context) => whoopBloc,
        ),
        BlocProvider(
          create: (context) => userBloc,
        ),
        BlocProvider(
          create: (context) => chatBloc,
        ),
        BlocProvider(
          create: (context) => weekPlanBloc,
        ),
      ],
      child: const App(),
    );
  }
}
