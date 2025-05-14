import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class RequestTimer {
  static final Map<String, Stopwatch> _activeRequests = {};

  static void startRequest(String requestId) {
    _activeRequests[requestId] = Stopwatch()..start();
  }

  static void endRequest(String requestId, {String? method, String? url}) {
    final stopwatch = _activeRequests.remove(requestId);
    if (stopwatch != null) {
      final duration = stopwatch.elapsed;
      log('API Request: $method $url took ${duration.inMilliseconds}ms');
    }
  }

  static Interceptor get dioInterceptor => InterceptorsWrapper(
        onRequest: (options, handler) {
          final requestId = '${options.method}_${options.path}';
          startRequest(requestId);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final requestId =
              '${response.requestOptions.method}_${response.requestOptions.path}';
          endRequest(
            requestId,
            method: response.requestOptions.method,
            url: response.requestOptions.path,
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          final requestId =
              '${error.requestOptions.method}_${error.requestOptions.path}';
          endRequest(
            requestId,
            method: error.requestOptions.method,
            url: error.requestOptions.path,
          );
          return handler.next(error);
        },
      );

  static http.Client get httpClient => _TimedHttpClient();
}

class _TimedHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      log('HTTP Request: ${request.method} ${request.url} took ${stopwatch.elapsed.inMilliseconds}ms');
      return response;
    } catch (e) {
      log('HTTP Request Error: ${request.method} ${request.url} took ${stopwatch.elapsed.inMilliseconds}ms');
      rethrow;
    }
  }
}
