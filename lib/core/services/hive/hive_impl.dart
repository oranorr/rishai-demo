import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';
import 'package:rishai/features/whoop/domain/entities/whoop_data_entity.dart';

part './hive_repo.dart';

final hive = getIt.get<HiveRepo>();

@Singleton(as: HiveRepo)
class HiveImpl implements HiveRepo {
  late Box<UserEntity> userBox;
  @override
  late Box<ChatSnapshotEntity> chatBox;
  late Box<WhoopDataEntity> whoopDataBox;
  late Box<UserDataEntity> userDataBox;
  int savedUserIndex = 0;

  @override
  Future<void> initHive() async {
    await Hive.initFlutter();
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
      ..registerAdapter(WhoopDataEntityAdapter())
      ..registerAdapter(UserDataEntityAdapter())
      ..registerAdapter(WorkoutModelAdapter())
      ..registerAdapter(WorkoutScoreAdapter())
      ..registerAdapter(BodyMeasurementsEntityAdapter());

    userBox = await Hive.openBox<UserEntity>('user_box');
    chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
    whoopDataBox = await Hive.openBox<WhoopDataEntity>('whoop_box');
    userDataBox = await Hive.openBox<UserDataEntity>('userData_box');
  }

  @override
  Future<void> saveUser({required UserEntity user}) async {
    await userBox.clear();
    savedUserIndex = await userBox.add(user);
  }

  @override
  Future<UserEntity?> retrieveSavedUser() async {
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
  }

  @override
  Future<void> clear() async {
    // await
    // // Полное удаление коробок с диска
    await userBox.clear();
    await chatBox.clear();
    await whoopDataBox.clear();
    // await userDataBox.clear();

    await userBox.close();
    await chatBox.close();
    await whoopDataBox.close();
    // await userDataBox.close();

    // // Повторно открываем коробки
    userBox = await Hive.openBox<UserEntity>('user_box');
    chatBox = await Hive.openBox<ChatSnapshotEntity>('chat_box');
    whoopDataBox = await Hive.openBox<WhoopDataEntity>('whoop_box');
    // userDataBox = await Hive.openBox<UserDataEntity>('userData_box');
  }

  @override
  Future<void> saveChatSnapshot({required ChatSnapshotEntity snapshot}) async {
    await chatBox.add(snapshot);
  }

  @override
  Future<ChatSnapshotEntity?> retrieveLastChat() async {
    if (chatBox.isEmpty) {
      return null;
    }
    final int last = chatBox.length - 1;
    return chatBox.getAt(last);
  }

  @override
  Future<void> saveWhoopData({required WhoopDataEntity data}) async {
    await whoopDataBox.add(data);
  }

  @override
  Future<WhoopDataEntity?> retrieveLastData() async {
    if (whoopDataBox.isEmpty) {
      return null;
    }
    final int last = whoopDataBox.length - 1;
    return whoopDataBox.getAt(last);
  }

  @override
  Future<void> saveUserData({required UserDataEntity dataEntity}) async {
    if (userDataBox.isEmpty) {
      final index = await userDataBox.add(dataEntity);
      log('SAVED AT $index');
      return;
    } else {
      int indexOfLast = 0;
      final listEntities = userDataBox.values.toList();

      for (var data in listEntities) {
        if (data.userId == dataEntity.userId) {
          indexOfLast = listEntities.indexOf(data);
          break;
        } else {
          indexOfLast = 0;
        }
      }

      await userDataBox.putAt(indexOfLast, dataEntity);
      log('SAVED AT $indexOfLast');
      return;
    }
  }

  @override
  Future<UserDataEntity?> fetchUserDataEntity({required String userId}) async {
    if (userDataBox.isEmpty) {
      log('NO USER DATA FOUND');
      return null;
    }
    UserDataEntity? last;
    final listEntities = userDataBox.values.toList().reversed;

    for (var data in listEntities) {
      if (data.userId == userId) {
        last = data;
      }
    }

    return last;
  }

  @override
  Future<void> disconnectWhoop() async {
    await whoopDataBox.clear();
    await userDataBox.clear();
  }

  @override
  Future<void> refreshChat() async {
    await chatBox.clear();
  }
}
