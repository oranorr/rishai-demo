import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class ConnectWhoopUsecase implements UseCase<void, NoParams> {
  const ConnectWhoopUsecase(this.whoopRepository);
  final WhoopRepository whoopRepository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return whoopRepository.authenticateUser();
  }
}
