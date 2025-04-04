import 'dart:convert';
import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';

import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/chat/data/local_data_source.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

final chatRemoteSrc = getIt.get<ChatRemoteDataSource>();

@Singleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  late GenerativeModel chatModel;
  // late GenerativeModel mealPlanModel;
  late GenerativeModel breakfastModel;
  late GenerativeModel mealsModel;
  late GenerativeModel snackModel;
  late ChatSession chatSession;

  @override
  String? get threadId => '';

  static String key = 'AIzaSyBuyrn8T1_7RvVQYno1Z7A-GekW4eM5FHI';
  static String model = 'models/gemini-2.0-flash';

  @override
  Future<bool> initGpt(String? savedThreadId) async {
    try {
      chatModel = GenerativeModel(
        apiKey: key,
        model: model,
        systemInstruction: Content(
          'system',
          [
            TextPart(
              ChatLocalDataSoucre.chatPrompt,
            ),
          ],
        ),
      );
      chatSession = chatModel.startChat();

      breakfastModel = GenerativeModel(
        apiKey: key,
        model: model,
        systemInstruction: Content('system', [
          TextPart(
            ChatLocalDataSoucre.breakfastPrompt,
          ),
        ]),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          // responseSchema: ChatLocalDataSoucre.schema,
        ),
      );
      mealsModel = GenerativeModel(
        apiKey: key,
        model: model,
        systemInstruction: Content('system', [
          TextPart(
            ChatLocalDataSoucre.mealsPrompt,
          ),
        ]),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          // responseSchema: ChatLocalDataSoucre.schema,
        ),
      );
      snackModel = GenerativeModel(
        apiKey: key,
        model: model,
        systemInstruction: Content('system', [
          TextPart(
            ChatLocalDataSoucre.snackPrompt,
          ),
        ]),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          // responseSchema: ChatLocalDataSoucre.schema,
        ),
      );

      return true;
    } on Exception catch (e) {
      log('Ошибка инициализации GPT: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> requestAssistant({
    required String prompt,
    required bool isChat,
    required GenerativeModel model,
  }) async {
    int retryCount = 0;
    const int maxRetries = 3;
    GenerateContentResponse? response;

    while (retryCount < maxRetries) {
      try {
        log('❗PROMPT: $prompt');
        // log('🔍 Chat history: ${chatSession.history.map((e) => e.toJson()).toList()}');

        if (isChat) {
          response = await chatSession.sendMessage(Content.text(prompt));
        } else {
          final chat = model.startChat();
          response = await chat.sendMessage(Content.text(prompt));
        }

        if (response.text == null || response.text!.isEmpty) {
          log('⚠️ Пустой ответ от ассистента, пересоздаю chatSession');
          chatSession = chatModel.startChat();
          return {'error': 'Пустой ответ от ассистента'};
        }
        log('GEMINI RESPONSE: ${response.text}');
        return isChat ? {'answer': response.text} : jsonDecode(response.text!);
      } catch (e) {
        log('Ошибка запроса к Gemini: $e');
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return {'error': 'Произошла ошибка при запросе к ассистенту.'};
  }

  @override
  Future<String?> sendMessage(String userMessage) async {
    final res = await requestAssistant(
      prompt: userMessage,
      isChat: true,
      model: chatModel,
    );
    return res['answer'];
  }

  @override
  Future<Map<String, dynamic>?> fetchLastChatSnap(
    String directusId,
    DateTime date,
  ) async {
    try {
      final rawUser = await directus.readOne(
        collection: usersCollection,
        id: directusId,
      );
      if (rawUser['days'].isEmpty) {
        return null;
      }

      // Если дата не указана, берем последний день

      final lastDay = await directus.readOne(
        collection: daysCollection,
        id: rawUser['days'].last.toString(),
      );
      if (lastDay['cycleId'] == null) return null;

      final isCycleEnded = await whoopRemote.pingLastCycle(
        cycleId: int.parse(lastDay['cycleId']),
      );

      if (isCycleEnded) {
        return null;
      }

      return (lastDay['chatSnap'] as Map<String, dynamic>)
        ..addAll({'mealPlan': lastDay['mealPlan']});
    } on Exception catch (e) {
      log('failed to fetch last Chat snap, with error: $e');
      rethrow;
    }
  }

  @override
  Future<void> closeGpt() async {
    // Clean up resources if necessary
  }

  @override
  set threadId(String? value) {
    threadId = value;
  }

  @override
  Future<Meal?> replaceMeal(ReplaceMealParams params) async {
    final currentMeals = whoopBloc.state.day.mealPlanEntity?.meals
            .map((m) => m.title)
            .join(', ') ??
        '';
    final prompt =
        "I dont like this meal: ${params.meal.title}, please replace this ${params.meal.type} with following macros target: ${params.meal.macros}. My food preferences are: ${params.foodPreferences.diets}, cuisines, I prefer: ${params.foodPreferences.cuisines}, restrictions: ${params.foodPreferences.restrictions}. Please exclude these meals from today's plan: $currentMeals";
    try {
      final meal =
          await regenerate(type: params.meal.servingType, prompt: prompt);
      await updateChatHistory('from ${params.meal.title} to $meal');
      return meal;
    } on Exception catch (e) {
      log('EXCEPTION: $e');
      return null;
    }
  }

  @override
  Future<Meal?> replaceIngredient(ReplaceIngredientParams params) async {
    List<String> ingredientsNames =
        List.from(params.ingredients.map((e) => e.title));
    final currentMeals = whoopBloc.state.day.mealPlanEntity?.meals
            .map((m) => m.title)
            .join(', ') ??
        '';
    final prompt =
        "In the meal ${params.meal.title} with such ingredients: ${params.meal.ingredients.map((e) => e.title).join(', ')} please replace this ingrdients: $ingredientsNames. Type of meal is: ${params.meal.type} with following macros target: ${params.meal.macros}. My food preferences are: ${params.preferences.diets}, cuisines, I prefer: ${params.preferences.cuisines}, restrictions: ${params.preferences.restrictions}. Please exclude these meals from today's plan: $currentMeals";
    try {
      return await regenerate(type: params.meal.servingType, prompt: prompt);
    } on Exception catch (e) {
      log('EXCEPTION: $e');
      return null;
    }
  }

  Future<Meal> regenerate({
    required ServingType type,
    required String prompt,
  }) async {
    Map<String, dynamic> newMeal;
    switch (type) {
      case ServingType.breakfast:
        newMeal = await requestAssistant(
          prompt: prompt,
          model: breakfastModel,
          isChat: false,
        );
        break;
      case ServingType.dinner || ServingType.lunch || ServingType.supper:
        newMeal = await requestAssistant(
          prompt: prompt,
          model: mealsModel,
          isChat: false,
        );
        break;
      case ServingType.snack:
        newMeal = await requestAssistant(
          prompt: prompt,
          model: snackModel,
          isChat: false,
        );
        break;
      // default:
      //   throw ArgumentError('Invalid meal type: ${params.meal.servingType}');
    }

    return Meal.fromMap(newMeal['meals'].first).copyWith(isRegenerated: true);
  }

  Future<void> updateChatHistory(String message) async {
    final prompt =
        'Meal plan has been changed: $message. Please, answer to this message with "You have changed $message"';
    await requestAssistant(
      prompt: prompt,
      isChat: true,
      model: chatModel,
    );
  }

  @override
  Future<Map<String, dynamic>> requestMealPlan(
    List<Map<ServingType, String>> prompts,
    bool isWeekPlan,
  ) async {
    final results = <String, dynamic>{};

    for (final prompt in prompts) {
      final entry = prompt.entries.first;
      final mealType = entry.key;
      final mealPrompt = entry.value;

      switch (mealType) {
        case ServingType.breakfast:
          results['breakfast'] = await requestAssistant(
            prompt: mealPrompt,
            model: breakfastModel,
            isChat: false,
          );
          break;
        case ServingType.dinner:
          results['generalMeals'] = await requestAssistant(
            prompt: mealPrompt,
            model: mealsModel,
            isChat: false,
          );
          break;
        case ServingType.snack:
          results['snack'] = await requestAssistant(
            prompt: mealPrompt,
            model: snackModel,
            isChat: false,
          );
          break;
        default:
          throw ArgumentError('Invalid meal type: $mealType');
      }
    }

    final meals = [
      ...results['breakfast']?['meals'] ?? [],
      ...results['generalMeals']?['meals'] ?? [],
      ...results['snack']?['meals'] ?? [],
    ];

    // Только для обычного плана питания добавляем в историю чата
    if (!isWeekPlan) {
      final dot = await requestAssistant(
        prompt: "{'meals': $meals}",
        isChat: true,
        model: chatModel,
      );
      log('CHAT ASSISTANT: $dot');
    }
    return {'meals': meals};
  }
}
