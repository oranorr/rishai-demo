import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';

@Singleton(as: UserRemoteSource)
class UserRemoteImpl implements UserRemoteSource {
  @override
  Future<bool> updateUser({required UserEntity user}) async {
    try {
      final res = await directus.updateOne(
          collection: usersCollection,
          itemId: user.directusId,
          updateData: user.toMap());
      return res.isNotEmpty;
    } on Exception {
      rethrow;
    }
  }
}
