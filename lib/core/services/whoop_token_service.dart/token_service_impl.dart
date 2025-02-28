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

  @override
  String get refToken => _refreshToken;
  @override
  String get accessToken => _accessToken;

  @override
  Future<void> createTokenService(AuthResponseEntity response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;

    await prefsRepo.writeTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
      expiresAt: DateTime.now().add(response.expiresIn).toIso8601String(),
    );
    await directus.updateOne(
      collection: usersCollection,
      itemId: userBloc.state.user.directusId,
      updateData: {'whoopRefreshToken': _refreshToken},
    );

    await scheduleTokenRefresh();
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
    if (await isAccessTokenValid()) {
      _accessToken = prefsRepo.fetchSavedAccessToken();
      _refreshToken = prefsRepo.fetchSavedRefreshToken();
      if (_accessToken.isEmpty || _refreshToken.isEmpty) {
        _logger('Locally stored tokens are empty');
        return false;
      }
      _logger('Tokens are valid');
      return true;
    } else {
      _logger('Tokens are refreshing now.');
      final latestRefreshToken = prefsRepo.fetchSavedRefreshToken();
      final res = await wRepo.refreshToken(latestRefreshToken);

      if (res != null) {
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
        return true;
      } else {
        return false;
      }
    }
  }

  Future<bool> isAccessTokenValid() async {
    final expiresAt = await prefsRepo.getTokenExpiryDate();
    print('Token expires at: $expiresAt');
    if (expiresAt == null) return false;

    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      _logger('Access token already expired!');
      return false;
    }

    return now.isBefore(expiresAt.subtract(const Duration(minutes: 2)));
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
          'whoopData': {},
          'bodyMeasurements': {},
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
