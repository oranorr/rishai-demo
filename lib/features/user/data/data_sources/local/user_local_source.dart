import 'package:rishai/features/user/domain/entities/user_entity.dart';

// ignore: one_member_abstracts
abstract class UserLocalDataSource {
  Future<bool> updateUser({required UserEntity user});
}
