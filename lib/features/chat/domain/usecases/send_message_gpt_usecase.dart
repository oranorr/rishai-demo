// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';

@injectable
class SendMessageGptUsecase implements UseCase<String, String> {
  final ChatRepository chatRepository;
  SendMessageGptUsecase(this.chatRepository);
  @override
  Future<Either<Failure, String>> call(String userMessage) {
    return chatRepository.sendMessage(userMessage);
  }
}
