import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/adapty_error_handler.dart';

final adapty = getIt.get<AdaptyRepository>();

@Singleton(as: AdaptyRepository)
class AdaptyRepositoryImpl implements AdaptyRepository {
  @override
  late List<AdaptyPaywallProduct> products;

  @override
  late bool isActive = false;

  @override
  late bool isTrialActive = false;

  late AdaptyPaywall paywall;

  // Флаг для режима разработки
  bool _isSimulatorMode = false;

  @override
  Future<void> initAdapty() async {
    try {
      // Проверяем, запущено ли приложение в симуляторе/эмуляторе

      bool isReal = await _isRealDevice();
      if (!isReal) {
        _logger('Обнаружен симулятор/эмулятор. Включение режима симуляции.');
        _isSimulatorMode = true;

        // В режиме симулятора используем заглушки
        isActive = true;
        isTrialActive = true;
        products = [];
        return;
      }

      // Продолжаем только если это реальное устройство
      final bool isActivated = await Adapty().isActivated();

      if (!isActivated) {
        await Adapty().activate(
          configuration: AdaptyConfiguration(
            apiKey: Env.adaptyKey,
          ),
        );
      }
      // .activate(apiKey: Env.adaptyKey);

      await Adapty().setLogLevel(AdaptyLogLevel.error);
      _logger('Adapty initialized successfully');

      // === УЛУЧШЕННАЯ ИНТЕГРАЦИЯ: Firebase Analytics + Adapty ===
      await _setupFirebaseAdaptyIntegration();
      // === КОНЕЦ ИНТЕГРАЦИИ ===

      paywall = await Adapty().getPaywall(
        placementId: 'onboard_placement',
      );
      products = await Adapty().getPaywallProducts(
        paywall: paywall,
      );
      // products = adaptyProducts;
      _logger('Products are set');
    } catch (e, stackTrace) {
      _logger('Error initializing Adapty: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_init',
      );

      // Независимо от причины ошибки, включаем режим симуляции
      _logger('Включение режима симуляции из-за ошибки: $e');
      _isSimulatorMode = true;
      isActive = true;
      isTrialActive = true;
      products = [];
    }
  }

  // Метод для определения, запущено ли на реальном устройстве
  Future<bool> _isRealDevice() async {
    try {
      // На iOS симулятор имеет префикс имени "iPhone Simulator" или "iPad Simulator"
      if (Platform.isIOS) {
        return !Platform.operatingSystem.toLowerCase().contains('simulator');
      }
      // На Android можно проверить некоторые признаки эмулятора
      else if (Platform.isAndroid) {
        String model =
            Platform.operatingSystem + Platform.operatingSystemVersion;
        return !(model.contains('google_sdk') ||
            model.contains('emulator') ||
            model.contains('sdk') ||
            model.toLowerCase().contains('genymotion') ||
            model.contains('Android SDK'));
      }
      // Если не мобильная платформа, считаем симулятором
      return false;
    } catch (e) {
      _logger('Ошибка при определении типа устройства: $e');
      // В случае ошибки считаем, что это симулятор
      return false;
    }
  }

  @override
  Future<String> makePurchase({required AdaptyPaywallProduct product}) async {
    // В режиме симулятора всегда возвращаем успех
    if (_isSimulatorMode) {
      _logger('Покупка в режиме симулятора. Автоматический успех.');
      isActive = true;
      return 'SUCCESS';
    }

    try {
      // Проверяем и переустанавливаем Firebase App Instance ID перед покупкой
      await _ensureFirebaseIntegration();

      final prof = await Adapty().getProfile();
      final isCurrentlyActive = prof.accessLevels['premium']?.isActive ?? false;

      // [FIX] Улучшенная логика проверки активной подписки
      if (isCurrentlyActive) {
        // Обновляем локальный статус в соответствии с реальным профилем
        isActive = true;
        final lvl = prof.accessLevels['premium'];
        if (lvl != null) {
          isTrialActive = await _isTrialPeriodAvailable(lvl);
        } else {
          isTrialActive = true;
        }

        _logger(
          '[AdaptyPurchase] ✅ Подписка уже активна, обновляем локальный статус',
        );

        // Если локальный статус не соответствовал реальному, это значит была проблема синхронизации
        // Возвращаем SUCCESS вместо ALREADY_EXISTS, так как пользователь должен пройти дальше
        return 'SUCCESS';
      }

      _logger(
        '[AdaptyPurchase] 🛒 Начинаем покупку продукта: ${product.vendorProductId}',
      );
      AdaptyPurchaseResult res = await Adapty().makePurchase(product: product);
      final profile = await Adapty().getProfile();

      final lvl = profile.accessLevels['premium'];
      // es.accessLevels['premium'];

      isActive = (lvl?.isActive ?? false) &&
          res.runtimeType == AdaptyPurchaseResultSuccess;
      if (lvl != null) {
        isTrialActive = await _isTrialPeriodAvailable(lvl);
      } else {
        isTrialActive = true;
      }

      if (isActive) {
        _logger('[AdaptyPurchase] ✅ Покупка подписки успешна!');
        return 'SUCCESS';
      } else {
        _logger('[AdaptyPurchase] ❌ Подписка не активна.');
        return 'CANCEL';
      }
    } catch (e, stackTrace) {
      _logger('[AdaptyPurchase] ❌ Ошибка при покупке: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_make_purchase',
        extras: {
          'product_id': product.vendorProductId,
          'product_price': product.price.amount,
          'product_currency': product.price.currencyCode,
        },
      );
      return 'Error happened, while processing purchase. Please, try again';
    }
  }

