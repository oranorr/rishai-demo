// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class ChangeModificatorOrSexUsecase
    implements UseCase<MacrosBreakdown, ChangeModificatorOrSexParams> {
  final WhoopRepository whoopRepository;
  const ChangeModificatorOrSexUsecase(this.whoopRepository);

  @override
  Future<Either<Failure, MacrosBreakdown>> call(
    ChangeModificatorOrSexParams params,
  ) async {
    return whoopRepository.changeModificatorOfSex(params: params);
  }
}

class ChangeModificatorOrSexParams {
  final double modificator;
  final Gender gender;
  final int weekTdeeAverage;
  final String userId;
  final int lastTdee;
  ChangeModificatorOrSexParams({
    required this.modificator,
    required this.gender,
    required this.weekTdeeAverage,
    required this.userId,
    required this.lastTdee,
  });
}
