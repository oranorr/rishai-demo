import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/envied/envied.dart';

/// Исключение User Service API с кодом ошибки для маппинга на Failure
class UserServiceException implements Exception {
  UserServiceException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'UserServiceException(code: $code, message: $message)';
}

/// HTTP-клиент для User Service API (Pivot backend)
///
/// Использует те же base URL и auth header, что и LlmProxyClient.
/// Все методы выбрасывают [UserServiceException] при ошибках API.
@injectable
class UserServiceClient {
  static const String _stagingBaseUrl =
      'https://pivot-backend-staging-676768388165.us-central1.run.app';
  static const String _productionBaseUrl =
      'https://pivot-backend-production-676768388165.us-central1.run.app';
  static const String _authHeaderKey = 'pivot-identity-key';
  static const String _authHeaderValue = Env.authHeaderKey;
  static const String _userIdHeaderKey = 'x-user-id';

  String get _baseUrl =>
      kDebugMode ? _stagingBaseUrl : _productionBaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        _authHeaderKey: _authHeaderValue,
      };

  Map<String, String> _whoopHeaders({
    required String userId,
    bool includeContentType = true,
  }) {
    return {
      if (includeContentType) 'Content-Type': 'application/json',
      _authHeaderKey: _authHeaderValue,
      _userIdHeaderKey: userId,
    };
  }

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final sanitizedQueryParameters = queryParameters?.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: sanitizedQueryParameters,
    );
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String code = 'UNKNOWN';
    String message = response.body;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == false && json['error'] != null) {
        final error = json['error'] as Map<String, dynamic>;
        code = (error['code'] as String?) ?? code;
        message = (error['message'] as String?) ?? message;
      }
    } catch (_) {}

    log(
      '[UserServiceClient] API error: ${response.statusCode} - $code: $message',
      name: 'UserServiceClient',
    );
    throw UserServiceException(
      code: code,
      message: message,
      statusCode: response.statusCode,
    );
  }

  /// POST /users/create — создание пользователя (email-регистрация)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String name,
    required String code,
  }) async {
    log('[createUser] email=$email', name: 'UserServiceClient');

    final response = await http.post(
      Uri.parse('$_baseUrl/users/create'),
      headers: _headers,
      body: jsonEncode({'email': email, 'name': name, 'code': code}),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /users/login — логин по email + OTP
  Future<Map<String, dynamic>> login({
    required String email,
    required String code,
  }) async {
    log('[login] email=$email', name: 'UserServiceClient');

    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'code': code}),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /users/login-oauth — OAuth (Google/Apple)
  Future<Map<String, dynamic>> loginOAuth({
    required String email,
    required String name,
    required String provider,
  }) async {
    log('[loginOAuth] email=$email, provider=$provider', name: 'UserServiceClient');

    final response = await http.post(
      Uri.parse('$_baseUrl/users/login-oauth'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'name': name,
        'provider': provider,
      }),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /users/:id — получение пользователя по id
  Future<Map<String, dynamic>> getUser(String id) async {
    log('[getUser] id=$id', name: 'UserServiceClient');

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /users/:id — обновление пользователя (частичный payload)
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> body) async {
    log('[updateUser] id=$id', name: 'UserServiceClient');

    // Исключаем directusId из body — id только в URL
    final cleanBody = Map<String, dynamic>.from(body)..remove('directusId');

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(cleanBody),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /users/:id — удаление аккаунта (204 No Content)
  Future<void> deleteUser(String id) async {
    log('[deleteUser] id=$id', name: 'UserServiceClient');

    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
    );

    _throwOnError(response);
  }

  /// POST /whoop/exchange-code — обмен authorization code на WHOOP токены.
  Future<void> exchangeWhoopCode({
    required String userId,
    required String code,
    String? redirectUri,
  }) async {
    log('[exchangeWhoopCode] userId=$userId', name: 'UserServiceClient');

    final body = <String, dynamic>{'code': code};
    if (redirectUri != null && redirectUri.isNotEmpty) {
      body['redirectUri'] = redirectUri;
    }

    final response = await http.post(
      _buildUri('/whoop/exchange-code'),
      headers: _whoopHeaders(userId: userId),
      body: jsonEncode(body),
    );

    _throwOnError(response);
  }

  /// POST /whoop/disconnect — отключение WHOOP на бэкенде.
  Future<void> disconnectWhoop({required String userId}) async {
    log('[disconnectWhoop] userId=$userId', name: 'UserServiceClient');

    final response = await http.post(
      _buildUri('/whoop/disconnect'),
      headers: _whoopHeaders(userId: userId, includeContentType: false),
    );

    _throwOnError(response);
  }

  /// GET /whoop/status — состояние подключения WHOOP.
  Future<Map<String, dynamic>> getWhoopStatus({required String userId}) async {
    log('[getWhoopStatus] userId=$userId', name: 'UserServiceClient');

    final response = await http.get(
      _buildUri('/whoop/status'),
      headers: _whoopHeaders(userId: userId, includeContentType: false),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWhoopCycles({
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/cycles',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getWhoopCycleById({
    required String userId,
    required int cycleId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/cycle/$cycleId',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getWhoopRecovery({
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/recovery',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getWhoopBody({
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/body',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getWhoopWorkouts({
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/workouts',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getWhoopSleep({
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getWhoopJson(
      '/whoop/sleep',
      userId: userId,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _getWhoopJson(
    String path, {
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await http.get(
      _buildUri(path, queryParameters: queryParameters),
      headers: _whoopHeaders(userId: userId, includeContentType: false),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
