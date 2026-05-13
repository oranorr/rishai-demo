import 'dart:developer';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/settings/domain/models/feedback_model.dart';
import 'package:rishai/features/settings/domain/repository/feedback_repository.dart';

/// Реализация репозитория обратной связи через Pivot User API ([POST /feedback]).
final feedbackRepository = getIt.get<FeedbackRepository>();

@Singleton(as: FeedbackRepository)
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._userServiceClient);
  final UserServiceClient _userServiceClient;

  @override
  Future<void> sendFeedback(FeedbackModel feedback) async {
    // Только JSON без вложений; ответ бэка: `{ "id": "..." }`.
    final id = await _userServiceClient.submitFeedbackPublic(feedback.toJson());
    log(
      '[FeedbackRepositoryImpl.sendFeedback] Создана запись feedback id=$id',
      name: 'FeedbackRepositoryImpl',
    );
  }

  @override
  Future<String> uploadFile(File file) async {
    // Вложения через API пока не поддерживаются; сохраняем сигнатуру для совместимости.
    log(
      '[FeedbackRepositoryImpl.uploadFile] Игнорируется: файлы feedback не обрабатываются бэкендом',
      name: 'FeedbackRepositoryImpl',
    );
    return '';
  }

  @override
  Future<void> linkFilesToFeedback({
    required String feedbackId,
    required List<String> fileIds,
  }) async {
    log(
      '[FeedbackRepositoryImpl.linkFilesToFeedback] No-op: связи feedback↔files отключены',
      name: 'FeedbackRepositoryImpl',
    );
  }
}
