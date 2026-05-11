// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/login/domain/params/email_otp_params.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';

@injectable
class RequestEmailOtpUsecase implements UseCase<Unit, RequestEmailOtpParams> {
  const RequestEmailOtpUsecase(this._loginRepository);

  final LoginRepository _loginRepository;

  @override
  Future<Either<Failure, Unit>> call(RequestEmailOtpParams params) {
    return _loginRepository.requestEmailOtp(params);
  }
}
