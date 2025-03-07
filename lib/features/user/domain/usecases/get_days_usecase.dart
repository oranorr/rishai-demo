// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@injectable
class GetDaysUsecase implements UseCase<List<DayEntity>, GetDaysParams> {
  final UserRepository userRepository;
  const GetDaysUsecase(this.userRepository);

  @override
  Future<Either<Failure, List<DayEntity>>> call(params) async {
    try {
      final days = await userRepository.getDaysWithMealPlans(params.daysIds);
      return days.fold(
        (failure) => Left(failure),
        (days) => Right(days),
      );
      // return Right(days);
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }
}

class GetDaysParams {
  final List<int> daysIds;
  final String userId;
  GetDaysParams({
    required this.daysIds,
    required this.userId,
  });
}
