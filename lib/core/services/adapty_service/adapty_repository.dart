import 'package:adapty_flutter/adapty_flutter.dart';

abstract class AdaptyRepository {
  List<AdaptyPaywallProduct> get products;
  bool get isActive;
  Future<void> initAdapty();
  Future<String> makePurchase({required AdaptyPaywallProduct product});
  Future<void> profileInfo();
}
