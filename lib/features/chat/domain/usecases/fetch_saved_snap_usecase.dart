import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';

@injectable
class FetchSavedSnapUsecase
    implements UseCase<ChatSnapshotEntity?, FetchSavedSnapParams> {
  const FetchSavedSnapUsecase(this.chatRepository);
  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, ChatSnapshotEntity?>> call(
    FetchSavedSnapParams params,
  ) async {
    return chatRepository.fetchSavedSnap(directusId: params.directusId);
  }
}

class FetchSavedSnapParams {
  FetchSavedSnapParams({
    required this.directusId,
  });
  final String directusId;
}
