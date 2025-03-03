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
import 'package:rishai/features/chat/data/chat_repository_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart';
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

int totalRequests = 5;

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
          ChatMainState(
            status: Status.initial,
            messages: [],
            requestsLeft: totalRequests,
            mealPlan: null,
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
  }
  final InitGptUsecase initGptUsecase;
  final RequestPlanUsecase requestMealPlan;
  final SendMessageGptUsecase sendMessageGptUsecase;
  final FetchSavedSnapUsecase fetchSavedSnapUsecase;
  final ReplaceMealUsecase replaceMealUsecase;
  final ReplaceIngredientUsecase replaceIngredientUsecase;

  bool get isRegenAvailable => kDebugMode
      ? true
      : (state.mealPlan != null &&
          !state.mealPlan!.meals.any((meal) => meal.isRegenerated));

  FutureOr<void> _init(InitChatBloc event, Emitter<ChatState> emit) async {
    final res = await fetchSavedSnapUsecase.call(
      FetchSavedSnapParams(directusId: userBloc.state.user.directusId),
    );

    String? threadId;

    res.fold(
      (left) {
        // Handle error if necessary
      },
      (snap) {
        if (snap != null) {
          log('requests left: ${snap.requestsLeft}');
          emit(
            state.copyWith(
              messages: snap.messages,
              requestsLeft: snap.requestsLeft,
              mealPlan: snap.mealPlan,
            ),
          );
          threadId = snap.threadId;
          log('requests left: ${state.requestsLeft}');
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
        userBloc.add(
          UserManageDay(
            day: whoopBloc.state.day.copyWith(
              snap: ChatSnapshotEntity(
                messages: [],
                date: DateTime.now(),
                requestsLeft: state.requestsLeft,
                threadId: chatRemoteSrc.threadId,
              ),
            ),
          ),
        );
      });
    }

    emit(state.copyWith(messages: list));
    add(ChatSaveSnap());
  }

  FutureOr<void> _createMealPlan(
    CreateMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final user = userBloc.state.user;
    final res = await requestMealPlan.call(
      RequestPlanParams(
        restrictions: user.foodPreferences!.restrictions,
        dietary: user.foodPreferences!.diets,
        cuisines: user.foodPreferences!.cuisines,
        calorieTarget: whoopBloc.state.day.macros.kcal,
        macros: whoopBloc.state.day.macros,
        trainingToday: event.trainingToday,
        servings: event.meals,
        snackForToday: event.snackToday,
        isWeekPlan: false,
      ),
    );
    res.fold((failure) {
      emit(state.copyWith(status: Status.error));
    }, (plan) {
      emit(
        state.copyWith(
          mealPlan: plan,
          requestsLeft: state.requestsLeft - 1,
          status: Status.success,
        ),
      );
      add(
        const ChatSendMessage(
          text: 'Your meal plan is ready. Check it out.',
          isMe: false,
        ),
      );
      whoopBloc.add(WhoopUpdateDayByMealPlan(mealPlanEntity: plan));
    });
    add(ChatSaveSnap());
  }

  FutureOr<void> _saveSnap(ChatSaveSnap event, Emitter<ChatState> emit) async {
    final chatSnap = ChatSnapshotEntity(
      messages: state.messages,
      date: DateTime.now(),
      requestsLeft: state.requestsLeft,
      mealPlan: state.mealPlan,
      threadId: chatRemoteSrc.threadId,
    );
    await chatRepo.saveChatSnapShot(chatSnap: chatSnap);
  }

  FutureOr<void> _deleteMealPlan(
    ChatDeleteMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        mealPlan: null,
        requestsLeft: 5,
        messages: [],
      ),
    );
    add(ChatSaveSnap());
  }

  FutureOr<void> _fetchLatsPlan(
    ChatFetchLastMealPlan event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(mealPlan: event.day.mealPlanEntity));
  }

  FutureOr<void> _chatOnLogout(
    ChatOnLogout event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        messages: [],
        requestsLeft: event.needsCounterClear ? 5 : state.requestsLeft,
        mealPlan: null,
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
        requestsLeft: event.needsRequestsAmountRefresh ? 5 : state.requestsLeft,
        mealPlan: null,
      ),
    );
  }

  FutureOr<void> _replaceMeal(
    ChatReplaceMeal event,
    Emitter<ChatState> emit,
  ) async {
    add(
      ChatSendMessage(
        text: 'I want to replace ${event.meal.title} to something else',
        isMe: true,
      ),
    );
    emit(state.copyWith(status: Status.loading));
    final user = userBloc.state.user;
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
    }, (meal) {
      final updatedMeals = state.mealPlan!.meals.map((m) {
        return m.servingType == meal.servingType ? meal : m;
      }).toList();

      final updatedMealPlan = state.mealPlan!.copyWith(meals: updatedMeals);

      emit(
        state.copyWith(
          mealPlan: updatedMealPlan,
          status: Status.success,
        ),
      );
      add(
        const ChatSendMessage(
          text: 'Your meal plan is updated. Check it out.',
          isMe: false,
        ),
      );
      whoopBloc.add(WhoopUpdateDayByMealPlan(mealPlanEntity: updatedMealPlan));
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

    res.fold(
      (l) {
        emit(state.copyWith(status: Status.error));
        add(
          const ChatSendMessage(
            text: 'Sorry, failed to replace ingredients. Please try again.',
            isMe: false,
          ),
        );
        appNavigationService
          ..pop(path: AppRoutes.homeScreen.path)
          ..pop(path: AppRoutes.homeScreen.path);
        RishSnackbar()
            .showSnackBar('Failed to replace ingredient, please try again.');
      },
      (meal) {
        final updatedMeals = state.mealPlan!.meals.map((m) {
          return m.servingType == meal.servingType ? meal : m;
        }).toList();

        final updatedMealPlan = state.mealPlan!.copyWith(meals: updatedMeals);

        emit(
          state.copyWith(
            mealPlan: updatedMealPlan,
            status: Status.success,
          ),
        );
        add(
          const ChatSendMessage(
            text: 'Your meal is updated. Check it out.',
            isMe: false,
          ),
        );
        whoopBloc
            .add(WhoopUpdateDayByMealPlan(mealPlanEntity: updatedMealPlan));
        appNavigationService
          ..pop(path: AppRoutes.homeScreen.path)
          ..pop(path: AppRoutes.homeScreen.path);
      },
    );
  }
}
