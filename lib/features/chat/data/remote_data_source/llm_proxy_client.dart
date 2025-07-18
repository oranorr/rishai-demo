import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/envied/envied.dart';

/// Типы запросов к LLM прокси
enum LlmRequestType {
  chat,
  breakfast,
  meal,
  snack,
}

/// Модель для предыдущих сообщений
class PreviousMessage {
  // 'user' | 'model'

  PreviousMessage({
    required this.text,
    required this.role,
  });
  final String text;
  final String role;

  Map<String, dynamic> toJson() => {
        'text': text,
        'role': role,
      };
}

/// Модель для запроса к LLM прокси
class LlmProxyRequest {
  LlmProxyRequest({
    required this.type,
    required this.message,
    this.previousMessages,
  });
  final LlmRequestType type;
  final String message;
  final List<PreviousMessage>? previousMessages;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        if (previousMessages != null)
          'previousMessages': previousMessages!.map((m) => m.toJson()).toList(),
      };
}

/// Модель для ответа от LLM прокси
class LlmProxyResponse {
  // 'user' | 'model'

  LlmProxyResponse({
    required this.text,
    required this.role,
  });

  factory LlmProxyResponse.fromJson(Map<String, dynamic> json) {
    return LlmProxyResponse(
      text: json['text'] as String,
      role: json['role'] as String,
    );
  }
  final String text;
  final String role;
}

/// Модель для запроса к новому чат endpoint'у /llm-proxy-chat
class LlmChatRequest {
  LlmChatRequest({
    required this.message,
    this.previousMessages,
  });
  final String message;
  final List<PreviousMessage>? previousMessages;

  Map<String, dynamic> toJson() => {
        'message': message,
        if (previousMessages != null)
          'previousMessages': previousMessages!.map((m) => m.toJson()).toList(),
      };
}

/// Модель для ответа от нового чат endpoint'а /llm-proxy-chat
class LlmChatResponse {
  LlmChatResponse({
    required this.message,
  });

  factory LlmChatResponse.fromJson(Map<String, dynamic> json) {
    return LlmChatResponse(
      message: json['message'] as String,
    );
  }
  final String message;
}

/// Типы запросов для генерации блюд
enum LlmMealRequestType {
  breakfast,
  meal,
  snack,
}