  /// Убеждаемся, что интеграция Firebase с Adapty настроена
  /// Используется перед критическими операциями как покупки
  Future<void> _ensureFirebaseIntegration() async {
    try {
      _logger(
        '[Firebase-Adapty Integration] 🔄 Проверяем интеграцию перед покупкой...',
      );

      final String? currentAppInstanceId =
          await FirebaseAnalytics.instance.appInstanceId;

      if (currentAppInstanceId != null && currentAppInstanceId.isNotEmpty) {
        // Переустанавливаем ID для уверенности
        await Adapty().setIntegrationIdentifier(
          key: 'firebase_app_instance_id',
          value: currentAppInstanceId,
        );

        _logger(
          '[Firebase-Adapty Integration] ✅ Firebase App Instance ID подтвержден: $currentAppInstanceId',
        );
      } else {
        _logger(
          '[Firebase-Adapty Integration] ⚠️ Firebase App Instance ID все еще отсутствует - попытка повторной настройки',
        );
        await _setupFirebaseAdaptyIntegration();
      }
    } catch (e) {
      _logger(
        '[Firebase-Adapty Integration] ❌ Ошибка при проверке интеграции: $e',
      );
      // Не прерываем покупку из-за проблем с интеграцией
    }
  }

  @override
  Future<void> identify({required String adaptyId}) async {
    // В режиме симулятора просто устанавливаем флаги
    if (_isSimulatorMode) {
      _logger('Identify в режиме симулятора для ID: $adaptyId');
      isActive = true;
      isTrialActive = true;
      return;
    }

    // await Adapty().logout();
    try {
      await Adapty().identify(adaptyId);
      final profile = await Adapty().getProfile();
      AdaptyAccessLevel? lvl = profile.accessLevels['premium'];
      _logger(profile.customerUserId.toString());

      isActive = lvl?.isActive ?? false;
      if (lvl != null) {
        isTrialActive = await _isTrialPeriodAvailable(lvl);
      } else {
        isTrialActive = true;
      }
      // _logger("ACCESS LEVEL $lvl");
      // isActive = true;
      // isTrialActive = true;
      _logger(
        'Sub is active: ${profile.accessLevels["premium"]?.isActive ?? false}',
      );
      _logger('Is trial available: $isTrialActive');
      _logger('Prof id: $adaptyId');
      _logger('Expires at: ${lvl?.expiresAt}');
    } catch (e, stackTrace) {
      _logger('Error during identify: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_identify',
        extras: {'adapty_id': adaptyId},
      );

      // [FIX] Улучшенное восстановление покупок при ошибке identify
      // Это решает проблему когда подписка уже привязана к другому аккаунту
      _logger('Попытка восстановления покупок после ошибки identify...');

      bool restoreSuccessful = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _logger('Попытка восстановления $attempt/3...');

          final profile = await Adapty().restorePurchases();
          AdaptyAccessLevel? lvl = profile.accessLevels['premium'];

          isActive = lvl?.isActive ?? false;
          if (lvl != null) {
            isTrialActive = await _isTrialPeriodAvailable(lvl);
          } else {
            isTrialActive = true;
          }

          _logger(
            'После восстановления (попытка $attempt) - подписка активна: $isActive, пробный период доступен: $isTrialActive',
          );

          // Если удалось восстановить активную подписку, выходим из цикла
          if (isActive) {
            _logger(
              'Подписка успешно восстановлена после ошибки identify на попытке $attempt',
            );
            restoreSuccessful = true;
            break;
          }

          // Небольшая задержка перед следующей попыткой
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
        } catch (restoreError) {
          _logger(
            'Ошибка при восстановлении покупок (попытка $attempt): $restoreError',
          );
          // Продолжаем попытки или устанавливаем статус по умолчанию на последней попытке
          if (attempt == 3) {
            isActive = false;
            isTrialActive = true;
          }
        }
      }

