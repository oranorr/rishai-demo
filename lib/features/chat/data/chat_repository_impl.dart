// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';
import 'package:rishai/features/user/domain/repositories/user_repository.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

final chatRepo = getIt.get<ChatRepository>();

@Singleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;

  final HiveRepo hive;
  // final Directus directus;
  final UserRepository userRepo;

  bool _isSaving = false;
  ChatSnapshotEntity? _lastSavedSnap;

  ChatRepositoryImpl({
    required this.hive,
    required this.remote,
    // required this.directus,
    required this.userRepo,
  });

  @override
  Future<void> saveChatSnapShot({
    required ChatSnapshotEntity chatSnap,
    DateTime? date,
  }) async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      // Проверяем, действительно ли изменились данные
      if (_lastSavedSnap != null &&
          listEquals(_lastSavedSnap!.messages, chatSnap.messages) &&
          _lastSavedSnap!.requestsLeft == chatSnap.requestsLeft &&
          _lastSavedSnap!.mealPlan == chatSnap.mealPlan) {
        log('No changes detected in chat snapshot, skipping save');
        return;
      }

      // Сохраняем в локальное хранилище
      await hive.saveChatSnapshot(chatSnap, date);
      _lastSavedSnap = chatSnap;

      // Если есть план питания и пользователь авторизован, обновляем в Directus
      if (chatSnap.mealPlan != null && userBloc.state.user.directusId != '-1') {
        final currentDay = whoopBloc.state.day;
        if (currentDay.mealPlanEntity == chatSnap.mealPlan &&
            currentDay.snap.messages == chatSnap.messages &&
            currentDay.snap.requestsLeft == chatSnap.requestsLeft) {
          log('No changes detected in chat snapshot, skipping update');
          return;
        }

        final res = await userRepo.updateDayWithMealPlan(
          userId: userBloc.state.user.directusId,
          snapshot: chatSnap,
          mealPlan: chatSnap.mealPlan!,
        );

        res.fold(
          (failure) => log('Failed to update day with meal plan: $failure'),
          (_) => log('Successfully updated day with meal plan'),
        );
      } else {
        log('User not authorized. User: ${userBloc.state.user}');
      }
    } catch (e) {
      log('Error saving chat snapshot: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  Future<Either<Failure, MealPlanEntity>> requestMealPlan({
    required RequestPlanParams params,
  }) async {
    try {
      final res = await remote.requestMealPlan(
        params.generatePrompt(),
        params.isWeekPlan,
      );

      // Проверяем наличие ошибки в ответе
      if (res.containsKey('error')) {
        return Left(ChatGptRequestMealFailures(res['error']));
      }

      // Проверяем что ответ не пустой и содержит необходимые данные
      if (res.isEmpty || !res.containsKey('meals') || res['meals'] == null) {
        return const Left(
          ChatGptRequestMealFailures(
            'Received empty or invalid response from assistant',
          ),
        );
      }

      // Проверяем что массив meals не пустой
      final meals = res['meals'] as List?;
      if (meals == null || meals.isEmpty) {
        return const Left(
          ChatGptRequestMealFailures('No meals were generated'),
        );
      }

      try {
        final mealPlan = MealPlanEntity.fromMap({
          ...res,
          'cycleId': whoopBloc.state.day.cycleId,
        });
        // Дополнительная проверка что план содержит блюда
        if (mealPlan.meals.isEmpty) {
          return const Left(
            ChatGptRequestMealFailures('Generated meal plan is empty'),
          );
        }
        return Right(mealPlan);
      } catch (e) {
        log('Error parsing meal plan: $e');
        return Left(
          ChatGptRequestMealFailures('Failed to parse meal plan: $e'),
        );
      }
    } catch (e) {
      log('Error requesting meal plan: $e');
      return Left(
        ChatGptRequestMealFailures('Failed to generate meal plan: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> initGpt(String? threadId) async {
    bool res = await remote.initGpt(threadId);
    return res ? const Right(null) : const Left(UnknownFailure());
  }

  @override
  Future<Either<Failure, String>> sendMessage(String userMessage) async {
    final res = await remote.sendMessage(userMessage);
    if (res == null) {
      return const Left(UnknownFailure());
    } else {
      return Right(res);
    }
  }

  @override
  Future<Either<Failure, ChatSnapshotEntity?>> fetchSavedSnap({
    required String directusId,
    DateTime? targetDate,
    bool forceUpdate = false,
  }) async {
    try {
      final date = targetDate ?? DateTime.now();
      final dateKey = date.toIso8601String().substring(0, 10);

      if (!forceUpdate) {
        ChatSnapshotEntity? snap = hive.chatBox.get(dateKey);
        if (snap != null) {
          return Right(snap);
        }
      }

      final map = await remote.fetchLastChatSnap(directusId, date);
      print('map: $map');
      if (map != null && map.isNotEmpty) {
        final serverSnap = ChatSnapshotEntity.fromDirectus(map);
        await saveChatSnapShot(chatSnap: serverSnap, date: date);
        print('serverSnap: ${serverSnap.mealPlan?.meals.first.title}');
        return Right(serverSnap);
      }

      await hive.chatBox.delete(dateKey);
      return const Right(null);
    } catch (e) {
      log('Error fetching chat snapshot: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<void> updateChatCache({
    required String directusId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      await fetchSavedSnap(
        directusId: directusId,
        targetDate: currentDate,
        forceUpdate: true,
      );
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  @override
  Future<Either<Failure, Meal>> replaceMeal({
    required ReplaceMealParams params,
  }) async {
    try {
      final res = await remote.replaceMeal(params);
      if (res == null) {
        return const Left(UnknownFailure());
      } else {
        return Right(res);
      }
    } on Exception catch (e) {
      log(e.toString());
      return const Left(FailureReplaceMeal());
    }
  }

  @override
  Future<Either<Failure, Meal>> replaceIngredient({
    required ReplaceIngredientParams params,
  }) async {
    try {
      final res = await remote.replaceIngredient(params);
      if (res == null) {
        return const Left(UnknownFailure());
      } else {
        return Right(res);
      }
    } on Exception catch (e) {
      log(e.toString());
      return const Left(FailureReplaceMeal());
    }
  }
}
