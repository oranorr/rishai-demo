# HomePageControllerService - Примеры использования

## Описание
Сервис для управления контроллерами HomePage извне. Позволяет программно управлять скроллингом домашней страницы из любого места приложения.

## Установка и регистрация

Сервис автоматически регистрируется в DI контейнере через `@Singleton` и доступен через глобальный экземпляр:

```dart
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';

// Доступ к сервису
homePageControllerService.scrollToBottom();
```

## Примеры использования

### 1. Прокрутка вниз до конца страницы

```dart
// Простой вызов с параметрами по умолчанию
final success = await homePageControllerService.scrollToBottom();
if (success) {
  print('Прокрутка выполнена успешно');
}

// С кастомной анимацией
await homePageControllerService.scrollToBottom(
  duration: Duration(milliseconds: 500),
  curve: Curves.easeOut,
);
```

### 2. Прокрутка к определенной позиции

```dart
// Прокрутка к конкретному смещению
await homePageControllerService.scrollToOffset(
  offset: 300.0, // 300 пикселей от верха
  duration: Duration(milliseconds: 400),
  curve: Curves.easeInOut,
);
```

### 3. Прокрутка вниз на определенное количество пикселей

```dart
// Прокрутка на 100px вниз (по умолчанию)
await homePageControllerService.scrollDown();

// Кастомная прокрутка на 200px
await homePageControllerService.scrollDown(
  delta: 200.0,
  duration: Duration(milliseconds: 300),
  curve: Curves.bounceOut,
);
```

### 4. Проверка доступности контроллера

```dart
if (homePageControllerService.hasScrollController) {
  await homePageControllerService.scrollToBottom();
} else {
  print('ScrollController еще не зарегистрирован');
}
```

## Использование в разных сценариях

### Из любого виджета

```dart
class MyCustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Прокручиваем домашнюю страницу вниз
        await homePageControllerService.scrollToBottom(
          duration: Duration(milliseconds: 600),
        );
      },
      child: Text('Прокрутить главную страницу вниз'),
    );
  }
}
```

### Из Bloc/Cubit

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyInitial()) {
    on<ScrollHomePageEvent>((event, emit) async {
      // Прокручиваем домашнюю страницу
      final success = await homePageControllerService.scrollToBottom();
      
      if (success) {
        emit(ScrollSuccessState());
      } else {
        emit(ScrollFailureState());
      }
    });
  }
}
```

### Из Repository или UseCase

```dart
class MyUseCase {
  Future<void> performActionAndScroll() async {
    // Выполняем какое-то действие
    await someAction();
    
    // Прокручиваем страницу для отображения результата
    await homePageControllerService.scrollDown(delta: 150.0);
  }
}
```

### С обработкой ошибок

```dart
Future<void> safeScrollToBottom() async {
  try {
    if (!homePageControllerService.hasScrollController) {
      print('Контроллер еще не готов');
      return;
    }
    
    final success = await homePageControllerService.scrollToBottom(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    
    if (!success) {
      print('Не удалось выполнить прокрутку');
    }
  } catch (e) {
    print('Ошибка при прокрутке: $e');
  }
}
```

## Важные замечания

1. **Жизненный цикл**: ScrollController регистрируется при создании HomePage и отменяется при его уничтожении.

2. **Проверка доступности**: Всегда проверяйте `hasScrollController` перед вызовом методов прокрутки, если не уверены, что HomePage уже инициализирована.

3. **Возвращаемые значения**: Все методы прокрутки возвращают `Future<bool>`:
   - `true` - прокрутка выполнена успешно
   - `false` - контроллер недоступен или произошла ошибка

4. **Потокобезопасность**: Методы безопасны для вызова из разных потоков, но сам ScrollController должен использоваться только в UI потоке.

5. **Логирование**: Все действия логируются в консоль с префиксом `[HomePageControllerService]` для отладки.

## API Reference

### Методы

- `registerScrollController(ScrollController controller)` - регистрирует контроллер (вызывается автоматически)
- `unregisterScrollController()` - отменяет регистрацию (вызывается автоматически)
- `hasScrollController` (getter) - проверяет наличие активного контроллера
- `scrollToBottom({Duration? duration, Curve? curve})` - прокрутка до конца
- `scrollToOffset({required double offset, Duration? duration, Curve? curve})` - прокрутка к позиции
- `scrollDown({double? delta, Duration? duration, Curve? curve})` - прокрутка вниз на delta пикселей

### Параметры по умолчанию

- `duration`: 300 миллисекунд
- `curve`: Curves.easeInOut
- `delta` (для scrollDown): 100.0 пикселей

