// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/services/user_service/task_status.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
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
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:uuid/uuid.dart';

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
    bool quietLogs = false,
  }) async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      if (!quietLogs) {
        log(
          'Сохранение снапшота чата: ${chatSnap.messages.length} сообщений, ${chatSnap.requestsLeft} запросов осталось',
        );
      }

      // Проверяем, действительно ли изменились данные
      if (_lastSavedSnap != null &&
          listEquals(_lastSavedSnap!.messages, chatSnap.messages) &&
          _lastSavedSnap!.requestsLeft == chatSnap.requestsLeft &&
          _lastSavedSnap!.mealPlan == chatSnap.mealPlan) {
        if (!quietLogs) {
          log('Изменений в снапшоте чата не обнаружено, пропускаем сохранение');
        }
        return;
      }

      // Сохраняем в локальное хранилище
      await hive.saveChatSnapshot(chatSnap, date);
      _lastSavedSnap = chatSnap;
      if (!quietLogs) {
        log('Снапшот чата сохранен в локальное хранилище');
      }

      // Если есть план питания и пользователь авторизован, обновляем в Directus
      if (chatSnap.mealPlan != null && userBloc.state.user.directusId != '-1') {
        final currentDay = whoopBloc.state.day;
        if (currentDay.mealPlanEntity == chatSnap.mealPlan &&
            currentDay.snap.messages == chatSnap.messages &&
            currentDay.snap.requestsLeft == chatSnap.requestsLeft) {
          if (!quietLogs) {
            log(
              'Изменений в снапшоте чата не обнаружено, пропускаем обновление в Directus',
            );
          }
          return;
        }

        final res = await userRepo.updateDayWithMealPlan(
          userId: userBloc.state.user.directusId,
          snapshot: chatSnap,
          mealPlan: chatSnap.mealPlan!,
        );

        res.fold(
          (failure) =>
              log('Не удалось обновить день с планом питания: $failure'),
          (_) {
            if (!quietLogs) {
              log('День с планом питания успешно обновлен в Directus');
            }
          },
        );
      } else {
        if (!quietLogs) {
          log(
            'Пользователь не авторизован или нет плана питания. Пользователь: ${userBloc.state.user}',
          );
        }
      }
    } catch (e) {
      log('Ошибка при сохранении снапшота чата: $e');
    } finally {
      _isSaving = false;
    }
  }

  @override
  @Deprecated(
    'Legacy client-side orchestration. Use requestDailyMealPlanViaTask (async tasks) for daily plans.',
  )
  Future<Either<Failure, MealPlanEntity>> requestMealPlanV2({
    required RequestPlanParams params,
  }) async {
    try {
      log('[requestMealPlanV2] Начинаем генерацию плана питания с новой структурой API');

      // Генерируем запросы блюд с новой структурой
      final mealRequests = params.generateMealRequestsV2();

      log('[requestMealPlanV2] Сгенерировано ${mealRequests.length} запросов блюд');
      for (int i = 0; i < mealRequests.length; i++) {
        final request = mealRequests[i];
        log('[requestMealPlanV2] Запрос ${i + 1}: ${request.type.name} с ${request.meals.length} блюдами');
      }

      // Отправляем запросы через новый метод remote data source
      final res = await remote.requestMealPlanV2(
        mealRequests,
        params.isWeekPlan,
      );

      // Проверяем наличие ошибки в ответе
      if (res.containsKey('error')) {
        log('[requestMealPlanV2] Ошибка в ответе: ${res['error']}');
        return Left(ChatGptRequestMealFailures(res['error']));
      }

      // Проверяем что ответ не пустой и содержит необходимые данные
      if (res.isEmpty || !res.containsKey('meals') || res['meals'] == null) {
        log('[requestMealPlanV2] Получен пустой или некорректный ответ от ассистента');
        return const Left(
          ChatGptRequestMealFailures(
            'Received empty or invalid response from assistant',
          ),
        );
      }

      // Проверяем что массив meals не пустой
      final meals = res['meals'] as List?;
      if (meals == null || meals.isEmpty) {
        log('[requestMealPlanV2] Не сгенерированы блюда');
        return const Left(
          ChatGptRequestMealFailures('No meals were generated'),
        );
      }

      try {
        log('[requestMealPlanV2] Парсим план питания с ${meals.length} блюдами');

        final mealPlan = MealPlanEntity.fromMap({
          ...res,
          'cycleId': whoopBloc.state.day.cycleId,
        });

        // Дополнительная проверка что план содержит блюда
        if (mealPlan.meals.isEmpty) {
          log('[requestMealPlanV2] Сгенерированный план питания пуст');
          return const Left(
            ChatGptRequestMealFailures('Generated meal plan is empty'),
          );
        }

        log('[requestMealPlanV2] Успешно создан план питания с ${mealPlan.meals.length} блюдами');
        return Right(mealPlan);
      } catch (e) {
        log('[requestMealPlanV2] Ошибка парсинга плана питания: $e');
        return Left(
          ChatGptRequestMealFailures('Failed to parse meal plan: $e'),
        );
      }
    } catch (e) {
      log('[requestMealPlanV2] Ошибка запроса плана питания: $e');
      return Left(
        ChatGptRequestMealFailures('Failed to generate meal plan: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MealPlanEntity>> requestDailyMealPlanViaTask({
    required RequestPlanParams params,
  }) async {
    if (params.isWeekPlan) {
      return const Left(
        ChatGptRequestMealFailures(
          'Weekly plan is not supported via async tasks in this migration',
        ),
      );
    }

    final userId = userBloc.state.user.directusId;
    if (userId == '-1') {
      return const Left(
        ChatGptRequestMealFailures('User is not authorized'),
      );
    }

    final userServiceClient = getIt.get<UserServiceClient>();

    try {
      log('[requestDailyMealPlanViaTask] Генерируем requests',
          name: 'ChatRepository');
      final mealRequests = params.generateMealRequestsV2();
      if (mealRequests.isEmpty) {
        return const Left(
          ChatGptRequestMealFailures('No meal requests were generated'),
        );
      }

      final input = <String, dynamic>{
        'requests': mealRequests.map((r) => r.toJson()).toList(),
      };

      final idempotencyClientKey = const Uuid().v4();

      log(
        '[requestDailyMealPlanViaTask] enqueue daily_meal_plan (requests=${mealRequests.length})',
        name: 'ChatRepository',
      );

      final enqueueRes = await userServiceClient.enqueueTask(
        userId: userId,
        type: 'daily_meal_plan',
        input: input,
        idempotencyClientKey: idempotencyClientKey,
      );

      final taskId =
          (enqueueRes['taskId'] as String?) ?? (enqueueRes['id'] as String?);
      if (taskId == null || taskId.isEmpty) {
        return const Left(
          ChatGptRequestMealFailures('Backend did not return taskId'),
        );
      }

      final task = await _pollDailyMealPlanTask(
        userServiceClient: userServiceClient,
        userId: userId,
        taskId: taskId,
        idempotencyClientKey: idempotencyClientKey,
        input: input,
      );

      if (task.status == TaskStatus.failed) {
        return Left(
          ChatGptRequestMealFailures(task.errorMessage ?? 'Task failed'),
        );
      }

      final outputMealPlan = task.output?['mealPlan'];
      if (outputMealPlan is! Map<String, dynamic>) {
        return const Left(
          ChatGptRequestMealFailures(
            'Task done but output.mealPlan is missing or invalid',
          ),
        );
      }

      try {
        final mealPlan = MealPlanEntity.fromMap(outputMealPlan);
        if (mealPlan.meals.isEmpty) {
          return const Left(
            ChatGptRequestMealFailures('Generated meal plan is empty'),
          );
        }
        return Right(mealPlan);
      } catch (e) {
        return Left(
          ChatGptRequestMealFailures('Failed to parse meal plan: $e'),
        );
      }
    } on UserServiceException catch (e) {
      return Left(ChatGptRequestMealFailures(e.message));
    } catch (e) {
      return Left(
          ChatGptRequestMealFailures('Failed to generate meal plan: $e'));
    }
  }

  Future<PublicTaskEntity> _pollDailyMealPlanTask({
    required UserServiceClient userServiceClient,
    required String userId,
    required String taskId,
    required String idempotencyClientKey,
    required Map<String, dynamic> input,
  }) async {
    final startedAt = DateTime.now();
    final maxDuration = const Duration(minutes: 2);
    final allowNotFoundFor = const Duration(seconds: 15);

    Duration delay = const Duration(seconds: 2);
    final maxDelay = const Duration(seconds: 5);

    bool reEnqueued = false;
    int attempt = 0;

    log(
      '[ChatRepository._pollDailyMealPlanTask] start poll taskId=$taskId userId=$userId allowNotFoundFor=${allowNotFoundFor.inSeconds}s maxDuration=${maxDuration.inSeconds}s delay=${delay.inMilliseconds}ms',
      name: 'ChatRepository',
    );

    while (true) {
      attempt += 1;
      PublicTaskEntity? task;
      try {
        final elapsedBefore = DateTime.now().difference(startedAt);
        log(
          '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt elapsed=${elapsedBefore.inMilliseconds}ms GET /tasks/$taskId',
          name: 'ChatRepository',
        );

        final raw = await userServiceClient.getTask(
          userId: userId,
          taskId: taskId,
        );
        task = PublicTaskEntity.fromMap(raw);

        log(
          '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt status=${task.status.name} type=${task.type} outputKeys=${task.output?.keys.toList()}',
          name: 'ChatRepository',
        );
      } on UserServiceException catch (e) {
        final elapsed = DateTime.now().difference(startedAt);

        log(
          '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt UserServiceException statusCode=${e.statusCode} code=${e.code} msg=${e.message} elapsed=${elapsed.inMilliseconds}ms',
          name: 'ChatRepository',
        );

        // Наблюдали в проде ситуацию: enqueue вернул taskId,
        // но первый GET /tasks/:id какое-то время отвечает 404,
        // хотя задача на backend уже существует/выполняется.
        // Поэтому даём небольшой «grace period» на eventual consistency.
        if (e.statusCode == 404 && elapsed < allowNotFoundFor) {
          log(
            '[requestDailyMealPlanViaTask] GET /tasks/$taskId пока 404 (elapsed=${elapsed.inSeconds}s), продолжаем поллинг',
            name: 'ChatRepository',
          );
        } else if (e.statusCode == 404) {
          // В некоторых окружениях/версиях backend публичный GET /tasks/:id может
          // отдавать 404 даже для реально существующей задачи (например, из-за
          // расхождений доступа/проекции). При этом воркер уже может записать day.
          // Чтобы не ломать UX — делаем fallback на источник правды: GET /days/current.
          try {
            log(
              '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt fallback GET /days/current (forceRefresh=true)',
              name: 'ChatRepository',
            );
            final rawDay = await userServiceClient.getCurrentDay(
              userId: userId,
              forceRefresh: true,
            );
            final day = DayEntity.fromMap(rawDay);
            final mealPlan = day.mealPlanEntity;
            if (mealPlan != null && mealPlan.meals.isNotEmpty) {
              log(
                '[requestDailyMealPlanViaTask] GET /tasks/$taskId 404, но day.mealPlan уже есть — считаем done',
                name: 'ChatRepository',
              );
              return PublicTaskEntity(
                taskId: taskId,
                type: 'daily_meal_plan',
                status: TaskStatus.done,
                output: {
                  'mealPlan': mealPlan.toMap(),
                },
              );
            }

            log(
              '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt fallback: day.mealPlan отсутствует/пустой, продолжаем поллинг',
              name: 'ChatRepository',
            );
          } catch (fallbackError) {
            log(
              '[requestDailyMealPlanViaTask] fallback GET /days/current failed: $fallbackError',
              name: 'ChatRepository',
            );
          }
        } else {
          return PublicTaskEntity(
            taskId: taskId,
            type: 'daily_meal_plan',
            status: TaskStatus.failed,
            error: {
              'message': e.message,
              'code': e.code,
              'statusCode': e.statusCode,
            },
            output: null,
          );
        }
      } catch (e) {
        log(
          '[ChatRepository._pollDailyMealPlanTask] attempt=$attempt unexpected error: $e',
          name: 'ChatRepository',
        );
        return PublicTaskEntity(
          taskId: taskId,
          type: 'daily_meal_plan',
          status: TaskStatus.failed,
          error: {'message': e.toString()},
          output: null,
        );
      }

      if (task != null &&
          (task.status == TaskStatus.done ||
              task.status == TaskStatus.failed)) {
        final elapsedDone = DateTime.now().difference(startedAt);
        log(
          '[ChatRepository._pollDailyMealPlanTask] finish attempt=$attempt status=${task.status.name} elapsed=${elapsedDone.inMilliseconds}ms',
          name: 'ChatRepository',
        );
        return task;
      }

      final elapsed = DateTime.now().difference(startedAt);
      if (!reEnqueued &&
          task?.status == TaskStatus.pending &&
          elapsed >= const Duration(seconds: 45)) {
        reEnqueued = true;
        try {
          log(
            '[ChatRepository._pollDailyMealPlanTask] pending долго, пробуем re-enqueue taskId=$taskId attempt=$attempt elapsed=${elapsed.inSeconds}s idempotencyClientKey=$idempotencyClientKey',
            name: 'ChatRepository',
          );
          await userServiceClient.enqueueTask(
            userId: userId,
            type: 'daily_meal_plan',
            input: input,
            idempotencyClientKey: idempotencyClientKey,
          );
        } catch (e) {
          log(
            '[ChatRepository._pollDailyMealPlanTask] re-enqueue не удался: $e',
            name: 'ChatRepository',
          );
        }
      }

      if (elapsed >= maxDuration) {
        log(
          '[ChatRepository._pollDailyMealPlanTask] timeout taskId=$taskId attempt=$attempt elapsed=${elapsed.inSeconds}s',
          name: 'ChatRepository',
        );
        return PublicTaskEntity(
          taskId: taskId,
          type: 'daily_meal_plan',
          status: TaskStatus.failed,
          error: const {'message': 'Task polling timed out'},
          output: null,
        );
      }

      log(
        '[ChatRepository._pollDailyMealPlanTask] sleep delay=${delay.inMilliseconds}ms attempt=$attempt',
        name: 'ChatRepository',
      );
      await Future<void>.delayed(delay);
      final nextMs = (delay.inMilliseconds * 1.2).round();
      delay = Duration(milliseconds: nextMs).compareTo(maxDelay) > 0
          ? maxDelay
          : Duration(milliseconds: nextMs);
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
    bool quietLogs = false,
  }) async {
    try {
      final date = targetDate ?? DateTime.now();
      final dateKey = date.toIso8601String().substring(0, 10);

      if (!quietLogs) {
        log('Загрузка снапшота чата для даты: $dateKey');
      }

      // Проверяем локальные данные с защитой от ошибок схемы
      ChatSnapshotEntity? localSnap;
      try {
        localSnap = hive.chatBox.get(dateKey);
        if (!quietLogs) {
          log(
            'Локальный снапшот ${localSnap != null ? 'найден' : 'не найден'}',
          );
        }
      } on Exception catch (e) {
        log('Ошибка при чтении локального снапшота: $e');
        // При ошибке чтения локальных данных продолжаем работу с сервером
        localSnap = null;
      }

      if (!forceUpdate && localSnap != null) {
        if (!quietLogs) {
          log(
            'Загружен снапшот из локального хранилища: ${localSnap.messages.length} сообщений',
          );
        }
        return Right(localSnap);
      }

      // Если локальных данных нет или требуется принудительное обновление, загружаем с сервера
      final map = await remote.fetchLastChatSnap(directusId, date);
      if (!quietLogs) {
        log('Получены данные с сервера: $map');
      }

      if (map != null && map.isNotEmpty) {
        final serverSnap = ChatSnapshotEntity.fromDirectus(map);

        // Если есть локальные данные с сообщениями, объединяем их с серверными данными
        if (localSnap != null && localSnap.messages.isNotEmpty) {
          if (!quietLogs) {
            log(
              'Объединяем локальные сообщения (${localSnap.messages.length}) с серверными данными',
            );
          }
          final combinedSnap = serverSnap.copyWith(
            messages: localSnap.messages,
            requestsLeft: localSnap.requestsLeft,
          );
          await saveChatSnapShot(
            chatSnap: combinedSnap,
            date: date,
            quietLogs: quietLogs,
          );
          return Right(combinedSnap);
        } else {
          if (!quietLogs) {
            log(
              'Используем только серверные данные (сообщений: ${serverSnap.messages.length})',
            );
          }
          await saveChatSnapShot(
            chatSnap: serverSnap,
            date: date,
            quietLogs: quietLogs,
          );
          return Right(serverSnap);
        }
      }

      // Если серверных данных нет, но есть локальные, возвращаем локальные
      if (localSnap != null) {
        if (!quietLogs) {
          log(
            'Серверных данных нет, используем локальные: ${localSnap.messages.length} сообщений',
          );
        }
        return Right(localSnap);
      }

      // Если данных нет вообще, удаляем ключ и возвращаем null
      await hive.chatBox.delete(dateKey);
      if (!quietLogs) {
        log('Данных чата не найдено');
      }
      return const Right(null);
    } catch (e) {
      log('Ошибка при загрузке снапшота чата: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<void> updateChatCache({
    required String directusId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // [updateChatCache] Раньше шли в цикле по [startDate..endDate], но
    // `RemoteDataSource.fetchLastChatSnap` сейчас **игнорирует дату** и всегда
    // тянет только **текущий** день с backend (`getLastDayWithCycleStatus`).
    // В результате при pull-to-refresh мы N раз дергали один и тот же ответ,
    // писали его в Hive под разными ключами и столько же раз делали PATCH
    // `/days/current` — отсюда «ебучее количество» одинаковых запросов и долгий UI.
    //
    // Пока нет API «чат-снапшот / день по calendar date», достаточно одного
    // принудительного обновления на конец интервала (у вызывающего это `now`).
    await fetchSavedSnap(
      directusId: directusId,
      targetDate: endDate,
      forceUpdate: true,
      // Один запрос вместо недельного цикла — логи не дублируем на каждый день.
      quietLogs: true,
    );
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

  /// Новые методы для регенерации блюд с использованием новой структуры API V2

  @override
  Future<Either<Failure, Meal>> replaceMealV2({
    required ReplaceMealParams params,
  }) async {
    try {
      log('[ChatRepository.replaceMealV2] Начинаем замену блюда через V2 API');
      final res = await remote.replaceMealV2(params);
      if (res == null) {
        log('[ChatRepository.replaceMealV2] Получен null результат');
        return const Left(UnknownFailure());
      } else {
        log('[ChatRepository.replaceMealV2] Успешно заменили блюдо: ${res.title}');
        return Right(res);
      }
    } on Exception catch (e) {
      log('[ChatRepository.replaceMealV2] Ошибка: $e');
      return const Left(FailureReplaceMeal());
    }
  }

  @override
  Future<Either<Failure, Meal>> replaceIngredientV2({
    required ReplaceIngredientParams params,
  }) async {
    try {
      log('[ChatRepository.replaceIngredientV2] Начинаем замену ингредиентов через V2 API');
      final res = await remote.replaceIngredientV2(params);
      if (res == null) {
        log('[ChatRepository.replaceIngredientV2] Получен null результат');
        return const Left(UnknownFailure());
      } else {
        log('[ChatRepository.replaceIngredientV2] Успешно заменили ингредиенты в блюде: ${res.title}');
        return Right(res);
      }
    } on Exception catch (e) {
      log('[ChatRepository.replaceIngredientV2] Ошибка: $e');
      return const Left(FailureReplaceMeal());
    }
  }
}
