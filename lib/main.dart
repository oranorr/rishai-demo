import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:rishai/app.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';

import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

void main() async {
  final stopwatch = Stopwatch()..start();

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
      print(
          'Sentry initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      print('Flutter binding took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      print(
          'Native splash preserve took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await Firebase.initializeApp();
      print(
          'Firebase initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await configureDependencies();
      print(
          'Dependencies configuration took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await dotenv.load();
      print('Dotenv loading took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await adapty.initAdapty();
      print(
          'Adapty initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await hive.initHive();
      print('Hive initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await prefsRepo.init();
      print('Prefs initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await directus.initDirectus();
      print(
          'Directus initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await notes.initNotificationsService();
      print(
          'Notifications service initialization took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      await notes.requestPermissions();
      print('Permissions request took: ${stopwatch.elapsed.inMilliseconds}ms');
      stopwatch.reset();

      FlutterNativeSplash.remove();
      print(
          'Native splash removal took: ${stopwatch.elapsed.inMilliseconds}ms');

      print('Total initialization time: ${stopwatch.elapsed.inMilliseconds}ms');
      runApp(const RishAi());
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
