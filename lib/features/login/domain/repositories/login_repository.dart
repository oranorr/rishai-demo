import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/login/domain/usecases/login_via_email_usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

abstract interface class LoginRepository {
  Future<Either<Failure, UserEntity>> loginViaGoogle();
  Future<Either<Failure, UserEntity>> createNewUser(CreateNewUserParams params);
  Future<Either<Failure, UserEntity>> loginViaEmail(LoginViaEmailParams params);
  Future<Either<Failure, UserEntity>> loginViaApple();
}
