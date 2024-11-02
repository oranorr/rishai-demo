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
    );
    final res = await directus.updateOne(
        collection: usersCollection,
        itemId: userBloc.state.user.directusId,
        updateData: {'whoopRefreshToken': _refreshToken});

    log('DIRECTUS UPDATE TOKEN DATA: $res');
    // Timer.periodic(response.expiresIn, (t) {

    Timer.periodic(response.expiresIn, (t) async {
      log('Token should be dead, refreshing now!');
      await refreshToken(_refreshToken);
    });
  }

  Future<bool> refreshToken(String refToken) async {
    final res = await wRepo.refreshToken(refToken);
    if (res != null) {
      _accessToken = res.accessToken;
      _refreshToken = res.refreshToken;
      await prefsRepo.writeTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      await directus.updateOne(
          collection: usersCollection,
          itemId: userBloc.state.user.directusId,
          updateData: {'whoopRefreshToken': _refreshToken});
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> initService() async {
    final String savedRefreshToken = prefsRepo.fetchSavedRefreshToken();
    if (savedRefreshToken.isNotEmpty) {
      final res = await refreshToken(savedRefreshToken);
      if (res) {
        return res;
      }
    }
    // else {
    try {
      final directusUser = await directus.readOne(
          collection: usersCollection, id: userBloc.state.user.directusId);
      final refToken = directusUser['whoopRefreshToken'];

      if (refToken != null && refToken!.isNotEmpty) {
        return await refreshToken(refToken);
      } else {
        return false;
      }
    } on Exception catch (e) {
      log('There are no saved refresh tokens anywhere. Should login user again. Error was: $e');
      return false;
    }
    // }
  }

  @override
  Future<void> diconnect(String userId) async {
    try {
      await prefsRepo.clearTokens();
      // final updUser =
      await directus.updateOne(
        collection: usersCollection,
        itemId: userId,
        updateData: {
          'whoopRefreshToken': null,
          'whoopData': {},
          'bodyMeasurements': {},
        },
      );
      // log('Cleared user: $updUser');

      // if (updUser['days'] != null && updUser['days'].isNotEmpty) {
      //   print('days were: ${updUser['days']}');
      //   await directus.deleteOne(
      //       collection: daysCollection, id: updUser['days'].last.toString());
      // }
    } catch (e) {
      rethrow;
    }
  }
}
