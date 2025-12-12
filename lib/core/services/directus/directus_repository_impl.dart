import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/network_error_handler.dart';
import 'package:rishai/core/services/network/request_timer.dart';

final directus = getIt.get<DirectusService>();

@Singleton(as: DirectusService)
class DirectusRepositoryImpl implements DirectusService {
  late DirectusCore sdk;
  DirectusCore get dir => sdk;

  @override
  Future<void> initDirectus() async {
    int maxRetries = 3;
    int attempt = 0;
    bool isConnected = false;

    while (attempt < maxRetries && !isConnected) {
      try {
        attempt += 1;
        final dio = Dio(
          BaseOptions(
            baseUrl: 'https://login.thepivotapp.ai/',
          ),
        );
        dio.interceptors.add(RequestTimer.dioInterceptor);

        sdk = await Directus(
          '',
          client: dio,
        ).init();

        await sdk.auth.login(
          email: Env.directusEmail,
          password: Env.directusPassword,
        );

        isConnected = true;
        log('Подключение успешно на попытке $attempt');
      } catch (e, stackTrace) {
        log('Ошибка подключения на попытке $attempt: $e');
        await NetworkErrorHandler.handleError(
          e,
          stackTrace,
          context: 'directus_init',
          extras: {
            'attempt': attempt,
            'max_retries': maxRetries,
          },
        );

        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
        } else {
          log('Все попытки подключения исчерпаны');
          rethrow;
        }
      }
    }
  }

  /// Определяет, является ли ошибка retryable (можно ли повторить попытку).
  ///
  /// Retryable ошибки:
  /// - DioException с типами: connectionTimeout, sendTimeout, receiveTimeout, connectionError
  /// - HTTP статусы: 5xx (кроме 501), 429, 502, 503, 504
  /// - SocketException и HttpException
  ///
  /// Non-retryable ошибки:
  /// - HTTP статусы: 400, 401, 403, 404, 422
  /// - 500 (если это не временная проблема)
  bool _isRetryableError(Object error) {
    // DioException - проверяем тип и статус
    if (error is DioException) {
      // Проверяем типы ошибок соединения и таймаутов
      final retryableTypes = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ];
      
      if (retryableTypes.contains(error.type)) {
        return true;
      }
      
      // Проверяем HTTP статус код
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        // Retryable статусы: 429 (Too Many Requests), 5xx (кроме 501)
        if (statusCode == 429) {
          return true;
        }
        
        // 5xx ошибки (кроме 501 Not Implemented)
        if (statusCode >= 500 && statusCode < 600 && statusCode != 501) {
          return true;
        }
        
        // Специфичные retryable статусы
        if ([502, 503, 504].contains(statusCode)) {
          return true;
        }
        
        // Non-retryable статусы: 400, 401, 403, 404, 422
        if ([400, 401, 403, 404, 422].contains(statusCode)) {
          return false;
        }
      }
      
      // Если тип ошибки unknown, проверяем сообщение на наличие сетевых проблем
      if (error.type == DioExceptionType.unknown) {
        final message = error.message?.toLowerCase() ?? '';
        if (message.contains('connection') ||
            message.contains('network') ||
            message.contains('timeout')) {
          return true;
        }
      }
    }
    
    // SocketException - всегда retryable (проблемы с сетью)
    if (error is SocketException) {
      return true;
    }
    
    // HttpException - проверяем сообщение
    if (error is HttpException) {
      final message = error.message.toLowerCase();
      // Если это временная проблема сервера, можно retry
      if (message.contains('connection') ||
          message.contains('timeout') ||
          message.contains('network')) {
        return true;
      }
    }
    
    // По умолчанию не retry для неизвестных ошибок
    return false;
  }

  @override
  Future<Map<String, dynamic>> updateOne({
    required String collection,
    required String itemId,
    required Map<String, dynamic> updateData,
  }) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt += 1;
        log('UPDATE DATA (попытка $attempt/$maxRetries): $updateData');
        
        final res =
            await sdk.items(collection).updateOne(data: updateData, id: itemId);
        
        if (attempt > 1) {
          log('UPDATE успешно после retry на попытке $attempt');
        }
        
        return res.data;
      } on Exception catch (e, stackTrace) {
        final isRetryable = _isRetryableError(e);
        
        log(
          'Ошибка UPDATE на попытке $attempt/$maxRetries: $e (retryable: $isRetryable)',
        );
        
        await NetworkErrorHandler.handleError(
          e,
          stackTrace,
          context: 'directus_update_one',
          extras: {
            'collection': collection,
            'itemId': itemId,
            'updateData': updateData,
            'attempt': attempt,
            'max_retries': maxRetries,
            'is_retryable': isRetryable,
          },
        );
        
        // Если ошибка не retryable или попытки исчерпаны, выходим
        if (!isRetryable || attempt >= maxRetries) {
          if (!isRetryable) {
            log('Ошибка не является retryable, прекращаем попытки');
          } else {
            log('Все попытки UPDATE исчерпаны');
          }
          // Сохраняем текущее поведение: возвращаем пустой объект
          return {};
        }
        
        // Экспоненциальная задержка: 1, 2, 4 секунды
        final delaySeconds = 1 << (attempt - 1); // 1, 2, 4
        log('Повторная попытка UPDATE через $delaySeconds секунд(ы)...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    
    // Этот код не должен выполниться, но на всякий случай
    return {};
  }

  @override
  Future<Map<String, dynamic>> createOne({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    const maxRetries = 3;
    int attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt < maxRetries) {
      try {
        attempt += 1;
        log('CREATE (попытка $attempt/$maxRetries) в коллекции $collection');
        
        final res = await sdk.items(collection).createOne(data);
        
        if (attempt > 1) {
          log('CREATE успешно после retry на попытке $attempt');
        }
        
        return res.data;
      } on Exception catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
        
        final isRetryable = _isRetryableError(e);
        
        log(
          'Ошибка CREATE на попытке $attempt/$maxRetries: $e (retryable: $isRetryable)',
        );
        
        await NetworkErrorHandler.handleError(
          e,
          stackTrace,
          context: 'directus_create_one',
          extras: {
            'collection': collection,
            'data': data,
            'attempt': attempt,
            'max_retries': maxRetries,
            'is_retryable': isRetryable,
          },
        );
        
        // Если ошибка не retryable или попытки исчерпаны, пробрасываем исключение
        if (!isRetryable || attempt >= maxRetries) {
          if (!isRetryable) {
            log('Ошибка не является retryable, прекращаем попытки');
          } else {
            log('Все попытки CREATE исчерпаны, пробрасываем исключение');
          }
          // Сохраняем текущее поведение: пробрасываем исключение
          rethrow;
        }
        
        // Экспоненциальная задержка: 1, 2, 4 секунды
        final delaySeconds = 1 << (attempt - 1); // 1, 2, 4
        log('Повторная попытка CREATE через $delaySeconds секунд(ы)...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    
    // Этот код не должен выполниться, но на всякий случай пробрасываем последнюю ошибку
    if (lastError != null && lastStackTrace != null) {
      if (lastError is Exception || lastError is Error) {
        throw lastError as Exception;
      }
      throw Exception('Неожиданная ошибка в createOne: $lastError');
    }
    throw Exception('Неожиданная ошибка в createOne');
  }

  @override
  Future<List<Map<String, dynamic>>> readMany({
    required String collection,
    Filters? filters,
    Query? query,
  }) async {
    try {
      final res =
          await sdk.items(collection).readMany(filters: filters, query: query);
      return res.data;
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_read_many',
        extras: {
          'collection': collection,
          'filters': filters?.toString(),
        },
      );
      return [];
    }
  }

  @override
  Future<void> deleteOne({
    required String collection,
    required String id,
  }) async {
    try {
      await sdk.items(collection).deleteOne(id);
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_delete_one',
        extras: {
          'collection': collection,
          'id': id,
        },
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> readOne({
    required String collection,
    required String id,
    Query? query,
  }) async {
    try {
      final res = await sdk.items(collection).readOne(id, query: query);
      return res.data;
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_read_one',
        extras: {
          'collection': collection,
          'id': id,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> createMany({
    required String collection,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      await sdk.items(collection).createMany(data);
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_create_many',
        extras: {
          'collection': collection,
          'data': data,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteMany({
    required String collection,
    required List<String> ids,
  }) async {
    try {
      await sdk.items(collection).deleteMany(ids);
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_delete_many',
        extras: {
          'collection': collection,
          'ids': ids,
        },
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> readAppConfig() async {
    final coll = await sdk.items(appConfig).readOne('1');
    return coll.data;
  }

  @override
  Future<Map<String, dynamic>> readAccountsWhiteList() async {
    final coll = await sdk.items(accountsWhiteListCollection).readOne('1');
    print('COLL: ${coll.data}');
    return coll.data;
  }

  @override
  Future<String> uploadFile({
    required File image,
  }) async {
    String fileId = '';
    try {
      final uploadFuture = await sdk.files.uploadFile(image.path);
      final response = await uploadFuture;
      fileId = response.data.id!;
      print('fileId: $fileId');
      return 'fileId';
    } on DirectusError catch (e) {
      log(e.toString());
      return '';
    }
    // res.listen((value) {
    //   log(value.data.id.toString());
    //   fileId = value.data.id!;
    // });

    // .then((value) {
    //   log(value.data.id.toString());
    //   fileId = value.data.id!;
    // });
    // Future<DirectusResponse<DirectusFile>> res =
    //     await sdk.files.uploadFile(image.path);

    // await res.then((value) {
    //   log(value.data.id.toString());
    //   fileId = value.data.id!;
    // });

    // await res.then((value) {
    //   log(value.data.id.toString());
    //   fileId = value.data.id!;
    // });
  }
}
