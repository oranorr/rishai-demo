import 'dart:io';

import 'package:rishai/features/settings/domain/models/feedback_model.dart';

/// Репозиторий обратной связи (Pivot Backend, без прямого Directus).
abstract interface class FeedbackRepository {
  /// Отправляет обратную связь на сервер.
  Future<void> sendFeedback(FeedbackModel feedback);

  /// Заглушка: вложения не загружаются (см. текущий контракт API без файлов).
  Future<String> uploadFile(File file);

  /// Связывает файлы с обратной связью
  Future<void> linkFilesToFeedback({
    required String feedbackId,
    required List<String> fileIds,
  });
}
