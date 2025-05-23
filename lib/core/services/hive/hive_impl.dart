import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/error/local_storage_error_handler.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:rishai/features/login/presentation/bloc/login_bloc.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';

part './hive_repo.dart';

final hive = getIt.get<HiveRepo>();

@Singleton(as: HiveRepo)
class HiveImpl implements HiveRepo {
  late Box<UserEntity> userBox;
  @override
  late Box<ChatSnapshotEntity> chatBox;
  late Box<DayEntity> dayBox;
  late Box<UserDataEntity> userDataBox;
  late Box<WeekPlanEntity> weekPlanBox;
  int savedUserIndex = 0;

  @override
  Future<void> initHive() async {
    try {
      log('STARTING HIVE INITIALIZATION');
      await Hive.initFlutter();
      log('REGISTERING HIVE ADAPTERS');
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
        ..registerAdapter(WeekPlanEntityAdapter())
        ..registerAdapter(HealthMetricsEntityAdapter())
        ..registerAdapter(MeasurementUnitAdapter());
      log('OPENING HIVE BOXES');
      userBox = await Hive.openBox<UserEntity>('user_box');
      chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
      dayBox = await Hive.openBox<DayEntity>('day_box');
      userDataBox = await Hive.openBox<UserDataEntity>('userData_box');
      weekPlanBox = await Hive.openBox<WeekPlanEntity>('weekPlan_box');
      log('HIVE INITIALIZATION COMPLETE');
      log(
        'BOX STATUSES - USER: ${userBox.isEmpty ? "empty" : "${userBox.length} items"}, '
        'USER DATA: ${userDataBox.isEmpty ? "empty" : "${userDataBox.length} items"}, '
        'DAY: ${dayBox.isEmpty ? "empty" : "${dayBox.length} items"}, '
        'CHAT: ${chatBox.isEmpty ? "empty" : "${chatBox.length} items"}, '
        'WEEK PLAN: ${weekPlanBox.isEmpty ? "empty" : "${weekPlanBox.length} items"}',
      );
    } on Exception catch (e, stackTrace) {
      log('ERROR DURING HIVE INITIALIZATION: $e');
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_init',
        operation: 'init',
        storageType: 'hive',
      );

      // При ошибке инициализации пытаемся сбросить хранилище
      await resetStorageOnFatalError();
      rethrow;
    }
  }

  /// Сбрасывает локальное хранилище при критических ошибках
  ///
  /// Этот метод очищает все боксы Hive, удаляет все данные из хранилища
  /// и перезагружает пустые боксы, чтобы приложение могло начать с чистого листа
  /// при обновлении или критических ошибках в схеме данных
  @override
  Future<void> resetStorageOnFatalError() async {
    log('Выполняется сброс локального хранилища из-за критической ошибки');
    try {
      // Вызываем событие выхода из системы
      loginBloc.add(LogoutEvent());
      log('Событие LogoutEvent вызвано для сброса состояния приложения');

      // Закрываем все боксы, если они открыты
      await _closeBoxesSafely();

      // Удаляем все боксы из хранилища
      await Hive.deleteBoxFromDisk('user_box');
      await Hive.deleteBoxFromDisk('chat_box');
      await Hive.deleteBoxFromDisk('day_box');
      await Hive.deleteBoxFromDisk('userData_box');
      await Hive.deleteBoxFromDisk('weekPlan_box');

      // Переоткрываем пустые боксы
      userBox = await Hive.openBox<UserEntity>('user_box');
      chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
      dayBox = await Hive.openBox<DayEntity>('day_box');
      userDataBox = await Hive.openBox<UserDataEntity>('userData_box');
      weekPlanBox = await Hive.openBox<WeekPlanEntity>('weekPlan_box');

      log('Сброс локального хранилища успешно выполнен');
    } on Exception catch (e) {
      log('Ошибка при сбросе локального хранилища: $e');
      // Здесь мы не вызываем handleError, чтобы избежать рекурсивной обработки ошибок
      // Вместо этого просто логируем ошибку
    }

    // Возвращаем пустоту, чтобы инициализация переключилась на удаленные данные
    return;
  }

  // Безопасное закрытие боксов
  Future<void> _closeBoxesSafely() async {
    try {
      if (userBox.isOpen) await userBox.close();
      if (chatBox.isOpen) await chatBox.close();
      if (dayBox.isOpen) await dayBox.close();
      if (userDataBox.isOpen) await userDataBox.close();
      if (weekPlanBox.isOpen) await weekPlanBox.close();
    } on Exception catch (e) {
      log('Ошибка при закрытии боксов: $e');
    }
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
      weekPlanBox = await Hive.openBox<WeekPlanEntity>('weekPlan_box');
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

  @override
  Future<void> saveDay({required DayEntity data}) async {
    try {
      if (data.cycleId == null) {
        await dayBox.add(data);
        return;
      }

      print('SAVING DAY: ${data.directusId}');

      final existingDays = dayBox.values.toList();
      final existingDayIndex =
          existingDays.indexWhere((day) => day.cycleId == data.cycleId);

      if (existingDayIndex != -1) {
        print('ID EXISTED: ${data.directusId}');
        await dayBox.putAt(existingDayIndex, data);
      } else {
        print('ID DIDNOT EXISST: ${data.directusId}');
        await dayBox.add(data);
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
      return dayBox.values.toList();
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
    await chatBox.clear();
  }

  @override
  Future<void> flushSavedDays() async {
    await dayBox.clear();
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
  Future<List<WeekPlanEntity>?> retrieveWeekPlan() async {
    return weekPlanBox.values.toList();
  }

  @override
  Future<void> saveWeekPlan({required WeekPlanEntity weekPlan}) async {
    await weekPlanBox.add(weekPlan);
  }

  @override
  void test() {
    final res = weekPlanBox.values.toList();
    log(res.toString());
  }

  @override
  Future<void> clearWeekPlans() async {
    try {
      await weekPlanBox.clear();
    } on Exception catch (e, stackTrace) {
      await LocalStorageErrorHandler.handleError(
        e,
        stackTrace,
        context: 'hive_week_plan',
        operation: 'clear_week_plans',
        storageType: 'hive',
      );
      rethrow;
    }
  }
}
