import 'package:adapty_flutter/adapty_flutter.dart';

abstract class AdaptyRepository {
  List<AdaptyPaywallProduct> get products;
  bool get isActive;
  bool get isTrialActive;
  Future<void> initAdapty();
  Future<String> makePurchase({required AdaptyPaywallProduct product});
  Future<void> identify({required String adaptyId});
  String generateAdaptyId({required String directusId});
  Future<void> logout();
}
