import 'package:rishai/features/whoop/data/models/v2/sleep_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/workout_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/cycle_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/recovery_model_v2.dart';
import 'package:rishai/features/whoop/core/config/whoop_api_config.dart';

/// Фабрика для создания v2 моделей из JSON ответов WHOOP API
/// Автоматически определяет версию API и создает соответствующие модели
class WhoopV2Factory {
  // ===== SLEEP MODELS =====

  /// Создает SleepModelV2 из JSON ответа WHOOP API
  static SleepModelV2 createSleepFromJson(Map<String, dynamic> json) {
    if (WhoopApiConfig.isV2) {
      return SleepModelV2.fromMap(json);
    } else {
      // Для v1 API создаем v2 модель с int ID и безопасной обработкой null
      try {
        return SleepModelV2(
          id: json['id'] as int? ?? 0, // Безопасная обработка null
          userId: json['user_id'] as int? ?? 0, // Безопасная обработка null
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(), // Fallback на текущее время
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(), // Fallback на текущее время
          start: json['start'] != null
              ? DateTime.parse(json['start'])
              : DateTime.now(), // Fallback на текущее время
          end: json['end'] != null
              ? DateTime.parse(json['end'])
              : DateTime.now(), // Fallback на текущее время
          nap: json['nap'] as bool? ?? false,
          scoreState: json['score_state'] as String? ?? 'UNKNOWN',
          score: json['score_state'] == 'SCORED' && json['score'] != null
              ? SleepScoreModelV2.fromMap(json['score'] as Map<String, dynamic>)
              : null,
          activityV1Id: json['id'] as int? ?? 0, // Безопасная обработка null
        );
      } catch (e) {
        // Логируем ошибку и возвращаем безопасную модель
        print('[WhoopV2Factory] Error creating SleepModelV2 from v1 data: $e');
        print('[WhoopV2Factory] JSON data: $json');

        // Возвращаем безопасную модель по умолчанию
        return SleepModelV2(
          id: 0,
          userId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          start: DateTime.now(),
          end: DateTime.now(),
          nap: false,
          scoreState: 'UNKNOWN',
          activityV1Id: 0,
        );
      }
    }
  }

  /// Создает список SleepModelV2 из JSON ответа
  static List<SleepModelV2> createSleepsFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => createSleepFromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===== WORKOUT MODELS =====

  /// Создает WorkoutModelV2 из JSON ответа WHOOP API
  static WorkoutModelV2 createWorkoutFromJson(Map<String, dynamic> json) {
    if (WhoopApiConfig.isV2) {
      return WorkoutModelV2.fromMap(json);
    } else {
      // Для v1 API создаем v2 модель с int ID и безопасной обработкой null
      try {
        return WorkoutModelV2(
          id: json['id'] as int? ?? 0, // Безопасная обработка null
          userId: json['user_id'] as int? ?? 0, // Безопасная обработка null
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(), // Fallback на текущее время
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(), // Fallback на текущее время
          start: json['start'] != null
              ? DateTime.parse(json['start'])
              : DateTime.now(), // Fallback на текущее время
          end: json['end'] != null ? DateTime.parse(json['end']) : null,
          timezoneOffset: json['timezone_offset'] as String? ?? '+00:00',
          sportId: json['sport_id'] as int? ?? 0, // Безопасная обработка null
          scoreState: json['score_state'] as String? ?? 'UNKNOWN',
          score: json['score_state'] == 'SCORED' && json['score'] != null
              ? WorkoutScoreV2.fromMap(json['score'] as Map<String, dynamic>)
              : null,
          activityV1Id: json['id'] as int? ?? 0, // Безопасная обработка null
        );
      } catch (e) {
        // Логируем ошибку и возвращаем безопасную модель
        print(
            '[WhoopV2Factory] Error creating WorkoutModelV2 from v1 data: $e');
        print('[WhoopV2Factory] JSON data: $json');

        // Возвращаем безопасную модель по умолчанию
        return WorkoutModelV2(
          id: 0,
          userId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          start: DateTime.now(),
          timezoneOffset: '+00:00',
          sportId: 0,
          scoreState: 'UNKNOWN',
          score: null,
          activityV1Id: 0,
        );
      }
    }
  }

  /// Создает список WorkoutModelV2 из JSON ответа
  static List<WorkoutModelV2> createWorkoutsFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => createWorkoutFromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===== CYCLE MODELS =====

