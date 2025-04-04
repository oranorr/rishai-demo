import 'package:flutter/widgets.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';

/// Класс для автоматического отслеживания событий сессии (открытие/закрытие приложения, длительность)
class AnalyticsEventTracker with WidgetsBindingObserver {
  factory AnalyticsEventTracker() => _instance;

  AnalyticsEventTracker._();
  static final AnalyticsEventTracker _instance = AnalyticsEventTracker._();

  bool _initialized = false;

  /// Инициализация трекера событий аналитики
  void init() {
    if (_initialized) return;

    // Добавляем наблюдатель для отслеживания изменений состояния приложения
    WidgetsBinding.instance.addObserver(this);

    // Логируем открытие приложения
    analytics.logAppOpen();
    analytics.startSession();

    _initialized = true;
  }

  /// Обработка изменений состояния приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Пользователь вернулся в приложение
        analytics.logAppOpen();
        analytics.startSession();
        break;
      case AppLifecycleState.paused:
        // Приложение ушло в фон
        analytics.endSession();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Ничего не делаем для этих состояний
        break;
    }
  }

  /// Освобождение ресурсов
  void dispose() {
    if (!_initialized) return;

    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  /// Отслеживание активности пользователя в приложении
  void trackUserActivityEvents() {
    analytics.setUserProperty(
      name: 'last_active_time',
      value: DateTime.now().toIso8601String(),
    );

    analytics.logCustomEvent(
      name: 'user_activity',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Отслеживание завершения онбординга
  void trackOnboardingCompletion() {
    analytics.logOnboardingComplete();
    analytics.setUserProperty(name: 'onboarding_completed', value: 'true');
  }

  /// Отслеживание успешной подписки
  void trackSubscriptionSuccess(String planName, double price) {
    analytics.logSubscriptionSuccess(
      planName: planName,
      value: price,
    );

    analytics.setUserProperty(name: 'subscription_plan', value: planName);
    analytics.setUserProperty(
      name: 'subscription_date',
      value: DateTime.now().toIso8601String(),
    );
  }
}
