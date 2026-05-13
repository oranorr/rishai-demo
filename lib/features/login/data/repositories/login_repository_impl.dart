import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source.dart';
import 'package:rishai/features/login/domain/params/email_otp_params.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/user/data/models/user_model.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@Singleton(as: LoginRepository)
class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl(this._remoteDataSource, this._userServiceClient);
  final LoginRemoteDataSource _remoteDataSource;
  final UserServiceClient _userServiceClient;

  @override
  Future<Either<Failure, UserEntity>> loginViaGoogle() async {
    try {
      final User? gUser = await _remoteDataSource.authorizeViaGoogle();

      if (gUser == null) {
        return const Left(
          FailureNoGoogleUser(
            'Google authentication failed. You may have cancelled login.',
          ),
        );
      }

      // Новый поток: Firebase ID token → POST /auth/oauth → сохранить JWT → GET /users/me.
      // Не используем legacy `POST /users/login-oauth` (оно доверяет телу и требует pivot-key).
      final String? idToken = await gUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const Left(
          FailureNoGoogleUser(
            'Google authentication failed. Firebase id_token is missing.',
          ),
        );
      }
      await _userServiceClient.exchangeOAuthToken(
        idToken: idToken,
        providerHint: 'google',
        // display_name опционально, но дешево передать при первом входе
        displayName: gUser.displayName,
      );
      final raw = await _userServiceClient.getMe();
      return Right(UserModel.fromMap(raw).toEntity());
    } on UserServiceException catch (e) {
      log('loginViaGoogle UserServiceException: ${e.code} - ${e.message}');
      return Left(FailureNoGoogleUser(e.message));
    } on Exception catch (ex) {
      log('loginViaGoogle Exception: $ex');
      return Left(FailureNoGoogleUser(ex.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createNewUser(
    CreateNewUserParams params,
  ) async {
    try {
      final raw = await _userServiceClient.createUser(
        email: params.email,
        name: params.name,
      );
      return Right(UserModel.fromMap(raw).toEntity());
    } on UserServiceException catch (e) {
      log('createNewUser UserServiceException: ${e.code} - ${e.message}');
      if (e.code == 'CONFLICT') {
        return const Left(FailureUserAlreadyExists());
      }
      if (e.code == 'VALIDATION_ERROR') {
        return const Left(FailureOnNewUserCreation());
      }
      return const Left(FailureOnNewUserCreation());
    } on Exception catch (e) {
      log('createNewUser Exception: $e');
      return const Left(FailureOnNewUserCreation());
    }
  }

  @override
  Future<Either<Failure, Unit>> requestEmailOtp(
    RequestEmailOtpParams params,
  ) async {
    try {
      await _userServiceClient.requestOtp(email: params.email);
      return const Right(unit);
    } on UserServiceException catch (e) {
      log('requestEmailOtp UserServiceException: ${e.code} - ${e.message}');
      return Left(FailureDirectus(e.message));
    } on Exception catch (e) {
      log('requestEmailOtp Exception: $e');
      return Left(FailureDirectus(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyEmailOtpAndFetchProfile(
    VerifyEmailOtpParams params,
  ) async {
    try {
      await _userServiceClient.verifyOtp(
        email: params.email,
        code: params.code,
      );
      final raw = await _userServiceClient.getMe();
      return Right(UserModel.fromMap(raw).toEntity());
    } on UserServiceException catch (e) {
      log(
        'verifyEmailOtpAndFetchProfile UserServiceException: ${e.code} - ${e.message}',
      );
      return Left(FailureDirectus(e.message));
    } on Exception catch (e) {
      log('verifyEmailOtpAndFetchProfile Exception: $e');
      return Left(FailureDirectus(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginViaApple() async {
    try {
      final User? aUser = await _remoteDataSource.authorizeViaApple();

      if (aUser == null) {
        return const Left(
          FailureNoAppleUser(
            'Apple authentication failed. You may have cancelled login.',
          ),
        );
      }

      // Новый поток: Firebase ID token → POST /auth/oauth → сохранить JWT → GET /users/me.
      //
      // Для Apple `display_name` бывает доступен только при первом входе на устройстве,
      // поэтому прокидываем его как опциональное поле (если есть).
      final String? idToken = await aUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const Left(
          FailureNoAppleUser(
            'Apple authentication failed. Firebase id_token is missing.',
          ),
        );
      }

      await _userServiceClient.exchangeOAuthToken(
        idToken: idToken,
        providerHint: 'apple',
        displayName: aUser.displayName,
      );

      final raw = await _userServiceClient.getMe();
      return Right(UserModel.fromMap(raw).toEntity());
    } on UserServiceException catch (e) {
      log('loginViaApple UserServiceException: ${e.code} - ${e.message}');
      return Left(FailureNoAppleUser(e.message));
    } on Exception catch (ex) {
      log('loginViaApple Exception: $ex');
      return const Left(
        FailureNoAppleUser(
          'Apple authentication failed. You may have cancelled login.',
        ),
      );
    }
  }
}
