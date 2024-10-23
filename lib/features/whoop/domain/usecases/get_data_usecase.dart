import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class WhoopGetDataUsecase implements UseCase<WhoopDataEntity, GetDataParams> {
  final WhoopRepository whoopRepository;

  const WhoopGetDataUsecase(this.whoopRepository);

  @override
  Future<Either<Failure, WhoopDataEntity>> call(GetDataParams params) async {
    return whoopRepository.getData(params: params);
  }
}

class GetDataParams {
  final Gender gender;
  final UserGoal goal;
  final String userId;
  GetDataParams({
    required this.gender,
    required this.goal,
    required this.userId,
  });
}
