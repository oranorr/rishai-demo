import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryTestWidget extends StatelessWidget {
  const SentryTestWidget({super.key});

  Future<void> _testSentry() async {
    try {
      // Генерируем тестовую ошибку
      throw Exception('Это тестовая ошибка для проверки Sentry');
    } catch (exception, stackTrace) {
      // Отправляем ошибку в Sentry
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('test_tag', 'test_value');
          scope.setExtra('test_extra', 'Дополнительная информация');
        },
      );

      // Показываем сообщение пользователю
      if (exception is Exception) {
        debugPrint('🔴 Ошибка отправлена в Sentry: $exception');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      centerTitle: true,
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: const Text(
        'Sentry Test',
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testSentry,
              child: Text(
                'Тест Sentry',
                style: context.styles.boldMedium.copyWith(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
