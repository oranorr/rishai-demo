import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@injectable
class LoginViaAppleUsecase implements UseCase<UserEntity, NoParams> {
  final LoginRepository _loginRepository;

  const LoginViaAppleUsecase(this._loginRepository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return _loginRepository.loginViaApple();
  }
}
