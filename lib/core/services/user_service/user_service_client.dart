import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';

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
/// Публичные `/auth/*` — только `Content-Type` (см. FRONTEND_AUTH_AND_OTP.md).
/// После `verify-otp` / `refresh` — защищённые запросы с `Authorization: Bearer`.
/// Все методы выбрасывают [UserServiceException] при ошибках API.
@injectable
class UserServiceClient {
  UserServiceClient(this._prefs);

  final PrefsRepository _prefs;

  static const String _stagingBaseUrl =
      'https://pivot-backend-staging-676768388165.us-central1.run.app';
  // ignore: unused_field — переключение prod/staging через kDebugMode в будущем.
  static const String _productionBaseUrl =
      'https://pivot-backend-production-676768388165.us-central1.run.app';
  static const String _authHeaderKey = 'pivot-identity-key';
  static const String _authHeaderValue = Env.authHeaderKey;
  static const String _userIdHeaderKey = 'x-user-id';

  /// За сколько секунд до истечения access вызывать проактивный refresh.
  static const int _accessRefreshSkewSeconds = 90;

  String get _baseUrl => _stagingBaseUrl;
  // kDebugMode ? _stagingBaseUrl : _productionBaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        _authHeaderKey: _authHeaderValue,
      };

  /// Заголовки для публичных `/auth/*` (без pivot, без Bearer).
  Map<String, String> get _publicJsonHeaders => {
        'Content-Type': 'application/json',
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

  /// С [Bearer] — только Authorization (без `x-user-id`, см. доку).
  /// Без токена — legacy pivot + `x-user-id`.
  Map<String, String> _userScopedHeaders({
    required String userId,
    bool includeContentType = true,
  }) {
    final access = _prefs.fetchAppAccessToken();
    if (access.isNotEmpty) {
      return {
        if (includeContentType) 'Content-Type': 'application/json',
        'Authorization': 'Bearer $access',
      };
    }
    return _whoopHeaders(
        userId: userId, includeContentType: includeContentType);
  }

  /// Заголовки для `GET|PUT|DELETE /users/me` (только при наличии access JWT).
  Map<String, String> _bearerOnlyHeaders({bool includeContentType = true}) {
    final access = _prefs.fetchAppAccessToken();
    return {
      if (includeContentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $access',
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

  /// Парсит [AuthTokensResponseDto] и сохраняет в prefs (отдельно от WHOOP).
  Future<void> _persistTokensFromAuthJson(Map<String, dynamic> json) async {
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final expiresInRaw = json['expires_in'];
    final expiresIn = expiresInRaw is int
        ? expiresInRaw
        : int.tryParse('$expiresInRaw') ?? 900;
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw UserServiceException(
        code: 'INVALID_TOKEN_RESPONSE',
        message: 'Missing access_token or refresh_token in auth response',
        statusCode: 500,
      );
    }
    await _prefs.writeAppJwtSession(
      accessToken: access,
      refreshToken: refresh,
      expiresInSeconds: expiresIn,
    );
  }

  /// Внутренний refresh по сохранённому refresh (публичный endpoint).
  Future<void> _refreshTokensInternal() async {
    final refresh = _prefs.fetchAppRefreshToken();
    if (refresh.isEmpty) {
      await _prefs.clearAppJwtSession();
      throw UserServiceException(
        code: 'NO_REFRESH_TOKEN',
        message: 'No refresh token stored',
        statusCode: 401,
      );
    }

    log('[_refreshTokensInternal] refreshing access',
        name: 'UserServiceClient');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: _publicJsonHeaders,
      body: jsonEncode({'refresh_token': refresh}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _prefs.clearAppJwtSession();
      _throwOnError(response);
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    await _persistTokensFromAuthJson(map);
  }

  /// Проактивный refresh, если access скоро истечёт или отсутствует при наличии refresh.
  Future<void> _ensureAppAccessFreshIfNeeded() async {
    final refresh = _prefs.fetchAppRefreshToken();
    if (refresh.isEmpty) return;

    final access = _prefs.fetchAppAccessToken();
    if (access.isEmpty) {
      await _refreshTokensInternal();
      return;
    }

    final exp = _prefs.getAppAccessTokenExpiry();
    if (exp == null) {
      await _refreshTokensInternal();
      return;
    }

    final threshold = exp.subtract(
      const Duration(seconds: _accessRefreshSkewSeconds),
    );
    if (!DateTime.now().isBefore(threshold)) {
      await _refreshTokensInternal();
    }
  }

  /// Один цикл: optional proactive refresh → запрос → при 401 один refresh → повтор.
  Future<http.Response> _sendUserScopedWithRetry({
    required String userId,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    await _ensureAppAccessFreshIfNeeded();
    Map<String, String> headers() => _userScopedHeaders(userId: userId);

    var response = await send(headers());
    if (response.statusCode == 401 &&
        _prefs.fetchAppRefreshToken().isNotEmpty) {
      try {
        await _refreshTokensInternal();
      } catch (_) {
        _throwOnError(response);
      }
      response = await send(headers());
    }
    return response;
  }

  /// То же для GET без Content-Type в заголовках.
  Future<http.Response> _sendUserScopedGetWithRetry({
    required String userId,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    await _ensureAppAccessFreshIfNeeded();
    Map<String, String> headers() =>
        _userScopedHeaders(userId: userId, includeContentType: false);

    var response = await send(headers());
    if (response.statusCode == 401 &&
        _prefs.fetchAppRefreshToken().isNotEmpty) {
      try {
        await _refreshTokensInternal();
      } catch (_) {
        _throwOnError(response);
      }
      response = await send(headers());
    }
    return response;
  }

  Future<http.Response> _sendBearerMeWithRetry({
    required Future<http.Response> Function(Map<String, String> headers) send,
    bool includeContentType = true,
  }) async {
    await _ensureAppAccessFreshIfNeeded();
    Map<String, String> headers() =>
        _bearerOnlyHeaders(includeContentType: includeContentType);

    var response = await send(headers());
    if (response.statusCode == 401 &&
        _prefs.fetchAppRefreshToken().isNotEmpty) {
      try {
        await _refreshTokensInternal();
      } catch (_) {
        _throwOnError(response);
      }
      response = await send(headers());
    }
    return response;
  }

  // --- Публичные auth (без pivot / Bearer) ---

  /// POST /auth/request-otp
  Future<void> requestOtp({required String email}) async {
    log('[requestOtp] email=$email', name: 'UserServiceClient');
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/request-otp'),
      headers: _publicJsonHeaders,
      body: jsonEncode({'email': email}),
    );
    _throwOnError(response);
  }

  /// POST /auth/verify-otp — сохраняет JWT в prefs.
  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    log('[verifyOtp] email=$email', name: 'UserServiceClient');
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: _publicJsonHeaders,
      body: jsonEncode({'email': email, 'code': code}),
    );
    _throwOnError(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    await _persistTokensFromAuthJson(map);
  }

  /// POST /users/create — создание пользователя (email-регистрация).
  ///
  /// [code] опционален: новый поток — create → request-otp → verify-otp.
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String name,
    String? code,
  }) async {
    log('[createUser] email=$email', name: 'UserServiceClient');

    final body = <String, dynamic>{'email': email, 'name': name};
    if (code != null && code.isNotEmpty) {
      body['code'] = code;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/users/create'),
      headers: _headers,
      body: jsonEncode(body),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /users/login — legacy логин по email + OTP (оставлен для совместимости).
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
    log(
      '[loginOAuth] email=$email, provider=$provider',
      name: 'UserServiceClient',
    );

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

  /// GET /users/me — текущий пользователь по JWT (`sub`).
  Future<Map<String, dynamic>> getMe() async {
    log('[getMe]', name: 'UserServiceClient');

    final response = await _sendBearerMeWithRetry(
      includeContentType: false,
      send: (h) => http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /users/:id — получение пользователя по id (legacy без JWT).
  Future<Map<String, dynamic>> getUser(String id) async {
    if (_prefs.hasAppAccessToken()) {
      log('[getUser] JWT present -> delegating to getMe()',
          name: 'UserServiceClient');
      return getMe();
    }
    log('[getUser] id=$id', name: 'UserServiceClient');

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /users/me — обновление текущего пользователя (JWT).
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    log('[updateMe]', name: 'UserServiceClient');

    final cleanBody = Map<String, dynamic>.from(body)..remove('directusId');

    final response = await _sendBearerMeWithRetry(
      send: (h) => http.put(
        Uri.parse('$_baseUrl/users/me'),
        headers: h,
        body: jsonEncode(cleanBody),
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /users/:id — обновление пользователя (частичный payload), legacy.
  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> body,
  ) async {
    if (_prefs.hasAppAccessToken()) {
      log('[updateUser] JWT present -> delegating to updateMe()',
          name: 'UserServiceClient');
      return updateMe(body);
    }
    log('[updateUser] id=$id', name: 'UserServiceClient');

    final cleanBody = Map<String, dynamic>.from(body)..remove('directusId');

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(cleanBody),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /users/me — удаление аккаунта (JWT).
  Future<void> deleteMe() async {
    log('[deleteMe]', name: 'UserServiceClient');

    final response = await _sendBearerMeWithRetry(
      includeContentType: false,
      send: (h) => http.delete(
        Uri.parse('$_baseUrl/users/me'),
        headers: h,
      ),
    );

    _throwOnError(response);
  }

  /// DELETE /users/:id — удаление аккаунта (204 No Content), legacy.
  Future<void> deleteUser(String id) async {
    if (_prefs.hasAppAccessToken()) {
      log('[deleteUser] JWT present -> delegating to deleteMe()',
          name: 'UserServiceClient');
      return deleteMe();
    }
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

    final response = await _sendUserScopedWithRetry(
      userId: userId,
      send: (h) => http.post(
        _buildUri('/whoop/exchange-code'),
        headers: h,
        body: jsonEncode(body),
      ),
    );

    _throwOnError(response);
  }

  /// POST /whoop/disconnect — отключение WHOOP на бэкенде.
  Future<void> disconnectWhoop({required String userId}) async {
    log('[disconnectWhoop] userId=$userId', name: 'UserServiceClient');

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.post(
        _buildUri('/whoop/disconnect'),
        headers: h,
      ),
    );

    _throwOnError(response);
  }

  /// GET /whoop/status — состояние подключения WHOOP.
  Future<Map<String, dynamic>> getWhoopStatus({required String userId}) async {
    log('[getWhoopStatus] userId=$userId', name: 'UserServiceClient');

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri('/whoop/status'),
        headers: h,
      ),
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

  /// GET /days/current — получить или пересчитать текущий день пользователя.
  Future<Map<String, dynamic>> getCurrentDay({
    required String userId,
    bool forceRefresh = false,
  }) async {
    log(
      '[getCurrentDay] userId=$userId, forceRefresh=$forceRefresh',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(
          '/days/current',
          queryParameters: forceRefresh ? {'forceRefresh': true} : null,
        ),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /days — получить историю дней пользователя с пагинацией.
  Future<Map<String, dynamic>> getDays({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    log(
      '[getDays] userId=$userId, limit=$limit, offset=$offset',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(
          '/days',
          queryParameters: {
            'limit': limit,
            'offset': offset,
          },
        ),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // --- Week plans (User API, не Directus) ---

  /// Нормализует тело ответа [GET /week-plans?limit&offset] в список карт, совместимых с
  /// [WeekPlanEntity.fromMap] (те же поля, что в Directus / WeekPlanResponseDto).
  static List<Map<String, dynamic>> weekPlanListFromResponse(
    Map<String, dynamic> response,
  ) {
    final raw = response['data'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Нормализует ответ [GET /week-plans/:id] и [GET /week-plans?startDateMs=] (один план).
  static Map<String, dynamic> weekPlanSingleFromResponse(
    Map<String, dynamic> response,
  ) {
    final raw = response['data'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    if (response['mealPlans'] != null) {
      return Map<String, dynamic>.from(response);
    }
    throw FormatException(
      'week plan response: expected data or mealPlans, got keys: ${response.keys}',
    );
  }

  /// GET /week-plans?limit&offset — список недельных планов (без [startDateMs]).
  /// Ответ: `{ "data": [...], "meta": { "total", "limit", "offset" } }`.
  Future<Map<String, dynamic>> getWeekPlans({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    log(
      '[getWeekPlans] userId=$userId, limit=$limit, offset=$offset',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(
          '/week-plans',
          queryParameters: {
            'limit': limit,
            'offset': offset,
          },
        ),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /week-plans/:id — план по Directus id (только при совпадении [x-user-id]).
  Future<Map<String, dynamic>> getWeekPlanById({
    required String userId,
    required String id,
  }) async {
    log('[getWeekPlanById] userId=$userId, id=$id', name: 'UserServiceClient');

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        Uri.parse('$_baseUrl/week-plans/${Uri.encodeComponent(id)}'),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /week-plans?startDateMs=... — один план с заданным началом недели (строка ms).
  Future<Map<String, dynamic>> getWeekPlanByStartDate({
    required String userId,
    required int startDateMs,
  }) async {
    log(
      '[getWeekPlanByStartDate] userId=$userId, startDateMs=$startDateMs',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(
          '/week-plans',
          queryParameters: {'startDateMs': startDateMs},
        ),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PATCH /days/current — частичное обновление текущего дня пользователя.
  ///
  /// Поддерживаемые поля payload: mealPlan, chatSnap, welnessEntity.
  Future<Map<String, dynamic>> patchDaysCurrent({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    log(
      '[patchDaysCurrent] userId=$userId, keys=${payload.keys.toList()}',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedWithRetry(
      userId: userId,
      send: (h) => http.patch(
        _buildUri('/days/current'),
        headers: h,
        body: jsonEncode(payload),
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /tasks/enqueue — поставить асинхронную задачу в очередь.
  ///
  /// Ожидаемый ответ: 202 Accepted (в `_throwOnError` это входит как success).
  Future<Map<String, dynamic>> enqueueTask({
    required String userId,
    required String type,
    required Map<String, dynamic> input,
    String? idempotencyClientKey,
  }) async {
    log(
      '[enqueueTask] userId=$userId, type=$type, idempotencyClientKey=$idempotencyClientKey',
      name: 'UserServiceClient',
    );

    final body = <String, dynamic>{
      'type': type,
      'input': input,
      if (idempotencyClientKey != null)
        'idempotencyClientKey': idempotencyClientKey,
    };

    final response = await _sendUserScopedWithRetry(
      userId: userId,
      send: (h) => http.post(
        _buildUri('/tasks/enqueue'),
        headers: h,
        body: jsonEncode(body),
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /tasks/:taskId — получить публичный статус задачи.
  ///
  /// Важно: backend возвращает 404 и для чужих задач (не раскрываем существование).
  Future<Map<String, dynamic>> getTask({
    required String userId,
    required String taskId,
    bool debug = false,
  }) async {
    log(
      '[getTask] userId=$userId, taskId=$taskId, debug=$debug',
      name: 'UserServiceClient',
    );

    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(
          '/tasks/$taskId',
          queryParameters: debug ? {'debug': true} : null,
        ),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _getWhoopJson(
    String path, {
    required String userId,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _sendUserScopedGetWithRetry(
      userId: userId,
      send: (h) => http.get(
        _buildUri(path, queryParameters: queryParameters),
        headers: h,
      ),
    );

    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
