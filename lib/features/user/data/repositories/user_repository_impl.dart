import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/user/data/data_sources/local/user_local_source.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

import '../../domain/repositories/user_repository.dart';

@Singleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> updateUser({required UserEntity user}) async {
    try {
      final remoteRes = await remoteDataSource.updateUser(user: user);
      final localRes = await localDataSource.updateUser(user: user);
      if (remoteRes && localRes) {
        return const Right(null);
      } else {
        return const Left(FailedUpdateUser(''));
      }
    } on Exception catch (error) {
      return Left(FailedUpdateUser(error.toString()));
    }
  }
}
