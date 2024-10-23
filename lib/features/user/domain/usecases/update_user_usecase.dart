import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';

@injectable
class UpdateUserUsecase implements UseCase<void, UserEntity> {
  final UserRepository userRepository;

  const UpdateUserUsecase(this.userRepository);

  @override
  Future<Either<Failure, void>> call(UserEntity params) async {
    return userRepository.updateUser(user: params);
  }
}
