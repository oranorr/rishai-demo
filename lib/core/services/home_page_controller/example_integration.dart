// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';

/// [ExampleIntegration]
/// Примеры интеграции HomePageControllerService в различные части приложения
///
/// ВАЖНО: Этот файл содержит только примеры и не должен использоваться в production коде.
/// Используйте эти примеры как референс для интеграции в ваш код.

// ============================================================================
// ПРИМЕР 1: Использование в простом виджете
// ============================================================================

class _ExampleButtonWidget extends StatelessWidget {
  const _ExampleButtonWidget();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Простая прокрутка вниз до конца
        final success = await homePageControllerService.scrollToBottom();

        if (success) {
          // Показываем snackbar об успехе
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Прокрутка выполнена!')),
          );
        } else {
          // Обрабатываем ошибку
          print('Не удалось выполнить прокрутку');
        }
      },
      child: const Text('Прокрутить главную страницу'),
    );
  }
}

// ============================================================================
// ПРИМЕР 2: Использование с кастомной анимацией
// ============================================================================

class _ExampleCustomAnimationWidget extends StatelessWidget {
  const _ExampleCustomAnimationWidget();

  Future<void> _scrollWithCustomAnimation() async {
    // Прокрутка с более медленной и плавной анимацией
    await homePageControllerService.scrollToBottom(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _scrollWithBounce() async {
    // Прокрутка с эффектом bounce
    await homePageControllerService.scrollDown(
      delta: 200,
      duration: const Duration(milliseconds: 600),
      curve: Curves.bounceOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _scrollWithCustomAnimation,
          child: const Text('Медленная анимация'),
        ),
        ElevatedButton(
          onPressed: _scrollWithBounce,
          child: const Text('Bounce анимация'),
        ),
      ],
    );
  }
}

// ============================================================================
// ПРИМЕР 3: Использование с проверкой доступности
// ============================================================================

class _ExampleSafeScrollWidget extends StatelessWidget {
  const _ExampleSafeScrollWidget();

  Future<void> _safeScroll() async {
    // Всегда проверяем доступность контроллера перед использованием
    if (!homePageControllerService.hasScrollController) {
      print('ScrollController еще не зарегистрирован');
      print('Убедитесь, что HomePage уже инициализирована');
      return;
    }

    // Выполняем прокрутку
    final success = await homePageControllerService.scrollToBottom();

    if (!success) {
      print('Прокрутка не выполнена');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _safeScroll,
      child: const Text('Безопасная прокрутка'),
    );
  }
}

// ============================================================================
// ПРИМЕР 4: Использование в последовательности действий
// ============================================================================

class _ExampleSequentialActionsWidget extends StatelessWidget {
  const _ExampleSequentialActionsWidget();

  Future<void> _performSequentialActions() async {
    // Шаг 1: Прокрутка к началу meal plan секции
    await homePageControllerService.scrollToOffset(
      offset: 400,
      duration: const Duration(milliseconds: 300),
    );

    // Шаг 2: Подождать немного
    await Future.delayed(const Duration(milliseconds: 500));

    // Шаг 3: Прокрутить еще немного вниз
    await homePageControllerService.scrollDown(
      delta: 100,
      duration: const Duration(milliseconds: 200),
    );

    // Шаг 4: Финальная прокрутка до конца
    await Future.delayed(const Duration(milliseconds: 500));
    await homePageControllerService.scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _performSequentialActions,
      child: const Text('Последовательная прокрутка'),
    );
  }
}

// ============================================================================
// ПРИМЕР 5: Использование в Floating Action Button Overlay
// ============================================================================

class _ExampleFABIntegration extends StatelessWidget {
  const _ExampleFABIntegration();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        // После выполнения основного действия (например, добавление meal)
        // прокручиваем страницу к этому элементу

        // Выполняем основное действие
        print('Meal добавлен в дневник');