/// Модель отдельного блюда в запросе
class LlmMealDto {
  LlmMealDto({
    required this.type,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Тип блюда: "Lunch", "Dinner", "Supper", "Savoury Breakfast", "Sweet Breakfast", "Savoury Snack", "Sweet Snack"
  final String type;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  Map<String, dynamic> toJson() => {
        'type': type,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

/// Модель запроса для генерации блюд
class LlmMealRequest {
  LlmMealRequest({
    required this.type,
    required this.message,
    required this.meals,
  });

  final LlmMealRequestType type;
  final String message;
  final List<LlmMealDto> meals;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'meals': meals.map((meal) => meal.toJson()).toList(),
      };
}

/// Модель запроса для регенерации блюда
class LlmRegenerateMealRequest {
  LlmRegenerateMealRequest({
    required this.type,
    required this.message,
    required this.targetMeal,
  });

  /// Тип блюда для регенерации
  final LlmMealRequestType type;

  /// Сообщение с описанием что нужно заменить/изменить
  final String message;

  /// Целевое блюдо с требуемыми макросами
  final LlmMealDto targetMeal;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'meals': [
          targetMeal.toJson(),
        ], // Оборачиваем в массив для совместимости с API
      };
}

/// HTTP клиент для взаимодействия с LLM прокси
@injectable
class LlmProxyClient {
  static const String _stagingBaseUrl =
      'https://pivot-backend-staging-676768388165.us-central1.run.app';
  static const String _productionBaseUrl =
      'https://pivot-backend-production-676768388165.us-central1.run.app';
  static const String _authHeaderKey = 'pivot-identity-key';
  static const String _authHeaderValue = Env.authHeaderKey;

  /// Определяем base URL в зависимости от окружения
  // TODO(dev): Replace with real environment detection logic
  String get _baseUrl {
    // Временно используем staging для разработки
    // В продакшене нужно будет определить правильную логику
    return kDebugMode
        ? _stagingBaseUrl
        : _productionBaseUrl; // TODO(dev): Replace with real environment check
  }

  /// Отправляет запрос к LLM прокси
  Future<List<LlmProxyResponse>> sendRequest(LlmProxyRequest request) async {
    try {
      log('🔄 Отправляем запрос к LLM прокси: ${request.type.name}');
      log('📝 Сообщение: ${request.message}');
      if (request.previousMessages != null) {
        log('📚 Предыдущих сообщений: ${request.previousMessages!.length}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/llm-proxy'),
        headers: {
          'Content-Type': 'application/json',
          _authHeaderKey: _authHeaderValue,
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<LlmProxyResponse> responses = responseData
            .map((item) => LlmProxyResponse.fromJson(item))
            .toList();

        log('✅ Получен ответ от LLM прокси: ${responses.length} сообщений');
        for (int i = 0; i < responses.length; i++) {
          log('📨 Сообщение $i (${responses[i].role}): ${responses[i].text}');
        }

        return responses;
      } else {
        log('❌ Ошибка от LLM прокси: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('💥 Исключение при запросе к LLM прокси: $e');
      rethrow;
    }
  }

  /// Отправляет чат сообщение (старый метод для совместимости)
  Future<String> sendChatMessage(
    String message, {
    List<PreviousMessage>? previousMessages,
  }) async {
    final request = LlmProxyRequest(
      type: LlmRequestType.chat,
      message: message,
      previousMessages: previousMessages,
    );

    final responses = await sendRequest(request);

    // Возвращаем последний ответ от модели
    final modelResponses = responses.where((r) => r.role == 'model').toList();
    if (modelResponses.isNotEmpty) {
      return modelResponses.last.text;
    }

    throw Exception('Не получен ответ от модели');
  }

  /// Отправляет чат сообщение через новый endpoint /llm-proxy-chat
  Future<String> sendChatMessageV2(
    String message, {
    List<PreviousMessage>? previousMessages,
  }) async {
    try {
      log('🔄 [ChatV2] Отправляем чат сообщение через /llm-proxy-chat');
      log('📝 [ChatV2] Сообщение: $message');
      if (previousMessages != null) {
        log('📚 [ChatV2] Предыдущих сообщений: ${previousMessages.length}');
      }

      final request = LlmChatRequest(
        message: message,
        previousMessages: previousMessages,
      );

      final url = '$_baseUrl/llm-proxy-chat';
      final requestBody = jsonEncode(request.toJson());

      log('📦 [ChatV2] ПОЛНЫЙ JSON ЗАПРОС:');
      log('📦 [ChatV2] URL: $url');
      log('📦 [ChatV2] BODY: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          _authHeaderKey: _authHeaderValue,
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API возвращает массив сообщений, как в старом API
        final List<dynamic> responseData = jsonDecode(response.body);
        final List<LlmProxyResponse> responses = responseData
            .map((item) => LlmProxyResponse.fromJson(item))
            .toList();

        log('✅ [ChatV2] Получен ответ от чат API: ${responses.length} сообщений');
        for (int i = 0; i < responses.length; i++) {
          log('📨 [ChatV2] Сообщение $i (${responses[i].role}): ${responses[i].text}');
        }

        // Возвращаем последний ответ от модели
        final modelResponses =
            responses.where((r) => r.role == 'model').toList();
        if (modelResponses.isNotEmpty) {
          final message = modelResponses.last.text;
          log('💬 [ChatV2] Финальное сообщение: $message');
          return message;
        } else {
          log('⚠️ [ChatV2] Не найдено ответов от модели');
          throw Exception('Не получен ответ от модели в новом чат API');
        }
      } else {
        log('❌ [ChatV2] Ошибка от чат API: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('💥 [ChatV2] Исключение при запросе к чат API: $e');
      rethrow;
    }
  }

  /// Отправляет запрос для генерации блюда
  Future<String> generateMeal(
    LlmRequestType type,
    String prompt, {
    List<PreviousMessage>? previousMessages,
  }) async {
    final request = LlmProxyRequest(
      type: type,
      message: prompt,
      previousMessages: previousMessages,
    );

    final responses = await sendRequest(request);

    log('🔍 Получено ${responses.length} ответов от LLM прокси');

    // Возвращаем последний ответ от модели
    final modelResponses = responses.where((r) => r.role == 'model').toList();
    log('🔍 Найдено ${modelResponses.length} ответов от модели');

    if (modelResponses.isNotEmpty) {
      final response = modelResponses.last.text;
      log('✅ Возвращаем ответ от модели: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      return response;
    }

    throw Exception('Не получен ответ от модели');
  }

  /// Отправляет запрос для генерации блюд с новой структурой API
  Future<Map<String, dynamic>> generateMeals(LlmMealRequest request) async {
    try {
      log('🔄 [generateMeals] Отправляем запрос генерации блюд: ${request.type.name}');
      log('📝 [generateMeals] Сообщение: ${request.message}');
      log('🍽️ [generateMeals] Блюд в запросе: ${request.meals.length}');

      for (int i = 0; i < request.meals.length; i++) {
        final meal = request.meals[i];
        log('📋 [generateMeals] Блюдо $i: ${meal.type} (${meal.kcal} ккал, ${meal.protein}г белка, ${meal.carbs}г углеводов, ${meal.fat}г жиров)');
      }

      final url = '$_baseUrl/llm-proxy-meal';
      final requestBody = jsonEncode(request.toJson());

      // 🎯 ПОЛНЫЙ ЗАПРОС - вот что вы хотели увидеть!
      log('📦 [generateMeals] ПОЛНЫЙ JSON ЗАПРОС:');
      log('📦 URL: $url');
      log('📦 BODY: $requestBody');

      final response = await http.post(
        Uri.parse(url), // Используем новый эндпоинт для блюд
        headers: {
          'Content-Type': 'application/json',
          _authHeaderKey: _authHeaderValue,
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        log('✅ [generateMeals] Получен ответ от LLM прокси: ${responseData.keys.join(', ')}');

        // 🎯 ПОЛНЫЙ ОТВЕТ - тоже может быть полезно
        log('📦 [generateMeals] ПОЛНЫЙ JSON ОТВЕТ: ${jsonEncode(responseData)}');

        // Проверяем наличие meals в ответе
        if (responseData.containsKey('meals')) {
          final meals = responseData['meals'] as List?;
          log('🍽️ [generateMeals] Получено блюд: ${meals?.length ?? 0}');
        }

        return responseData;
      } else {
        log('❌ [generateMeals] Ошибка от LLM прокси URL: $url - Статус: ${response.statusCode} - Ответ: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('💥 [generateMeals] Исключение при запросе к LLM прокси: $e');
      rethrow;
    }
  }

  /// Отправляет запрос для регенерации блюда с новой структурой API
  Future<Map<String, dynamic>> regenerateMeal(
      LlmRegenerateMealRequest request) async {
    try {
      log('🔄 [regenerateMeal] Отправляем запрос регенерации блюда: ${request.type.name}');
      log('📝 [regenerateMeal] Сообщение: ${request.message}');
      log('🍽️ [regenerateMeal] Целевое блюдо: ${request.targetMeal.type} (${request.targetMeal.kcal} ккал, ${request.targetMeal.protein}г белка, ${request.targetMeal.carbs}г углеводов, ${request.targetMeal.fat}г жиров)');

      final url = '$_baseUrl/llm-proxy-meal';
      final requestBody = jsonEncode(request.toJson());

      // 🎯 ПОЛНЫЙ ЗАПРОС для регенерации
      log('📦 [regenerateMeal] ПОЛНЫЙ JSON ЗАПРОС:');
      log('📦 URL: $url');
      log('📦 BODY: $requestBody');

      final response = await http.post(
        Uri.parse(url), // Используем тот же эндпоинт что и для генерации блюд
        headers: {
          'Content-Type': 'application/json',
          _authHeaderKey: _authHeaderValue,
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        log('✅ [regenerateMeal] Получен ответ от LLM прокси: ${responseData.keys.join(', ')}');

        // 🎯 ПОЛНЫЙ ОТВЕТ регенерации
        log('📦 [regenerateMeal] ПОЛНЫЙ JSON ОТВЕТ: ${jsonEncode(responseData)}');

        // Проверяем наличие meals в ответе
        if (responseData.containsKey('meals')) {
          final meals = responseData['meals'] as List?;
          log('🍽️ [regenerateMeal] Получено регенерированных блюд: ${meals?.length ?? 0}');
        }

        return responseData;
      } else {
        log('❌ [regenerateMeal] Ошибка от LLM прокси URL: $url - Статус: ${response.statusCode} - Ответ: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('💥 [regenerateMeal] Исключение при запросе к LLM прокси: $e');
      rethrow;
    }
  }
}
