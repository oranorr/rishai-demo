import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';
import 'package:rishai/core/services/envied/envied.dart';
import 'package:rishai/core/services/error/network_error_handler.dart';

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
        sdk = await Directus(
          '',
          client: Dio(
            BaseOptions(
              baseUrl: 'https://login.thepivotapp.ai/',
            ),
          ),
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

  @override
  Future<Map<String, dynamic>> updateOne({
    required String collection,
    required String itemId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      log('UPDATE DATA: $updateData');
      final res =
          await sdk.items(collection).updateOne(data: updateData, id: itemId);
      return res.data;
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_update_one',
        extras: {
          'collection': collection,
          'itemId': itemId,
          'updateData': updateData,
        },
      );
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createOne({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await sdk.items(collection).createOne(data);
      return res.data;
    } catch (e, stackTrace) {
      await NetworkErrorHandler.handleError(
        e,
        stackTrace,
        context: 'directus_create_one',
        extras: {
          'collection': collection,
          'data': data,
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readMany({
    required String collection,
    Filters? filters,
  }) async {
    try {
      final res = await sdk.items(collection).readMany(filters: filters);
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
  }) async {
    try {
      final res = await sdk.items(collection).readOne(id);
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
}
