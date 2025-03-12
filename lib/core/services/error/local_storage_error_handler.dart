import 'package:sentry_flutter/sentry_flutter.dart';

class LocalStorageErrorHandler {
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
    String? operation,
    String? storageType,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          scope.setTag('error_context', context);
        }

        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }

        if (operation != null) {
          scope.setTag('storage_operation', operation);
        }

        if (storageType != null) {
          scope.setTag('storage_type', storageType);
        }

        scope
          ..setTag('service', 'local_storage')
          ..level = SentryLevel.error;
      },
    );
  }
}
