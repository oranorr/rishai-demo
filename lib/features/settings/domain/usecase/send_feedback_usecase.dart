import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/settings/domain/models/feedback_model.dart';
import 'package:rishai/features/settings/domain/repository/feedback_repository.dart';

/// Параметры для отправки обратной связи
class SendFeedbackParams {
  SendFeedbackParams({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.attachments,
    required this.userId,
  });
  final String name;
  final String email;
  final String subject;
  final String message;
  final List<File> attachments;
  final String? userId;
}

@injectable
class SendFeedbackUseCase implements UseCase<void, SendFeedbackParams> {
  SendFeedbackUseCase(this._feedbackRepository);
  final FeedbackRepository _feedbackRepository;

  @override
  Future<Either<Failure, void>> call(SendFeedbackParams params) async {
    try {
      if (params.attachments.isNotEmpty) {
        log(
          '[SendFeedbackUseCase.call] Вложения не отправляются: контракт API только JSON без файлов',
          name: 'SendFeedbackUseCase',
        );
      }

      final feedback = FeedbackModel.fromForm(
        name: params.name,
        email: params.email,
        subject: params.subject,
        message: params.message,
        attachments: const [],
        userId: params.userId,
      );

      await _feedbackRepository.sendFeedback(feedback);

      return const Right(null);
    } catch (e, stackTrace) {
      log(
        '[SendFeedbackUseCase.call] Ошибка: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'SendFeedbackUseCase',
      );
      return const Left(FailureDirectus());
    }
  }
}
