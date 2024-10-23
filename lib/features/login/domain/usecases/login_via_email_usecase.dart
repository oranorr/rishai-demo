// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/login/domain/entities/login_info_entity.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@injectable
class LoginViaEmailUsecase implements UseCase<UserEntity, LoginViaEmailParams> {
  final LoginRepository _loginRepository;

  const LoginViaEmailUsecase(this._loginRepository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginViaEmailParams params) async {
    return _loginRepository.loginViaEmail(params);
  }
}

class LoginViaEmailParams extends Equatable {
  final LoginInfoEntity loginInfoEntity;
  const LoginViaEmailParams({
    required this.loginInfoEntity,
  });

  @override
  List<Object> get props => [loginInfoEntity];
}
