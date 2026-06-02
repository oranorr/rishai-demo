import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/error/local_storage_error_handler.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/pivot_life_scrore_entity.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
// Недельные планы кэшируем как JSON-строки (toMap/fromMap уже round-trip'ятся),
// поэтому отдельный HiveType/adapter не нужен — храним в Box<String>.
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';

part './hive_repo.dart';

final hive = getIt.get<HiveRepo>();

@Singleton(as: HiveRepo)
class HiveImpl implements HiveRepo {
  late Box<UserEntity> userBox;
  @override
  late Box<ChatSnapshotEntity> chatBox;
  late Box<DayEntity> dayBox;
  late Box<UserDataEntity> userDataBox;

  /// Кэш недельных планов: ключ — startDate(ms) в виде String, значение — JSON
  /// сериализованного [WeekPlanEntity.toMap]. Box<String> (v5 [hiveSchemaVersion]).
  late Box<String> weekPlanBox;

  int savedUserIndex = 0;

  @override
  Future<void> initHive() async {
    try {
      log('[HIVE] Начинаем инициализацию Hive');

      // Проверяем совместимость версии схемы данных
      final isSchemaCompatible =
          prefsRepo.isHiveSchemaVersionCompatible(hiveSchemaVersion);
      final savedVersion = prefsRepo.getHiveSchemaVersion();

      log('[HIVE] Проверка версии схемы - Ожидаемая: $hiveSchemaVersion, Сохраненная: $savedVersion, Совместимая: $isSchemaCompatible');

      // ЭЛЕГАНТНОЕ РЕШЕНИЕ: Используем уникальные пути для каждой версии схемы
      // Вместо сложного удаления, просто используем разные директории
      const hiveDirectory = 'hive_v$hiveSchemaVersion';

      // Инициализируем Hive с версионированной директорией
      await Hive.initFlutter(hiveDirectory);
      log('[HIVE] Hive.initFlutter() выполнен с директорией: $hiveDirectory');

      // Регистрируем адаптеры
      _registerHiveAdapters();
      log('[HIVE] Все адаптеры Hive зарегистрированы');

      // Открываем боксы
      await _openHiveBoxes();
      log('[HIVE] Все боксы Hive открыты успешно');

      // Сохраняем текущую версию схемы после успешной инициализации
      await prefsRepo.setHiveSchemaVersion(hiveSchemaVersion);
      log('[HIVE] Версия схемы сохранена: $hiveSchemaVersion');

      log('[HIVE] Инициализация завершена успешно');
      _logBoxStatuses();
    } catch (e, stackTrace) {
      log('[HIVE] КРИТИЧЕСКАЯ ОШИБКА при инициализации: $e');
      log('[HIVE] StackTrace: $stackTrace');

      // При критической ошибке выполняем экстренный сброс и повторную инициализацию
      await _handleCriticalInitializationError(e, stackTrace);
    }
  }

  /// Выполняет сброс локального хранилища при обновлении схемы
  Future<void> _performStorageReset() async {
    log('[HIVE] Выполняем сброс хранилища для обеспечения совместимости схемы');

    try {
      // Закрываем все боксы если они открыты (с безопасной проверкой)
      await _closeBoxesSafely();

      // Полное закрытие Hive перед сбросом
      try {
        await Hive.close();
        log('[HIVE] Все боксы Hive закрыты');
      } catch (e) {
        log('[HIVE] Ошибка при закрытии Hive: $e');
      }

      // МАКСИМАЛЬНО АГРЕССИВНОЕ удаление данных
      bool deletionSuccessful = false;

      // Попытка 1: Массовое удаление через Hive API
      try {
        await Hive.deleteFromDisk();
        log('[HIVE] Hive.deleteFromDisk() выполнен');
      } catch (e) {
        log('[HIVE] Ошибка при Hive.deleteFromDisk(): $e');
      }

      // Попытка 2: Удаление боксов по отдельности
      try {
        await _deleteBoxesIndividually();
      } catch (e) {
        log('[HIVE] Ошибка при удалении боксов по отдельности: $e');
      }

      // Попытка 3: ФИЗИЧЕСКОЕ удаление файлов из файловой системы
      try {
        await _physicallyDeleteHiveFiles();
        deletionSuccessful = true;
        log('[HIVE] ✅ Физическое удаление файлов выполнено успешно');
      } catch (e) {
        log('[HIVE] ❌ Ошибка при физическом удалении файлов: $e');
      }

      // Даем время системе освободить файлы
      await Future.delayed(const Duration(milliseconds: 1000));

      if (deletionSuccessful) {
        log('[HIVE] ✅ Сброс хранилища завершен успешно');
      } else {
        log('[HIVE] ⚠️ Сброс хранилища завершен с частичными ошибками');
      }
    } catch (e) {
      log('[HIVE] Критическая ошибка при сбросе хранилища: $e');
      // Пытаемся выполнить финальную очистку
      try {
        await _physicallyDeleteHiveFiles();
      } catch (e2) {
        log('[HIVE] Финальная очистка неудачна: $e2');
      }
    }
  }

