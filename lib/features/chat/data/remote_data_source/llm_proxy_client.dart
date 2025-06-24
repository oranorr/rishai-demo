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

  /// Отправляет чат сообщение
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
}
