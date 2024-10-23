// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';

@injectable
class FetchSavedSnapUsecase
    implements UseCase<ChatSnapshotEntity?, FetchSavedSnapParams> {
  final ChatRepository chatRepository;

  const FetchSavedSnapUsecase(this.chatRepository);

  @override
  Future<Either<Failure, ChatSnapshotEntity?>> call(
      FetchSavedSnapParams params) async {
    return chatRepository.fetchSavedSnap(directusId: params.directusId);
  }
}

class FetchSavedSnapParams {
  final String directusId;
  FetchSavedSnapParams({
    required this.directusId,
  });
}
