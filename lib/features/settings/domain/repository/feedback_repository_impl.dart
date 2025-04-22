import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/settings/domain/models/feedback_model.dart';
import 'package:rishai/features/settings/domain/repository/feedback_repository.dart';

/// Реализация репозитория для работы с обратной связью
final feedbackRepository = getIt.get<FeedbackRepository>();

@Singleton(as: FeedbackRepository)
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl();

  @override
  Future<void> sendFeedback(FeedbackModel feedback) async {
    try {
      // Создаем запись обратной связи
      // final result = await _directusService.createOne(
      //   collection: feedbackCollection,
      //   data: feedback.toJson(),
      // );
      final result = await directus.createOne(
        collection: feedbackCollection,
        data: feedback.toJson(),
      );

      final feedbackId = result['id'].toString();

      // // Если есть прикрепленные файлы, связываем их с обратной связью
      if (feedback.media.isNotEmpty) {
        final fileIds =
            feedback.media.map((file) => file.directusFileId).toList();
        await linkFilesToFeedback(
          feedbackId: feedbackId,
          fileIds: fileIds,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadFile(File file) async {
    try {
      return await directus.uploadFile(
        image: file,
      );

      // // Создаем Dio клиент
      // final dio = Dio(
      //   BaseOptions(
      //     baseUrl: 'https://login.thepivotapp.ai/',
      //   ),
      // );

      // // Авторизуемся с помощью учетных данных
      // final authResponse = await dio.post(
      //   '/auth/login',
      //   data: {
      //     'email': Env.directusEmail,
      //     'password': Env.directusPassword,
      //   },
      // );

      // final accessToken = authResponse.data['data']['access_token'];

      // Создаем FormData для загрузки файла
      // final formData = FormData.fromMap({
      //   'file': await MultipartFile.fromFile(
      //     file.path,
      //     filename: file.path.split('/').last,
      //   ),
      // });

      // // Отправляем запрос с токеном
      // final response = await dio.post(
      //   '/files',
      //   data: formData,
      //   options: Options(
      //     headers: {
      //       'Authorization': 'Bearer $accessToken',
      //     },
      //   ),
      // );

      // // Возвращаем ID загруженного файла
      // return response.data['data']['id'];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> linkFilesToFeedback({
    required String feedbackId,
    required List<String> fileIds,
  }) async {
    try {
      // Создаем записи связей между обратной связью и файлами
      final relationData = fileIds.map((fileId) {
        return {
          'feedback_id': feedbackId,
          'directus_files_id': fileId,
        };
      }).toList();

      await directus.createMany(
        collection: feedbackFilesCollection,
        data: relationData,
      );
    } catch (e) {
      rethrow;
    }
  }
}
