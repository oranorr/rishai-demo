import 'dart:convert';
import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/features/chat/data/local_data_source.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
// import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';

final chatRemoteSrc = getIt.get<ChatRemoteDataSource>();

@Singleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  late GenerativeModel chatModel;
  late GenerativeModel mealPlanModel;
  late ChatSession chatSession;
  // late OpenAIClient client;
  // late AssistantObject assistantChat;
  // late AssistantObject assistantBreakfast;
  // late AssistantObject assistantGeneralMeals;
  // late AssistantObject assistantSnack;
  // late ThreadObject thread;

  @override
  String? get threadId => '';

  @override
  Future<bool> initGpt(String? savedThreadId) async {
    try {
      chatModel = GenerativeModel(
        apiKey: 'AIzaSyBuyrn8T1_7RvVQYno1Z7A-GekW4eM5FHI',
        model: 'models/gemini-1.5-flash',
        systemInstruction: Content('system', [
          TextPart(
            ChatLocalDataSoucre.chatPrompt,
          ),
        ]),
      );

      mealPlanModel = GenerativeModel(
        apiKey: 'AIzaSyBuyrn8T1_7RvVQYno1Z7A-GekW4eM5FHI',
        model: 'models/gemini-1.5-flash',
        systemInstruction: Content('system', [
          TextPart(
            ChatLocalDataSoucre.generativePrompt,
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

// @override
//TODO надо добавить сюда историю чата
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
        log('PROMPT: $prompt');

        if (isChat) {
          chatSession = model.startChat();
          response = await chatSession.sendMessage(Content.text(prompt));
        } else {
          response = await model.generateContent([Content.text(prompt)]);
        }

        log('Ответ ассистента: ${response.text}');

        if (response.text != null && response.text!.isNotEmpty) {
          return jsonDecode(response.text!);
        } else {
          return {'error': 'Пустой ответ от ассистента'};
        }
      } catch (e) {
        log('Ошибка запроса к Gemini: $e');
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return {'error': 'Произошла ошибка при запросе к ассистенту.'};
  }

  @override
  Future<Map<String, dynamic>> requestMealPlan(
    List<Map<ServingType, String>> prompts,
  ) async {
    final results = <String, dynamic>{};

    for (final prompt in prompts) {
      final entry = prompt.entries.first;
      final mealType = entry.key; // Ключ — тип приёма пищи (ServingType)
      final mealPrompt = entry.value; // Значение — строка (prompt)

      // Переключение по mealType
      switch (mealType) {
        case ServingType.breakfast:
          results['breakfast'] = await requestAssistant(
            prompt: mealPrompt,
            model: mealPlanModel,
            isChat: false,
          );
          break;
        case ServingType.dinner:
          results['generalMeals'] = await requestAssistant(
            prompt: mealPrompt,
            model: mealPlanModel,
            isChat: false,
          );
          break;
        case ServingType.snack:
          results['snack'] = await requestAssistant(
            prompt: mealPrompt,
            model: mealPlanModel,
            isChat: false,
          );
          break;
        default:
          throw ArgumentError('Invalid meal type: $mealType');
      }
    }

    // Объединяем все блюда в один массив
    final meals = [
      ...results['breakfast']?['meals'] ?? [],
      ...results['generalMeals']?['meals'] ?? [],
      ...results['snack']?['meals'] ?? [],
    ];

    // final dot = await requestAssistant(
    //   prompt: meals.toString(),
    //   isChat: true,
    //   model: chatModel,
    // );
    // log('CHAT ASSISTANT: $dot');

    return {'meals': meals};
  }

  @override
  Future<String?> sendMessage(String userMessage) async {
    return null;

    // try {
    //   final run = await client.createThreadRun(
    //     threadId: thread.id,
    //     request: CreateRunRequest(
    //       assistantId: assistantChat.id,
    //       model: const CreateRunRequestModel.model(RunModels.gpt4oMini),
    //       additionalInstructions: userMessage,
    //     ),
    //   );

    //   log('Прогон ассистента запущен: ${run.id}, threadId: ${run.threadId}');

    //   bool runCompleted = false;
    //   const maxAttempts = 10;
    //   int attempts = 0;

    //   while (!runCompleted && attempts < maxAttempts) {
    //     await Future.delayed(const Duration(seconds: 2));

    //     final runStatus =
    //         await client.getThreadRun(threadId: thread.id, runId: run.id);
    //     if (runStatus.status == RunStatus.completed) {
    //       runCompleted = true;
    //       log('Прогон ассистента завершен');
    //     }

    //     attempts++;
    //   }

    //   if (!runCompleted) {
    //     log('Прогон не завершился за отведенное время, отменяем.');
    //     await client.cancelThreadRun(threadId: thread.id, runId: run.id);
    //     return null;
    //   }

    //   final responseMessages =
    //       await client.listThreadMessages(threadId: thread.id);
    //   MessageObject? assistantResponse;

    //   for (final message in responseMessages.data.reversed) {
    //     if (message.role == MessageRole.assistant &&
    //         message.runId == run.id &&
    //         message.content.isNotEmpty) {
    //       assistantResponse = message;
    //       break;
    //     }
    //   }

    //   if (assistantResponse != null) {
    //     final content = assistantResponse.content.first;
    //     log('Ответ ассистента: ${content.toJson()}');
    //     return content.text;
    //   } else {
    //     log('Ответ ассистента не был получен.');
    //     return null;
    //   }
    // } on Exception catch (e) {
    //   log('Ошибка при отправке сообщения: $e');
    //   return null;
    // }
  }

  @override
  Future<Map<String, dynamic>?> fetchLastChatSnap(String directusId) async {
    try {
      final rawUser =
          await directus.readOne(collection: usersCollection, id: directusId);
      if (rawUser['days'].isEmpty) {
        return null;
      } else {
        final last = rawUser['days'].last;
        final rawLastDay = await directus.readOne(
          collection: daysCollection,
          id: last.toString(),
        );
        return rawLastDay['chatSnap'];
      }
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
    return null;

    // final type = params.meal.servingType;
    // Map<String, dynamic> newMeal;
    // final prompt =
    //     'I dont like this meal: ${params.meal.title}, please replace this ${params.meal.type} with following macros target: ${params.meal.macros}. My food preferences are: ${params.foodPreferences.diets}, cuisines, I prefer: ${params.foodPreferences.cuisines}, restrictions: ${params.foodPreferences.restrictions}';
    // try {
    //   switch (type) {
    //     case ServingType.breakfast:
    //       newMeal = await _requestAssistant(prompt, assistantBreakfast);
    //       break;
    //     case ServingType.lunch || ServingType.dinner || ServingType.supper:
    //       newMeal = await _requestAssistant(prompt, assistantGeneralMeals);
    //       break;
    //     case ServingType.snack:
    //       newMeal = await _requestAssistant(prompt, assistantSnack);
    //       break;
    //   }
    //   log('RESPONSE IS: $newMeal');
    //   return Meal.fromMap(newMeal['meals'].first).copyWith(isRegenerated: true);
    // } on Exception catch (e) {
    //   log('EXCEPTION: $e');
    //   return null;
    // }
  }

  @override
  Future<Meal?> replaceIngredient(ReplaceIngredientParams params) async {
    return null;

    // Map<String, dynamic> res;
    // List<String> ingredientsNames =
    //     List.from(params.ingredients.map((e) => e.title));
    // final prompt =
    //     'Replace please ${ingredientsNames.join(', ')} in this meal: ${params.meal.title}, type is: ${params.meal.type}. My food preferences are: ${params.preferences.diets}, cuisines, I prefer: ${params.preferences.cuisines}, restrictions: ${params.preferences.restrictions}';
    // // 'I dont like this meal: ${params.mealTitle}, please replace this ${params.servingType} with following macros target: ${params.meal.macros}. My food preferences are: ${params.foodPreferences.diets}, cuisines, I prefer: ${params.foodPreferences.cuisines}, restrictions: ${params.foodPreferences.restrictions}';
    // try {
    //   switch (params.meal.servingType) {
    //     case ServingType.breakfast:
    //       res = await _requestAssistant(prompt, assistantBreakfast);
    //       break;
    //     case ServingType.lunch || ServingType.dinner || ServingType.supper:
    //       res = await _requestAssistant(prompt, assistantGeneralMeals);
    //       break;
    //     case ServingType.snack:
    //       res = await _requestAssistant(prompt, assistantSnack);
    //       break;
    //   }
    //   log('RESPONSE IS: $res');
    //   return Meal.fromMap(res['meals'].first).copyWith(isRegenerated: true);
    // } on Exception catch (e) {
    //   log('EXCEPTION: $e');
    //   return null;
    // }
  }
}
