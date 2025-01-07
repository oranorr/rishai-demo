// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/chat/data/remote_data_source/remote_data_source.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/chat/domain/usecases/request_plan_usecase.dart';

final chatRepo = getIt.get<ChatRepository>();

@Singleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl(this.remote);

  @override
  Future<void> saveChatSnapShot({required ChatSnapshotEntity chatSnap}) async {
    if (hive.chatBox.isEmpty) {
      await hive.chatBox.add(chatSnap);
    } else {
      int last = hive.chatBox.length - 1;
      await hive.chatBox.putAt(last, chatSnap);
    }
  }

  @override
  Future<Either<Failure, MealPlanEntity>> requestMealPlan({
    required RequestPlanParams params,
  }) async {
    final res = await remote.requestMealPlan(params.generatePrompt());
    if (res.containsKey('error')) {
      return Left(ChatGptRequestMealFailures(res['error']));
    } else {
      return Right(MealPlanEntity.fromMap(res));
    }
  }

  @override
  Future<Either<Failure, void>> initGpt(String? threadId) async {
    bool res = await remote.initGpt(threadId);
    return res ? const Right(null) : const Left(UnknownFailure());
  }

  @override
  Future<Either<Failure, String>> sendMessage(String userMessage) async {
    final res = await remote.sendMessage(userMessage);
    if (res == null) {
      return const Left(UnknownFailure());
    } else {
      return Right(res);
    }
  }

  @override
  Future<Either<Failure, ChatSnapshotEntity?>> fetchSavedSnap({
    required String directusId,
  }) async {
    try {
      ChatSnapshotEntity? snap;
      snap = await hive.retrieveLastChat();
      if (snap != null) {
        return Right(snap);
      }
      final map = await remote.fetchLastChatSnap(directusId);
      if (map != null && map.isNotEmpty) {
        return Right(ChatSnapshotEntity.fromDirectus(map));
      } else {
        return const Right(null);
      }
    } on Exception catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