  /// Создает CycleModelV2 из JSON ответа WHOOP API
  static CycleModelV2 createCycleFromJson(Map<String, dynamic> json) {
    // Определяем версию API по структуре данных, а не по конфигурации
    final isV2ResponseData = isV2Response(json);

    if (isV2ResponseData) {
      // Для v2 API создаем модель и устанавливаем activityV1Id если доступен
      final cycle = CycleModelV2.fromMap(json);
      // Если у нас есть activity_v1_id, используем его для обратной совместимости
      if (json.containsKey('activity_v1_id') &&
          json['activity_v1_id'] != null) {
        return CycleModelV2(
          id: cycle.id,
          userId: cycle.userId,
          createdAt: cycle.createdAt,
          updatedAt: cycle.updatedAt,
          start: cycle.start,
          end: cycle.end,
          scoreState: cycle.scoreState,
          score: cycle.score,
          activityV1Id: json['activity_v1_id'] as int,
        );
      }
      return cycle;
    } else {
      // Для v1 API создаем v2 модель с int ID и безопасной обработкой null
      try {
        final id = json['id'];
        return CycleModelV2(
          id: id, // Передаем как есть (может быть int или String)
          userId: json['user_id'] as int? ?? 0, // Безопасная обработка null
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(), // Fallback на текущее время
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(), // Fallback на текущее время
          start: json['start'] != null
              ? DateTime.parse(json['start'])
              : DateTime.now(), // Fallback на текущее время
          end: json['end'] != null ? DateTime.parse(json['end']) : null,
          scoreState: json['score_state'] as String? ?? 'UNKNOWN',
          score: json['score_state'] == 'SCORED' && json['score'] != null
              ? CycleScoreV2.fromMap(json['score'] as Map<String, dynamic>)
              : null,
          activityV1Id:
              id is int ? id : null, // Используем оригинальный ID если это int
        );
      } catch (e) {
        // Логируем ошибку и возвращаем безопасную модель
        print('[WhoopV2Factory] Error creating CycleModelV2 from v1 data: $e');
        print('[WhoopV2Factory] JSON data: $json');

        // Возвращаем безопасную модель по умолчанию
        return CycleModelV2(
          id: 0,
          userId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          start: DateTime.now(),
          scoreState: 'UNKNOWN',
          activityV1Id: 0,
        );
      }
    }
  }

  /// Создает список CycleModelV2 из JSON ответа
  static List<CycleModelV2> createCyclesFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => createCycleFromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===== RECOVERY MODELS =====

  /// Создает RecoveryModelV2 из JSON ответа WHOOP API
  static RecoveryModelV2 createRecoveryFromJson(Map<String, dynamic> json) {
    if (WhoopApiConfig.isV2) {
      return RecoveryModelV2.fromJson(json);
    } else {
      // Для v1 API создаем v2 модель с безопасной обработкой null значений
      try {
        return RecoveryModelV2(
          cycleId: json['cycle_id'] as int? ?? 0, // Безопасная обработка null
          sleepId: json['sleep_id'] as int? ?? 0, // Безопасная обработка null
          userId: json['user_id'] as int? ?? 0, // Безопасная обработка null
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(), // Fallback на текущее время
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime
                  .now(), // Fallback на текущее время для обязательного поля
          scoreState: json['score_state'] as String? ?? 'UNKNOWN',
          score: json['score_state'] == 'SCORED' && json['score'] != null
              ? RecoveryScoreModelV2.fromJson(
                  json['score'] as Map<String, dynamic>)
              : null,
          activityV1Id: json['id'] as int? ?? 0, // Безопасная обработка null
        );
      } catch (e) {
        // Логируем ошибку и возвращаем безопасную модель
        print(
            '[WhoopV2Factory] Error creating RecoveryModelV2 from v1 data: $e');
        print('[WhoopV2Factory] JSON data: $json');

        // Возвращаем безопасную модель по умолчанию
        return RecoveryModelV2(
          cycleId: 0,
          sleepId: 0,
          userId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(), // Обязательное поле
          scoreState: 'UNKNOWN',
          activityV1Id: 0,
        );
      }
    }
  }

  /// Создает список RecoveryModelV2 из JSON ответа
  static List<RecoveryModelV2> createRecoveriesFromJson(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((json) => createRecoveryFromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ===== UTILITY METHODS =====

  /// Проверяет, является ли JSON ответ от v2 API
  static bool isV2Response(Map<String, dynamic> json) {
    // v2 API обычно имеет более сложную структуру и UUID
    final id = json['id'];
    return id is String && id.length > 10;
  }

  /// Логирует информацию о созданной модели
  static void logModelCreation(String modelType, model) {
    if (WhoopApiConfig.isV2) {
      print('[WhoopV2Factory] Created $modelType v2 with UUID: ${model.id}');
    } else {
      print('[WhoopV2Factory] Created $modelType v2 with int ID: ${model.id}');
    }
  }
}
