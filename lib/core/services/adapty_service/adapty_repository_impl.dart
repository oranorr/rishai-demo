import 'dart:developer';
import 'dart:math' as math;
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository.dart';
import 'package:rishai/core/services/envied/envied.dart';

final adapty = getIt.get<AdaptyRepository>();

@Singleton(as: AdaptyRepository)
class AdaptyRepositoryImpl implements AdaptyRepository {
  // final Adapty Adapty() = Adapty();
  @override
  late List<AdaptyPaywallProduct> products;

  @override
  late bool isActive;

  @override
  late bool isTrialActive;

  @override
  Future<void> initAdapty() async {
    // isActive = true;
    // isTrialActive = false;
    try {
      await Adapty().activate(apiKey: Env.adaptyKey);

      await Adapty().setLogLevel(AdaptyLogLevel.error);
      _logger('Adapty initialized successfully');
      final paywall = await Adapty().getPaywall(
        placementId: 'onboard_placement',
      );
      final adaptyProducts = await Adapty().getPaywallProducts(
        paywall: paywall,
      );
      products = adaptyProducts;
      _logger('Products are set');
    } on AdaptyError catch (adaptyError) {
      _logger(adaptyError.toString());
    }
  }

  @override
  Future<String> makePurchase({required AdaptyPaywallProduct product}) async {
    // return '';
    try {
      final profile = await Adapty().getProfile();
      if (profile.accessLevels["premium"]?.isActive ?? false) {
        return 'ALREADY_EXISTS';
      }
      final res = await Adapty().makePurchase(product: product);
      // if (res.runtimeType == AdaptyPurchaseResultSuccess) {
      final lvl = res?.accessLevels['premium'];

      isActive = lvl?.isActive ?? false;
      isTrialActive = lvl != null ? await _isTrialPeriodAvailable(lvl) : false;

      if (isActive) {
        print("Subscription purchase successful!");
        return 'SUCCESS';
      } else {
        print("Subscription is not active.");
        return 'CANCEL';
      }
    } catch (error) {
      print("Error during purchase: $error");
      return 'Error happened, while processing purchase. Please, try again';
    }
  }

  @override
  Future<void> identify({required String adaptyId}) async {
    // await Adapty().logout();
    await Adapty().identify(adaptyId);
    final profile = await Adapty().getProfile();
    AdaptyAccessLevel? lvl = profile.accessLevels["premium"];
    _logger(profile.customerUserId.toString());

    isActive = lvl?.isActive ?? false;
    isTrialActive = lvl != null ? await _isTrialPeriodAvailable(lvl) : false;
    // isActive = true;
    // isTrialActive = true;
    _logger(
        'Sub is active: ${profile.accessLevels["premium"]?.isActive ?? false}');
    _logger('Is trial available: $isTrialActive');
    _logger('Prof id: $adaptyId');
    _logger('Expires at: ${lvl?.expiresAt}');
  }

  @override
  String generateAdaptyId({required String directusId}) {
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    int randomNum = math.Random().nextInt(1000000);

    String uniqueId = "$directusId-$timestamp-$randomNum";
    if (uniqueId.length > 255) {
      uniqueId = uniqueId.substring(0, 255);
    }
    return uniqueId;
  }

  Future<bool> _isTrialPeriodAvailable(
    AdaptyAccessLevel? accessLevel,
  ) async {
    // Если accessLevel пустой, проверяем eligibility через Adapty API
    // if (accessLevel == null) {
    //   _logger("Access level is null. Checking eligibility...");
    //   final eligibility = await Adapty()
    //       .getProductsIntroductoryOfferEligibility(products: products);

    //   for (var product in products) {
    //     final isEligible =
    //         eligibility[product.vendorProductId] == AdaptyEligibility.eligible;
    //     if (isEligible) {
    //       _logger("Trial is available for product: ${product.vendorProductId}");
    //       return true;
    //     }
    //   }
    //   _logger("No trial available for any product.");
    //   return false;
    // }

    _logger(
        "Active Introductory Offer Type: ${accessLevel!.activeIntroductoryOfferType}");
    _logger("Expires At: ${accessLevel.expiresAt}");

    // Проверяем, использовал ли пользователь вводное предложение
    final hasActiveTrial =
        accessLevel.activeIntroductoryOfferType == 'free_trial' ||
            accessLevel.activeIntroductoryOfferType == 'free';

    // Проверяем, истёк ли доступ
    final isExpired = accessLevel.expiresAt != null &&
        DateTime.now().isAfter(accessLevel.expiresAt!);

    // Если активный пробный период уже есть, возвращаем false
    if (hasActiveTrial && !isExpired) {
      _logger("Trial has already been used and is still active.");
      return false;
    }

    // Проверяем через API, если данные не позволяют точно определить статус
    final eligibility = await Adapty()
        .getProductsIntroductoryOfferEligibility(products: products);

    for (var product in products) {
      final isEligible =
          eligibility[product.vendorProductId] == AdaptyEligibility.eligible;
      if (isEligible) {
        _logger("Trial is available for product: ${product.vendorProductId}");
        return true;
      }
    }

    _logger("No trial available for any product.");
    return false;
  }

  @override
  Future<void> logout() async {
    await Adapty().logout();
  }

  @override
  Future<String> restorePurchases() async {
    try {
      final profile = await Adapty().restorePurchases();
      AdaptyAccessLevel? lvl = profile.accessLevels["premium"];
      _logger(profile.customerUserId.toString());

      isActive = lvl?.isActive ?? false;
      if (isActive) {
        return 'ACTIVE';
      } else {
        return 'NO_ACTIVE';
      }
    } catch (e) {
      _logger('Error while restoring: $e');
      return 'ERROR';
    }
  }

  @override
  Future<void> test() async {
    final prof = await Adapty().getProfile();
    final s = await _isTrialPeriodAvailable(prof.accessLevels['premium']);

    _logger(s.toString());
    //   final p = await Adapty()
    //       .getProductsIntroductoryOfferEligibility(products: products);
    //   _logger(p.toString());
  }
}

void _logger(String message) {
  log(message, name: 'Adapty Service');
}
