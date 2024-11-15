import 'dart:developer';
import 'dart:math' as math;
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository.dart';

final adapty = getIt.get<AdaptyRepository>();

@Singleton(as: AdaptyRepository)
class AdaptyRepositoryImpl implements AdaptyRepository {
  final Adapty _adapty = Adapty();
  @override
  late List<AdaptyPaywallProduct> products;

  @override
  late bool isActive;

  @override
  late bool isTrialActive;

  @override
  Future<void> initAdapty() async {
    try {
      await Adapty().activate();
      await Adapty().setLogLevel(AdaptyLogLevel.verbose);
      _logger('Adapty initialized successfully');
      final paywall =
          await Adapty().getPaywall(placementId: 'onboard_placement');
      final adaptyProducts =
          await Adapty().getPaywallProducts(paywall: paywall);
      products = adaptyProducts;
      _logger('Products are set');
    } on AdaptyError catch (adaptyError) {
      _logger(adaptyError.toString());
    }
  }

  @override
  Future<String> makePurchase({required AdaptyPaywallProduct product}) async {
    try {
      final profile = await _adapty.getProfile();
      if (profile.accessLevels["premium"]?.isActive ?? false) {
        return 'ALREADY_EXISTS';
      }
      final res = await _adapty.makePurchase(product: product);
      _logger(res.toString());
      isActive = res?.accessLevels["premium"]?.isActive ?? false;
      isTrialActive = res?.accessLevels["premium"] != null
          ? _isTrialPeriodActive(res!.accessLevels["premium"]!)
          : false;

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
    await _adapty.logout();
    await _adapty.identify(adaptyId);
    final profile = await _adapty.getProfile();
    AdaptyAccessLevel? lvl = profile.accessLevels["premium"];

    isActive = lvl?.isActive ?? false;
    isTrialActive = lvl != null ? _isTrialPeriodActive(lvl) : false;
    _logger(
        'Sub is active: ${profile.accessLevels["premium"]?.isActive ?? false}');
    _logger('Is sub trial: $isTrialActive');
    _logger('Prof id: $adaptyId');
    _logger('Expires at: ${lvl!.expiresAt}');
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

  bool _isTrialPeriodActive(AdaptyAccessLevel accessLevel) {
    _logger("Offer type: ${accessLevel.activeIntroductoryOfferType}");
    return accessLevel.activeIntroductoryOfferType == 'free_trial' &&
        (accessLevel.expiresAt == null ||
            DateTime.now().isBefore(accessLevel.expiresAt!));
  }

  @override
  Future<void> logout() async {
    await _adapty.logout();
  }
}

void _logger(String message) {
  log(message, name: 'Adapty Service');
}



// (profileId: c6688d47-c7fa-4eb9-a699-edb15e6d2f2f, _segmentId: not implemented, customerUserId: 230-1731580368123-972821,
//vendorOriginalTransactionId: 2000000770906587
//
// 
// (profileId: e25dd79f-0a8e-452b-bc70-f9e7245d4b58, _segmentId: not implemented, customerUserId: 129-1731646644914-27759,
//vendorOriginalTransactionId: GPA.3362-5340-2077-12437