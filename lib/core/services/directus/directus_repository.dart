import 'package:directus/directus.dart';

abstract interface class DirectusService {
  Future<void> initDirectus();

  Future<Map<String, dynamic>> updateOne({
    required String collection,
    required String itemId,
    required Map<String, dynamic> updateData,
  });

  Future<Map<String, dynamic>> createOne({
    required String collection,
    required Map<String, dynamic> data,
  });

  Future<List<Map<String, dynamic>>> readMany({
    required String collection,
    Filters? filters,
    Query? query,
  });

  Future<Map<String, dynamic>> readOne({
    required String collection,
    required String id,
    Query? query,
  });

  Future<void> deleteOne({required String collection, required String id});

  Future<void> createMany({
    required String collection,
    required List<Map<String, dynamic>> data,
  });

  Future<void> deleteMany({
    required String collection,
    required List<String> ids,
  });

  Future<Map<String, dynamic>> readAppConfig();
}
