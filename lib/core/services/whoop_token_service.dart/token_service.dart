import 'package:rishai/features/whoop/domain/entities/auth_response_entity.dart';

abstract class WhoopTokenService {
  Future<void> createTokenService(AuthResponseEntity response);
  String get refToken;
  String get accessToken;

  Future<bool> initService();
}
