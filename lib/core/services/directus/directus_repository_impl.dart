import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';
import 'package:rishai/core/services/envied/envied.dart';

final directus = getIt.get<DirectusService>();

@Singleton(as: DirectusService)
class DirectusRepositoryImpl implements DirectusService {
  late DirectusCore sdk;
  DirectusCore get dir => sdk;

  @override
  Future<void> initDirectus() async {
    int maxRetries = 3; // Количество попыток
    int attempt = 0;
    bool isConnected = false;

    while (attempt < maxRetries && !isConnected) {
      try {
        attempt += 1;
        sdk = await Directus(
          '',
          client: Dio(
            BaseOptions(
              baseUrl:
                  // kDebugMode
                  //     ?
                  // 'https://rishai.dev.mvplab.org/'
                  'https://login.thepivotapp.ai/',
            ),
          ),
        ).init();

        await sdk.auth.login(
          email: Env.directusEmail,
          password: Env.directusPassword,
        );

        isConnected = true; // Успешное подключение
        log('Подключение успешно на попытке $attempt');
      } on Exception catch (e) {
        log('Ошибка подключения на попытке $attempt: $e');
        if (attempt < maxRetries) {
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Ожидание перед следующей попыткой
        } else {
          log('Все попытки подключения исчерпаны');
          rethrow; // Переброс ошибки, если все попытки исчерпаны
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
    } on DirectusError catch (e) {
      log(e.message);
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
    } on DirectusError catch (e) {
      log(e.message);
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
    } on DirectusError catch (e) {
      log(e.message);
      return [];
    }
  }

  @override
  Future<void> deleteOne({
    required String collection,
    required String id,
  }) async {
    await sdk.items(collection).deleteOne(id);
  }

  @override
  Future<Map<String, dynamic>> readOne({
    required String collection,
    required String id,
  }) async {
    final res = await sdk.items(collection).readOne(id);

    return res.data;
  }

  @override
  Future<void> createMany({
    required String collection,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      await sdk.items(collection).createMany(data);
    } on DirectusError catch (e) {
      log(e.message);
      rethrow;
    }
  }
}
