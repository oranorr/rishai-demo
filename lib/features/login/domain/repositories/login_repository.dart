import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/login/domain/params/email_otp_params.dart';
import 'package:rishai/features/login/domain/usecases/create_new_user_usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

abstract interface class LoginRepository {
  Future<Either<Failure, UserEntity>> loginViaGoogle();

  /// Шаг 1 регистрации: `POST /users/create` (с pivot-key), без клиентского OTP.
  Future<Either<Failure, UserEntity>> createNewUser(CreateNewUserParams params);

  /// `POST /auth/request-otp` — публичный endpoint.
  Future<Either<Failure, Unit>> requestEmailOtp(RequestEmailOtpParams params);

  /// `verify-otp` + `GET /users/me` — после этого в prefs лежат app JWT.
  Future<Either<Failure, UserEntity>> verifyEmailOtpAndFetchProfile(
    VerifyEmailOtpParams params,
  );

  Future<Either<Failure, UserEntity>> loginViaApple();
}
