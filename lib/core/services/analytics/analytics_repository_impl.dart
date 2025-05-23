import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/analytics/analytics_repository.dart';

final analytics = getIt.get<AnalyticsRepository>();

@Singleton(as: AnalyticsRepository)
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  DateTime? _sessionStartTime;

  @override
  Future<void> init() async {
    // Выводим информацию о Firebase Analytics
    if (kDebugMode) {
      print('🔥 Инициализация Analytics Repository');
      print('🔥 Firebase Analytics instance: $_analytics');
    }

    // Включаем сбор аналитики и режим отладки
    await _analytics.setAnalyticsCollectionEnabled(true);

    // Проверяем работу аналитики
    try {
      if (kDebugMode) {
        await _analytics.logEvent(
          name: 'analytics_repository_init',
          parameters: {
            'init_time': DateTime.now().toIso8601String(),
            'debug_mode': 'true', // Используем строку вместо bool
          },
        );
        print('🔥 Тестовое событие analytics_repository_init отправлено');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Ошибка отправки тестового события: $e');
      }
    }

    // Включаем режим отладки для Firebase Analytics (только в режиме разработки)
    if (kDebugMode) {
      // В новых версиях Firebase Analytics используется другой метод для отладки
      print(
        '🔍 Firebase Analytics debug mode enabled through Firebase console',
      );
      print(
        '👉 Check "DebugView" in Firebase console to see events in real-time',
      );

      // При необходимости можно использовать консольные логи для отладки событий
      // Для просмотра событий в консоли Firebase можно воспользоваться инструкцией:
      // https://firebase.google.com/docs/analytics/debugview
    }
  }

  @override
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      if (kDebugMode) {
        print('🔍 Event logged: app_open');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging app_open: $e');
      }
    }
  }

  @override
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'default');
      if (kDebugMode) {
        print('🔍 Event logged: sign_up with method: ${method ?? 'default'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging sign_up: $e');
      }
    }
  }

  @override
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'default');
      if (kDebugMode) {
        print('🔍 Event logged: login with method: ${method ?? 'default'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging login: $e');
      }
    }
  }

  @override
  Future<void> logOnboardingComplete() async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_complete',
        parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      if (kDebugMode) {
        print('🔍 Event logged: onboarding_complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging onboarding_complete: $e');
      }
    }
  }

  @override
  Future<void> logBeginSubscription() async {
    try {
      await _analytics.logBeginCheckout(
        value: 0,
        currency: 'USD',
        items: [],
      );
      if (kDebugMode) {
        print('🔍 Event logged: begin_checkout');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging begin_checkout: $e');
      }
    }
  }

  @override
  Future<void> logSubscriptionSuccess({String? planName, double? value}) async {
    try {
      await _analytics.logPurchase(
        value: value ?? 0.0,
        currency: 'USD',
        items: [
          AnalyticsEventItem(
            itemName: planName ?? 'subscription',
            itemCategory: 'subscription',
          ),
        ],
      );
      if (kDebugMode) {
        print(
          '🔍 Event logged: purchase with plan: ${planName ?? 'subscription'}, value: ${value ?? 0.0}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging purchase: $e');
      }
    }
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        print(
          '🔍 Event logged: screen_view - $screenName (${screenClass ?? 'no class'})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging screen_view: $e');
      }
    }
  }

  @override
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Преобразуем все значения в строки или числа, если они еще не являются таковыми
      Map<String, Object>? sanitizedParams;

      if (parameters != null) {
        sanitizedParams = <String, Object>{};
        parameters.forEach((key, value) {
          if (value is String || value is num) {
            sanitizedParams![key] = value;
          } else if (value is List) {
            // Преобразуем списки в строки через запятую
            sanitizedParams![key] = value.join(', ');
          } else if (value is Map) {
            // Преобразуем Map в строку JSON
            sanitizedParams![key] = json.encode(value);
          } else {
            // Любые другие типы преобразуем в строку
            sanitizedParams![key] = value.toString();
          }
        });
      }

      await _analytics.logEvent(
        name: name,
        parameters: sanitizedParams,
      );

      if (kDebugMode) {
        print('🔍 Event logged: $name with params: $sanitizedParams');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging event $name: $e');
      }
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('🔍 User property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user property $name: $e');
      }
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
      if (kDebugMode) {
        print('🔍 User ID set: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user ID: $e');
      }
    }
  }

  @override
  Future<void> startSession() async {
    try {
      _sessionStartTime = DateTime.now();

      // Логируем начало сессии - используем кастомное имя события
      await _analytics.logEvent(
        name: 'app_session_started',
        parameters: {'timestamp': _sessionStartTime!.millisecondsSinceEpoch},
      );

      if (kDebugMode) {
        print('🔍 Event logged: app_session_started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging app_session_started: $e');
      }
    }
  }

  @override
  Future<void> endSession({int? durationSeconds}) async {
    try {
      // Расчет длительности сессии
      final int sessionDuration = durationSeconds ??
          (_sessionStartTime != null
              ? DateTime.now().difference(_sessionStartTime!).inSeconds
              : 0);

      // Логируем конец сессии - используем кастомное имя события
      await _analytics.logEvent(
        name: 'app_session_ended',
        parameters: {
          'duration_seconds': sessionDuration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (kDebugMode) {
        print(
          '🔍 Event logged: app_session_ended with duration: $sessionDuration seconds',
        );
      }

      _sessionStartTime = null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging app_session_ended: $e');
      }
    }
  }
}
