import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
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
  ) : super(
          const ChatMainState(
            status: Status.initial,
            messages: [],
            requestsLeft: defaultRequestsLimit,
            askedQuestions: {},
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

    String? threadId;
    List<MessageEntity> initialMessages = [];
    int initialRequestsLeft = defaultRequestsLimit;

    final res = await fetchSavedSnapUsecase.call(
      FetchSavedSnapParams(directusId: event.directusId),
    );

    res.fold(
      (left) {
        // Handle error if necessary
      },
      (snap) {
        if (snap != null) {
          // Load messages and requests from snap, but keep askedQuestions empty
          initialMessages = snap.messages ?? [];
          initialRequestsLeft = snap.requestsLeft ?? defaultRequestsLimit;
          threadId = snap.threadId;
        }
      },
    );

    // Emit the initial state with potentially loaded messages/requests
    // but always empty askedQuestions.
    emit(
      state.copyWith(
        messages: initialMessages,
        requestsLeft: initialRequestsLeft,
        askedQuestions: {},
      ),
    );

    await initGptUsecase.call(InitGptParams(threadId: threadId));
  }

  Set<String> get safeAskedQuestions => state.askedQuestions ?? {};

  FutureOr<void> _sendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    MessageEntity msg =
        MessageEntity(text: event.text, isMe: event.isMe ?? true);

    List<MessageEntity> list = List.from(state.messages);
    Set<String> currentAsked = Set.from(safeAskedQuestions);

    if (msg.text.isNotEmpty) {
      list.add(msg);
      // If it's a question prompt request, add it to askedQuestions
      if (event.isRequest ?? false) {
        currentAsked.add(event.text);
      }
      emit(state.copyWith(messages: list, askedQuestions: currentAsked));
    }

    if (event.isRequest ?? false) {
      emit(state.copyWith(status: Status.loading));
      final res = await sendMessageGptUsecase.call(event.text);
      res.fold((failure) {
        // On failure, remove the question from asked set so user can try again?
        // Or keep it asked? Let's keep it for now.
        // currentAsked.remove(event.text);
        emit(
          state.copyWith(
            status: Status.error, /*, askedQuestions: currentAsked*/
          ),
        );
      }, (result) {
        // Success, update state
        final responseMsg = MessageEntity(text: result, isMe: false);
        list.add(responseMsg); // Add response message
        emit(
          state.copyWith(
            status: Status.initial,
            messages: list,
            requestsLeft: state.requestsLeft - 1,
            // askedQuestions is already updated above
          ),
        );

        // Create snapshot (askedQuestions not included)
        final snap = _createSnapshot();

        // Update day via whoopBloc (passing snapshot without askedQuestions)
        if (whoopBloc.state.day.mealPlanEntity != null) {
          whoopBloc.add(
            WhoopUpdateDayByMealPlan(
              mealPlanEntity: whoopBloc.state.day.mealPlanEntity!,
              snapshot: snap,
            ),
          );
        } // else: What to do if there's no meal plan? Maybe still save snap?
      });
    } // else: If not a request, just update messages (already done above)
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
          await dayManager.createDay(day: updatedDay);

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
    // askedQuestions is not saved in the snapshot
    final chatSnap = _createSnapshot();
    await chat_repo.chatRepo.saveChatSnapShot(chatSnap: chatSnap);
  }

  FutureOr<void> _deleteMealPlan(
    ChatDeleteMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: Status.loading));

      // Clear chat state including askedQuestions
      emit(
        state.copyWith(
          requestsLeft: defaultRequestsLimit,
          messages: [],
          askedQuestions: {},
        ),
      );

      // Create new snapshot (without askedQuestions)
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
      // Load messages/requests from the day's snapshot
      // Reset askedQuestions as it's not persisted in the snapshot
      emit(
        state.copyWith(
          requestsLeft: event.day.snap.requestsLeft ?? state.requestsLeft,
          messages: event.day.snap.messages ?? state.messages,
          askedQuestions: {},
        ),
      );

      // Save snapshot (without askedQuestions)
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
    // Clear state including askedQuestions
    emit(
      state.copyWith(
        messages: [],
        requestsLeft:
            event.needsCounterClear ? defaultRequestsLimit : state.requestsLeft,
        status: Status.initial,
        askedQuestions: {},
      ),
    );
  }

  FutureOr<void> _refreshChat(
    ChatRefreshChat event,
    Emitter<ChatState> emit,
  ) async {
    await hive.refreshChat();
    // Clear askedQuestions on refresh
    emit(
      state.copyWith(
        messages: event.needsRequestsAmountRefresh ? [] : state.messages,
        requestsLeft: event.needsRequestsAmountRefresh
            ? defaultRequestsLimit
            : state.requestsLeft,
        askedQuestions: {},
      ),
    );
  }

  Future<void> _saveToDirectus(MealPlanEntity updatedMealPlan) async {
    final updatedDay = whoopBloc.state.day.copyWith(
      mealPlanEntity: updatedMealPlan,
    );
    await dayManager.createDay(day: updatedDay);
  }

  Future<void> _saveChanges(MealPlanEntity updatedMealPlan) async {
    // Сохраняем через DayManager (и в Hive, и в Directus)
    final updatedDay = whoopBloc.state.day.copyWith(
      mealPlanEntity: updatedMealPlan,
    );
    await dayManager.createDay(day: updatedDay);
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

    await res.fold((failure) {
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

      // Сохраняем изменения через DayManager
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

    await res.fold((failure) {
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

      // Сохраняем изменения через DayManager
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

      // Check if user is logged in
      if (userBloc.state.user.directusId == '-1') {
        if (!emit.isDone) {
          // Clear state including askedQuestions if logged out
          emit(
            state.copyWith(
              messages: [],
              requestsLeft: defaultRequestsLimit,
              askedQuestions: {},
            ),
          );
        }
        return;
      }

      // Get data from selected day's snapshot
      final newMessages = selectedDay.snap.messages ?? [];
      final newRequestsLeft =
          selectedDay.snap.requestsLeft ?? state.requestsLeft;

      // Always reset askedQuestions when syncing to a new day
      // Check if state needs updating (messages, requests, or non-empty askedQuestions)
      if (!listEquals(state.messages, newMessages) ||
          state.requestsLeft != newRequestsLeft ||
          safeAskedQuestions.isNotEmpty) {
        log('Синхронизация чата: обновляем состояние (сброс askedQuestions)');

        if (!emit.isDone) {
          emit(
            state.copyWith(
              messages: newMessages,
              requestsLeft: newRequestsLeft,
              askedQuestions: {},
            ),
          );
        }

        // Save snapshot (without askedQuestions)
        final chatSnap = _createSnapshot();
        await chat_repo.chatRepo.saveChatSnapShot(chatSnap: chatSnap);
      }
    });
  }
}
