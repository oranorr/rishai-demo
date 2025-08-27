# WHOOP API Migration Guide: v1 → v2

## Обзор

Этот документ описывает процесс миграции с WHOOP API v1 на v2 в приложении Rishai. Миграция необходима, так как WHOOP прекращает поддержку v1 API в октябре 2025 года.

## Основные изменения в v2

### 1. ID форматы
- **v1**: Использует `int` ID
- **v2**: Использует `String` UUID
- **Обратная совместимость**: Поддерживаются оба формата

### 2. Структура эндпоинтов
- **v1**: `/v1/cycle`, `/v1/activity/workout`, etc.
- **v2**: `/v2/cycle`, `/v2/activity/workout`, etc.

### 3. Новые поля
- Добавлены дополнительные метрики
- Улучшенная структура данных
- Новые типы оценок

## Архитектура миграции

### Конфигурация версий
```dart
// lib/features/whoop/core/config/whoop_api_config.dart
class WhoopApiConfig {
  static const String _apiVersion = 'v1'; // Изменить на 'v2' для миграции
  
  static String get apiVersion => _apiVersion;
  static bool get isV2 => _apiVersion == 'v2';
  static bool get isV1 => _apiVersion == 'v1';
}
```

### Модели данных
- **v1 модели**: Оригинальные модели с `int` ID
- **v2 модели**: Новые модели с поддержкой UUID и обратной совместимости
- **Адаптеры**: Конвертация между версиями

## Структура файлов

```
lib/features/whoop/
├── core/
│   └── config/
│       └── whoop_api_config.dart          # Конфигурация версий API
├── data/
│   ├── models/                            # v1 модели (существующие)
│   │   ├── sleep_model.dart
│   │   ├── workout_model.dart
│   │   ├── cycle_model.dart
│   │   └── recovery_model.dart
│   ├── models/v2/                         # v2 модели (новые)
│   │   ├── sleep_model_v2.dart
│   │   ├── workout_model_v2.dart
│   │   ├── cycle_model_v2.dart
│   │   └── recovery_model_v2.dart
│   └── adapters/                          # Адаптеры для конвертации
│       └── whoop_model_adapter.dart
└── data_sources/
    └── remote/
        └── endpoints.dart                  # Обновленные эндпоинты
```

## Модели v2

### SleepModelV2
```dart
class SleepModelV2 {
  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime start;
  final DateTime end;
  final bool nap;
  final String scoreState;
  final SleepScoreModelV2? score;
  final int? activityV1Id; // Для обратной совместимости

  // Геттеры для совместимости
  String get idAsString => id.toString();
  int? get idAsInt => id is int ? id as int : activityV1Id;
  String? get idAsUuid => id is String ? id as String : null;
  bool get isUuid => id is String;
}
```

### WorkoutModelV2
```dart
class WorkoutModelV2 {
  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime start;
  final DateTime? end;
  final String timezoneOffset;
  final int sportId;
  final String scoreState;
  final WorkoutScoreV2? score;
  final int? activityV1Id; // Для обратной совместимости

  // Геттеры для совместимости
  String get idAsString => id.toString();
  int? get idAsInt => id is int ? id as int : activityV1Id;
  String? get idAsUuid => id is String ? id as String : null;
  bool get isUuid => id is String;
}
```

### CycleModelV2
```dart
class CycleModelV2 {
  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime start;
  final DateTime? end;
  final String scoreState;
  final CycleScoreV2? score;
  final int? activityV1Id; // Для обратной совместимости

  // Геттеры для совместимости
  String get idAsString => id.toString();
  int? get idAsInt => id is int ? id as int : activityV1Id;
  String? get idAsUuid => id is String ? id as String : null;
  bool get isUuid => id is String;
}
```

### RecoveryModelV2
```dart
class RecoveryModelV2 {
  final dynamic cycleId; // String (UUID) в v2, int в v1
  final dynamic sleepId; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String scoreState;
  final RecoveryScoreV2? score;
  final int? activityV1Id; // Для обратной совместимости

  // Геттеры для совместимости
  String? get cycleIdAsUuid => cycleId is String ? cycleId as String : null;
  int? get cycleIdAsInt => cycleId is int ? cycleId as int : null;
  String? get sleepIdAsUuid => sleepId is String ? sleepId as String : null;
  int? get sleepIdAsInt => sleepId is int ? sleepId as int : null;
}
```

## Адаптеры

