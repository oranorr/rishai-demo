import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@Singleton(as: UserLocalDataSource)
class UserLocalDataImpl implements UserLocalDataSource {
  @override
  Future<bool> updateUser({required UserEntity user}) async {
    try {
      await hive.saveUser(user: user);
      return true;
    } on Exception catch (e) {
      log(e.toString());
      return false;
    }
  }

  @override
  Future<List<DayEntity>> retrieveSavedDays() async {
    return hive.retrieveSavedDays();
  }
}
