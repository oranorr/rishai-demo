import 'dart:async';
import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/services/whoop_token_service.dart/token_service.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/data/repository/whoop_repository_impl.dart';
import 'package:rishai/features/whoop/domain/entities/auth_response_entity.dart';

final wTokenService = getIt.get<WhoopTokenService>();

@Singleton(as: WhoopTokenService)
class WhoopTokenServiceImpl implements WhoopTokenService {
  String _accessToken = '';
  String _refreshToken = '';
  int _failedSyncAttempts = 0;
  static const int maxFailedAttempts = 3;
  DateTime? _lastSuccessfulSync;

  @override
  String get refToken => _refreshToken;
  @override
  String get accessToken => _accessToken;

  @override
  Future<void> createTokenService(AuthResponseEntity response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _failedSyncAttempts = 0;
    _lastSuccessfulSync = DateTime.now();

    await prefsRepo.writeTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
      expiresAt: DateTime.now().add(response.expiresIn).toIso8601String(),
    );
    await directus.updateOne(
      collection: usersCollection,
      itemId: userBloc.state.user.directusId,
      updateData: {
        'whoopRefreshToken': _refreshToken,
        'lastSuccessfulSync': DateTime.now().toIso8601String(),
      },
    );

    await scheduleTokenRefresh();
  }

  @override
  Future<bool> shouldAttemptReconnect() async {
    if (_failedSyncAttempts >= maxFailedAttempts) {
      _logger(
        'Достигнуто максимальное количество попыток ($maxFailedAttempts)',
      );
      return false;
    }

    if (_lastSuccessfulSync == null) {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: userBloc.state.user.directusId,
      );
      final lastSyncStr = rawUser['lastSuccessfulSync'];
      if (lastSyncStr != null) {
        _lastSuccessfulSync = DateTime.parse(lastSyncStr);
      }
    }

    // Если последняя успешная синхронизация была более 24 часов назад
    if (_lastSuccessfulSync != null &&
        DateTime.now().difference(_lastSuccessfulSync!) >
            const Duration(hours: 24)) {
      _logger('Последняя успешная синхронизация была более 24 часов назад');
      // Сбрасываем счетчик попыток, так как прошло много времени
      _failedSyncAttempts = 0;
      return true;
    }

    // Если нет успешных синхронизаций или прошло менее 24 часов,
    // разрешаем попытку, если не превышен лимит
    return _failedSyncAttempts < maxFailedAttempts;
  }

  Future<void> handleSyncSuccess() async {
    _failedSyncAttempts = 0;
    _lastSuccessfulSync = DateTime.now();
    await directus.updateOne(
      collection: usersCollection,
      itemId: userBloc.state.user.directusId,
      updateData: {
        'lastSuccessfulSync': _lastSuccessfulSync!.toIso8601String(),
      },
    );
  }

  void handleSyncFailure() {
    _failedSyncAttempts++;
    _logger('Sync attempt failed. Total failed attempts: $_failedSyncAttempts');
  }

  Future<void> scheduleTokenRefresh() async {
    final expiresAt = await prefsRepo.getTokenExpiryDate();
    if (expiresAt == null) return;

    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);

    _logger('Token expires in: $timeUntilExpiry');

    if (timeUntilExpiry.isNegative) {
      _logger('Token already expired, refreshing now!');
      await refreshToken(prefsRepo.fetchSavedRefreshToken());
    } else {
      Future.delayed(timeUntilExpiry - const Duration(minutes: 1), () async {
        _logger('Refreshing token 1 minute before expiration...');
        await refreshToken(prefsRepo.fetchSavedRefreshToken());
      });
    }
  }

  Future<bool> refreshToken(String refToken) async {
    if (refToken.isEmpty) {
      _logger('Получен пустой refresh token');
      handleSyncFailure();
      return false;
    }

    try {
      if (await isAccessTokenValid()) {
        _accessToken = prefsRepo.fetchSavedAccessToken();
        _refreshToken = prefsRepo.fetchSavedRefreshToken();
        if (_accessToken.isEmpty || _refreshToken.isEmpty) {
          _logger('Локально сохраненные токены пусты');
          handleSyncFailure();
          return false;
        }
        _logger('Токены действительны');
        await handleSyncSuccess();
        return true;
      } else {
        _logger('Начинаем обновление токенов...');
        final latestRefreshToken = prefsRepo.fetchSavedRefreshToken();
        if (latestRefreshToken.isEmpty) {
          _logger('Не найден сохраненный refresh token');
          handleSyncFailure();
          return false;
        }

        final res = await wRepo.refreshToken(latestRefreshToken);
        if (res != null) {
          _logger('Получены новые токены, сохраняем...');
          _accessToken = res.accessToken;
          _refreshToken = res.refreshToken;

          await prefsRepo.writeTokens(
            accessToken: res.accessToken,
            refreshToken: res.refreshToken,
            expiresAt: DateTime.now().add(res.expiresIn).toIso8601String(),
          );

          await directus.updateOne(
            collection: usersCollection,
            itemId: userBloc.state.user.directusId,
            updateData: {'whoopRefreshToken': _refreshToken},
          );

          await scheduleTokenRefresh();
          await handleSyncSuccess();
          _logger('Токены успешно обновлены');
          return true;
        } else {
          _logger('Не удалось получить новые токены от сервера');
          handleSyncFailure();
          return false;
        }
      }
    } catch (e) {
      _logger('Критическая ошибка при обновлении токенов: $e');
      handleSyncFailure();
      return false;
    }
  }

  Future<bool> isAccessTokenValid() async {
    try {
      final expiresAt = await prefsRepo.getTokenExpiryDate();
      _logger('Token expires at: $expiresAt');

      if (expiresAt == null) {
        _logger('Дата истечения токена не найдена');
        return false;
      }

      final now = DateTime.now();
      if (now.isAfter(expiresAt)) {
        _logger('Токен уже истек');
        return false;
      }

      return now.isBefore(expiresAt.subtract(const Duration(minutes: 2)));
    } catch (e) {
      _logger('Ошибка при проверке валидности токена: $e');
      return false;
    }
  }

  @override
  Future<bool> initService() async {
    final String savedRefreshToken = prefsRepo.fetchSavedRefreshToken();
    if (savedRefreshToken.isNotEmpty && !(await isAccessTokenValid())) {
      _logger('We have locally stored tokens');
      return refreshToken(savedRefreshToken);
    }

    try {
      final directusUser = await directus.readOne(
        collection: usersCollection,
        id: userBloc.state.user.directusId,
      );
      final refToken = directusUser['whoopRefreshToken'];

      if (refToken != null && refToken.isNotEmpty) {
        return await refreshToken(refToken);
      } else {
        return false;
      }
    } on Exception catch (e) {
      _logger('No saved refresh tokens. User should log in again. Error: $e');
      return false;
    }
  }

  @override
  Future<void> diconnect(String userId) async {
    try {
      await prefsRepo.clearTokens();
      await directus.updateOne(
        collection: usersCollection,
        itemId: userId,
        updateData: {
          'whoopRefreshToken': null,
        },
      );
    } on Exception catch (e) {
      _logger(e.toString());
      rethrow;
    }
  }

  void _logger(String message) {
    log(message, name: 'WhoopTokenService');
  }
}
