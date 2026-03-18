import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service.dart';
import 'package:rishai/features/whoop/domain/entities/auth_response_entity.dart';

final wTokenService = getIt.get<WhoopTokenService>();

@Singleton(as: WhoopTokenService)
class WhoopTokenServiceImpl implements WhoopTokenService {
  WhoopTokenServiceImpl(this._userServiceClient);
  // [Whoop migration] Держим зависимость в конструкторе для совместимости с DI,
  // но клиент больше не управляет WHOOP токенами локально.
  // ignore: unused_field
  final UserServiceClient _userServiceClient;

  @override
  String get refToken => '';
  @override
  String get accessToken => '';

  @override
  Future<void> createTokenService(AuthResponseEntity response) async {}

  @override
  Future<bool> shouldAttemptReconnect() async => false;

  @override
  Future<bool> refreshToken(String refToken) async => false;

  @override
  Future<bool> isAccessTokenValid() async => false;

  @override
  Future<bool> initService() async => false;

  @override
  Future<void> diconnect(String userId) async {
    try {
      await prefsRepo.clearTokens();
    } on Exception catch (e) {
      _logger(e.toString());
      rethrow;
    }
  }

  void _logger(String message) {
    log(message, name: 'WhoopTokenService');
  }
}
