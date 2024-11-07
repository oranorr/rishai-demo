import 'dart:developer';

import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository.dart';

final adapty = getIt.get<AdaptyRepository>();

@Singleton(as: AdaptyRepository)
class AdaptyRepositoryImpl implements AdaptyRepository {
  @override
  Future<void> initAdapty() async {
    try {
      await Adapty().activate();
      await Adapty().setLogLevel(AdaptyLogLevel.debug);
    } on AdaptyError catch (adaptyError) {
      log(adaptyError.toString(), name: 'Adapty Service');
    }
  }
}
