# HomePageControllerService

## 📝 Описание

Микросервис для централизованного управления контроллерами главной страницы приложения (HomePage). Предоставляет возможность программно управлять скроллингом и другими функциями HomePage из любого места приложения.

## 🎯 Назначение

- **Централизованное управление**: Единая точка доступа к контроллерам HomePage
- **Управление скроллингом**: Программная прокрутка списка с анимацией
- **Гибкость**: Вызов из любого места - виджеты, блоки, репозитории, use cases
- **Безопасность**: Проверка доступности контроллера перед использованием

## 🏗️ Архитектура

Сервис следует паттерну Clean Architecture и состоит из:

1. **Интерфейс** (`home_page_controller_service.dart`) - абстрактный класс с контрактом
2. **Реализация** (`home_page_controller_service_impl.dart`) - конкретная реализация
3. **DI регистрация** - автоматическая регистрация через `@Singleton` от `injectable`

## 📦 Структура файлов

```
lib/core/services/home_page_controller/
├── home_page_controller_service.dart          # Интерфейс
├── home_page_controller_service_impl.dart     # Реализация
├── README.md                                  # Документация
└── USAGE_EXAMPLE.md                          # Примеры использования
```

## 🚀 Быстрый старт

### Импорт

```dart
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';
```

### Базовое использование

```dart
// Прокрутка вниз до конца
await homePageControllerService.scrollToBottom();

// Прокрутка на определенное расстояние
await homePageControllerService.scrollDown(delta: 200.0);

// Прокрутка к конкретной позиции
await homePageControllerService.scrollToOffset(offset: 500.0);
```

## 📚 API

### Методы управления контроллером

| Метод | Описание |
|-------|----------|
| `registerScrollController(controller)` | Регистрирует ScrollController (вызывается автоматически) |
| `unregisterScrollController()` | Отменяет регистрацию (вызывается автоматически) |
| `hasScrollController` | Проверяет, зарегистрирован ли контроллер |

### Методы скроллинга

| Метод | Параметры | Возвращает | Описание |
|-------|-----------|------------|----------|
| `scrollToBottom()` | `duration`, `curve` | `Future<bool>` | Прокрутка до конца списка |
| `scrollToOffset()` | `offset`, `duration`, `curve` | `Future<bool>` | Прокрутка к позиции |
| `scrollDown()` | `delta`, `duration`, `curve` | `Future<bool>` | Прокрутка вниз на delta px |

### Параметры по умолчанию

- **duration**: `Duration(milliseconds: 300)`
- **curve**: `Curves.easeInOut`
- **delta**: `100.0` пикселей

## 💡 Примеры использования

### Из виджета

```dart
ElevatedButton(
  onPressed: () async {
    final success = await homePageControllerService.scrollToBottom(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
    if (success) {
      print('Прокрутка выполнена');
    }
  },
  child: Text('Прокрутить вниз'),
)
```

### Из Bloc

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  on<ScrollEvent>((event, emit) async {
    await homePageControllerService.scrollDown(delta: 150.0);
  });
}
```

### С проверкой доступности

```dart
if (homePageControllerService.hasScrollController) {
  await homePageControllerService.scrollToBottom();
} else {
  print('Контроллер еще не готов');
}
```

## 🔄 Жизненный цикл

1. **Инициализация**: ScrollController создается в `_HomePageBodyState.initState()`
2. **Регистрация**: Автоматически регистрируется в сервисе
3. **Использование**: Доступен из любого места приложения через `homePageControllerService`
4. **Очистка**: Автоматически отменяется в `_HomePageBodyState.dispose()`

## ⚠️ Важные замечания

1. **Проверяйте доступность**: Используйте `hasScrollController` перед вызовом методов
2. **Возвращаемые значения**: `true` = успех, `false` = ошибка/недоступен
3. **Логирование**: Все действия логируются с префиксом `[HomePageControllerService]`
4. **UI Thread**: ScrollController должен использоваться только в UI потоке

## 🔧 Техническая информация

### Зависимости

- `injectable` - для DI регистрации
- `get_it` - для доступа к синглтону
- Flutter Material - для ScrollController

### Регистрация в DI

```dart
@Singleton(as: HomePageControllerService)
class HomePageControllerServiceImpl implements HomePageControllerService {
  // ...
}

// Глобальный экземпляр
final homePageControllerService = getIt.get<HomePageControllerService>();
```

## 📖 Дополнительная документация

Смотрите [USAGE_EXAMPLE.md](./USAGE_EXAMPLE.md) для детальных примеров использования во всех возможных сценариях.

## 🧪 Тестирование

Сервис готов к unit-тестированию благодаря интерфейсу `HomePageControllerService`. Можно легко создать mock для тестов:

```dart
class MockHomePageControllerService extends Mock 
    implements HomePageControllerService {}
```

## 🎨 Apple Human Interface Guidelines

Все анимации прокрутки следуют принципам Apple HIG:
- Плавные естественные кривые анимации (easeInOut)
- Адекватная продолжительность (300ms по умолчанию)
- Предсказуемое поведение

## 🚀 Расширение функциональности

В будущем можно добавить:
- Управление PageController для переключения страниц
- Управление другими контроллерами (TabController, AnimationController)
- События и слушатели для отслеживания состояния скролла
- Сохранение позиции скролла между сессиями

---

**Автор**: Rish AI Team  
**Версия**: 1.0.0  
**Дата создания**: 2025-10-28

