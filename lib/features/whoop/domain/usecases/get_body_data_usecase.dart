import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class WhoopGetBodyData implements UseCase<BodyMeasurementsEntity, NoParams> {
  final WhoopRepository whoopRepository;
  const WhoopGetBodyData(this.whoopRepository);

  @override
  Future<Either<Failure, BodyMeasurementsEntity>> call(NoParams params) {
    return whoopRepository.getBodyData();
  }
}
