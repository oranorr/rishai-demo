// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/whoop/domain/repository/whoop_repository.dart';

@injectable
class DisconnectWhoopUsecase implements UseCase<void, DisconnecWhoopParams> {
  final WhoopRepository whoopRepository;
  DisconnectWhoopUsecase(this.whoopRepository);

  @override
  Future<Either<Failure, void>> call(DisconnecWhoopParams params) {
    return whoopRepository.disconnectWhoop(params: params);
  }
}

class DisconnecWhoopParams {
  final String userId;
  DisconnecWhoopParams({
    required this.userId,
  });
}
