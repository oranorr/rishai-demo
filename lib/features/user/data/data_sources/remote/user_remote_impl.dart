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

  // Старый метод fetchRemoteDays удалён - используем fetchUserDays

  @override
  Future<List<DayEntity>> fetchUserDays({
    required String userId,
  }) async {
    try {
      log(
        'Получение дней пользователя $userId через новый метод',
        name: 'UserRemoteImpl',
      );

      final res = await dayManager.getUserDays(userId: userId);
      return res.fold(
        (failure) {
          log(
            'Ошибка получения дней: ${failure.message}',
            name: 'UserRemoteImpl',
          );
          return [];
        },
        (days) {
          log('Успешно получено ${days.length} дней', name: 'UserRemoteImpl');
          return days;
        },
      );
    } catch (e) {
      log(
        'Исключение при получении дней пользователя: $e',
        name: 'UserRemoteImpl',
      );
      return [];
    }
  }
}
