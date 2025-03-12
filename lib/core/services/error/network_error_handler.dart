import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class NetworkErrorHandler {
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    // Отправляем ошибку в Sentry
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
        if (error is DioException) {
          scope.setTag('error_type', 'network_dio');
          scope.setTag('status_code',
              error.response?.statusCode?.toString() ?? 'unknown');
          scope.setTag('method', error.requestOptions.method);
          scope.setTag('path', error.requestOptions.path);

          // Добавляем детали запроса
          scope.setExtra('request_headers', error.requestOptions.headers);
          scope.setExtra('request_data', error.requestOptions.data);

          // Добавляем детали ответа, если есть
          if (error.response != null) {
            scope.setExtra('response_data', error.response?.data);
            scope.setExtra('response_headers', error.response?.headers.map);
          }
        } else if (error is SocketException) {
          scope.setTag('error_type', 'network_socket');
          scope.setTag('port', error.port?.toString() ?? 'unknown');
          scope.setTag('address', error.address?.toString() ?? 'unknown');
        } else if (error is HttpException) {
          scope.setTag('error_type', 'network_http');
        } else {
          scope.setTag('error_type', 'network_other');
        }

        scope.level = SentryLevel.error;
      },
    );
  }
}
