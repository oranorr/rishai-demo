import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/app.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/ads/ads_repository.dart';
import 'package:rishai/core/services/analytics/analytics_event_tracker.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/version_check/version_check_service.dart';
import 'package:rishai/core/theme/themes.dart';
import 'package:rishai/core/widgets/update_dialog.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

      // Инициализируем Firebase только если приложение еще не инициализировано
      try {
        // Проверяем, не инициализирован ли Firebase уже
        final apps = Firebase.apps;
        if (apps.isEmpty) {
          // Если еще не инициализирован, инициализируем
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('Firebase инициализирован в Dart');
        } else {
          print('Firebase уже инициализирован ранее');
        }
      } catch (e) {
        print('Ошибка при инициализации Firebase: $e');
      }

      // Инициализируем Firebase Analytics для всех сборок
      FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      print('🔥 Firebase Analytics collection enabled explicitly');

      // Проверяем получение App Instance ID сразу после инициализации
      try {
        final String? appInstanceId = await analytics.appInstanceId;
        print(
          '🔥 Firebase App Instance ID: ${appInstanceId ?? "NOT_AVAILABLE"}',
        );

        if (appInstanceId == null) {
          print(
            '⚠️ Firebase App Instance ID недоступен сразу после инициализации',
          );
          // Принудительно логируем событие для инициализации
          await analytics.logEvent(
            name: 'force_initialization',
            parameters: {
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'platform': 'Flutter',
              'mode': kDebugMode ? 'debug' : 'release',
            },
          );
          print(
            '🔥 Отправлено принудительное событие для инициализации Analytics',
          );

          // Даем время Firebase для инициализации App Instance ID
          await Future.delayed(const Duration(milliseconds: 1000));

          final String? retryAppInstanceId = await analytics.appInstanceId;
          print(
            '🔥 Firebase App Instance ID после задержки: ${retryAppInstanceId ?? "STILL_NOT_AVAILABLE"}',
          );
        }
      } catch (e) {
        print('❌ Ошибка получения Firebase App Instance ID: $e');
      }

      // Дополнительные тестовые события только в debug режиме
      if (kDebugMode) {
        // Создаем несколько тестовых событий для проверки работы аналитики
        print('🔥 Отправляем тестовые события Firebase analytics...');

        // Тестовое событие 1
        await analytics.logEvent(
          name: 'test_analytics_event_1',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'debug': 'true',
            'platform': 'Flutter',
            'test_number': 1,
          },
        );

        // Тестовое событие 2
        await analytics.logEvent(
          name: 'test_analytics_event_2',
          parameters: {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'debug': 'true',
            'platform': 'Flutter',
            'test_number': 2,
          },
        );

        // Тестовое стандартное событие
        await analytics.logScreenView(
          screenName: 'test_screen',
          screenClass: 'TestScreen',
        );

        print('🔥 Тестовые события Firebase analytics отправлены');
      }

      await configureDependencies();

      await dotenv.load();

      AnalyticsEventTracker().init();

      await adapty.initAdapty();

      // Инициализация Google Mobile Ads SDK
      try {
        final adsRepository = getIt<AdsRepository>();
        await adsRepository.init();
        print('[main] Google Mobile Ads SDK инициализирован');
      } catch (e) {
        print('[main] Ошибка инициализации Google Mobile Ads SDK: $e');
      }

      // ВАЖНО: преференсы должны инициализироваться ДО Hive,
      // так как версионирование схемы данных зависит от SharedPreferences
      await prefsRepo.init();

      await hive.initHive();

      await notes.initNotificationsService();

      await notes.requestPermissions();

      // Восстанавливаем запланированные уведомления после рестарта/обновления.
      // Каждый запуск переплановывает пуш, если пользователь ранее его включал —
      // это гарантирует, что WorkManager/zonedSchedule не потеряется при перезагрузке.
      final String? savedNotificationTime = prefsRepo.getNoteTime();
      if (savedNotificationTime != null) {
        try {
          final parts = savedNotificationTime.split(':');
          final time = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          await notes.scheduleNotification(time);
          print('[main] Уведомление восстановлено на $savedNotificationTime');
        } catch (e) {
          print('[main] Ошибка восстановления уведомления: $e');
        }
      }

      await FlutterBranchSdk.init(
        enableLogging: kDebugMode,
      ); // Включаем логирование только в debug режиме для продакшена
      // FlutterBranchSdk
      // .validateSDKIntegration(); // Убираем валидацию для продакшена
      // BranchService().initDeepLinkListener();

      // Test Branch Integration
      //

      FlutterNativeSplash.remove();

      final versionCheckService = getIt<VersionCheckService>();
      final bool updateRequired = await versionCheckService.isUpdateRequired();
      print('updateRequired: $updateRequired');
      if (updateRequired && !kDebugMode) {
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
        BlocProvider(
          create: (context) => foodDiaryCubit,
        ),
      ],
      child: const App(),
    );
  }
}
