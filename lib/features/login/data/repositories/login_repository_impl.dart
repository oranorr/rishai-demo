import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/login/data/dara_sources/remote/remote_data_source.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_email_usecase.dart';
import 'package:rishai/features/user/data/models/user_model.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@Singleton(as: LoginRepository)
class LoginRepositoryImpl implements LoginRepository {
  // final LoginLocalDataSource _localDataSource;

  const LoginRepositoryImpl(this._remoteDataSource);
  final LoginRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> loginViaGoogle() async {
    UserEntity user;
    try {
      final gUser = await _remoteDataSource.authorizeViaGoogle();

      if (gUser == null) {
        return const Left(
          FailureNoGoogleUser(
            'Google authentication failed. You may have cancelled login.',
          ),
        );
      }

      final res = await directus.readMany(
        collection: usersCollection,
        filters: Filters({'email': F.eq(gUser.email)}),
      );

      if (res.isEmpty) {
        final rawNewUser = await directus.createOne(
          collection: usersCollection,
          data: {'email': gUser.email, 'name': gUser.displayName},
        );
        user = UserModel.fromMap(rawNewUser).toEntity();
      } else {
        user = UserModel.fromMap(res.first).toEntity();
      }

      return Right(user);
    } on Exception catch (ex) {
      return Left(FailureNoGoogleUser(ex.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createNewUser(
    CreateNewUserParams params,
  ) async {
    try {
      final res = await directus.readMany(
        collection: usersCollection,
        filters: Filters({'email': F.eq(params.email)}),
      );

      if (res.isEmpty) {
        final raw = await directus.createOne(
          collection: usersCollection,
          data: {
            'name': params.name,
            'email': params.email,
            'code': params.code,
          },
        );
        return Right(UserModel.fromMap(raw).toEntity());
      } else {
        return const Left(FailureUserAlreadyExists());
      }
    } on Exception catch (e) {
      log(e.toString());
      return const Left(FailureOnNewUserCreation());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginViaEmail(
    LoginViaEmailParams params,
  ) async {
    try {
      final res = await directus.readMany(
        collection: usersCollection,
        filters: Filters({'email': F.eq(params.loginInfoEntity.email)}),
      );

      if (res.isEmpty) {
        return const Left(FailureNoUserWithEmail());
      } else {
        final rawUpd = await directus.updateOne(
          collection: usersCollection,
          itemId: res.first['id'].toString(),
          updateData: {
            'email': params.loginInfoEntity.email,
            'code': params.loginInfoEntity.verificationCode,
            'name': res.first['name'],
          },
        );
        final user = UserModel.fromMap(rawUpd).toEntity();
        return Right(user);
      }
    } on Exception catch (e) {
      log(e.toString());
      return const Left(FailureDirectus());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginViaApple() async {
    UserEntity user;
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
      final res = await directus.readMany(
        collection: usersCollection,
        filters: Filters({'email': F.eq(aUser.email)}),
      );

      if (res.isEmpty) {
        final rawNewUser = await directus.createOne(
          collection: usersCollection,
          data: {
            'email': aUser.email,
            'name': aUser.displayName ?? 'Undefined',
          },
        );
        user = UserModel.fromMap(rawNewUser).toEntity();
      } else {
        final existingUser = res.first;
        final rawUpdUser = await directus.updateOne(
          collection: usersCollection,
          itemId: existingUser['id'].toString(),
          updateData: {
            'email': aUser.email,
            'name': aUser.displayName ?? existingUser['name'],
          },
        );
        user = UserModel.fromMap(rawUpdUser).toEntity();
      }

      return Right(user);
    } on Exception catch (ex) {
      // return Left(FailureNoGoogleUser(ex.toString()));
      return const Left(
        FailureNoAppleUser(
          'Apple authentication failed. You may have cancelled login.',
        ),
      );
    }
  }
}