### WhoopModelAdapter
```dart
class WhoopModelAdapter {
  // Конвертация v2 → v1
  static SleepModel toV1SleepModel(SleepModelV2 v2Model);
  static WorkoutModel toV1WorkoutModel(WorkoutModelV2 v2Model);
  static CycleModel toV1CycleModel(CycleModelV2 v2Model);
  static RecoveryModel toV1RecoveryModel(RecoveryModelV2 v2Model);

  // Конвертация v1 → v2
  static SleepModelV2 toV2SleepModel(SleepModel v1Model);
  static WorkoutModelV2 toV2WorkoutModel(WorkoutModel v1Model);
  static CycleModelV2 toV2CycleModel(CycleModel v1Model);
  static RecoveryModelV2 toV2RecoveryModel(RecoveryModel v1Model);
}
```

## Эндпоинты

### Обновленная структура
```dart
class WhoopEndpoints {
  String get whoopCycles => useMock
      ? WhoopApiConfig.getMockEndpoint('cycle')
      : WhoopApiConfig.getEndpoint('cycle');
      
  String get workouts => useMock
      ? WhoopApiConfig.getMockEndpoint('activity/workout')
      : WhoopApiConfig.getEndpoint('activity/workout');
      
  String get sleeps => useMock
      ? WhoopApiConfig.getMockEndpoint('activity/sleep')
      : WhoopApiConfig.getEndpoint('activity/sleep');
      
  String get recoveries => useMock
      ? WhoopApiConfig.getMockEndpoint('recovery')
      : WhoopApiConfig.getEndpoint('recovery');
}
```

## Процесс миграции

### Этап 1: Подготовка ✅
- [x] Создание конфигурации версий API
- [x] Обновление эндпоинтов
- [x] Создание моделей v2
- [x] Создание адаптеров

### Этап 2: Тестирование
- [ ] Тестирование моделей v2
- [ ] Тестирование адаптеров
- [ ] Интеграционное тестирование
- [ ] Тестирование производительности

### Этап 3: Переключение
- [ ] Изменение `_apiVersion` на 'v2'
- [ ] Обновление всех вызовов API
- [ ] Тестирование в продакшене
- [ ] Мониторинг ошибок

### Этап 4: Очистка
- [ ] Удаление неиспользуемых v1 моделей
- [ ] Удаление адаптеров
- [ ] Обновление документации

## Тестирование

### Запуск тестов
```bash
# Тестирование моделей v2
flutter test test/whoop_v2_models_test.dart

# Анализ кода
flutter analyze lib/features/whoop/data/models/v2/
flutter analyze lib/features/whoop/data/adapters/
```

### Примеры тестов
```dart
test('SleepModelV2 should work with UUID and int IDs', () {
  final sleepV2 = SleepModelV2(
    id: '550e8400-e29b-41d4-a716-446655440000', // UUID
    userId: 12345,
    // ... другие поля
    activityV1Id: 67890, // Для обратной совместимости
  );

  expect(sleepV2.idAsUuid, '550e8400-e29b-41d4-a716-446655440000');
  expect(sleepV2.idAsInt, 67890); // Использует activityV1Id
});
```

## Мониторинг и отладка

### Логирование
```dart
// В WhoopApiConfig
static String getEndpoint(String path) {
  final endpoint = '$baseUrl/$_apiVersion/$path';
  print('[WhoopApiConfig] Generated endpoint: $endpoint');
  return endpoint;
}
```

### Проверка версии
```dart
if (WhoopApiConfig.isV2) {
  print('Using WHOOP API v2');
} else {
  print('Using WHOOP API v1');
}
```

## Риски и митигация

### Риски
1. **Несовместимость данных**: v2 может возвращать данные в другом формате
2. **Производительность**: UUID длиннее int, может влиять на размер данных
3. **Ошибки API**: Новые эндпоинты могут иметь баги

### Митигация
1. **Постепенная миграция**: Поддержка обеих версий во время перехода
2. **Тестирование**: Обширное тестирование перед переключением
3. **Rollback план**: Возможность быстро вернуться к v1
4. **Мониторинг**: Отслеживание ошибок и производительности

## Временные рамки

- **Январь 2025**: Завершение разработки и тестирования
- **Февраль 2025**: Тестирование в staging окружении
- **Март 2025**: Переключение на v2 в продакшене
- **Апрель 2025**: Мониторинг и исправление проблем
- **Май 2025**: Очистка v1 кода
- **Октябрь 2025**: WHOOP прекращает поддержку v1

## Контакты

- **Разработчик**: AI Assistant
- **Дата создания**: Январь 2025
- **Статус**: В разработке

## Ссылки

- [WHOOP API v2 Documentation](https://developer.whoop.com/docs/developing/v1-v2-migration/)
- [WHOOP API v1 Documentation](https://developer.whoop.com/docs/developing/)
- [Migration Timeline](https://developer.whoop.com/docs/developing/v1-v2-migration/#timeline)
