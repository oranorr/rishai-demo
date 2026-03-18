import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_email_usecase.dart';
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
      final gUser = await _remoteDataSource.authorizeViaGoogle();

      if (gUser == null) {
        return const Left(
          FailureNoGoogleUser(
            'Google authentication failed. You may have cancelled login.',
          ),
        );
      }

      final raw = await _userServiceClient.loginOAuth(
        email: gUser.email ?? '',
        name: gUser.displayName ?? '',
        provider: 'google',
      );
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
        code: params.code,
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
  Future<Either<Failure, UserEntity>> loginViaEmail(
    LoginViaEmailParams params,
  ) async {
    try {
      final raw = await _userServiceClient.login(
        email: params.loginInfoEntity.email,
        code: params.loginInfoEntity.verificationCode,
      );
      return Right(UserModel.fromMap(raw).toEntity());
    } on UserServiceException catch (e) {
      log('loginViaEmail UserServiceException: ${e.code} - ${e.message}');
      if (e.code == 'NOT_FOUND') {
        return const Left(FailureNoUserWithEmail());
      }
      return const Left(FailureDirectus());
    } on Exception catch (e) {
      log('loginViaEmail Exception: $e');
      return const Left(FailureDirectus());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginViaApple() async {
    try {
      final aUser = await _remoteDataSource.authorizeViaApple();

      if (aUser == null) {
        return const Left(
          FailureNoAppleUser(
            'Apple authentication failed. You may have cancelled login.',
          ),
        );
      }

      log(aUser.email.toString());
      final raw = await _userServiceClient.loginOAuth(
        email: aUser.email ?? '',
        name: aUser.displayName ?? 'Undefined',
        provider: 'apple',
      );
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
