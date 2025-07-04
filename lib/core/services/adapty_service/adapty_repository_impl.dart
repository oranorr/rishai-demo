import 'dart:developer';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:adapty_flutter/adapty_flutter.dart';
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
      if (Platform.isIOS || Platform.isAndroid) {
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
      } else {
        // Если не на мобильной платформе, также включаем режим симуляции
        _logger(
          'Запуск не на мобильной платформе. Включение режима симуляции.',
        );
        _isSimulatorMode = true;
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
      final prof = await Adapty().getProfile();
      if (prof.accessLevels['premium']?.isActive ?? false) {
        return 'ALREADY_EXISTS';
      }
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
        log('Subscription purchase successful!');
        return 'SUCCESS';
      } else {
        log('Subscription is not active.');
        return 'CANCEL';
      }
    } catch (e, stackTrace) {
      log('Error during purchase: $e');
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
      rethrow;
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
}

void _logger(String message) {
  log(message, name: 'Adapty Service');
}
