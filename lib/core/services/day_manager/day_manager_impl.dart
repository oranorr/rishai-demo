import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/directus/directus_collections.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/error/whoop_error_handler.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/user/data/models/user_model.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';

final dayManager = getIt.get<DayManager>();

@Singleton(as: DayManager)
class DayManagerImpl implements DayManager {
  @override
  Future<Either<Failure, List<DayEntity>>> fetchDays({
    required List<int> daysIds,
  }) async {
    final res = await hive.retrieveSavedDays();
    final savedIds = res.map((e) => e.directusId).toList();
    final missingIds = daysIds.where((id) => !savedIds.contains(id)).toList();
    if (missingIds.isEmpty) return Right(res);

    for (final id in missingIds) {
      print('fetching day with id: $id');
      final day = await directus.readOne(
        collection: daysCollection,
        id: id.toString(),
      );
      final dayEntity = DayEntity.fromMap(day);
      await hive.saveDay(data: dayEntity);
      res.add(dayEntity);
    }
    return Right(res);
  }

  @override
  Future<DayEntity> createDay({required DayEntity day}) async {
    try {
      _logger(
        'Начало создания/обновления дня: ${day.dateTime}, cycleId: ${day.cycleId}',
      );
      List<DayEntity> days = userBloc.state.days;
      List<int> daysIds = List.from(userBloc.state.user.daysIds).cast<int>();
      int? existingDayId;
      DayEntity dayEntity;

      // Проверяем, есть ли уже сегодняшний день
      if (days.isNotEmpty) {
        // Проверяем на совпадение даты (сегодня)
        for (final stateDay in days) {
          if (stateDay.dateTime.isSameDate(DateTime.now()) &&
              day.dateTime.isSameDate(DateTime.now())) {
            existingDayId = stateDay.directusId;
            _logger(
              'Найден существующий день с той же датой (сегодня): $existingDayId',
            );
            break;
          }
        }

        // Если не нашли по дате, проверяем по cycleId
        if (existingDayId == null && day.directusId != 0) {
          for (final stateDay in days) {
            if (stateDay.cycleId != null) {
              final isSameCycle = stateDay.cycleId == day.cycleId;

              if (isSameCycle) {
                existingDayId = day.directusId;
                _logger('Найден существующий день с id: $existingDayId');
                break;
              }
            }
          }
        }
      }

      int dayId;
      if (existingDayId != null) {
        // Обновляем существующий день
        _logger('Обновление существующего дня с id: $existingDayId');
        print(existingDayId);
        final raw = await directus.updateOne(
          collection: daysCollection,
          itemId: existingDayId.toString(),
          updateData: day.toDirectus(userId: userBloc.state.user.directusId),
        );
        dayEntity = DayEntity.fromMap(raw);
        dayId = existingDayId;
        _logger('День успешно обновлен');
      } else {
        // Создаем новый день
        _logger('Создание нового дня');
        final dayData = day.toDirectus(userId: userBloc.state.user.directusId);
        final createdDay = await directus.createOne(
          collection: daysCollection,
          data: dayData,
        );
        dayId = createdDay['id'];
        dayEntity = DayEntity.fromMap(createdDay);
        _logger('Новый день создан с id: $dayId');

        // Добавляем ID нового дня в список дней пользователя
        if (!daysIds.contains(dayId)) {
          daysIds.add(dayId);
          _logger('ID дня добавлен в список дней пользователя');
        }
      }

      // Обновляем данные пользователя
      _logger('Обновление данных пользователя');
      final raw = await directus.updateOne(
        collection: usersCollection,
        itemId: userBloc.state.user.directusId,
        updateData: {
          'days': daysIds,
        },
      );
      userBloc
        ..add(UserUpdateDay(day: dayEntity))
        ..add(UpdateUserEvent(user: UserModel.fromMap(raw).toEntity()));

      _logger(
        'Успешно создан/обновлен день с датой: ${day.dateTime}, cycleId: ${day.cycleId} и directusId: ${day.directusId}',
      );
      return dayEntity;
    } catch (e, stackTrace) {
      _logger('Ошибка при обновлении Directus: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'whoop_update_directus',
        extras: {
          'user_id': userBloc.state.user.directusId,
          'day_id': day.directusId,
          'date_time': day.dateTime.toString(),
          'cycle_id': day.cycleId,
        },
      );
      rethrow;
    }
  }
}

void _logger(String message) {
  log(message, name: 'DayManager');
}