  /// Удаляет боксы по отдельности если массовое удаление не сработало
  Future<void> _deleteBoxesIndividually() async {
    final boxNames = [
      'user_box',
      'chat_box',
      'day_box',
      'userData_box',
      'weekPlan_box',
    ];

    log('[HIVE] Удаляем боксы по отдельности...');

    for (final boxName in boxNames) {
      // Делаем несколько попыток для каждого бокса
      bool deleted = false;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          log('[HIVE] ✅ Удален бокс: $boxName (попытка $attempt)');
          deleted = true;
          break;
        } catch (e) {
          log('[HIVE] ❌ Ошибка при удалении бокса $boxName (попытка $attempt): $e');
          if (attempt < 3) {
            // Пауза между попытками
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
        }
      }

      if (!deleted) {
        log('[HIVE] ⚠️ Не удалось удалить бокс $boxName после 3 попыток');
      }
    }

    log('[HIVE] Завершено удаление боксов по отдельности');
  }

  /// Регистрирует все необходимые адаптеры Hive
  void _registerHiveAdapters() {
    Hive
      ..registerAdapter<UserEntity>(UserEntityAdapter())
      ..registerAdapter(GenderAdapter())
      ..registerAdapter(FoodPreferencesAdapter())
      ..registerAdapter(ChatSnapshotEntityAdapter())
      ..registerAdapter(MessageEntityAdapter())
      ..registerAdapter(MealPlanEntityAdapter())
      ..registerAdapter(UserGoalAdapter())
      ..registerAdapter(MealAdapter())
      ..registerAdapter(IngredientAdapter())
      ..registerAdapter(MacrosBreakdownAdapter())
      ..registerAdapter(GoalTypeAdapter())
      ..registerAdapter(DayEntityAdapter())
      ..registerAdapter(UserDataEntityAdapter())
      ..registerAdapter(WorkoutModelAdapter())
      ..registerAdapter(WorkoutScoreAdapter())
      ..registerAdapter(BodyMeasurementsEntityAdapter())
      ..registerAdapter(HealthMetricsEntityAdapter())
      ..registerAdapter(WelnessEntityAdapter())
      ..registerAdapter(DiaryMealAdapter())
      ..registerAdapter(PivotLifeScoreEntityAdapter())
      ..registerAdapter(MeasurementUnitAdapter());
  }

  /// Открывает все необходимые боксы Hive
  Future<void> _openHiveBoxes() async {
    userBox = await Hive.openBox<UserEntity>('user_box');
    chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
    dayBox = await Hive.openBox<DayEntity>('day_box');
    userDataBox = await Hive.openBox<UserDataEntity>('userData_box');
    weekPlanBox = await Hive.openBox<String>('weekPlan_box');
  }

  /// Обрабатывает критические ошибки инициализации
  Future<void> _handleCriticalInitializationError(
    error,
    StackTrace stackTrace,
  ) async {
    try {
      // Логируем ошибку через систему обработки ошибок
      await LocalStorageErrorHandler.handleError(
        error is Exception ? error : Exception(error.toString()),
        stackTrace,
        context: 'hive_critical_init',
        operation: 'critical_initialization_failure',
        storageType: 'hive',
      );

      log('[HIVE] Пытаемся выполнить экстренное восстановление');

      // ПРОСТОЕ РЕШЕНИЕ: Просто пересоздаем с новой версионированной директорией
      const hiveDirectory = 'hive_v${hiveSchemaVersion}_recovery';

      // Повторная попытка инициализации с recovery директорией
      await Hive.initFlutter(hiveDirectory);
      log('[HIVE] Экстренная инициализация с директорией: $hiveDirectory');

      // Регистрируем адаптеры
      try {
        _registerHiveAdapters();
        log('[HIVE] Адаптеры зарегистрированы при восстановлении');
      } catch (e) {
        log('[HIVE] Адаптеры уже зарегистрированы или ошибка регистрации: $e');
      }

      await _openHiveBoxes();

      log('[HIVE] Экстренное восстановление выполнено успешно');
    } catch (e) {
      log('[HIVE] ПОЛНЫЙ ПРОВАЛ ИНИЦИАЛИЗАЦИИ: $e');
      rethrow;
    }
  }

  /// Выполняет экстренный сброс всех данных
  Future<void> _emergencyDataReset() async {
    log('[HIVE] 🚨 ЭКСТРЕННЫЙ СБРОС ДАННЫХ');

    try {
      // Шаг 1: Полное закрытие Hive
      try {
        await Hive.close();
        log('[HIVE] Все боксы принудительно закрыты');
      } catch (e) {
        log('[HIVE] Ошибка при закрытии Hive: $e');
      }

      // НЕ сбрасываем адаптеры - это удалит встроенные адаптеры для DateTime и других типов
      // Hive.resetAdapters(); // УБРАНО - вызывает ошибки с DateTime

      // Шаг 3: МАКСИМАЛЬНО АГРЕССИВНОЕ удаление данных
      bool deletionSuccessful = false;

      // Попытка 1: Полное удаление через Hive API
      try {
        await Hive.deleteFromDisk();
        log('[HIVE] Экстренное Hive.deleteFromDisk() выполнено');
      } catch (e) {
        log('[HIVE] ❌ Ошибка при экстренном Hive.deleteFromDisk(): $e');
      }

      // Попытка 2: Удаление по боксам
      try {
        await _deleteBoxesIndividually();
        log('[HIVE] Экстренное удаление по боксам выполнено');
      } catch (e) {
        log('[HIVE] ❌ Ошибка при экстренном удалении по боксам: $e');
      }

      // Попытка 3: ФИЗИЧЕСКОЕ удаление файлов (самая агрессивная)
      try {
        await _physicallyDeleteHiveFiles();
        deletionSuccessful = true;
        log('[HIVE] ✅ ЭКСТРЕННОЕ физическое удаление файлов выполнено');
      } catch (e) {
        log('[HIVE] ❌ Ошибка при экстренном физическом удалении: $e');
      }

      // Даем больше времени системе освободить файлы
      await Future.delayed(const Duration(milliseconds: 1500));

      if (deletionSuccessful) {
        log('[HIVE] 🚨 ЭКСТРЕННЫЙ СБРОС ЗАВЕРШЕН УСПЕШНО');
      } else {
        log('[HIVE] 🚨 ЭКСТРЕННЫЙ СБРОС ЗАВЕРШЕН С ОШИБКАМИ');
      }
    } catch (e) {
      log('[HIVE] 💥 КРИТИЧЕСКАЯ ОШИБКА ЭКСТРЕННОГО СБРОСА: $e');
      // Последняя попытка - только физическое удаление
      try {
        await _physicallyDeleteHiveFiles();
        log('[HIVE] 💾 Последняя попытка физического удаления выполнена');
      } catch (e2) {
        log('[HIVE] 💥 ФИНАЛЬНАЯ ОШИБКА: $e2');
      }
    }
  }

  /// Выводит статистику по боксам
  void _logBoxStatuses() {
    log('[HIVE] Статистика боксов:');
    log('  - USER: ${userBox.isEmpty ? "пустой" : "${userBox.length} записей"}');
    log('  - CHAT: ${chatBox.isEmpty ? "пустой" : "${chatBox.length} записей"}');
    log('  - DAY: ${dayBox.isEmpty ? "пустой" : "${dayBox.length} записей"}');
    log('  - USER_DATA: ${userDataBox.isEmpty ? "пустой" : "${userDataBox.length} записей"}');
    log('  - WEEK_PLAN: ${weekPlanBox.isEmpty ? "пустой" : "${weekPlanBox.length} записей"}');
  }

  @override
  Future<void> saveUser({required UserEntity user}) async {
    try {
      await userBox.clear();
      savedUserIndex = await userBox.add(user);
      print('User is saved: $user');
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_user',
        operation: 'save_user',
        storageType: 'hive',
        extras: {'user_id': user.directusId},
      );
      rethrow;
    }
  }

  @override
  Future<UserEntity?> retrieveSavedUser() async {
    try {
      if (!userBox.isOpen) {
        userBox = await Hive.openBox<UserEntity>('user_box');
        UserEntity? user = userBox.getAt(savedUserIndex);
        return user;
      } else {
        if (userBox.isNotEmpty) {
          UserEntity? user = userBox.getAt(savedUserIndex);
          return user;
        } else {
          return null;
        }
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_user',
        operation: 'retrieve_user',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await userBox.clear();
      await chatBox.clear();
      await dayBox.clear();
      await weekPlanBox.clear();

      await userBox.close();
      await chatBox.close();
      await dayBox.close();
      await weekPlanBox.close();

      userBox = await Hive.openBox<UserEntity>('user_box');
      chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
      dayBox = await Hive.openBox<DayEntity>('day_box');
      weekPlanBox = await Hive.openBox<String>('weekPlan_box');
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_clear',
        operation: 'clear_all',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> saveChatSnapshot(
    ChatSnapshotEntity snapshot, [
    DateTime? date,
  ]) async {
    try {
      final dateKey = date?.toIso8601String().substring(0, 10) ??
          snapshot.date.toIso8601String().substring(0, 10);
      await chatBox.put(dateKey, snapshot);
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_chat',
        operation: 'save_chat_snapshot',
        storageType: 'hive',
        extras: {
          'date': date?.toString() ?? snapshot.date.toString(),
          'messages_count': snapshot.messages.length,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> clearMealPlan() async {
    try {
      final today = DateTime.now();
      final dateKey = today.toIso8601String().substring(0, 10);

      final currentSnap = await getChatSnapshot(today);
      if (currentSnap != null) {
        await saveChatSnapshot(
          currentSnap.copyWith(
            messages: [],
            requestsLeft: 50,
          ),
          today,
        );
      }

      final days = await retrieveSavedDays();
      final todayDay = days
          .where(
            (day) => day.dateTime.toIso8601String().substring(0, 10) == dateKey,
          )
          .firstOrNull;

      if (todayDay != null) {
        await saveDay(
          data: todayDay.copyWith(
            snap: currentSnap?.copyWith(
              messages: [],
              requestsLeft: 50,
            ),
          ),
        );
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_meal_plan',
        operation: 'clear_meal_plan',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<ChatSnapshotEntity?> getChatSnapshot([DateTime? date]) async {
    try {
      final dateKey = date?.toIso8601String().substring(0, 10) ??
          DateTime.now().toIso8601String().substring(0, 10);
      return chatBox.get(dateKey);
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_chat',
        operation: 'get_chat_snapshot',
        storageType: 'hive',
        extras: {'date': date?.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<ChatSnapshotEntity?> retrieveLastChat() async {
    try {
      if (chatBox.isEmpty) {
        return null;
      }
      final int last = chatBox.length - 1;
      return chatBox.getAt(last);
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_chat',
        operation: 'retrieve_last_chat',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  /// [saveDay] Мёрдж incoming поверх existing — не затираем локальный дневник.
  DayEntity _mergeDayForHive(DayEntity? existing, DayEntity incoming) {
    if (existing == null) {
      return incoming;
    }

    return incoming.copyWith(
      welnessEntity: incoming.welnessEntity ?? existing.welnessEntity,
      mealPlanEntity: incoming.mealPlanEntity ?? existing.mealPlanEntity,
    );
  }

  /// [saveDay] Ищем существующую запись: directusId → cycleId → календарная дата.
  ///
  /// Раньше merge шёл только по [cycleId]; дни без cycleId (legacy / до WHOOP /
  /// seed-данные) каждый раз делали [add] и раздували box.
  (dynamic key, DayEntity day)? _findExistingDayEntry(DayEntity data) {
    dynamic cycleKey;
    DayEntity? cycleDay;
    dynamic dateKey;
    DayEntity? dateDay;

    for (final entry in dayBox.toMap().entries) {
      final day = entry.value;

      if (data.directusId > 0 && day.directusId == data.directusId) {
        return (entry.key, day);
      }

      if (cycleKey == null &&
          data.cycleId != null &&
          day.cycleId == data.cycleId) {
        cycleKey = entry.key;
        cycleDay = day;
      }

      if (dateKey == null &&
          day.dateTime.year == data.dateTime.year &&
          day.dateTime.month == data.dateTime.month &&
          day.dateTime.day == data.dateTime.day) {
        dateKey = entry.key;
        dateDay = day;
      }
    }

    if (cycleKey != null && cycleDay != null) {
      return (cycleKey, cycleDay);
    }
    if (dateKey != null && dateDay != null) {
      return (dateKey, dateDay);
    }

    return null;
  }

  @override
  Future<void> saveDay({required DayEntity data}) async {
    try {
      // [saveDay] Логируем наличие welnessEntity при сохранении
      final hasWellness = data.welnessEntity != null;
      print(
        '[Hive.saveDay] Сохранение дня ID=${data.directusId}, cycleId=${data.cycleId}, wellness=${hasWellness ? "есть (${data.welnessEntity!.consumedMeals.length} блюд)" : "нет"}',
      );

      if (data.cycleId == null && data.directusId > 0) {
        print(
          '[Hive.saveDay] ℹ️ День directusId=${data.directusId} без cycleId — legacy/до WHOOP, upsert по id',
        );
      }

      final existingEntry = _findExistingDayEntry(data);
      final merged = _mergeDayForHive(existingEntry?.$2, data);

      if (existingEntry != null) {
        final existingDay = existingEntry.$2;
        if (hasWellness && existingDay.welnessEntity == null) {
          print(
            '[Hive.saveDay] ⚠️ Обновление дня: новый день имеет welnessEntity, старый - нет',
          );
        } else if (!hasWellness && existingDay.welnessEntity != null) {
          print(
            '[Hive.saveDay] ✅ Сохранён локальный welnessEntity при обновлении с сервера',
          );
        }

        await dayBox.put(existingEntry.$1, merged);
      } else {
        await dayBox.add(merged);
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_day',
        operation: 'save_day',
        storageType: 'hive',
        extras: {
          'cycle_id': data.cycleId,
          'date_time': data.dateTime.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<DayEntity>> retrieveSavedDays() async {
    try {
      if (dayBox.isEmpty) {
        return [];
      }
      
      final days = dayBox.values.toList();
      
      // [retrieveSavedDays] Логируем статистику по welnessEntity
      final daysWithWellness = days.where((d) => d.welnessEntity != null).length;
      final daysWithoutWellness = days.length - daysWithWellness;
      print(
        '[Hive.retrieveSavedDays] Загружено ${days.length} дней из кэша: с wellness=$daysWithWellness, без wellness=$daysWithoutWellness',
      );
      
      return days;
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_day',
        operation: 'retrieve_saved_days',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> saveUserData({required UserDataEntity dataEntity}) async {
    try {
      log('ATTEMPTING TO SAVE USER DATA FOR USER ID: ${dataEntity.userId}');
      log('CURRENT USER DATA BOX IS EMPTY: ${userDataBox.isEmpty}, COUNT: ${userDataBox.length}');

      if (userDataBox.isEmpty) {
        final index = await userDataBox.add(dataEntity);
        log('SAVED NEW USER DATA AT INDEX $index FOR USER ID: ${dataEntity.userId}');
        return;
      } else {
        int indexOfLast = 0;
        final listEntities = userDataBox.values.toList();
        log('EXISTING USER DATA COUNT: ${listEntities.length}');

        // Логируем все существующие userId для понимания
        final existingUserIds =
            listEntities.map((data) => data.userId).toList();
        log('EXISTING USER IDS IN BOX: $existingUserIds');

        for (final data in listEntities) {
          if (data.userId == dataEntity.userId) {
            indexOfLast = listEntities.indexOf(data);
            log('FOUND EXISTING USER DATA FOR USER ID: ${dataEntity.userId} AT INDEX: $indexOfLast');
            break;
          } else {
            indexOfLast = 0;
          }
        }

        await userDataBox.putAt(indexOfLast, dataEntity);
        log('UPDATED USER DATA AT INDEX $indexOfLast FOR USER ID: ${dataEntity.userId}');

        // Проверка после сохранения
        final updatedUserData = userDataBox.getAt(indexOfLast);
        log('AFTER SAVE: USER DATA IS NULL: ${updatedUserData == null}');
        if (updatedUserData != null) {
          log('AFTER SAVE: USER ID IN SAVED DATA: ${updatedUserData.userId}');
        }

        return;
      }
    } on Exception catch (e, stackTrace) {
      log('ERROR SAVING USER DATA: $e');
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_user_data',
        operation: 'save_user_data',
        storageType: 'hive',
        extras: {
          'user_id': dataEntity.userId,
          'ask_time': dataEntity.askTime.toString(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<UserDataEntity?> fetchUserDataEntity({required String userId}) async {
    try {
      log('ATTEMPTING TO FETCH USER DATA FOR USER ID: $userId');
      log('USER DATA BOX STATUS - IS EMPTY: ${userDataBox.isEmpty}, COUNT: ${userDataBox.length}');

      if (userDataBox.isEmpty) {
        log('NO USER DATA FOUND - BOX IS EMPTY');
        return null;
      }

      final listEntities = userDataBox.values.toList().reversed;
      log('FOUND ${listEntities.length} USER DATA ENTRIES');

      // Логируем все имеющиеся userId для понимания
      final availableUserIds = listEntities.map((data) => data.userId).toList();
      log('AVAILABLE USER IDS IN BOX: $availableUserIds');

      UserDataEntity? last;

      for (final data in listEntities) {
        log('CHECKING USER DATA WITH ID: ${data.userId}');
        if (data.userId == userId) {
          last = data;
          log('FOUND MATCHING USER DATA FOR USER ID: $userId');
          break;
        }
      }

      if (last == null) {
        log('NO MATCHING USER DATA FOUND FOR USER ID: $userId');
      } else {
        log('RETURNING USER DATA: $last');
      }

      return last;
    } on Exception catch (e, stackTrace) {
      log('ERROR FETCHING USER DATA: $e');
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_user_data',
        operation: 'fetch_user_data',
        storageType: 'hive',
        extras: {'user_id': userId},
      );
      rethrow;
    }
  }

  @override
  Future<List<UserDataEntity>> retrieveAllUserData() async {
    try {
      if (userDataBox.isEmpty) {
        log('UserDataBox is empty');
        return [];
      }
      return userDataBox.values.toList();
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_user_data',
        operation: 'retrieve_all_user_data',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> disconnectWhoop() async {
    try {
      log('DISCONNECTING WHOOP - STARTING DATA CLEANUP');
      log('BEFORE CLEANUP - DAY BOX COUNT: ${dayBox.length}, USER DATA BOX COUNT: ${userDataBox.length}');

      if (userDataBox.isNotEmpty) {
        final userData = userDataBox.values.toList();
        log('USER DATA BEFORE CLEANUP - COUNT: ${userData.length}, USER IDS: ${userData.map((data) => data.userId).toList()}');
      }

      await dayBox.clear();
      await userDataBox.clear();

      log('AFTER CLEANUP - DAY BOX COUNT: ${dayBox.length}, USER DATA BOX COUNT: ${userDataBox.length}');
    } on Exception catch (e, stackTrace) {
      log('ERROR DURING WHOOP DISCONNECT: $e');
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_whoop',
        operation: 'disconnect_whoop',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> refreshChat() async {
    try {
      await chatBox.clear();
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_chat',
        operation: 'refresh_chat',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> replaceSavedDays({required List<DayEntity> days}) async {
    try {
      print(
        '[Hive.replaceSavedDays] Замена кэша: ${dayBox.length} → ${days.length} дней',
      );
      await dayBox.clear();
      for (final day in days) {
        await dayBox.add(day);
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_day',
        operation: 'replace_saved_days',
        storageType: 'hive',
        extras: {'days_count': days.length},
      );
      rethrow;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Недельные планы (preps) — кэш Box<String> с JSON.
  //  Источник истины — backend (GET /week-plans); Hive нужен только для
  //  мгновенного отображения при следующем входе (stale-while-revalidate).
  // ───────────────────────────────────────────────────────────────────────

  @override
  Future<void> replaceSavedWeekPlans({required List<WeekPlanEntity> weeks}) async {
    try {
      print(
        '[Hive.replaceSavedWeekPlans] Замена кэша preps: ${weekPlanBox.length} → ${weeks.length}',
      );

      await weekPlanBox.clear();

      for (final week in weeks) {
        // Ключ — startDate(ms): один prep на дату старта, перезапись дубликатов.
        final key = week.startDate.millisecondsSinceEpoch.toString();
        weekPlanBox.put(key, jsonEncode(week.toMap()));
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_week_plan',
        operation: 'replace_saved_week_plans',
        storageType: 'hive',
        extras: {'weeks_count': weeks.length},
      );
      rethrow;
    }
  }

  @override
  Future<List<WeekPlanEntity>> retrieveSavedWeekPlans() async {
    try {
      if (weekPlanBox.isEmpty) {
        return [];
      }

      final weeks = <WeekPlanEntity>[];

      for (final raw in weekPlanBox.values) {
        try {
          final decoded = jsonDecode(raw);
          weeks.add(WeekPlanEntity.fromMap(decoded));
        } on Object catch (e) {
          // Битую/несовместимую запись пропускаем, не роняем весь кэш.
          print('[Hive.retrieveSavedWeekPlans] Пропуск записи: $e');
        }
      }

      weeks.sort((a, b) => a.startDate.compareTo(b.startDate));
      print('[Hive.retrieveSavedWeekPlans] Загружено ${weeks.length} preps из кэша');
      return weeks;
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_week_plan',
        operation: 'retrieve_saved_week_plans',
        storageType: 'hive',
      );
      return [];
    }
  }

  @override
  Future<void> flushWeekPlans() async {
    try {
      await weekPlanBox.clear();
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_week_plan',
        operation: 'flush_week_plans',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> flushSavedDays() async {
    try {
      await dayBox.clear();
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_day',
        operation: 'flush_saved_days',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteLastDay() async {
    try {
      if (dayBox.isNotEmpty) {
        // Получаем все записи и их ключи
        final Map<dynamic, DayEntity> entries =
            dayBox.toMap().cast<dynamic, DayEntity>();
        if (entries.isEmpty) {
          log('Нет дней для удаления.');
          return;
        }

        // Находим запись с максимальной датой
        DayEntity? latestDay;
        dynamic latestDayKey;

        entries.forEach((key, day) {
          if (latestDay == null || day.dateTime.isAfter(latestDay!.dateTime)) {
            latestDay = day;
            latestDayKey = key;
          }
        });

        // Удаляем найденный день по ключу
        if (latestDayKey != null) {
          await dayBox.delete(latestDayKey);
          log('День с датой ${latestDay!.dateTime.toIso8601String()} удален успешно.');
        } else {
          log('Не удалось найти день для удаления.');
        }
      } else {
        log('Нет дней для удаления.');
      }
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_day',
        operation: 'delete_last_day',
        storageType: 'hive',
      );
      rethrow;
    }
  }

  @override
  void test() {
    try {
      final res = userBox.length;
      log('[HIVE] test: userBox entries=$res');
    } on Exception catch (e) {
      log('Ошибка в test методе: $e');
    }
  }

  /// Сбрасывает локальное хранилище при критических ошибках
  ///
  /// Этот метод теперь использует элегантное решение с версионированными директориями
  /// вместо агрессивной очистки файлов
  @override
  Future<void> resetStorageOnFatalError() async {
    log('[HIVE] Выполняется сброс локального хранилища из-за критической ошибки');
    try {
      // ЭЛЕГАНТНОЕ РЕШЕНИЕ: Используем новую версионированную директорию
      const recoveryDirectory = 'hive_v${hiveSchemaVersion}_fatal_recovery';

      // Переоткрываем с чистой директорией
      await Hive.initFlutter(recoveryDirectory);
      log('[HIVE] Инициализация с recovery директорией: $recoveryDirectory');

      // Регистрируем адаптеры
      try {
        _registerHiveAdapters();
        log('[HIVE] Адаптеры зарегистрированы при сбросе');
      } catch (e) {
        log('[HIVE] Адаптеры уже зарегистрированы или ошибка регистрации: $e');
      }

      await _openHiveBoxes();

      log('[HIVE] Сброс локального хранилища успешно выполнен');
    } on Exception catch (e) {
      log('[HIVE] Ошибка при сбросе локального хранилища: $e');
      // Здесь мы не вызываем handleError, чтобы избежать рекурсивной обработки ошибок
      // Вместо этого просто логируем ошибку
    }
  }

  // Безопасное закрытие боксов
  Future<void> _closeBoxesSafely() async {
    try {
      // Проверяем инициализацию боксов перед попыткой их закрытия
      try {
        if (userBox.isOpen) await userBox.close();
      } catch (e) {
        log('[HIVE] userBox не инициализирован или уже закрыт: $e');
      }

      try {
        if (chatBox.isOpen) await chatBox.close();
      } catch (e) {
        log('[HIVE] chatBox не инициализирован или уже закрыт: $e');
      }

      try {
        if (dayBox.isOpen) await dayBox.close();
      } catch (e) {
        log('[HIVE] dayBox не инициализирован или уже закрыт: $e');
      }

      try {
        if (userDataBox.isOpen) await userDataBox.close();
      } catch (e) {
        log('[HIVE] userDataBox не инициализирован или уже закрыт: $e');
      }

      try {
        if (weekPlanBox.isOpen) await weekPlanBox.close();
      } catch (e) {
        log('[HIVE] weekPlanBox не инициализирован или уже закрыт: $e');
      }

    } catch (e) {
      log('[HIVE] Общая ошибка при закрытии боксов: $e');
    }
  }

  /// Выполняет физическое удаление всех файлов Hive из файловой системы
  Future<void> _physicallyDeleteHiveFiles() async {
    log('[HIVE] 🗂️ ФИЗИЧЕСКОЕ УДАЛЕНИЕ ФАЙЛОВ HIVE');

    try {
      // Пытаемся найти и удалить файлы Hive разными способами
      bool anyFilesDeleted = false;

      // Способ 1: Ищем в текущей директории
      try {
        final currentDir = Directory.current;
        await _searchAndDeleteHiveFiles(currentDir, recursive: true);
        anyFilesDeleted = true;
      } catch (e) {
        log('[HIVE] Поиск в текущей директории неудачен: $e');
      }

      // Способ 2: Ищем в типичных местах для Flutter приложений
      final potentialPaths = [
        '/data/data', // Android data directory
        '/var/mobile/Containers/Data', // iOS data directory
        'Documents', // Relative documents
        'Library', // Relative library
        '.', // Current directory
      ];

      for (final path in potentialPaths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            final deleted =
                await _searchAndDeleteHiveFiles(dir, recursive: true);
            if (deleted) anyFilesDeleted = true;
          }
        } catch (e) {
          // Продолжаем поиск в других местах
          log('[HIVE] Поиск в $path неудачен: $e');
        }
      }

      if (anyFilesDeleted) {
        log('[HIVE] ✅ Физическое удаление файлов выполнено');
        // Пауза для освобождения ресурсов файловой системы
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        log('[HIVE] ⚠️ Файлы Hive не найдены для физического удаления');
      }
    } catch (e) {
      log('[HIVE] ❌ Общая ошибка физического удаления файлов: $e');
    }
  }

  /// Ищет и удаляет файлы Hive в указанной директории
  Future<bool> _searchAndDeleteHiveFiles(
    Directory directory, {
    bool recursive = false,
  }) async {
    bool anyFilesDeleted = false;

    try {
      log('[HIVE] 🔍 Поиск файлов Hive в: ${directory.path}');

      final files = await directory.list(recursive: recursive).toList();

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split(Platform.pathSeparator).last;

          // Удаляем файлы, связанные с нашими боксами
          if (_isHiveFile(fileName)) {
            try {
              await file.delete();
              log('[HIVE] 🗑️ Удален файл: ${file.path}');
              anyFilesDeleted = true;
            } catch (e) {
              log('[HIVE] ❌ Не удалось удалить файл: ${file.path}, ошибка: $e');
            }
          }
        }
      }
    } catch (e) {
      log('[HIVE] ❌ Ошибка поиска в директории ${directory.path}: $e');
    }

    return anyFilesDeleted;
  }

  /// Проверяет, является ли файл файлом Hive
  bool _isHiveFile(String fileName) {
    return fileName.startsWith('user_box') ||
        fileName.startsWith('chat_box') ||
        fileName.startsWith('day_box') ||
        fileName.startsWith('userData_box') ||
        fileName.startsWith('weekPlan_box') ||
        fileName.endsWith('.hive') ||
        fileName.endsWith('.lock') ||
        fileName.contains('hive'); // Общий паттерн для файлов Hive
  }

  /// Альтернативный метод удаления файлов Hive
  Future<void> _deleteHiveFilesAlternativeMethod() async {
    log('[HIVE] 🔄 Альтернативный метод удаления файлов');

    try {
      // Пытаемся удалить файлы по известным именам в текущей директории
      final boxNames = [
        'user_box.hive',
        'chat_box.hive',
        'day_box.hive',
        'userData_box.hive',
        'weekPlan_box.hive',
        'user_box.lock',
        'chat_box.lock',
        'day_box.lock',
        'userData_box.lock',
        'weekPlan_box.lock',
      ];

      for (final fileName in boxNames) {
        try {
          final file = File(fileName);
          if (await file.exists()) {
            await file.delete();
            log('[HIVE] 🗑️ Удален файл: $fileName');
          }
        } catch (e) {
          // Файл может не существовать - это нормально
          log('[HIVE] Файл $fileName не найден или не может быть удален: $e');
        }
      }
    } catch (e) {
      log('[HIVE] ❌ Ошибка альтернативного метода: $e');
    }
  }
}
