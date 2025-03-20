import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/chat/data/chat_repository_impl.dart'
    as chat_repo;
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart'
    as chat_remote;
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/fetch_saved_snap_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/init_gpt_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/send_message_gpt_usecase.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';
import 'package:rishai/features/user/domain/usecases/manage_day_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'chat_event.dart';

final chatBloc = getIt.get<ChatBloc>();

const int totalRequests = 50;
const int defaultRequestsLimit = totalRequests;

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(
    this.initGptUsecase,
    this.requestMealPlan,
    this.sendMessageGptUsecase,
    this.fetchSavedSnapUsecase,
    this.replaceMealUsecase,
    this.replaceIngredientUsecase,
    this.manageDayUsecase,
  ) : super(
          const ChatMainState(
            status: Status.initial,
            messages: [],
            requestsLeft: defaultRequestsLimit,
          ),
        ) {
    on<ChatSendMessage>(_sendMessage);
    on<CreateMealPlan>(_createMealPlan);
    on<InitChatBloc>(_init);
    on<ChatSaveSnap>(_saveSnap);
    on<ChatDeleteMealPlan>(_deleteMealPlan);
    on<ChatFetchLastMealPlan>(_fetchLatsPlan);
    on<ChatOnLogout>(_chatOnLogout);
    on<ChatRefreshChat>(_refreshChat);
    on<ChatReplaceMeal>(_replaceMeal);
    on<ChatReplaceIngredient>(_replaceIngredient);
    on<ChatSyncWithSelectedDate>(_syncWithSelectedDate);
  }

  final InitGptUsecase initGptUsecase;
  final RequestPlanUsecase requestMealPlan;
  final SendMessageGptUsecase sendMessageGptUsecase;
  final FetchSavedSnapUsecase fetchSavedSnapUsecase;
  final ReplaceMealUsecase replaceMealUsecase;
  final ReplaceIngredientUsecase replaceIngredientUsecase;
  final ManageDayUsecase manageDayUsecase;

  Timer? _syncDebounceTimer;

  bool get isRegenAvailable => kDebugMode
      ? true
      : (whoopBloc.state.day.mealPlanEntity != null &&
          !whoopBloc.state.day.mealPlanEntity!.meals
              .any((meal) => meal.isRegenerated));

  ChatSnapshotEntity _createSnapshot() {
    return ChatSnapshotEntity(
      messages: state.messages,
      date: DateTime.now(),
      requestsLeft: state.requestsLeft,
      threadId: chat_remote.chatRemoteSrc.threadId,
    );
  }

  FutureOr<void> _init(InitChatBloc event, Emitter<ChatState> emit) async {
    if (event.directusId == '-1') return;

    final res = await fetchSavedSnapUsecase.call(
      FetchSavedSnapParams(directusId: event.directusId),
    );

    String? threadId;

    res.fold(
      (left) {
        // Handle error if necessary
      },
      (snap) {
        if (snap != null) {
          emit(
            state.copyWith(
              messages: snap.messages,
              requestsLeft: snap.requestsLeft,
            ),
          );
          threadId = snap.threadId;
        }
      },
    );

    await initGptUsecase.call(InitGptParams(threadId: threadId));
  }

  FutureOr<void> _sendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    MessageEntity msg =
        MessageEntity(text: event.text, isMe: event.isMe ?? true);

    List<MessageEntity> list = List.from(state.messages);

    if (msg.text.isNotEmpty) {
      list.add(msg);
      emit(state.copyWith(messages: list));
    }

    if (event.isRequest ?? false) {
      emit(state.copyWith(status: Status.loading));
      final res = await sendMessageGptUsecase.call(event.text);
      res.fold((failure) {
        emit(state.copyWith(status: Status.error));
      }, (result) {
        emit(state.copyWith(status: Status.initial));
        final msg = MessageEntity(text: result, isMe: false);
        list.add(msg);
        emit(state.copyWith(requestsLeft: state.requestsLeft - 1));

        // Создаем новый снэпшот
        final snap = _createSnapshot();

        // Обновляем день через whoopBloc
        whoopBloc.add(
          WhoopUpdateDayByMealPlan(
            mealPlanEntity: whoopBloc.state.day.mealPlanEntity!,
            snapshot: snap,
          ),
        );
      });
    }

    emit(state.copyWith(messages: list));
  }

  Future<void> _createMealPlan(
    CreateMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: Status.loading));

      final result = await requestMealPlan(
        RequestPlanParams(
          dietary: userBloc.state.user.foodPreferences?.diets ?? [],
          cuisines: userBloc.state.user.foodPreferences?.cuisines ?? [],
          restrictions: userBloc.state.user.foodPreferences?.restrictions ?? [],
          calorieTarget: whoopBloc.state.day.macros.kcal,
          macros: whoopBloc.state.day.macros,
          trainingToday: event.trainingToday,
          servings: event.meals,
          snackForToday: event.snackToday,
          isWeekPlan: false,
        ),
      );

      await result.fold(
        (failure) {
          emit(state.copyWith(status: Status.error));
          RishSnackbar().showSnackBar(failure.message);
        },
        (mealPlan) async {
          // Создаем снапшот чата
          final chatSnap = _createSnapshot();

          // Обновляем день с новым планом питания и снапшотом
          final updatedDay = whoopBloc.state.day.copyWith(
            mealPlanEntity: mealPlan,
            snap: chatSnap,
          );

          // Сохраняем обновленный день
          await hive.saveDay(data: updatedDay);

          // Немедленно обновляем в Directus
          await _saveToDirectus(mealPlan);

          // Обновляем состояние
          emit(
            state.copyWith(
              status: Status.success,
              requestsLeft: state.requestsLeft - 1,
            ),
          );

          // Обновляем состояние в WhoopBloc
          whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar(e.toString());
    }
  }

  FutureOr<void> _saveSnap(ChatSaveSnap event, Emitter<ChatState> emit) async {
    final chatSnap = _createSnapshot();

    await chat_repo.chatRepo.saveChatSnapShot(chatSnap: chatSnap);
  }

  FutureOr<void> _deleteMealPlan(
    ChatDeleteMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: Status.loading));

      // Очищаем состояние чата
      emit(
        state.copyWith(
          requestsLeft: defaultRequestsLimit,
          messages: [],
        ),
      );

      // Создаем новый снапшот без плана питания
      final chatSnap = ChatSnapshotEntity(
        messages: [],
        date: DateTime.now(),
        requestsLeft: defaultRequestsLimit,
        threadId: chat_remote.chatRemoteSrc.threadId,
      );

      // Создаем день без плана питания, сохраняя остальные данные
      final updatedDay = whoopBloc.state.day.copyWith(
        snap: chatSnap,
      );

      // Обновляем день в WhoopBloc
      whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));

      // Очищаем данные в Hive
      await hive.clearMealPlan();

      emit(state.copyWith(status: Status.success));
    } catch (e) {
      log('Error clearing meal plan: $e');
      emit(state.copyWith(status: Status.error));
      RishSnackbar()
          .showSnackBar('Failed to clear meal plan. Please try again.');
    }
  }

  Future<void> _fetchLatsPlan(
    ChatFetchLastMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Обновляем состояние с сообщениями и количеством запросов
      emit(
        state.copyWith(
          requestsLeft: event.day.snap.requestsLeft ?? state.requestsLeft,
          messages: event.day.snap.messages ?? state.messages,
        ),
      );

      // Сохраняем снапшот
      final chatSnap = _createSnapshot();
      await chat_repo.chatRepo.saveChatSnapShot(chatSnap: chatSnap);
    } catch (e) {
      RishSnackbar().showSnackBar(e.toString());
    }
  }

  FutureOr<void> _chatOnLogout(
    ChatOnLogout event,
    Emitter<ChatState> emit,
  ) async {
    // Просто очищаем состояние чата без создания нового снапшота
    emit(
      state.copyWith(
        messages: [],
        requestsLeft:
            event.needsCounterClear ? defaultRequestsLimit : state.requestsLeft,
        status: Status.initial,
      ),
    );
  }

  FutureOr<void> _refreshChat(
    ChatRefreshChat event,
    Emitter<ChatState> emit,
  ) async {
    await hive.refreshChat();
    emit(
      state.copyWith(
        messages: event.needsRequestsAmountRefresh ? [] : state.messages,
        requestsLeft: event.needsRequestsAmountRefresh
            ? defaultRequestsLimit
            : state.requestsLeft,
      ),
    );
  }

  Future<void> _saveToDirectus(MealPlanEntity updatedMealPlan) async {
    final updatedDay = whoopBloc.state.day.copyWith(
      mealPlanEntity: updatedMealPlan,
    );
    final data = updatedDay.toDirectus(userId: userBloc.state.user.directusId);
    await manageDayUsecase.call(
      ManageDayParams(
        userId: userBloc.state.user.directusId,
        dayMap: data,
        incomingDay: updatedDay,
      ),
    );
  }

  Future<void> _saveToHive(MealPlanEntity updatedMealPlan) async {
    final updatedDay = whoopBloc.state.day.copyWith(
      mealPlanEntity: updatedMealPlan,
    );
    await hive.saveDay(data: updatedDay);
  }

  Future<void> _saveChanges(MealPlanEntity updatedMealPlan) async {
    // Сохраняем в Hive
    await _saveToHive(updatedMealPlan);

    // Сохраняем в Directus
    await _saveToDirectus(updatedMealPlan);
  }

  FutureOr<void> _replaceMeal(
    ChatReplaceMeal event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final user = userBloc.state.user;
    if (user.foodPreferences == null) {
      emit(state.copyWith(status: Status.error));
      RishSnackbar().showSnackBar('Please set your food preferences first');
      return;
    }

    final res = await replaceMealUsecase.call(
      ReplaceMealParams(
        meal: event.meal,
        foodPreferences: user.foodPreferences!,
      ),
    );

    res.fold((failure) {
      emit(state.copyWith(status: Status.error));
      add(
        ChatSendMessage(
          text:
              'Sorry, failed to replace ${event.meal.title}. Please try again.',
          isMe: false,
        ),
      );
      appNavigationService.go(path: AppRoutes.homeScreen.path);
      RishSnackbar().showSnackBar('Failed to replace meal, try again.');
    }, (meal) async {
      final updatedMeals = whoopBloc.state.day.mealPlanEntity!.meals.map((m) {
        return m.servingType == meal.servingType ? meal : m;
      }).toList();

      final updatedMealPlan =
          whoopBloc.state.day.mealPlanEntity!.copyWith(meals: updatedMeals);

      emit(state.copyWith(status: Status.success));
      add(
        const ChatSendMessage(
          text: 'Your meal plan is updated. Check it out.',
          isMe: false,
        ),
      );
      whoopBloc.add(WhoopUpdateDayByMealPlan(mealPlanEntity: updatedMealPlan));

      // Сохраняем изменения в Hive и Directus
      await _saveChanges(updatedMealPlan);

      appNavigationService
        ..pop(path: AppRoutes.homeScreen.path)
        ..pop(path: AppRoutes.homeScreen.path);
    });
  }

  FutureOr<void> _replaceIngredient(
    ChatReplaceIngredient event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final res = await replaceIngredientUsecase.call(
      ReplaceIngredientParams(
        meal: event.meal,
        ingredients: event.ingredients,
        preferences: userBloc.state.user.foodPreferences!,
      ),
    );

    res.fold((failure) {
      emit(state.copyWith(status: Status.error));
      add(
        ChatSendMessage(
          text:
              'Sorry, failed to replace ingredients in ${event.meal.title}. Please try again.',
          isMe: false,
        ),
      );
      appNavigationService.go(path: AppRoutes.homeScreen.path);
      RishSnackbar().showSnackBar('Failed to replace ingredients, try again.');
    }, (meal) async {
      final updatedMeals = whoopBloc.state.day.mealPlanEntity!.meals.map((m) {
        return m.servingType == meal.servingType ? meal : m;
      }).toList();

      final updatedMealPlan =
          whoopBloc.state.day.mealPlanEntity!.copyWith(meals: updatedMeals);

      emit(state.copyWith(status: Status.success));
      add(
        const ChatSendMessage(
          text: 'Your meal plan is updated. Check it out.',
          isMe: false,
        ),
      );
      whoopBloc.add(WhoopUpdateDayByMealPlan(mealPlanEntity: updatedMealPlan));

      // Сохраняем изменения в Hive и Directus
      await _saveChanges(updatedMealPlan);

      appNavigationService
        ..pop(path: AppRoutes.homeScreen.path)
        ..pop(path: AppRoutes.homeScreen.path);
    });
  }

  FutureOr<void> _syncWithSelectedDate(
    ChatSyncWithSelectedDate event,
    Emitter<ChatState> emit,
  ) async {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (emit.isDone) return;

      final selectedDay = whoopBloc.state.day;

      // Проверяем, что пользователь авторизован
      if (userBloc.state.user.directusId == '-1') {
        if (!emit.isDone) {
          emit(
            state.copyWith(
              messages: [],
              requestsLeft: defaultRequestsLimit,
            ),
          );
        }
        return;
      }

      // Проверяем, нужно ли обновлять состояние
      final currentMessages = state.messages;
      final newMessages = selectedDay.snap.messages ?? [];
      final currentRequestsLeft = state.requestsLeft;
      final newRequestsLeft =
          selectedDay.snap.requestsLeft ?? state.requestsLeft;

      // Обновляем состояние только если есть реальные изменения
      if (!listEquals(currentMessages, newMessages) ||
          currentRequestsLeft != newRequestsLeft) {
        log('Синхронизация чата: обновляем состояние с новыми данными');

        if (!emit.isDone) {
          emit(
            state.copyWith(
              messages: newMessages,
              requestsLeft: newRequestsLeft,
            ),
          );
        }

        // Сохраняем снапшот в кэш только если есть изменения
        final chatSnap = _createSnapshot();
        await chat_repo.chatRepo.saveChatSnapShot(chatSnap: chatSnap);
      }
    });
  }
}
