import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

abstract class DayManager {
  Future<Either<Failure, List<DayEntity>>> fetchDays({
    required List<int> daysIds,
  });
  Future<DayEntity> createDay({
    required DayEntity day,
  });

  Future<List<int>> getDaysIds({required String userId});
}
