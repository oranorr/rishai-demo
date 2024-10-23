// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';

@injectable
class InitGptUsecase implements UseCase<void, InitGptParams> {
  final ChatRepository chatRepository;
  InitGptUsecase(this.chatRepository);
  @override
  Future<Either<Failure, void>> call(InitGptParams params) async {
    return chatRepository.initGpt(params.threadId);
  }
}

class InitGptParams {
  final String? threadId;
  InitGptParams({
    this.threadId,
  });
}
