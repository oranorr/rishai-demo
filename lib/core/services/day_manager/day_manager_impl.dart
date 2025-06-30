import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:directus/directus.dart';
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

final dayManager = getIt.get<DayManager>();

@Singleton(as: DayManager)
class DayManagerImpl implements DayManager {
  @override
  Future<Either<Failure, List<DayEntity>>> fetchDays({
    required List<int> daysIds,
  }) async {
    try {
      _logger('Начало получения дней, всего ID: ${daysIds.length}');
      final res = await hive.retrieveSavedDays();
      final savedIds = res.map((e) => e.directusId).toList();
      final missingIds = daysIds.where((id) => !savedIds.contains(id)).toList();

      _logger(
        'Найдено в кэше: ${savedIds.length}, отсутствует: ${missingIds.length}',
      );

      if (missingIds.isEmpty) {
        _logger('Все дни найдены в кэше, возвращаем локальные данные');
        return Right(res);
      }

      int successCount = 0;
      int failCount = 0;

      for (final id in missingIds) {
        const maxRetries = 2; // Количество повторных попыток для каждого дня
        bool dayFetched = false;

        for (int attempt = 0; attempt <= maxRetries; attempt++) {
          try {
            if (attempt > 0) {
              _logger('Повторная попытка #$attempt получения дня с id: $id');
              await Future.delayed(
                Duration(
                  milliseconds: 300 * attempt,
                ),
              ); // Увеличиваем задержку с каждой попыткой
            } else {
              _logger('Получение дня с id: $id');
            }

            final day = await directus.readOne(
              collection: daysCollection,
              id: id.toString(),
            );

            final dayEntity = DayEntity.fromMap(day);
            await hive.saveDay(data: dayEntity);
            res.add(dayEntity);

            _logger('День с id: $id успешно получен и сохранен');
            dayFetched = true;
            successCount++;
            break; // Выходим из цикла повторных попыток
          } catch (e, stackTrace) {
            if (attempt < maxRetries) {
              _logger(
                'Ошибка при получении дня с id: $id, попытка: ${attempt + 1}/$maxRetries, ошибка: $e',
              );
              continue; // Пробуем еще раз
            }

            // Все попытки исчерпаны
            _logger(
              'Не удалось получить день с id: $id после ${maxRetries + 1} попыток',
            );
            await WhoopErrorHandler.handleError(
              e,
              stackTrace,
              context: 'day_manager_fetch_day',
              extras: {
                'day_id': id,
                'saved_ids': savedIds,
                'missing_ids': missingIds,
                'attempt': attempt + 1,
              },
            );

            failCount++;
          }
        }
      }

      _logger(
        'Завершено получение дней. Успешно: $successCount, не удалось: $failCount',
      );

      // Если хотя бы какие-то дни загружены, считаем это частичным успехом
      if (res.isNotEmpty) {
        if (failCount > 0) {
          _logger(
            'Возвращаем частично загруженные данные (${res.length} дней)',
          );
        } else {
          _logger('Все дни успешно загружены (${res.length} дней)');
        }
        return Right(res);
      } else {
        _logger('Не удалось загрузить ни одного дня');
        return const Left(FailedToGetUserData('Failed to fetch any days'));
      }
    } catch (e, stackTrace) {
      _logger('Общая ошибка при получении дней: $e');
      await WhoopErrorHandler.handleError(
        e,
        stackTrace,
        context: 'day_manager_fetch_days',
        extras: {
          'days_ids': daysIds,
        },
      );
      return const Left(FailedToGetUserData('Failed to fetch days'));
    }
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
        // for (final stateDay in days) {
        //   if (stateDay.dateTime.isSameDate(DateTime.now()) &&
        //       day.dateTime.isSameDate(DateTime.now())) {
        //   // if (stateDay.dateTime.isSameDate(DateTime.now()) &&
        //   //     day.dateTime.isSameDate(DateTime.now())) {
        //     existingDayId = stateDay.directusId;
        //     _logger(
        //       'Найден существующий день с той же датой (сегодня): $existingDayId',
        //     );
        //     break;
        //   }
        // }

        // Если не нашли по дате, проверяем по cycleId
        if (day.directusId != 0) {
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
        await hive.saveDay(data: dayEntity);
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
        dayEntity = DayEntity.fromMap(createdDay).copyWith(directusId: dayId);
        _logger('Новый день создан с id: $dayId');

        // Сохраняем созданный день в Hive
        await hive.saveDay(data: dayEntity);

        // Добавляем ID нового дня в список дней пользователя
        if (!daysIds.contains(dayId)) {
          daysIds.add(dayId);
          _logger(
            'ID ($dayId) дня добавлен в список дней пользователя, последний: ${daysIds.last}',
          );
        }
      }

      // Обновляем данные пользователя
      _logger('Обновление данных пользователя');
      await directus.updateOne(
        collection: usersCollection,
        itemId: userBloc.state.user.directusId,
        updateData: {
          'days': daysIds,
        },
      );

      final raw = await directus.readOne(
        collection: usersCollection,
        id: userBloc.state.user.directusId,
      );
      print('RAW FRESH USER IS: $raw');
      final newUser = UserModel.fromMap(raw).toEntity();
      print('newUser last day: ${newUser.daysIds.last}');

      // Исправление: Обновляем локально daysIds в модели пользователя
      final updatedUser = newUser.copyWith(daysIds: daysIds);
      print('updatedUser last day: ${updatedUser.daysIds.last}');

      userBloc
        ..add(UserUpdateDay(day: dayEntity))
        ..add(UpdateUserEvent(user: updatedUser));

      _logger(
        'Успешно создан/обновлен день с датой: ${dayEntity.dateTime}, cycleId: ${dayEntity.cycleId} и directusId: ${dayEntity.directusId}',
      );
      return dayEntity;
    } on Exception catch (e, stackTrace) {
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

  @override
  Future<List<int>> getDaysIds({required String userId}) async {
    _logger('Получение daysIds для пользователя: $userId');
    List days = await directus.readMany(
      collection: daysCollection,
      filters: Filters({'userId': F.eq(userId)}),
      query: Query(
        limit: 1000,
      ),
    );

    final daysIds = days.map((e) => e['id']).toList().cast<int>();
    _logger('Найдено дней в Directus: ${daysIds.length}');
    return daysIds;
  }
}

void _logger(String message) {
  log(message, name: 'DayManager');
}