        // Прокручиваем к food diary секции
        await homePageControllerService.scrollToOffset(
          offset: 600, // Примерная позиция food diary
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // Показываем уведомление
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal добавлен!')),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

// ============================================================================
// ПРИМЕР 6: Интеграция в бизнес-логику (UseCase)
// ============================================================================

class _ExampleUseCase {
  /// Пример use case, который после выполнения действия
  /// прокручивает главную страницу для показа результата
  Future<void> createMealPlanAndShowIt() async {
    try {
      // 1. Создаем meal plan
      print('Создание meal plan...');
      await Future.delayed(const Duration(seconds: 2)); // Имитация API call

      // 2. Проверяем доступность контроллера
      if (!homePageControllerService.hasScrollController) {
        print('Warning: ScrollController недоступен');
        return;
      }

      // 3. Прокручиваем к meal plan секции
      final scrollSuccess = await homePageControllerService.scrollToOffset(
        offset: 500, // Позиция meal plan секции
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      if (scrollSuccess) {
        print('✅ Страница прокручена к новому meal plan');
      } else {
        print('⚠️ Не удалось прокрутить страницу');
      }
    } catch (e) {
      print('❌ Ошибка при создании meal plan: $e');
    }
  }

  /// Пример use case для навигации к определенной секции
  Future<void> navigateToSection(String sectionName) async {
    final offsetMap = {
      'calendar': 0.0,
      'pivot_life': 100.0,
      'wellness': 200.0,
      'health_metrics': 400.0,
      'macros': 600.0,
      'meal_plan': 800.0,
    };

    final offset = offsetMap[sectionName] ?? 0.0;

    await homePageControllerService.scrollToOffset(
      offset: offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

// ============================================================================
// ПРИМЕР 7: Интеграция с gesture распознаванием
// ============================================================================

class _ExampleGestureWidget extends StatelessWidget {
  const _ExampleGestureWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Свайп вниз - прокручиваем главную страницу вниз
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          // Свайп вниз
          homePageControllerService.scrollDown(
            delta: 150,
            duration: const Duration(milliseconds: 400),
          );
        }
      },

      // Двойной тап - прокрутка до конца
      onDoubleTap: () {
        homePageControllerService.scrollToBottom(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Text('Свайпните или сделайте двойной тап'),
      ),
    );
  }
}

// ============================================================================
// ПРИМЕР 8: Использование в debug инструментах
// ============================================================================

class _ExampleDebugPanel extends StatelessWidget {
  const _ExampleDebugPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Debug: HomePage Scroll Control',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Статус контроллера
          Text(
            'Controller Status: ${homePageControllerService.hasScrollController ? "✅ Active" : "❌ Inactive"}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),

          // Кнопки управления
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    homePageControllerService.scrollToOffset(offset: 0),
                child: const Text('Top'),
              ),
              ElevatedButton(
                onPressed: () =>
                    homePageControllerService.scrollDown(delta: 100),
                child: const Text('Down 100'),
              ),
              ElevatedButton(
                onPressed: () =>
                    homePageControllerService.scrollDown(delta: 300),
                child: const Text('Down 300'),
              ),
              ElevatedButton(
                onPressed: () => homePageControllerService.scrollToBottom(),
                child: const Text('Bottom'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ПРИМЕР 9: Использование с условной логикой
// ============================================================================

class _ExampleConditionalScrollWidget extends StatelessWidget {
  const _ExampleConditionalScrollWidget();

  Future<void> _scrollBasedOnCondition(BuildContext context) async {
    if (!homePageControllerService.hasScrollController) {
      return;
    }

    // Пример: получаем состояние из state/bloc
    // В реальном приложении это будет из BlocBuilder или другого источника
    final hasNewMealPlan = _checkHasNewMealPlan(); // Пример функции проверки

    if (hasNewMealPlan) {
      // Есть новый meal plan - прокручиваем к нему
      await homePageControllerService.scrollToOffset(
        offset: 800,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Новый meal plan готов!')),
        );
      }
    } else {
      // По умолчанию - прокручиваем к wellness секции
      await homePageControllerService.scrollToOffset(
        offset: 200,
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  // Пример вспомогательной функции для проверки условия
  bool _checkHasNewMealPlan() {
    // В реальном приложении здесь будет проверка state
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _scrollBasedOnCondition(context),
      child: const Text('Smart Scroll'),
    );
  }
}

// ============================================================================
// ПРИМЕР 10: Использование с error handling
// ============================================================================

class _ExampleErrorHandlingWidget extends StatelessWidget {
  const _ExampleErrorHandlingWidget();

  Future<void> _scrollWithErrorHandling(BuildContext context) async {
    try {
      // Проверка 1: Доступность контроллера
      if (!homePageControllerService.hasScrollController) {
        throw Exception('ScrollController не инициализирован');
      }

      // Попытка прокрутки
      final success = await homePageControllerService.scrollToBottom(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Проверка 2: Успешность выполнения
      if (!success) {
        throw Exception('Прокрутка не выполнена');
      }

      // Успех
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Прокрутка выполнена успешно'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Обработка ошибок
      print('Ошибка при прокрутке: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _scrollWithErrorHandling(context),
      child: const Text('Scroll with Error Handling'),
    );
  }
}
