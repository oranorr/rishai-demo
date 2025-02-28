import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

// ignore: one_member_abstracts
abstract class UserLocalDataSource {
  Future<bool> updateUser({required UserEntity user});
  Future<List<DayEntity>> retrieveSavedDays();
}
