import 'dart:developer';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hive/hive.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';

/// Обработчик ошибок локального хранилища данных
class LocalStorageErrorHandler {
  /// Обрабатывает ошибки локального хранилища
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    required String context,
    required String operation,
    required String storageType,
    Map<String, dynamic>? extras,
  }) async {
    log(
      'Ошибка локального хранилища: $error\n'
      'Контекст: $context, Операция: $operation, Тип хранилища: $storageType\n'
      'Дополнительная информация: ${extras ?? 'нет'}\n'
      'Стек: $stackTrace',
    );

    // Проверяем, является ли ошибка критической, требующей сброса хранилища
    if (_isFatalStorageError(error)) {
      log('Обнаружена критическая ошибка хранилища, выполняется сброс');
      try {
        // Вызываем метод сброса хранилища
        await hive.resetStorageOnFatalError();
      } catch (e) {
        log('Ошибка при попытке сбросить хранилище: $e');
      }
    }

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_context', context);

        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }

        scope.setTag('storage_operation', operation);

        scope.setTag('storage_type', storageType);

        scope
          ..setTag('service', 'local_storage')
          ..level = SentryLevel.error;
      },
    );
  }

  /// Определяет, является ли ошибка критической, требующей сброса хранилища
  static bool _isFatalStorageError(Object error) {
    // Типичные критические ошибки Hive связанные с обновлением приложения:
    // 1. Ошибки схемы данных (HiveError)
    // 2. Ошибки десериализации (типично при изменении структуры классов)
    // 3. Ошибки формата (старый формат хранилища)

    if (error is HiveError) {
      final errorMessage = error.toString().toLowerCase();

      // Проверяем типичные критические ошибки Hive
      return errorMessage.contains('corrupted') ||
          errorMessage.contains('incompatible') ||
          errorMessage.contains('not found in the registry') ||
          errorMessage.contains('could not read') ||
          errorMessage.contains('type conflict') ||
          errorMessage.contains('wrong signature') ||
          errorMessage.contains('unexpected value');
    }

    // Проверяем ошибки десериализации
    if (error is TypeError ||
        error is FormatException ||
        error is ArgumentError) {
      return true;
    }

    return false;
  }
}
