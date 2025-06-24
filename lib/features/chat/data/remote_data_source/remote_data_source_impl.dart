import 'dart:convert';
import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';

import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/whoop/data/data_sources/remote/remote_data_source_impl.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';

final chatRemoteSrc = getIt.get<ChatRemoteDataSource>();

@Singleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._llmProxyClient);
  final LlmProxyClient _llmProxyClient;

  // История сообщений для чата
  final List<PreviousMessage> _chatHistory = [];

  @override
  String? get threadId => '';

  @override
  Future<bool> initGpt(String? savedThreadId) async {
    try {
      log('✅ Инициализация LLM прокси клиента');
      // Очищаем историю чата при инициализации
      _chatHistory.clear();
      return true;
    } on Exception catch (e) {
      log('❌ Ошибка инициализации LLM прокси: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> requestAssistant({
    required String prompt,
    required bool isChat,
    required LlmRequestType type,
  }) async {
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        log('❗PROMPT: $prompt');
        log('🔍 Тип запроса: ${type.name}, isChat: $isChat');

        String responseText;

        if (isChat) {
          // Получаем текущий план питания для контекста
          final currentMealPlan = whoopBloc.state.day.mealPlanEntity;
          List<PreviousMessage> contextMessages = [];

          // Добавляем информацию о текущем плане питания в контекст
          if (currentMealPlan != null && currentMealPlan.meals.isNotEmpty) {
            final mealPlanContext = _buildMealPlanContext(currentMealPlan);
            log('🍽️ Добавляем контекст плана питания: ${mealPlanContext.substring(0, mealPlanContext.length > 200 ? 200 : mealPlanContext.length)}...');
            contextMessages.add(
              PreviousMessage(
                text: mealPlanContext,
                role: 'user',
              ),
            );
            contextMessages.add(
              PreviousMessage(
                text:
                    'Понял, у вас есть план питания на сегодня. Чем могу помочь?',
                role: 'model',
              ),
            );
          } else {
            log('⚠️ План питания не найден или пуст');
          }

          // Добавляем историю чата
          if (_chatHistory.isNotEmpty) {
            log('💬 Добавляем ${_chatHistory.length} сообщений из истории чата');
            contextMessages.addAll(_chatHistory);
          }

          log('📤 Отправляем запрос с ${contextMessages.length} сообщениями в контексте');

          // Отправляем запрос с контекстом
          responseText = await _llmProxyClient.sendChatMessage(
            prompt,
            previousMessages:
                contextMessages.isNotEmpty ? contextMessages : null,
          );

          // Добавляем сообщения в историю
          _chatHistory.add(PreviousMessage(text: prompt, role: 'user'));
          _chatHistory.add(PreviousMessage(text: responseText, role: 'model'));
        } else {
          // Для генерации блюд не используем историю
          responseText = await _llmProxyClient.generateMeal(type, prompt);
        }

        if (responseText.isEmpty) {
          log('⚠️ Пустой ответ от ассистента');
          return {'error': 'Пустой ответ от ассистента'};
        }

        log('GEMINI RESPONSE: $responseText');

        if (isChat) {
          return {'answer': responseText};
        } else {
          try {
            final parsedResponse = jsonDecode(responseText);
            log('✅ Успешно распарсили JSON ответ');
            return parsedResponse;
          } catch (e) {
            log('❌ Ошибка парсинга JSON: $e');
            return {'error': 'Ошибка парсинга ответа от ассистента'};
          }
        }
      } catch (e) {
        log('❌ Ошибка запроса к LLM прокси: $e');
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return {'error': 'Произошла ошибка при запросе к ассистенту.'};
  }

  /// Строит контекст с информацией о текущем плане питания
  String _buildMealPlanContext(MealPlanEntity mealPlan) {
    final meals = mealPlan.meals;
    final mealsInfo = meals.map((meal) {
      final ingredients = meal.ingredients
          .map((i) => '${i.title} (${i.quantity} ${i.unit.toDisplayString()})')
          .join(', ');
      return '''
${meal.title} (${meal.type})
Описание: ${meal.description}
Макросы: ${meal.macros.kcal} ккал, ${meal.macros.protein}г белка, ${meal.macros.carbs}г углеводов, ${meal.macros.fat}г жиров
Ингредиенты: $ingredients
Инструкции по приготовлению: ${meal.cookingInstructions.join('; ')}''';
    }).join('\n\n');

    return '''У меня есть план питания на сегодня:

$mealsInfo

Пожалуйста, используй эту информацию, когда отвечаешь на мои вопросы о питании.''';
  }

  @override
  Future<String?> sendMessage(String userMessage) async {
    // Трекинг обращения к чату
    await analytics.logCustomEvent(
      name: 'chat_message_sent',
      parameters: {
        'message_length': userMessage.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    final res = await requestAssistant(
      prompt: userMessage,
      isChat: true,
      type: LlmRequestType.chat,
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

      final daysIds = await dayManager.getDaysIds(userId: directusId);

      final lastDay = await directus.readOne(
        collection: daysCollection,
        id: daysIds.last.toString(),
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
    // Очищаем историю чата при закрытии
    _chatHistory.clear();
  }

  @override
  set threadId(String? value) {
    // Не используется в новой реализации
  }

  @override
  Future<Meal?> replaceMeal(ReplaceMealParams params) async {
    // Трекинг замены блюда
    await analytics.logCustomEvent(
      name: 'replace_meal',
      parameters: {
        'meal_type': params.meal.type,
        'meal_title': params.meal.title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

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
    LlmRequestType requestType;

    switch (type) {
      case ServingType.breakfast:
        requestType = LlmRequestType.breakfast;
        break;
      case ServingType.dinner || ServingType.lunch || ServingType.supper:
        requestType = LlmRequestType.meal;
        break;
      case ServingType.snack:
        requestType = LlmRequestType.snack;
        break;
    }

    final responseText = await requestAssistant(
      prompt: prompt,
      isChat: false,
      type: requestType,
    );

    newMeal = responseText;

    return Meal.fromMap(newMeal['meals'].first).copyWith(isRegenerated: true);
  }

  Future<void> updateChatHistory(String message) async {
    final prompt =
        'Meal plan has been changed: $message. Please, answer to this message with "You have changed $message"';
    await requestAssistant(
      prompt: prompt,
      isChat: true,
      type: LlmRequestType.chat,
    );
  }

  @override
  Future<Map<String, dynamic>> requestMealPlan(
    List<Map<ServingType, String>> prompts,
    bool isWeekPlan,
  ) async {
    final results = <String, dynamic>{};
    // Трекинг создания плана питания
    await analytics.logCustomEvent(
      name: isWeekPlan ? 'create_5day_meal_plan' : 'create_1day_meal_plan',
      parameters: {
        'serving_types': prompts.map((p) => p.keys.first.name).join(', '),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    for (final prompt in prompts) {
      final entry = prompt.entries.first;
      final mealType = entry.key;
      final mealPrompt = entry.value;

      LlmRequestType requestType;
      switch (mealType) {
        case ServingType.breakfast:
          requestType = LlmRequestType.breakfast;
          break;
        case ServingType.dinner:
        case ServingType.lunch:
          requestType = LlmRequestType.meal;
          break;
        case ServingType.snack:
          requestType = LlmRequestType.snack;
          break;
        case ServingType.supper:
          requestType = LlmRequestType.meal;
          break;
      }

      final response = await requestAssistant(
        prompt: mealPrompt,
        isChat: false,
        type: requestType,
      );

      switch (mealType) {
        case ServingType.breakfast:
          results['breakfast'] = response;
          break;
        case ServingType.dinner:
        case ServingType.lunch:
        case ServingType.supper:
          results['generalMeals'] = response;
          break;
        case ServingType.snack:
          results['snack'] = response;
          break;
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
        type: LlmRequestType.chat,
      );
      log('CHAT ASSISTANT: $dot');
    }
    return {'meals': meals};
  }
}
