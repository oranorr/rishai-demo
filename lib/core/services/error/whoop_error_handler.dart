import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

class WhoopErrorHandler {
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
    http.Response? response,
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

        // Добавляем информацию о HTTP ответе, если есть
        if (response != null) {
          scope.setTag('status_code', response.statusCode.toString());
          scope.setExtra('response_headers', response.headers);

          try {
            // Пытаемся распарсить тело ответа как JSON
            final responseBody = jsonDecode(response.body);
            scope.setExtra('response_body', responseBody);
          } catch (e) {
            // Если не получилось распарсить как JSON, добавляем как есть
            scope.setExtra('response_body', response.body);
          }
        }

        // Определяем тип ошибки
        if (error is http.ClientException) {
          scope.setTag('error_type', 'whoop_http_client');
          scope.setTag('error_message', error.message);
        } else if (error is FormatException) {
          scope.setTag('error_type', 'whoop_format');
          scope.setTag('error_message', error.message);
        } else if (error is Exception) {
          scope.setTag('error_type', 'whoop_exception');
          scope.setTag('error_message', error.toString());
        } else {
          scope.setTag('error_type', 'whoop_other');
        }

        scope.setTag('service', 'whoop');
        scope.level = SentryLevel.error;
      },
    );
  }
}
