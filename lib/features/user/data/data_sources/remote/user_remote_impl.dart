import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@Singleton(as: UserRemoteSource)
class UserRemoteImpl implements UserRemoteSource {
  @override
  Future<bool> updateUser({required UserEntity user}) async {
    try {
      log(
        'Обновление пользователя в Directus: ${user.directusId}',
        name: 'UserRemoteImpl',
      );
      log(
        'daysIds для отправки: ${user.daysIds.length} элементов',
        name: 'UserRemoteImpl',
      );

      final res = await directus.updateOne(
        collection: usersCollection,
        itemId: user.directusId,
        updateData: user.toMap(),
      );

      log('Пользователь успешно обновлен в Directus', name: 'UserRemoteImpl');
      return res.isNotEmpty;
    } on Exception catch (e) {
      log('Ошибка при обновлении пользователя: $e', name: 'UserRemoteImpl');
      rethrow;
    }
  }

  @override
  Future<List<DayEntity>> fetchRemoteDays({
    required List<int> daysIds,
  }) async {
    try {
      final res = await dayManager.fetchDays(daysIds: daysIds);
      return res.fold(
        (l) => [],
        (r) => r,
      );
    } catch (e) {
      log('Error fetching remote days: $e');
      return [];
    }
  }
}
