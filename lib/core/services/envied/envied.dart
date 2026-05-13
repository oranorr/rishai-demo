import 'package:envied/envied.dart';
import 'package:flutter/foundation.dart';

part 'envied.g.dart';

@Envied(
  path: '.env',
)
abstract class Env {
  @EnviedField(varName: 'OPEN_AI_API_KEY')
  static const String apiKey = _Env.apiKey;

  @EnviedField(varName: 'WHOOP_CLIENT_ID')
  static const String clientId = _Env.clientId;

  @EnviedField(varName: 'WHOOP_CLIENT_SECRET')
  static const String clientSecret = _Env.clientSecret;

  @EnviedField(varName: 'GPT_ASSISTANT_ID')
  static const String gptAssistantId = _Env.gptAssistantId;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID')
  static const String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'ADAPTY_SDK_KEY')
  static const String adaptyKey = _Env.adaptyKey;

  @EnviedField(varName: 'AUTH_HEADER_KEY')
  static const String authHeaderKey = _Env.authHeaderKey;
}

/// Константы для Branch SDK
class BranchConfig {
  /// Тестовый ключ Branch SDK
  static const String testKey = 'key_test_bvFnrp1Yvth9XpJU6kI7idjiuxpLxhaa';

  /// Продакшн ключ Branch SDK
  static const String liveKey = 'key_live_guvoqm49tveW5nOI8oV8okafrCgPh1W1';

  /// Продакшн секрет Branch SDK
  static const String liveSecret =
      'secret_live_GvutdURNUnQCP1educILr2OXUaMiLlX4';

  /// Тестовые домены Branch
  static const String testDomain = '75lyh.test-app.link';
  static const String testAlternateDomain = '75lyh-alternate.test-app.link';

  /// Продакшн домены Branch
  static const String liveDomain = '75lyh.app.link';
  static const String liveAlternateDomain = '75lyh-alternate.app.link';

  /// Получить текущий ключ в зависимости от режима сборки
  static String get currentKey => kDebugMode ? testKey : liveKey;

  /// Получить текущий домен в зависимости от режима сборки
  static String get currentDomain => kDebugMode ? testDomain : liveDomain;

  /// Получить текущий альтернативный домен в зависимости от режима сборки
  static String get currentAlternateDomain =>
      kDebugMode ? testAlternateDomain : liveAlternateDomain;
}
