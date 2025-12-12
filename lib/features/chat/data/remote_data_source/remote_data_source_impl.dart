import 'dart:convert';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/usecases/replace_ingredient_usecase.dart';
import 'package:rishai/features/chat/domain/usecases/replace_meal_usecase.dart';
import 'package:rishai/features/food_diary/presentation/wellness_page/wellness_page.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

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
                    'I understand you have a meal plan for today. How can I help you?',
                role: 'model',
              ),
            );
          } else {
            log('⚠️ План питания не найден или пуст');
          }

          // Добавляем текущую рекомендацию по питанию в контекст
          final currentRecommendation = RecommendationService.getCurrentRecommendation();
          if (currentRecommendation != null && currentRecommendation.isNotEmpty) {
            log('💡 Добавляем текущую рекомендацию в контекст чата: ${currentRecommendation.substring(0, currentRecommendation.length > 200 ? 200 : currentRecommendation.length)}...');
            contextMessages.add(
              PreviousMessage(
                text: 'Current nutritional recommendation: $currentRecommendation',
                role: 'user',
              ),
            );
            contextMessages.add(
              PreviousMessage(
                text: 'I understand the current nutritional recommendation. I will consider it when answering questions.',
                role: 'model',
              ),
            );
          } else {
            log('⚠️ Текущая рекомендация не найдена или пуста');
            // Добавляем информацию о том, что рекомендации нет
            contextMessages.add(
              PreviousMessage(
                text: 'The user does not have a current nutritional recommendation at this time.',
                role: 'user',
              ),
            );
            contextMessages.add(
              PreviousMessage(
                text: 'I understand. I will help with nutrition questions without a specific recommendation.',
                role: 'model',
              ),
            );
          }

          // Добавляем историю чата
          if (_chatHistory.isNotEmpty) {
            log('💬 Добавляем ${_chatHistory.length} сообщений из истории чата');
            contextMessages.addAll(_chatHistory);
          }

          log('📤 Отправляем запрос с ${contextMessages.length} сообщениями в контексте');

          // Отправляем запрос с контекстом через новый endpoint /llm-proxy-chat
          responseText = await _llmProxyClient.sendChatMessageV2(
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
          return {'error': 'Empty response from assistant'};
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
            return {'error': 'Error parsing assistant response'};
          }
        }
      } catch (e) {
        log('❌ Ошибка запроса к LLM прокси: $e');
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return {'error': 'An error occurred while requesting the assistant.'};
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
Description: ${meal.description}
Macros: ${meal.macros.kcal} kcal, ${meal.macros.protein}g protein, ${meal.macros.carbs}g carbs, ${meal.macros.fat}g fat
Ingredients: $ingredients
Cooking instructions: ${meal.cookingInstructions.join('; ')}''';
    }).join('\n\n');

    return '''I have a meal plan for today:

$mealsInfo

Please use this information when answering my nutrition questions.''';
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
      // Используем унифицированный метод вместо дублирующей логики
      final result = await dayManager.getLastDayWithCycleStatus(
        userId: directusId,
      );

      // Если день не найден или цикл завершен, возвращаем null
      if (result == null || !result.isCycleActive) {
        return null;
      }

      // Возвращаем chatSnap с мealPlan
      return (result.day.snap.toDirectus())
        ..addAll({'mealPlan': result.day.mealPlanEntity?.toMap()});
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
      final meal = await regenerate(
        type: params.meal.servingType,
        prompt: prompt,
        targetMacros: params.meal.macros, // 🎯 Передаем целевые макросы
      );
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
      return await regenerate(
        type: params.meal.servingType,
        prompt: prompt,
        targetMacros: params.meal.macros, // 🎯 Передаем целевые макросы
      );
    } on Exception catch (e) {
      log('EXCEPTION: $e');
      return null;
    }
  }

  Future<Meal> regenerate({
    required ServingType type,
    required String prompt,
    MacrosBreakdown? targetMacros, // 🎯 Добавляем параметр для целевых макросов
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

    final regeneratedMeal =
        Meal.fromMap(newMeal['meals'].first).copyWith(isRegenerated: true);

    // 🎯 ЗАМЕНЯЕМ ФАКТИЧЕСКИЕ МАКРОСЫ НА ЦЕЛЕВЫЕ (если переданы)
    if (targetMacros != null) {
      final mealWithTargetMacros =
          regeneratedMeal.copyWith(macros: targetMacros);
      log('[regenerate] 🎯 Заменили макросы на целевые: ${targetMacros.kcal} ккал, ${targetMacros.protein}г белка, ${targetMacros.carbs}г углеводов, ${targetMacros.fat}г жиров');
      return mealWithTargetMacros;
    }

    return regeneratedMeal;
  }

  Future<void> updateChatHistory(String message) async {
    final prompt =
        'Meal plan has been changed: $message. Please acknowledge this change with "You have changed $message"';
    await requestAssistant(
      prompt: prompt,
      isChat: true,
      type: LlmRequestType.chat,
    );
  }

  @override
  Future<Map<String, dynamic>> requestMealPlanV2(
    List<LlmMealRequest> requests,
    bool isWeekPlan,
  ) async {
    log('[requestMealPlanV2] Начинаем генерацию плана питания с новой структурой API');
    log('[requestMealPlanV2] Количество запросов: ${requests.length}');
    log('[requestMealPlanV2] Недельный план: $isWeekPlan');

    final results = <String, dynamic>{};
    final allMeals = <Map<String, dynamic>>[];

    // 🎯 Создаем мапу целевых макросов для каждого типа блюда
    final Map<LlmMealRequestType, List<LlmMealDto>> targetMacrosByType = {};
    for (final request in requests) {
      targetMacrosByType[request.type] = request.meals;
    }

    // Трекинг создания плана питания
    await analytics.logCustomEvent(
      name:
          isWeekPlan ? 'create_5day_meal_plan_v2' : 'create_1day_meal_plan_v2',
      parameters: {
        'request_types': requests.map((r) => r.type.name).join(', '),
        'total_meals': requests.fold<int>(0, (sum, r) => sum + r.meals.length),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // 🚀 ПАРАЛЛЕЛЬНАЯ обработка всех запросов вместо последовательной
    log('[requestMealPlanV2] Запускаем ${requests.length} запросов параллельно');

    final futures = requests.map((request) async {
      try {
        log('[requestMealPlanV2] Обрабатываем запрос: ${request.type.name} с ${request.meals.length} блюдами');

        // Используем новый метод generateMeals из LlmProxyClient (теперь с retry логикой)
        final response = await _llmProxyClient.generateMeals(request);

        // Проверяем ответ
        if (response.containsKey('error')) {
          log('[requestMealPlanV2] ❌ Ошибка в ответе для ${request.type.name}: ${response['error']}');
          return null;
        }

        if (!response.containsKey('meals') || response['meals'] == null) {
          log('[requestMealPlanV2] ❌ Нет блюд в ответе для ${request.type.name}');
          return null;
        }

        final meals = response['meals'] as List;
        log('[requestMealPlanV2] ✅ Получено блюд для ${request.type.name}: ${meals.length}');

        return {
          'type': request.type,
          'response': response,
          'meals': meals.cast<Map<String, dynamic>>(),
        };
      } catch (e) {
        log('[requestMealPlanV2] ❌ Ошибка при обработке запроса ${request.type.name}: $e');

        // Логируем детали ошибки для отладки
        if (e.toString().contains('502')) {
          log('[requestMealPlanV2] 🔍 HTTP 502 ошибка для ${request.type.name} - retry логика уже отработала');
        }

        return null;
      }
    }).toList();

    // Ожидаем завершения всех запросов
    final responses = await Future.wait(futures);

    // Обрабатываем результаты
    for (final responseData in responses) {
      if (responseData == null) continue;

      final requestType = responseData['type']! as LlmMealRequestType;
      final response = responseData['response']! as Map<String, dynamic>;
      final meals = responseData['meals']! as List<Map<String, dynamic>>;

      // 🎯 ЗАМЕНЯЕМ ФАКТИЧЕСКИЕ МАКРОСЫ НА ЦЕЛЕВЫЕ
      final targetMeals = targetMacrosByType[requestType] ?? [];
      final mealsWithTargetMacros = <Map<String, dynamic>>[];

      for (int i = 0; i < meals.length; i++) {
        final meal = Map<String, dynamic>.from(meals[i]);

        // Если есть соответствующие целевые макросы, заменяем их
        if (i < targetMeals.length) {
          final targetMeal = targetMeals[i];
          meal['macros'] = {
            'kcal': targetMeal.kcal,
            'protein': targetMeal.protein,
            'carbs': targetMeal.carbs,
            'fat': targetMeal.fat,
          };

          log('[requestMealPlanV2] 🎯 Заменили макросы для блюда ${meal['title']}: ${targetMeal.kcal} ккал, ${targetMeal.protein}г белка, ${targetMeal.carbs}г углеводов, ${targetMeal.fat}г жиров');
        }

        mealsWithTargetMacros.add(meal);
      }

      // Сохраняем результат по типам для совместимости с существующим кодом
      switch (requestType) {
        case LlmMealRequestType.breakfast:
          results['breakfast'] = response;
          break;
        case LlmMealRequestType.meal:
          results['generalMeals'] = response;
          break;
        case LlmMealRequestType.snack:
          results['snack'] = response;
          break;
      }

      // Добавляем все блюда с целевыми макросами в общий список
      allMeals.addAll(mealsWithTargetMacros);
    }

    // Подсчитываем статистику успешных и неудачных запросов
    final successfulRequests = responses.where((r) => r != null).length;
    final totalRequests = requests.length;
    final failedRequests = totalRequests - successfulRequests;

    log('[requestMealPlanV2] 📊 Статистика запросов: $successfulRequests успешных из $totalRequests');
    log('[requestMealPlanV2] 🍽️ Всего сгенерировано блюд с целевыми макросами: ${allMeals.length}');

    // Предупреждение о частичных сбоях
    if (failedRequests > 0) {
      log('[requestMealPlanV2] ⚠️ ВНИМАНИЕ: $failedRequests запросов завершились неудачно');
      log('[requestMealPlanV2] 💡 Рекомендуется повторить генерацию плана для получения всех блюд');
    }

    // Только для обычного плана питания добавляем в историю чата ОДИН раз
    if (!isWeekPlan && allMeals.isNotEmpty) {
      try {
        log('[requestMealPlanV2] Добавляем план питания в историю чата');
        final chatResponse = await requestAssistant(
          prompt: "{'meals': $allMeals}",
          isChat: true,
          type: LlmRequestType.chat,
        );
        log('[requestMealPlanV2] Ответ чат-ассистента: ${chatResponse['answer'] ?? 'нет ответа'}');
      } catch (e) {
        log('[requestMealPlanV2] Ошибка при добавлении в чат: $e');
        // Не критичная ошибка, продолжаем
      }
    }

    return {'meals': allMeals};
  }

  /// Новые методы для регенерации блюд с использованием V2 структуры API

  @override
  Future<Meal?> replaceMealV2(ReplaceMealParams params) async {
    // Трекинг замены блюда V2
    await analytics.logCustomEvent(
      name: 'replace_meal_v2',
      parameters: {
        'meal_type': params.meal.type,
        'meal_title': params.meal.title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    try {
      log('[replaceMealV2] Начинаем замену блюда: ${params.meal.title}');

      // Получаем текущие блюда для исключения
      final currentMeals = whoopBloc.state.day.mealPlanEntity?.meals
              .map((m) => m.title)
              .join(', ') ??
          '';

      // Формируем сообщение для регенерации
      final message = """
I don't like this meal: ${params.meal.title}. Please replace this ${params.meal.type} with a different meal.

My food preferences:
- Dietary preferences: ${params.foodPreferences.diets.join(', ')}
- Cuisine preferences: ${params.foodPreferences.cuisines.join(', ')}
- Restrictions: ${params.foodPreferences.restrictions.join(', ')}

Please exclude these meals from today's plan: $currentMeals

The new meal should have similar nutritional values to the original.
""";

      // Определяем тип запроса
      LlmMealRequestType requestType;
      switch (params.meal.servingType) {
        case ServingType.breakfast:
          requestType = LlmMealRequestType.breakfast;
          break;
        case ServingType.snack:
          requestType = LlmMealRequestType.snack;
          break;
        case ServingType.dinner:
        case ServingType.lunch:
        case ServingType.supper:
          requestType = LlmMealRequestType.meal;
          break;
      }

      // Форматируем тип блюда согласно API
      final mealType = _formatMealTypeForRegeneration(
        params.meal.servingType,
        params.meal.type,
      );

      // Создаем целевое блюдо с макросами
      final targetMeal = LlmMealDto(
        type: mealType,
        kcal: params.meal.macros.kcal,
        protein: params.meal.macros.protein,
        carbs: params.meal.macros.carbs,
        fat: params.meal.macros.fat,
      );

      // Создаем запрос регенерации
      final request = LlmRegenerateMealRequest(
        type: requestType,
        message: message,
        targetMeal: targetMeal,
      );

      // Отправляем запрос
      final response = await _llmProxyClient.regenerateMeal(request);

      // Проверяем ответ
      if (response.containsKey('error')) {
        log('[replaceMealV2] Ошибка в ответе: ${response['error']}');
        return null;
      }

      if (!response.containsKey('meals') || response['meals'] == null) {
        log('[replaceMealV2] Нет блюд в ответе');
        return null;
      }

      final meals = response['meals'] as List;
      if (meals.isEmpty) {
        log('[replaceMealV2] Пустой список блюд');
        return null;
      }

      log('[replaceMealV2] Получено регенерированное блюдо');
      final regeneratedMeal =
          Meal.fromMap(meals.first).copyWith(isRegenerated: true);

      // 🎯 ЗАМЕНЯЕМ ФАКТИЧЕСКИЕ МАКРОСЫ НА ЦЕЛЕВЫЕ
      final mealWithTargetMacros = regeneratedMeal.copyWith(
        macros: MacrosBreakdown(
          kcal: targetMeal.kcal,
          protein: targetMeal.protein,
          carbs: targetMeal.carbs,
          fat: targetMeal.fat,
        ),
      );

      log('[replaceMealV2] 🎯 Заменили макросы на целевые: ${targetMeal.kcal} ккал, ${targetMeal.protein}г белка, ${targetMeal.carbs}г углеводов, ${targetMeal.fat}г жиров');

      // Обновляем историю чата
      await updateChatHistory(
        'from ${params.meal.title} to ${mealWithTargetMacros.title}',
      );

      return mealWithTargetMacros;
    } catch (e) {
      log('[replaceMealV2] Ошибка: $e');
      return null;
    }
  }

  @override
  Future<Meal?> replaceIngredientV2(ReplaceIngredientParams params) async {
    // Трекинг замены ингредиентов V2
    await analytics.logCustomEvent(
      name: 'replace_ingredient_v2',
      parameters: {
        'meal_type': params.meal.type,
        'meal_title': params.meal.title,
        'ingredients_count': params.ingredients.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    try {
      log('[replaceIngredientV2] Начинаем замену ингредиентов в блюде: ${params.meal.title}');

      // Получаем названия ингредиентов для замены
      final ingredientsToReplace =
          params.ingredients.map((e) => e.title).toList();

      // Получаем текущие блюда для исключения
      final currentMeals = whoopBloc.state.day.mealPlanEntity?.meals
              .map((m) => m.title)
              .join(', ') ??
          '';

      // Формируем сообщение для регенерации
      final message = """
In the meal "${params.meal.title}" with ingredients: ${params.meal.ingredients.map((e) => e.title).join(', ')}, please replace these ingredients: ${ingredientsToReplace.join(', ')}.

The meal type is: ${params.meal.type}

My food preferences:
- Dietary preferences: ${params.preferences.diets.join(', ')}
- Cuisine preferences: ${params.preferences.cuisines.join(', ')}
- Restrictions: ${params.preferences.restrictions.join(', ')}

Please exclude these meals from today's plan: $currentMeals

Keep the same nutritional values and meal structure, but replace only the specified ingredients with suitable alternatives.
""";

      // Определяем тип запроса
      LlmMealRequestType requestType;
      switch (params.meal.servingType) {
        case ServingType.breakfast:
          requestType = LlmMealRequestType.breakfast;
          break;
        case ServingType.snack:
          requestType = LlmMealRequestType.snack;
          break;
        case ServingType.dinner:
        case ServingType.lunch:
        case ServingType.supper:
          requestType = LlmMealRequestType.meal;
          break;
      }

      // Форматируем тип блюда согласно API
      final mealType = _formatMealTypeForRegeneration(
        params.meal.servingType,
        params.meal.type,
      );

      // Создаем целевое блюдо с макросами
      final targetMeal = LlmMealDto(
        type: mealType,
        kcal: params.meal.macros.kcal,
        protein: params.meal.macros.protein,
        carbs: params.meal.macros.carbs,
        fat: params.meal.macros.fat,
      );

      // Создаем запрос регенерации
      final request = LlmRegenerateMealRequest(
        type: requestType,
        message: message,
        targetMeal: targetMeal,
      );

      // Отправляем запрос
      final response = await _llmProxyClient.regenerateMeal(request);

      // Проверяем ответ
      if (response.containsKey('error')) {
        log('[replaceIngredientV2] Ошибка в ответе: ${response['error']}');
        return null;
      }

      if (!response.containsKey('meals') || response['meals'] == null) {
        log('[replaceIngredientV2] Нет блюд в ответе');
        return null;
      }

      final meals = response['meals'] as List;
      if (meals.isEmpty) {
        log('[replaceIngredientV2] Пустой список блюд');
        return null;
      }

      log('[replaceIngredientV2] Получено блюдо с замененными ингредиентами');
      final regeneratedMeal =
          Meal.fromMap(meals.first).copyWith(isRegenerated: true);

      // 🎯 ЗАМЕНЯЕМ ФАКТИЧЕСКИЕ МАКРОСЫ НА ЦЕЛЕВЫЕ
      final mealWithTargetMacros = regeneratedMeal.copyWith(
        macros: MacrosBreakdown(
          kcal: targetMeal.kcal,
          protein: targetMeal.protein,
          carbs: targetMeal.carbs,
          fat: targetMeal.fat,
        ),
      );

      log('[replaceIngredientV2] 🎯 Заменили макросы на целевые: ${targetMeal.kcal} ккал, ${targetMeal.protein}г белка, ${targetMeal.carbs}г углеводов, ${targetMeal.fat}г жиров');

      // Обновляем историю чата
      await updateChatHistory(
        'replaced ingredients in ${params.meal.title}: ${ingredientsToReplace.join(', ')}',
      );

      return mealWithTargetMacros;
    } catch (e) {
      log('[replaceIngredientV2] Ошибка: $e');
      return null;
    }
  }

  /// Форматирует тип блюда для регенерации согласно API
  String _formatMealTypeForRegeneration(
    ServingType servingType,
    String currentType,
  ) {
    switch (servingType) {
      case ServingType.breakfast:
        // Сохраняем текущий тип завтрака (Savoury/Sweet)
        if (currentType.toLowerCase().contains('sweet')) {
          return 'Sweet Breakfast';
        } else {
          return 'Savoury Breakfast';
        }
      case ServingType.snack:
        // Сохраняем текущий тип снека (Savoury/Sweet)
        if (currentType.toLowerCase().contains('sweet')) {
          return 'Sweet Snack';
        } else {
          return 'Savoury Snack';
        }
      case ServingType.lunch:
        return 'Lunch';
      case ServingType.dinner:
        return 'Dinner';
      case ServingType.supper:
        return 'Supper';
      default:
        return currentType; // Возвращаем оригинальный тип как fallback
    }
  }
}
