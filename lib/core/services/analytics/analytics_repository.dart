abstract class AnalyticsRepository {
  /// Инициализация аналитического сервиса
  Future<void> init();

  /// Отслеживание начала сессии
  Future<void> logAppOpen();

  /// Отслеживание активации пользователя (регистрация)
  Future<void> logSignUp({String? method});

  /// Отслеживание события логина
  Future<void> logLogin({String? method});

  /// Отслеживание завершения онбординга
  Future<void> logOnboardingComplete();

  /// Отслеживание начала процесса оформления подписки
  Future<void> logBeginSubscription();

  /// Отслеживание успешного оформления подписки
  Future<void> logSubscriptionSuccess({String? planName, double? value});

  /// Отслеживание просмотра экрана
  Future<void> logScreenView({required String screenName, String? screenClass});

  /// Отслеживание пользовательского события
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  });

  /// Установка свойств пользователя
  Future<void> setUserProperty({required String name, required String? value});

  /// Установка ID пользователя
  Future<void> setUserId(String? id);

  /// Отслеживание длительности сессии
  Future<void> startSession();

  /// Завершение отслеживания сессии
  Future<void> endSession({int? durationSeconds});
}
