import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AdaptyErrorHandler {
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        // Добавляем контекст
        if (context != null) {
          scope.setTag('error_context', context);
        }

        // Добавляем дополнительные данные
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }

        // Определяем тип ошибки и добавляем соответствующие теги
        if (error is AdaptyError) {
          scope
            ..setTag('error_type', 'adapty_error')
            ..setTag('adapty_message', error.message)
            ..setExtra('adapty_details', error.toString());
        } else {
          scope.setTag('error_type', 'adapty_other');
        }

        scope.level = SentryLevel.error;
      },
    );
  }
}
