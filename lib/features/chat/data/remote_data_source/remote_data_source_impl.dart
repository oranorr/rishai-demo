import 'dart:convert';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import '../../../../core/services/envied/envied.dart';

final chatRemoteSrc = getIt.get<ChatRemoteDataSource>();

@Singleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  late OpenAIClient client;
  late AssistantObject assistant;
  late ThreadObject thread;

  @override
  String? get threadId => thread.id;

  @override
  Future<bool> initGpt(String? savedThreadId) async {
    try {
      client = OpenAIClient(apiKey: Env.apiKey);
      assistant = await client.getAssistant(
          assistantId: 'asst_pnoQdlmVN0GP4qKSgzRictaq');

      if (savedThreadId != null) {
        thread = await client.getThread(threadId: savedThreadId);
      } else {
        thread =
            await client.createThread(request: const CreateThreadRequest());
      }

      return true;
    } catch (e) {
      log('Ошибка инициализации GPT: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> requestMealPlan(String prompt) async {
    try {
      log(prompt);
      if (chatBloc.state.mealPlan == null) {
        thread =
            await client.createThread(request: const CreateThreadRequest());
      }
      final run = await client.createThreadRun(
        threadId: thread.id,
        request: CreateRunRequest(
            assistantId: assistant.id,
            model: const CreateRunRequestModel.model(RunModels.gpt4oMini),
            instructions: assistant.instructions,
            additionalInstructions: prompt),
      );
      print('Прогон ассистента запущен: ${run.id}, threadId: ${run.threadId}');

      // Добавляем цикл ожидания с проверкой
      const maxAttempts = 10; // Максимальное количество попыток
      int attempts = 0;
      bool foundResponse = false;
      MessageObject? assistantResponse;

      while (attempts < maxAttempts && !foundResponse) {
        await Future.delayed(
            const Duration(seconds: 2)); // Задержка между проверками

        final responseMessages =
            await client.listThreadMessages(threadId: thread.id);

        // Ищем сообщение от ассистента вручную
        for (var message in responseMessages.data) {
          // print(message);
          if (message.role == MessageRole.assistant &&
              message.content.isNotEmpty) {
            assistantResponse = message;
            foundResponse = true;
            break;
          }
        }

        attempts++;
      }

      if (assistantResponse != null) {
        final content = assistantResponse.content.first;
        final json = content.toJson();
        log('Ответ ассистента: $json');
        final map = json['text']['value'];
        // return map;
        return jsonDecode(map);
      } else {
        print('Ответ ассистента не был получен.');
        await client.cancelThreadRun(threadId: thread.id, runId: run.id);
        // Возвращаем сообщение об ошибке после нескольких неудачных попыток
        return {
          'error': 'Ассистент не смог предоставить ответ. Попробуйте позже.'
        };
      }
    } catch (e) {
      log('Ошибка при запросе плана питания: $e');

      // Возвращаем сообщение об ошибке в случае исключения
      return {'error': 'Произошла ошибка при запросе плана питания: $e'};
    }
  }

  @override
  Future<String?> sendMessage(String userMessage) async {
    try {
      // Отправляем сообщение пользователя в текущий поток
      final userMessageObject = await client.createThreadMessage(
        threadId: thread.id,
        request: CreateMessageRequest(
          role: MessageRole.user,
          content: CreateMessageRequestContent.text(userMessage),
        ),
      );

      print(
          'Сообщение пользователя отправлено: ${userMessageObject.id}, threadId: ${userMessageObject.threadId}');
      // Проверяем, есть ли незавершенные прогоны (чтобы не запускать новый каждый раз)

      //TODO: This all down was working fine. On re-login breaks.
      //Commented, becase not required. And will re-do gpt service anyway.

      // final activeRuns = await client.listThreadRuns(threadId: thread.id);

      // // Фильтруем и отменяем только те прогоны, которые не завершены
      // for (var run in activeRuns.data) {
      //   final runStatus =
      //       await client.getThreadRun(threadId: thread.id, runId: run.id);
      //   if (runStatus.status != RunStatus.completed &&
      //       runStatus.status != RunStatus.expired) {
      //     print('Незавершенный прогон найден: ${run.id}, отменяем его.');
      //     await client.cancelThreadRun(threadId: thread.id, runId: run.id);
      //   } else {
      //     print('Прогон уже завершен: ${run.id}, пропускаем отмену.');
      //   }
      // }

      final run = await client.createThreadRun(
        threadId: thread.id,
        request: CreateRunRequest(
          assistantId: assistant.id,
          model: const CreateRunRequestModel.model(RunModels.gpt4oMini),
          // instructions: assistant.instructions,
          additionalInstructions:
              userMessage, // Передаем текущее сообщение пользователя как инструкцию
        ),
      );

      print('Прогон ассистента запущен: ${run.id}, threadId: ${run.threadId}');

      // Ждем завершения прогона с оптимизированной проверкой
      bool runCompleted = false;
      const maxAttempts = 10;
      int attempts = 0;

      while (!runCompleted && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));

        // Получаем статус прогона
        final runStatus =
            await client.getThreadRun(threadId: thread.id, runId: run.id);
        if (runStatus.status == RunStatus.completed) {
          runCompleted = true;
          print('Прогон ассистента завершен');
        }

        attempts++;
      }

      if (!runCompleted) {
        print('Прогон не завершился за отведенное время, отменяем.');
        await client.cancelThreadRun(threadId: thread.id, runId: run.id);
        return null;
      }

      // Получаем сообщения из потока, проверяем самое свежее сообщение
      final responseMessages =
          await client.listThreadMessages(threadId: thread.id);
      MessageObject? assistantResponse;

      for (var message in responseMessages.data.reversed) {
        // Ищем сообщение от ассистента, относящееся к текущему прогону
        if (message.role == MessageRole.assistant &&
            message.runId == run.id &&
            message.content.isNotEmpty) {
          assistantResponse = message;
          break;
        }
      }

      // Если найдено сообщение ассистента, возвращаем его содержимое
      if (assistantResponse != null) {
        final content = assistantResponse.content.first;
        print('Ответ ассистента: ${content.toJson()}');
        return content.text;
      } else {
        print('Ответ ассистента не был получен.');
        return null;
      }
    } catch (e) {
      print('Ошибка при отправке сообщения: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchLastChatSnap(String directusId) async {
    try {
      final rawUser =
          await directus.readOne(collection: usersCollection, id: directusId);
      if (rawUser['days'].isEmpty) {
        return null;
      } else {
        final last = rawUser['days'].last;
        final rawLastDay = await directus.readOne(
            collection: daysCollection, id: last.toString());
        // log(rawLastDay.toString());
        return rawLastDay['chatSnap'];
      }
    } catch (e) {
      log('failed to fetch last Chat snap, with error: $e');
      rethrow;
    }

    // return null;
  }
}
