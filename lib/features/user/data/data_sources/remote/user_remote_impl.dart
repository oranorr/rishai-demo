import 'dart:developer';

import 'package:directus/directus.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/features/user/data/data_sources/remote/user_remote_source.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

@Singleton(as: UserRemoteSource)
class UserRemoteImpl implements UserRemoteSource {
  @override
  Future<bool> updateUser({required UserEntity user}) async {
    try {
      final res = await directus.updateOne(
        collection: usersCollection,
        itemId: user.directusId,
        updateData: user.toMap(),
      );
      return res.isNotEmpty;
    } on Exception {
      rethrow;
    }
  }

  @override
  Future<List<DayEntity>> fetchRemoteDays({
    required List<int> daysIds,
  }) async {
    final rawList = await directus.readMany(
      collection: daysCollection,
      filters: Filters({'id': F.isIn(daysIds)}),
    );

    var days = rawList.map((map) => DayEntity.fromMap(map)).toList();

    // Разделяем дни: с cycleId и без него
    final List<DayEntity> noCycleDays = [];
    final Map<String, List<DayEntity>> groupedDays = {};

    for (final day in days) {
      if (day.cycleId == null) {
        noCycleDays.add(day);
      } else {
        groupedDays.putIfAbsent(day.cycleId.toString(), () => []).add(day);
      }
    }

    final List<DayEntity> uniqueDays = [...noCycleDays];
    for (final entry in groupedDays.entries) {
      final List<DayEntity> duplicates = entry.value;

      if (duplicates.length > 1) {
        // Сортируем и берем только самый свежий день
        duplicates.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      }
      uniqueDays.add(duplicates.first);
    }

    log('Returning ${uniqueDays.length} unique days');
    return uniqueDays;
  }
}
