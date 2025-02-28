// ignore_for_file: one_member_abstracts

import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

abstract class UserRemoteSource {
  Future<bool> updateUser({required UserEntity user});
  Future<List<DayEntity>> fetchRemoteDays({required List<int> daysIds});
}
