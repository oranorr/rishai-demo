// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@injectable
class ManageDayUsecase implements UseCase<void, ManageDayParams> {
  final UserRepository userRepository;
  const ManageDayUsecase(this.userRepository);

  @override
  Future<Either<Failure, void>> call(ManageDayParams params) {
    return userRepository.manageDay(params: params);
  }
}

class ManageDayParams {
  final String userId;
  final Map<String, dynamic> dayMap;
  final DayEntity incomingDay;
  ManageDayParams({
    required this.userId,
    required this.dayMap,
    required this.incomingDay,
  });
}
