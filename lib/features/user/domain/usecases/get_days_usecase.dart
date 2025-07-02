// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

// === НОВАЯ УПРОЩЕННАЯ АРХИТЕКТУРА ===

@injectable
class GetUserDaysUsecase
    implements UseCase<List<DayEntity>, GetUserDaysParams> {
  final UserRepository userRepository;
  const GetUserDaysUsecase(this.userRepository);

  @override
  Future<Either<Failure, List<DayEntity>>> call(
    GetUserDaysParams params,
  ) async {
    try {
      final days = await userRepository.getUserDays(userId: params.userId);
      return days.fold(
        (failure) => Left(failure),
        (days) => Right(days),
      );
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }
}

// === ПАРАМЕТРЫ ===

class GetUserDaysParams {
  final String userId;
  GetUserDaysParams({
    required this.userId,
  });
}