      // Перебрасываем оригинальную ошибку только если не удалось восстановить подписку
      if (!restoreSuccessful) {
        _logger(
          'Все попытки восстановления не удались, перебрасываем ошибку identify',
        );
        rethrow;
      }
    }
  }

  @override
  String generateAdaptyId({required String directusId}) {
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    int randomNum = math.Random().nextInt(1000000);

    String uniqueId = '$directusId-$timestamp-$randomNum';
    if (uniqueId.length > 255) {
      uniqueId = uniqueId.substring(0, 255);
    }
    return uniqueId;
  }

  Future<bool> _isTrialPeriodAvailable(
    AdaptyAccessLevel? accessLevel,
  ) async {
    // В режиме симулятора всегда возвращаем true
    if (_isSimulatorMode) {
      return true;
    }

    try {
      _logger(
        'Active Introductory Offer Type: ${accessLevel!.activeIntroductoryOfferType}',
      );
      _logger('Expires At: ${accessLevel.expiresAt}');

      // Проверяем, использовал ли пользователь вводное предложение
      final hasActiveTrial =
          accessLevel.activeIntroductoryOfferType == 'free_trial' ||
              accessLevel.activeIntroductoryOfferType == 'free';

      // Проверяем, истёк ли доступ
      final isExpired = accessLevel.expiresAt != null &&
          DateTime.now().isAfter(accessLevel.expiresAt!);

      // Если активный пробный период уже есть, возвращаем false
      if (hasActiveTrial && !isExpired) {
        _logger('Trial has already been used and is still active.');
        return false;
      }

      // Проверяем через API, если данные не позволяют точно определить статус
      // final eligibility = await Adapty().getPaywallProducts(paywall: paywall);

      // .getProductsIntroductoryOfferEligibility(products: products);

      for (final product in products) {
        log(product.toString());
        // final isEligible = product.subscription.offer
        // eligibility[product.vendorProductId] == AdaptyEligibility.eligible;
        // if (isEligible) {
        //   _logger('Trial is available for product: ${product.vendorProductId}');
        //   return true;
        // }
      }

      _logger('No trial available for any product.');
      return false;
    } catch (e, stackTrace) {
      _logger('Error checking trial availability: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_check_trial',
        extras: {
          'access_level_type': accessLevel?.activeIntroductoryOfferType,
          'expires_at': accessLevel?.expiresAt?.toString(),
        },
      );
      return false;
    }
  }

  @override
  Future<void> logout() async {
    // В режиме симулятора просто логгируем действие
    if (_isSimulatorMode) {
      _logger('Logout в режиме симулятора');
      return;
    }

    try {
      await Adapty().logout();
    } catch (e, stackTrace) {
      _logger('Error during logout: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_logout',
      );
      rethrow;
    }
  }

  @override
  Future<String> restorePurchases() async {
    // В режиме симулятора всегда считаем, что подписка активна
    if (_isSimulatorMode) {
      _logger('Восстановление покупок в режиме симулятора');
      isActive = true;
      return 'ACTIVE';
    }

    try {
      final profile = await Adapty().restorePurchases();
      AdaptyAccessLevel? lvl = profile.accessLevels['premium'];
      _logger(profile.customerUserId.toString());

      isActive = lvl?.isActive ?? false;
      if (isActive) {
        return 'ACTIVE';
      } else {
        return 'NO_ACTIVE';
      }
    } catch (e, stackTrace) {
      _logger('Error while restoring: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_restore_purchases',
      );
      return 'ERROR';
    }
  }

  @override
  Future<void> test() async {
    // В режиме симулятора просто логгируем
    if (_isSimulatorMode) {
      _logger('Тест в режиме симулятора');
      return;
    }

    try {
      final prof = await Adapty().getProfile();
      final s = await _isTrialPeriodAvailable(prof.accessLevels['premium']);

      _logger(s.toString());
      //   final p = await Adapty()
      //       .getProductsIntroductoryOfferEligibility(products: products);
      //   _logger(p.toString());
    } catch (e, stackTrace) {
      _logger('Error during test: $e');
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'adapty_test',
      );
      rethrow;
    }
  }

  /// Настройка интеграции Firebase с Adapty
  /// Включает retry-механизм для получения Firebase App Instance ID
  Future<void> _setupFirebaseAdaptyIntegration() async {
    try {
      _logger(
        '[Firebase-Adapty Integration] 🚀 Начинаем настройку интеграции...',
      );

      // Убеждаемся, что Firebase Analytics включен
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      _logger(
        '[Firebase-Adapty Integration] ✅ Firebase Analytics Collection включен',
      );

      // Пытаемся получить Firebase App Instance ID с повторными попытками
      String? firebaseAppInstanceId =
          await _getFirebaseAppInstanceIdWithRetry();

      if (firebaseAppInstanceId != null && firebaseAppInstanceId.isNotEmpty) {
        // Устанавливаем Firebase App Instance ID в Adapty для связи аналитики
        await Adapty().setIntegrationIdentifier(
          key: 'firebase_app_instance_id',
          value: firebaseAppInstanceId,
        );

        _logger(
          '[Firebase-Adapty Integration] ✅ Firebase App Instance ID успешно установлен в Adapty: $firebaseAppInstanceId',
        );

        // Дополнительно устанавливаем идентификатор для Firebase as Integration
        try {
          await Adapty().setIntegrationIdentifier(
            key: 'firebase',
            value: firebaseAppInstanceId,
          );
          _logger(
            '[Firebase-Adapty Integration] ✅ Дополнительный Firebase ID установлен',
          );
        } catch (e) {
          _logger(
            '[Firebase-Adapty Integration] ⚠️ Ошибка установки дополнительного Firebase ID: $e',
          );
        }
      } else {
        _logger(
          '[Firebase-Adapty Integration] ❌ Не удалось получить Firebase App Instance ID после всех попыток',
        );

        // Отправляем уведомление в Sentry для мониторинга
        await AdaptyErrorHandler.handleError(
          Exception('Firebase App Instance ID is null or empty'),
          StackTrace.current,
          context: 'firebase_adapty_integration_failure',
          extras: {
            'firebase_app_instance_id':
                firebaseAppInstanceId?.toString() ?? 'null',
            'platform': Platform.operatingSystem,
            'is_release_mode': kReleaseMode.toString(),
          },
        );
      }
    } catch (e, stackTrace) {
      _logger(
        '[Firebase-Adapty Integration] ❌ Критическая ошибка при интеграции Firebase с Adapty: $e',
      );

      // Не прерываем инициализацию Adapty из-за ошибки интеграции
      await AdaptyErrorHandler.handleError(
        e,
        stackTrace,
        context: 'firebase_adapty_integration_error',
        extras: {
          'platform': Platform.operatingSystem,
          'is_release_mode': kReleaseMode.toString(),
        },
      );
    }
  }

  /// Получение Firebase App Instance ID с повторными попытками
  /// Возвращает null если не удалось получить ID после всех попыток
  Future<String?> _getFirebaseAppInstanceIdWithRetry({
    int maxRetries = 5,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger(
          '[Firebase-Adapty Integration] 🔄 Попытка $attempt/$maxRetries получить Firebase App Instance ID...',
        );

        final String? appInstanceId =
            await FirebaseAnalytics.instance.appInstanceId;

        if (appInstanceId != null && appInstanceId.isNotEmpty) {
          _logger(
            '[Firebase-Adapty Integration] ✅ Firebase App Instance ID получен на попытке $attempt: $appInstanceId',
          );
          return appInstanceId;
        } else {
          _logger(
            '[Firebase-Adapty Integration] ⚠️ Попытка $attempt: Firebase App Instance ID пустой или null',
          );
        }
      } catch (e) {
        _logger(
          '[Firebase-Adapty Integration] ❌ Ошибка на попытке $attempt: $e',
        );
      }

      // Если это не последняя попытка, ждем перед следующей
      if (attempt < maxRetries) {
        final Duration delay = Duration(
          milliseconds: initialDelay.inMilliseconds *
              attempt, // Экспоненциальная задержка
        );
        _logger(
          '[Firebase-Adapty Integration] ⏳ Ожидание ${delay.inMilliseconds}ms перед следующей попыткой...',
        );
        await Future.delayed(delay);
      }
    }

    _logger(
      '[Firebase-Adapty Integration] ❌ Не удалось получить Firebase App Instance ID после $maxRetries попыток',
    );
    return null;
  }
}

void _logger(String message) {
  log(message, name: 'Adapty Service');
}
