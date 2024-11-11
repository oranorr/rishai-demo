import 'dart:developer';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository.dart';

final adapty = getIt.get<AdaptyRepository>();

@Singleton(as: AdaptyRepository)
class AdaptyRepositoryImpl implements AdaptyRepository {
  @override
  late List<AdaptyPaywallProduct> products;

  @override
  late bool isActive;

  @override
  Future<void> initAdapty() async {
    try {
      await Adapty().activate();
      await Adapty().setLogLevel(AdaptyLogLevel.debug);
      _logger('Adapty initialized successfully');
      final paywall =
          await Adapty().getPaywall(placementId: 'onboard_placement');
      final adaptyProducts =
          await Adapty().getPaywallProducts(paywall: paywall);
      products = adaptyProducts;
      _logger('Products are set');
      await profileInfo();
    } on AdaptyError catch (adaptyError) {
      _logger(adaptyError.toString());
    }
  }

  @override
  Future<String> makePurchase({required AdaptyPaywallProduct product}) async {
    try {
      final res = await Adapty().makePurchase(product: product);
      // _logger(res.toString());
      final isActive = res?.accessLevels["premium"]?.isActive ?? false;

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
  Future<void> profileInfo() async {
    final profile = await Adapty().getProfile();
    isActive = profile.accessLevels["premium"]?.isActive ?? false;
    _logger('Sub is active: $isActive');
    // isActive = profile.
    // final subscription = profile.accessLevels["premium"];
    // _logger('Sub is: $subscription');
  }
}

void _logger(String message) {
  log(message, name: 'Adapty Service');
}
