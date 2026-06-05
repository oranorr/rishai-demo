import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';

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
    required this.diet,
  });

  final LlmMealRequestType type;
  final String message;
  final List<LlmMealDto> meals;
  final String diet;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'diet': diet,
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

/// Модель ответа для анализа фотографий еды
class FoodPhotoAnalysisResponse {
  FoodPhotoAnalysisResponse({
    required this.nameOfMeal,
    required this.macrosBreakdown,
  });

  factory FoodPhotoAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return FoodPhotoAnalysisResponse(
      nameOfMeal: json['nameOfMeal'] as String,
      macrosBreakdown: MacrosBreakdownDto.fromJson(
        json['macrosBreakdown'] as Map<String, dynamic>,
      ),
    );
  }

  /// Название блюда
  final String nameOfMeal;

  /// Разбивка макронутриентов
  final MacrosBreakdownDto macrosBreakdown;
}

/// Модель для макронутриентов в ответе анализа фотографий
class MacrosBreakdownDto {
  MacrosBreakdownDto({
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.kcals,
  });

  factory MacrosBreakdownDto.fromJson(Map<String, dynamic> json) {
    return MacrosBreakdownDto(
      protein: json['protein'] as int,
      fats: json['fats'] as int,
      carbs: json['carbs'] as int,
      kcals: json['kcals'] as int,
    );
  }

  final int protein;
  final int fats;
  final int carbs;
  final int kcals;
}

/// Модель запроса для получения рекомендаций от ИИ
class RecommendationRequest {
  RecommendationRequest({
    required this.foodPreferences,
    required this.consumedMacros,
    required this.targetMacros,
    this.comment,
  });

  /// Предпочтения в еде (диеты, кухни, ограничения)
  final Map<String, dynamic> foodPreferences;

  /// Потребленные макросы
  final Map<String, dynamic> consumedMacros;

  /// Целевые макросы
  final Map<String, dynamic> targetMacros;

  /// [comment] Комментарий с предыдущей рекомендацией для генерации нового блюда
  final String? comment;

  Map<String, dynamic> toJson() => {
        'foodPreferences': foodPreferences,
        'consumedMacros': consumedMacros,
        'targetMacros': targetMacros,
        if (comment != null) 'comment': comment,
      };
}

/// HTTP клиент для взаимодействия с LLM прокси
@injectable
class LlmProxyClient {
  final UserServiceClient _userServiceClient = getIt.get<UserServiceClient>();

  static const String _stagingBaseUrl =
      'https://your-backend.example.com';
  static const String _productionBaseUrl =
      'https://your-backend.example.com';

  /// Определяем base URL в зависимости от окружения
  // TODO(dev): Replace with real environment detection logic
  String get _baseUrl {
    return _productionBaseUrl;
    // return kDebugMode
    //     ? _stagingBaseUrl
    //     : _productionBaseUrl;
  }

