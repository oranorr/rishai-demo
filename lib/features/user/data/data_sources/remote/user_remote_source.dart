import 'package:rishai/features/user/domain/entities/user_entity.dart';

abstract class UserRemoteSource {
  Future<bool> updateUser({required UserEntity user});
}
