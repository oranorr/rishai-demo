// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/login/domain/repositories/login_repository.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@injectable
class CreateNewUserUsecase implements UseCase<UserEntity, CreateNewUserParams> {
  final LoginRepository _loginRepository;

  const CreateNewUserUsecase(this._loginRepository);

  @override
  Future<Either<Failure, UserEntity>> call(CreateNewUserParams params) async {
    return _loginRepository.createNewUser(params);
  }
}

class CreateNewUserParams extends Equatable {
  const CreateNewUserParams({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  List<Object> get props => [name, email];
}
