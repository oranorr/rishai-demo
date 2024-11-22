import 'package:envied/envied.dart';

part 'envied.g.dart';

@Envied(path: ".env")
abstract class Env {
  @EnviedField(varName: 'OPEN_AI_API_KEY')
  static const String apiKey = _Env.apiKey;

  @EnviedField(varName: 'WHOOP_CLIENT_ID')
  static const String clientId = _Env.clientId;

  @EnviedField(varName: 'WHOOP_CLIENT_SECRET')
  static const String clientSecret = _Env.clientSecret;

  @EnviedField(varName: 'DIRECTUS_EMAIL')
  static const String directusEmail = _Env.directusEmail;

  @EnviedField(varName: 'DIRECTUS_PASSWORD')
  static const String directusPassword = _Env.directusPassword;

  @EnviedField(varName: 'DIRECTUS_ACCESS_TOKEN')
  static const String directusAccessToken = _Env.directusAccessToken;

  @EnviedField(varName: 'GPT_ASSISTANT_ID')
  static const String gptAssistantId = _Env.gptAssistantId;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID')
  static const String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'ADAPTY_SDK_KEY')
  static const String adaptyKey = _Env.adaptyKey;
}