  Future<http.Response> _postJsonWithBearer({
    required String url,
    required Object body,
    required String context,
  }) {
    return _userServiceClient.sendAppBearerWithRetry(
      context: context,
      send: (headers) => http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ),
    );
  }

  /// Отправляет запрос к LLM прокси
  Future<List<LlmProxyResponse>> sendRequest(LlmProxyRequest request) async {
    try {
      log('🔄 Отправляем запрос к LLM прокси: ${request.type.name}');
      log('📝 Сообщение: ${request.message}');
      if (request.previousMessages != null) {
        log('📚 Предыдущих сообщений: ${request.previousMessages!.length}');
      }

      final response = await _postJsonWithBearer(
        url: '$_baseUrl/llm-proxy',
        context: 'POST /llm-proxy',
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

    throw Exception('No model response received');
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

      final response = await _postJsonWithBearer(
        url: url,
        context: 'POST /llm-proxy-chat',
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
          throw Exception('No model response received from new chat API');
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

    throw Exception('No model response received');
  }

  /// Отправляет запрос для генерации блюд с новой структурой API
  /// Включает retry логику для обработки HTTP 502 ошибок
  Future<Map<String, dynamic>> generateMeals(LlmMealRequest request) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        log('🔄 [generateMeals] Попытка ${retryCount + 1}/${maxRetries + 1} для ${request.type.name}');
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

        final response = await _postJsonWithBearer(
          url: url,
          context: 'POST /llm-proxy-meal',
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

          // Если это была повторная попытка, логируем успех
          if (retryCount > 0) {
            log('🎉 [generateMeals] Успешно получен ответ после $retryCount повторных попыток для ${request.type.name}');
          }

          return responseData;
        } else {
          // Проверяем, является ли это HTTP 502 ошибкой
          final is502Error = response.statusCode == 502;
          final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';

          log('❌ [generateMeals] Ошибка от LLM прокси URL: $url - Статус: ${response.statusCode} - Ответ: ${response.body}');

          // Если это 502 ошибка и у нас есть попытки, пробуем еще раз
          if (is502Error && retryCount < maxRetries) {
            retryCount++;
            final delaySeconds =
                retryCount * 5; // Экспоненциальная задержка: 5, 10, 15 секунд
            log('🔄 [generateMeals] HTTP 502 ошибка для ${request.type.name}, повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }

          // Если это не 502 ошибка или попытки исчерпаны, выбрасываем исключение
          throw Exception(errorMessage);
        }
      } catch (e) {
        final errorString = e.toString();
        final is502Error = errorString.contains('502');

        // Если это 502 ошибка и у нас есть попытки, пробуем еще раз
        if (is502Error && retryCount < maxRetries) {
          retryCount++;
          final delaySeconds =
              retryCount * 5; // Экспоненциальная задержка: 5, 10, 15 секунд
          log('💥 [generateMeals] HTTP 502 исключение для ${request.type.name}: $e');
          log('🔄 [generateMeals] Повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        // Если это не 502 ошибка или попытки исчерпаны, выбрасываем исключение
        log('💥 [generateMeals] Исключение при запросе к LLM прокси: $e');
        if (retryCount >= maxRetries) {
          log('❌ [generateMeals] Все ${maxRetries + 1} попытки исчерпаны для ${request.type.name}');
        }
        rethrow;
      }
    }

    // Этот код никогда не должен выполниться, но на всякий случай
    throw Exception('Неожиданная ошибка в retry логике generateMeals');
  }

  /// Отправляет запрос для регенерации блюда с новой структурой API
  /// Включает retry логику для обработки HTTP 502 ошибок
  Future<Map<String, dynamic>> regenerateMeal(
    LlmRegenerateMealRequest request,
  ) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        log('🔄 [regenerateMeal] Попытка ${retryCount + 1}/${maxRetries + 1} для ${request.type.name}');
        log('📝 [regenerateMeal] Сообщение: ${request.message}');
        log('🍽️ [regenerateMeal] Целевое блюдо: ${request.targetMeal.type} (${request.targetMeal.kcal} ккал, ${request.targetMeal.protein}г белка, ${request.targetMeal.carbs}г углеводов, ${request.targetMeal.fat}г жиров)');

        final url = '$_baseUrl/llm-proxy-meal';
        final requestBody = jsonEncode(request.toJson());

        // 🎯 ПОЛНЫЙ ЗАПРОС для регенерации
        log('📦 [regenerateMeal] ПОЛНЫЙ JSON ЗАПРОС:');
        log('📦 URL: $url');
        log('📦 BODY: $requestBody');

        final response = await _postJsonWithBearer(
          url: url,
          context: 'POST /llm-proxy-meal',
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

          // Если это была повторная попытка, логируем успех
          if (retryCount > 0) {
            log('🎉 [regenerateMeal] Успешно получен ответ после $retryCount повторных попыток для ${request.type.name}');
          }

          return responseData;
        } else {
          // Проверяем, является ли это HTTP 502 ошибкой
          final is502Error = response.statusCode == 502;
          final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';

          log('❌ [regenerateMeal] Ошибка от LLM прокси URL: $url - Статус: ${response.statusCode} - Ответ: ${response.body}');

          // Если это 502 ошибка и у нас есть попытки, пробуем еще раз
          if (is502Error && retryCount < maxRetries) {
            retryCount++;
            final delaySeconds =
                retryCount * 5; // Экспоненциальная задержка: 5, 10, 15 секунд
            log('🔄 [regenerateMeal] HTTP 502 ошибка для ${request.type.name}, повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }

          // Если это не 502 ошибка или попытки исчерпаны, выбрасываем исключение
          throw Exception(errorMessage);
        }
      } catch (e) {
        final errorString = e.toString();
        final is502Error = errorString.contains('502');

        // Если это 502 ошибка и у нас есть попытки, пробуем еще раз
        if (is502Error && retryCount < maxRetries) {
          retryCount++;
          final delaySeconds =
              retryCount * 5; // Экспоненциальная задержка: 5, 10, 15 секунд
          log('💥 [regenerateMeal] HTTP 502 исключение для ${request.type.name}: $e');
          log('🔄 [regenerateMeal] Повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        // Если это не 502 ошибка или попытки исчерпаны, выбрасываем исключение
        log('💥 [regenerateMeal] Исключение при запросе к LLM прокси: $e');
        if (retryCount >= maxRetries) {
          log('❌ [regenerateMeal] Все ${maxRetries + 1} попытки исчерпаны для ${request.type.name}');
        }
        rethrow;
      }
    }

    // Этот код никогда не должен выполниться, но на всякий случай
    throw Exception('Неожиданная ошибка в retry логике regenerateMeal');
  }

  /// [analyzeFoodPhoto] Отправляет фотографии еды на анализ
  ///
  /// Принимает до 5 фотографий и описание.
  /// Фотографии опциональны - можно передавать пустой массив.
  /// Возвращает название блюда и разбивку макронутриентов.
  ///
  /// Параметры:
  /// - [images] - список фотографий (XFile) от 0 до 5 штук (опционально)
  /// - [description] - описание/вопрос о еде
  ///
  /// Возвращает [FoodPhotoAnalysisResponse] с названием блюда и макросами
  Future<FoodPhotoAnalysisResponse> analyzeFoodPhoto({
    required List<XFile> images,
    required String description,
  }) async {
    try {
      log('🔄 [analyzeFoodPhoto] Отправка фотографий на анализ');
      log('📝 [analyzeFoodPhoto] Количество фотографий: ${images.length}');
      log('📝 [analyzeFoodPhoto] Описание: "$description"');

      final url = Uri.parse('$_baseUrl/llm-proxy-food-photo/analyze');
      log('📦 [analyzeFoodPhoto] URL: $url');

      Future<http.MultipartRequest> buildRequest(
        Map<String, String> headers,
      ) async {
        final request = http.MultipartRequest('POST', url)
          ..headers.addAll(headers)
          ..fields['description'] = description;

        // Добавляем изображения только если они есть
        if (images.isNotEmpty) {
          for (final image in images) {
            // Определяем MIME-тип на основе расширения файла
            String? mimeType;
            final extension = image.path.split('.').last.toLowerCase();

            switch (extension) {
              case 'jpg':
              case 'jpeg':
                mimeType = 'image/jpeg';
                break;
              case 'png':
                mimeType = 'image/png';
                break;
              case 'webp':
                mimeType = 'image/webp';
                break;
              case 'heic':
                mimeType = 'image/heic';
                break;
              case 'heif':
                mimeType = 'image/heif';
                break;
              default:
                mimeType = 'image/jpeg'; // По умолчанию
            }

            final multipartFile = await http.MultipartFile.fromPath(
              'images', // имя поля
              image.path,
              contentType: MediaType.parse(mimeType),
            );
            request.files.add(multipartFile);
            log('📷 [analyzeFoodPhoto] Добавлено изображение: ${image.path.split('/').last} (MIME: $mimeType)');
          }
        } else {
          log('📝 [analyzeFoodPhoto] Фотографии не переданы, анализ будет проводиться только на основе описания');
        }

        return request;
      }

      log('📤 [analyzeFoodPhoto] Отправка запроса...');

      final response = await _userServiceClient.sendAppBearerWithRetry(
        includeContentType: false,
        context: 'POST /llm-proxy-food-photo/analyze',
        send: (headers) async {
          final request = await buildRequest(headers);
          final streamedResponse = await request.send();
          return http.Response.fromStream(streamedResponse);
        },
      );

      final responseData = response.body;

      log('📥 [analyzeFoodPhoto] Получен ответ: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('📦 [analyzeFoodPhoto] ПОЛНЫЙ JSON ОТВЕТ: $responseData');

        // Парсим JSON ответ
        final jsonResponse = json.decode(responseData) as Map<String, dynamic>;
        final analysisResponse =
            FoodPhotoAnalysisResponse.fromJson(jsonResponse);

        log('✅ [analyzeFoodPhoto] Успешно проанализировано');
        log('🍽️ [analyzeFoodPhoto] Блюдо: ${analysisResponse.nameOfMeal}');
        log('📊 [analyzeFoodPhoto] Макросы: P=${analysisResponse.macrosBreakdown.protein}г, F=${analysisResponse.macrosBreakdown.fats}г, C=${analysisResponse.macrosBreakdown.carbs}г, K=${analysisResponse.macrosBreakdown.kcals}ккал');

        return analysisResponse;
      } else {
        log('❌ [analyzeFoodPhoto] Ошибка от сервера: ${response.statusCode} - $responseData');
        throw Exception(
          'HTTP ${response.statusCode}: $responseData',
        );
      }
    } catch (e) {
      log('💥 [analyzeFoodPhoto] Исключение при анализе фотографий: $e');
      rethrow;
    }
  }

  /// [getRecommendation] Получает рекомендацию от ИИ на основе предпочтений и макросов
  ///
  /// Отправляет запрос к endpoint `/recommend` с предпочтениями в еде,
  /// потребленными и целевыми макросами.
  ///
  /// Параметры:
  /// - [request] - запрос с предпочтениями и макросами
  ///
  /// Возвращает [String?] - текст рекомендации или null при ошибке
  /// Включает retry логику для обработки HTTP 500 и 502 ошибок
  Future<String?> getRecommendation(RecommendationRequest request) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        log('[RecommendationsWidget] 🔄 Попытка ${retryCount + 1}/${maxRetries + 1} - Отправляем запрос к /recommend');
        log('[RecommendationsWidget] 📝 Предпочтения: ${request.foodPreferences}');
        log('[RecommendationsWidget] 📊 Потребленные макросы: ${request.consumedMacros}');
        log('[RecommendationsWidget] 🎯 Целевые макросы: ${request.targetMacros}');

        final url = '$_baseUrl/recommend';
        final requestBody = jsonEncode(request.toJson());

        log('[RecommendationsWidget] 📦 URL: $url');
        log('[RecommendationsWidget] 📦 BODY: $requestBody');

        final response = await _postJsonWithBearer(
          url: url,
          context: 'POST /recommend',
          body: requestBody,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // API возвращает JSON объект с полем "recommendation"
          try {
            final responseData =
                jsonDecode(response.body) as Map<String, dynamic>;
            final recommendation = responseData['recommendation'] as String?;

            if (recommendation != null && recommendation.isNotEmpty) {
              // Если это была повторная попытка, логируем успех
              if (retryCount > 0) {
                log('[RecommendationsWidget] 🎉 Успешно получена рекомендация после $retryCount повторных попыток');
              }

              log('[RecommendationsWidget] ✅ Получена рекомендация: ${recommendation.substring(0, recommendation.length > 100 ? 100 : recommendation.length)}...');
              return recommendation;
            } else {
              log('[RecommendationsWidget] ⚠️ Поле "recommendation" пустое или отсутствует');
              return null;
            }
          } catch (e) {
            log('[RecommendationsWidget] ❌ Ошибка парсинга JSON ответа: $e');
            log('[RecommendationsWidget] 📦 Тело ответа: ${response.body}');
            // Ошибка парсинга не требует ретрая, возвращаем null
            return null;
          }
        } else {
          // Проверяем, является ли это HTTP 500 или 502 ошибкой (временные ошибки сервера)
          final isRetryableError =
              response.statusCode == 500 || response.statusCode == 502;
          final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';

          log('[RecommendationsWidget] ❌ Ошибка от API: ${response.statusCode} - ${response.body}');

          // Если это 500 или 502 ошибка и у нас есть попытки, пробуем еще раз
          if (isRetryableError && retryCount < maxRetries) {
            retryCount++;
            // Задержки между попытками: 3, 4, 5 секунд
            final delays = [3, 4, 5];
            final delaySeconds = delays[retryCount - 1];
            log('[RecommendationsWidget] 🔄 HTTP ${response.statusCode} ошибка, повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }

          // Если это не 500/502 ошибка или попытки исчерпаны, возвращаем null
          log('[RecommendationsWidget] ❌ Не удалось получить рекомендацию: $errorMessage');
          return null;
        }
      } catch (e) {
        final errorString = e.toString();
        // Проверяем, является ли это HTTP 500 или 502 ошибкой (временные ошибки сервера)
        final isRetryableError = errorString.contains('500') ||
            errorString.contains('502') ||
            errorString.contains('Internal Server Error') ||
            errorString.contains('Bad Gateway') ||
            errorString.contains('502 Bad Gateway') ||
            errorString.contains('500 Internal Server Error');

        // Если это 500 или 502 ошибка и у нас есть попытки, пробуем еще раз
        if (isRetryableError && retryCount < maxRetries) {
          retryCount++;
          // Задержки между попытками: 3, 4, 5 секунд
          final delays = [3, 4, 5];
          final delaySeconds = delays[retryCount - 1];
          log('[RecommendationsWidget] 💥 HTTP 500/502 исключение: $e');
          log('[RecommendationsWidget] 🔄 Повторяем через $delaySecondsс (попытка ${retryCount + 1}/${maxRetries + 1})');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        // Если это не 500/502 ошибка или попытки исчерпаны, логируем и возвращаем null
        log('[RecommendationsWidget] 💥 Исключение при запросе рекомендации: $e');
        if (retryCount >= maxRetries) {
          log('[RecommendationsWidget] ❌ Все ${maxRetries + 1} попытки исчерпаны');
        }
        return null;
      }
    }

    // Этот код никогда не должен выполниться, но на всякий случай
    log('[RecommendationsWidget] ❌ Неожиданная ошибка в retry логике getRecommendation');
    return null;
  }
}
