import 'dart:io';

import 'package:rishai/features/settings/domain/models/feedback_model.dart';

/// Репозиторий для работы с обратной связью
abstract interface class FeedbackRepository {
  /// Отправляет обратную связь в Directus
  Future<void> sendFeedback(FeedbackModel feedback);

  /// Загружает файл в Directus и возвращает ID файла
  Future<String> uploadFile(File file);

  /// Связывает файлы с обратной связью
  Future<void> linkFilesToFeedback({
    required String feedbackId,
    required List<String> fileIds,
  });
}
