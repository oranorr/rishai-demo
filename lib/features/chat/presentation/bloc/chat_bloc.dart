import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/constants/constants.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/data/chat_repository_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source_impl.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';
import 'package:rishai/features/chat/domain/usecases/fetch_savedSnap_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/init_gpt_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/send_message_gpt_usecase.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'chat_event.dart';

final chatBloc = getIt.get<ChatBloc>();

int totalRequests = 5;
// int totalRequests = kDebugMode ? 5000 : 5;
Map<String, dynamic> map = {
  "meals": [
    {
      "title": "Scrambled Eggs with Spinach and Avocado",
      "type": "Meal 1",
      "description":
          "Start your day with a hearty breakfast of scrambled eggs mixed with fresh spinach and creamy avocado. This meal provides a great source of protein, healthy fats and leafy greens to fuel your morning. The eggs are rich in essential nutrients while the spinach adds fiber and vitamins. Slice up half an avocado to enjoy the buttery texture alongside your eggs, completing a nutritious and satisfying start to your day.",
      "macros": {"kcal": 780, "protein": 36, "carbs": 30, "fat": 60},
      "ingredients": [
        {"emojiCode": "🥚", "title": "Eggs", "amount": "4 pcs"},
        {"emojiCode": "🥬", "title": "Spinach", "amount": "1 cup"},
        {"emojiCode": "🥑", "title": "Avocado", "amount": "1/2 piece"},
        {"emojiCode": "🧂", "title": "Salt", "amount": "1 pinch"},
        {"emojiCode": "🧄", "title": "Garlic powder", "amount": "1 tsp"}
      ]
    },
    {
      "title": "Grilled Chicken Salad with Olive Oil Dressing",
      "type": "Meal 2",
      "description":
          "Enjoy a refreshing grilled chicken salad for lunch. The salad includes mixed greens topped with juicy grilled chicken, cherry tomatoes, cucumber slices, and a light drizzle of olive oil. This meal is rich in protein from the chicken, providing energy and supporting muscle recovery. The fresh vegetables add essential vitamins and hydration. The addition of olive oil enhances the flavor while supplying healthy fat for a balanced meal.",
      "macros": {"kcal": 900, "protein": 52, "carbs": 30, "fat": 60},
      "ingredients": [
        {
          "emojiCode": "🍗",
          "title": "Grilled Chicken Breast",
          "amount": "200g"
        },
        {"emojiCode": "🥗", "title": "Mixed Greens", "amount": "3 cups"},
        {"emojiCode": "🍅", "title": "Cherry Tomatoes", "amount": "1/2 cup"},
        {"emojiCode": "🥒", "title": "Cucumber", "amount": "1/2 piece"},
        {"emojiCode": "🫒", "title": "Olive Oil", "amount": "2 tbsp"}
      ]
    },
    {
      "title": "Baked Salmon with Asparagus",
      "type": "Meal 3",
      "description":
          "Savor a delicious baked salmon for dinner paired with tender asparagus. This meal is packed with protein and omega-3 fatty acids from the salmon which supports heart health. The asparagus is rich in vitamins and adds a nice crunch. Season the salmon with lemon juice and herbs to enhance the flavors without extra calories, making this meal both satisfying and nutritious.",
      "macros": {"kcal": 800, "protein": 50, "carbs": 12, "fat": 50},
      "ingredients": [
        {"emojiCode": "🐟", "title": "Salmon Fillet", "amount": "200g"},
        {"emojiCode": "🌿", "title": "Asparagus", "amount": "1 bunch"},
        {"emojiCode": "🍋", "title": "Lemon", "amount": "1 piece"},
        {"emojiCode": "🧂", "title": "Salt", "amount": "1 pinch"},
        {"emojiCode": "🕳️", "title": "Black pepper", "amount": "1 pinch"}
      ]
    },
    {
      "title": "Nuts and Seeds Snack Mix",
      "type": "Snack",
      "description":
          "Enjoy a handful of mixed nuts and seeds as a satisfying snack. This mix can include almonds, walnuts, and sunflower seeds for a boost of energy and healthy fats. Nuts are a great source of protein while the seeds provide fiber, making it a perfect mid-afternoon snack to keep you full until dinner.",
      "macros": {"kcal": 300, "protein": 15, "carbs": 5, "fat": 25},
      "ingredients": [
        {"emojiCode": "🌰", "title": "Almonds", "amount": "1/4 cup"},
        {"emojiCode": "🌰", "title": "Walnuts", "amount": "1/4 cup"},
        {"emojiCode": "🌻", "title": "Sunflower Seeds", "amount": "1/4 cup"}
      ]
    }
  ]
};

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final InitGptUsecase initGptUsecase;
  final RequestPlanUsecase requestMealPlan;
  final SendMessageGptUsecase sendMessageGptUsecase;
  final FetchSavedSnapUsecase fetchSavedSnapUsecase;
  ChatBloc(
    this.initGptUsecase,
    this.requestMealPlan,
    this.sendMessageGptUsecase,
    this.fetchSavedSnapUsecase,
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
  }
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
        if (snap != null && chatIsActual(snap.date)) {
          emit(state.copyWith(
            messages: snap.messages,
            requestsLeft: snap.requestsLeft,
            mealPlan: snap.mealPlan,
          ));
          threadId = snap.threadId;
        }
      },
    );

    await initGptUsecase.call(InitGptParams(threadId: threadId));
  }

  FutureOr<void> _sendMessage(
      ChatSendMessage event, Emitter<ChatState> emit) async {
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
        emit(state.copyWith(status: Status.success));
        final msg = MessageEntity(text: result, isMe: false);
        list.add(msg);
        emit(state.copyWith(requestsLeft: state.requestsLeft - 1));
        userBloc.add(UserManageDay(
          day: whoopBloc.state.day.copyWith(
            snap: ChatSnapshotEntity(
              messages: [],
              date: DateTime.now(),
              requestsLeft: state.requestsLeft,
              threadId: chatRemoteSrc.threadId,
            ),
          ),
        ));
      });
    }

    emit(state.copyWith(messages: list));

    add(ChatSaveSnap());
  }

  FutureOr<void> _createMealPlan(
      CreateMealPlan event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: Status.loading));
    final user = userBloc.state.user;
    final res = await requestMealPlan.call(
      RequestPlanParams(
        dietary: user.foodPreferences!.diets,
        cuisines: user.foodPreferences!.cuisines,
        calorieTarget: whoopBloc.state.day.macros.kcal,
        macros: whoopBloc.state.day.macros,
        trainingToday: event.trainingToday,
        mealsAmount: event.mealsAmount,
        snackForToday: event.snackToday,
      ),
    );
    res.fold((failure) {
      emit(state.copyWith(status: Status.error));
    }, (plan) {
      emit(state.copyWith(
        mealPlan: plan,
        requestsLeft: state.requestsLeft - 1,
        status: Status.success,
      ));
      add(const ChatSendMessage(
          text: 'Your meal plan is ready. Check it out.', isMe: false));
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
        threadId: chatRemoteSrc.threadId);
    await chatRepo.saveChatSnapShot(chatSnap: chatSnap);
  }

  FutureOr<void> _deleteMealPlan(
      ChatDeleteMealPlan event, Emitter<ChatState> emit) async {
    emit(state.copyWith(
      mealPlan: null,
      requestsLeft: state.requestsLeft + 1,
      messages: [],
    ));
    add(ChatSaveSnap());
  }

  FutureOr<void> _fetchLatsPlan(
      ChatFetchLastMealPlan event, Emitter<ChatState> emit) async {
    emit(state.copyWith(mealPlan: event.day.mealPlanEntity));
  }

  FutureOr<void> _chatOnLogout(
      ChatOnLogout event, Emitter<ChatState> emit) async {
    emit(state.copyWith(
      messages: [],
      requestsLeft: 5,
      mealPlan: null,
    ));
  }
}
