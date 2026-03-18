import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@Singleton(as: UserRemoteSource)
class UserRemoteImpl implements UserRemoteSource {
  UserRemoteImpl(this._userServiceClient);
  final UserServiceClient _userServiceClient;

  /// Преобразует UserEntity.toMap() в формат User Service API.
  /// Бекенд ожидает: userGoal.goalType (string), userGoal.modificator (string).
  /// foodPreferences: diets, cuisines, restrictions — отправляем и flat, и nested
  /// (бекенд/Directus может принимать любой вариант).
  Map<String, dynamic> _toApiBody(UserEntity user) {
    final body = Map<String, dynamic>.from(user.toMap());

    // userGoal: goal → goalType, modificator (double) → string
    final userGoal = body['userGoal'] as Map<String, dynamic>?;
    if (userGoal != null && userGoal.isNotEmpty) {
      body['userGoal'] = {
        'goalType': userGoal['goal'] ?? userGoal['goalType'],
        'modificator': (userGoal['modificator'] ?? 0).toString(),
        if (userGoal['updatedAt'] != null) 'updatedAt': userGoal['updatedAt'],
      };
    }

    // foodPreferences: diets, cuisines, restrictions — добавляем вложенный объект,
    // если бекенд ожидает foodPreferences: { diets, cuisines, restrictions }
    final diets = body['diets'] as List<dynamic>?;
    final cuisines = body['cuisines'] as List<dynamic>?;
    final restrictions = body['restrictions'] as List<dynamic>?;
    if ((diets != null && diets.isNotEmpty) ||
        (cuisines != null && cuisines.isNotEmpty) ||
        (restrictions != null && restrictions.isNotEmpty)) {
      body['foodPreferences'] = {
        'diets': diets ?? [],
        'cuisines': cuisines ?? [],
        'restrictions': restrictions ?? [],
      };
    }

    log(
      '[UserRemoteImpl] PUT body: diets=${body['diets']}, cuisines=${body['cuisines']}, '
      'restrictions=${body['restrictions']}, foodPreferences=${body['foodPreferences']}',
      name: 'UserRemoteImpl',
    );
    return body;
  }

  @override
  Future<bool> updateUser({required UserEntity user}) async {
    try {
      log(
        '[UserRemoteImpl] Обновление пользователя через User Service: ${user.directusId}',
        name: 'UserRemoteImpl',
      );

      await _userServiceClient.updateUser(
        user.directusId,
        _toApiBody(user),
      );

      log('Пользователь успешно обновлен через User Service', name: 'UserRemoteImpl');
      return true;
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
