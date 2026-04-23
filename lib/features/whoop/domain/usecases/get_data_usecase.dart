import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class WhoopGetDataUsecase implements UseCase<DayEntity, GetDataParams> {
  const WhoopGetDataUsecase(this.whoopRepository);
  final WhoopRepository whoopRepository;

  @override
  Future<Either<Failure, DayEntity>> call(GetDataParams params) async {
    return whoopRepository.getData(params: params);
  }
}

class GetDataParams {
  GetDataParams({
    required this.gender,
    required this.goal,
    required this.userId,
    this.forceRefresh = false,
  });
  final Gender gender;
  final UserGoal goal;
  final String userId;
  final bool forceRefresh;
}
