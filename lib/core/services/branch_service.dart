import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';

class BranchService {
  factory BranchService() => _instance;

  BranchService._internal();
  static final BranchService _instance = BranchService._internal();

  void initDeepLinkListener() {
    FlutterBranchSdk.listSession().listen(
      (data) {
        print('[BranchDeepLink] Получены данные: $data');
        // Здесь можно обработать параметры deep link
        if (data.containsKey('+clicked_branch_link') &&
            data['+clicked_branch_link'] == true) {
          final String? customData = data['custom_key'];
          if (customData != null) {
            // TODO: навигация или логика
          }
        }
      },
      onError: (error) {
        print('[BranchDeepLink] Ошибка: $error');
      },
    );
  }
}
