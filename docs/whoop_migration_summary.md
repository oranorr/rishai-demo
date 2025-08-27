# WHOOP API Migration - Краткое резюме

## Что реализовано ✅

### 1. Конфигурация версий API
- **Файл**: `lib/features/whoop/core/config/whoop_api_config.dart`
- **Функционал**: Централизованное управление версиями API
- **Возможности**: Легкое переключение между v1 и v2, поддержка mock сервера

### 2. Обновленные эндпоинты
- **Файл**: `lib/features/whoop/data/data_sources/remote/endpoints.dart`
- **Функционал**: Все эндпоинты используют централизованную конфигурацию
- **Преимущества**: Единая точка изменения версий API

### 3. Модели v2 с поддержкой UUID
- **SleepModelV2**: `lib/features/whoop/data/models/v2/sleep_model_v2.dart`
- **WorkoutModelV2**: `lib/features/whoop/data/models/v2/workout_model_v2.dart`
- **CycleModelV2**: `lib/features/whoop/data/models/v2/cycle_model_v2.dart`
- **RecoveryModelV2**: `lib/features/whoop/data/models/v2/recovery_model_v2.dart`

**Ключевые особенности**:
- Поддержка как UUID (v2), так и int (v1) ID
- Поле `activityV1Id` для обратной совместимости
- Геттеры `idAsInt`, `idAsUuid`, `isUuid` для удобства

### 4. Адаптеры для конвертации
- **Файл**: `lib/features/whoop/data/adapters/whoop_model_adapter.dart`
- **Функционал**: Конвертация между v1 и v2 моделями
- **Назначение**: Обеспечение обратной совместимости

### 5. Фабрика для создания v2 моделей
- **Файл**: `lib/features/whoop/data/factories/whoop_v2_factory.dart`
- **Функционал**: Автоматическое создание v2 моделей из JSON ответов WHOOP API
- **Особенности**: 
  - Автоматическое определение версии API по структуре данных
  - Поддержка как v1, так и v2 форматов
  - Логирование создания моделей

### 6. Интеграция в RemoteDataSourceImpl
- **Файл**: `lib/features/whoop/data/data_sources/remote/remote_data_source_impl.dart`
- **Обновленные методы**:
  - `getCycles()` - создает v2 модели через фабрику
  - `getWorkoutsOfCycle()` - создает v2 модели через фабрику
  - `getRecoveryOfCycle()` - создает v2 модели через фабрику
  - `getLastSleep()` - создает v2 модели через фабрику

**Логика работы**:
1. Получение JSON данных от WHOOP API
2. Создание v2 моделей через `WhoopV2Factory`
3. Конвертация v2 моделей в v1 для обратной совместимости
4. Возврат v1 моделей в существующий код

### 7. Тестирование
- **Файл**: `test/whoop_v2_models_test.dart` - тесты v2 моделей ✅
- **Файл**: `test/whoop_integration_test.dart` - тесты фабрики ✅
- **Файл**: `test/whoop_remote_data_source_test.dart` - тесты интеграции ✅
- **Статус**: ✅ Все тесты проходят

## Архитектурные решения

### Динамические ID
```dart
final dynamic id; // String (UUID) в v2, int в v1
```

**Плюсы**:
- Гибкость при работе с разными версиями API
- Простота миграции

**Минусы**:
- Потеря type safety
- Необходимость проверки типов

### Обратная совместимость
```dart
final int? activityV1Id; // Для обратной совместимости с v1

int? get idAsInt => id is int ? id as int : activityV1Id;
```

**Логика**: Если ID уже int - используем его, иначе используем `activityV1Id`

### Умная фабрика
```dart
// Определяем версию API по структуре данных, а не по конфигурации
final isV2ResponseData = isV2Response(json);

if (isV2ResponseData) {
  // Создаем v2 модель
} else {
  // Создаем v1 модель
}
```

**Преимущества**:
- Автоматическое определение версии API
- Работа с реальными данными, а не конфигурацией
- Гибкость при миграции

## Как использовать

### Переключение на v2
```dart
// В whoop_api_config.dart
static const String _apiVersion = 'v2'; // Изменить с 'v1' на 'v2'
```

### Работа с моделями
```dart
// Создание модели v2
final sleepV2 = SleepModelV2(
  id: '550e8400-e29b-41d4-a716-446655440000', // UUID
  userId: 12345,
  // ... другие поля
  activityV1Id: 67890, // Для обратной совместимости
);

// Получение ID в нужном формате
final int? intId = sleepV2.idAsInt; // 67890
final String? uuid = sleepV2.idAsUuid; // '550e8400-e29b-41d4-a716-446655440000'
final bool isUuid = sleepV2.isUuid; // true
```

### Конвертация между версиями
```dart
// v2 → v1
final sleepV1 = WhoopModelAdapter.toV1SleepModel(sleepV2);

// v1 → v2
final sleepV2 = WhoopModelAdapter.toV2SleepModel(sleepV1);
```

### Автоматическое создание через фабрику
```dart
// Фабрика автоматически определяет версию API и создает соответствующую модель
final cycleV2 = WhoopV2Factory.createCycleFromJson(jsonData);

// Логирование для отладки
WhoopV2Factory.logModelCreation('Cycle', cycleV2);
```

## Следующие шаги

### 1. Интеграция в существующий код ✅
- [x] Обновить `RemoteDataSourceImpl` для использования v2 моделей
- [x] Добавить логику переключения версий
- [x] Создать фабрику для автоматического создания моделей

### 2. Тестирование ✅
- [x] Тестирование моделей v2
- [x] Тестирование фабрики
- [x] Тестирование интеграции в RemoteDataSourceImpl
- [ ] Интеграционное тестирование
- [ ] Тестирование производительности

### 3. Переключение на v2
- [ ] Изменить `_apiVersion` на 'v2'
- [ ] Обновить все вызовы API
- [ ] Тестирование в продакшене
- [ ] Мониторинг ошибок

### 4. Очистка
- [ ] Удаление неиспользуемых v1 моделей
- [ ] Удаление адаптеров
- [ ] Обновление документации

## Статус проекта

- **Этап**: 2 из 4 (Тестирование) ✅
- **Прогресс**: 50%
- **Следующий этап**: Переключение на v2
- **Дедлайн**: Октябрь 2025 (WHOOP прекращает поддержку v1)

## Команды для разработки

```bash
# Анализ кода
flutter analyze lib/features/whoop/data/models/v2/
flutter analyze lib/features/whoop/data/adapters/
flutter analyze lib/features/whoop/data/factories/
flutter analyze lib/features/whoop/data/data_sources/remote/

# Запуск тестов
flutter test test/whoop_v2_models_test.dart
flutter test test/whoop_integration_test.dart
flutter test test/whoop_remote_data_source_test.dart

# Проверка компиляции
flutter build apk --debug
```

## Контакты

- **Разработчик**: AI Assistant
- **Дата**: Январь 2025
- **Статус**: Готово к следующему этапу
