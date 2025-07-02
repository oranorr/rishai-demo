// ignore_for_file: one_member_abstracts

import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

abstract class UserRemoteSource {
  Future<bool> updateUser({required UserEntity user});

  // === НОВАЯ УПРОЩЕННАЯ АРХИТЕКТУРА ===
  Future<List<DayEntity>> fetchUserDays({required String userId});
}
