import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:directus/directus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'food_diary_event.dart';
part 'food_diary_state.dart';

// [FoodDiaryCubit] Глобальный экземпляр кубита для доступа из других частей приложения
final foodDiaryCubit = getIt.get<FoodDiaryCubit>();

/// [FoodDiaryCubit] Кубит для управления состоянием дневника питания
///
/// Отвечает за:
/// - Управление записями в дневнике питания
/// - Отслеживание потребленных калорий и макронутриентов
/// - Синхронизацию данных с бэкендом
/// - Локальное кэширование данных
@injectable
class FoodDiaryCubit extends Bloc<FoodDiaryEvent, FoodDiaryState> {
  FoodDiaryCubit()
      : super(
          const FoodDiaryMainState(
            status: Status.initial,
            entries: [],
            totalCalories: 0,
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0,
          ),
        ) {
    // [FoodDiaryCubit] Регистрируем обработчики событий
    on<FoodDiaryInitialize>(_initialize);
    on<FoodDiaryAddEntry>(_addEntry);
    on<FoodDiaryUpdateEntry>(_updateEntry);
    on<FoodDiaryDeleteEntry>(_deleteEntry);
    on<FoodDiaryLoadEntries>(_loadEntries);
    on<FoodDiaryClearAll>(_clearAll);
    on<FoodDiaryClearTodayEntries>(_clearTodayEntries);
  }

  /// [_initialize] Инициализация кубита дневника питания
  /// Загружает сохраненные данные и настраивает начальное состояние
  FutureOr<void> _initialize(
    FoodDiaryInitialize event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] Инициализация дневника питания',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет загрузка данных из локального хранилища или API
      // Пока что просто устанавливаем начальное состояние

      emit((state as FoodDiaryMainState).copyWith(status: Status.success));

      log(
        '[FoodDiaryCubit] Инициализация завершена успешно',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при инициализации: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [_addEntry] Добавление новой записи в дневник питания
  FutureOr<void> _addEntry(
    FoodDiaryAddEntry event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] Добавление записи в дневник',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет логика добавления записи
      // - Валидация данных
      // - Сохранение в локальное хранилище
      // - Синхронизация с бэкендом
      // - Пересчет общих показателей

      emit((state as FoodDiaryMainState).copyWith(status: Status.success));

      log('[FoodDiaryCubit] Запись успешно добавлена', name: 'FoodDiaryCubit');
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при добавлении записи: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [_updateEntry] Обновление существующей записи в дневнике
  FutureOr<void> _updateEntry(
    FoodDiaryUpdateEntry event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] Обновление записи в дневнике',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет логика обновления записи
      // - Поиск записи по ID
      // - Валидация новых данных
      // - Обновление в локальном хранилище
      // - Синхронизация с бэкендом
      // - Пересчет общих показателей

      emit((state as FoodDiaryMainState).copyWith(status: Status.success));

      log('[FoodDiaryCubit] Запись успешно обновлена', name: 'FoodDiaryCubit');
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при обновлении записи: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [_deleteEntry] Удаление записи из дневника питания
  FutureOr<void> _deleteEntry(
    FoodDiaryDeleteEntry event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] Удаление записи из дневника',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет логика удаления записи
      // - Поиск записи по ID
      // - Удаление из локального хранилища
      // - Синхронизация с бэкендом
      // - Пересчет общих показателей

      emit((state as FoodDiaryMainState).copyWith(status: Status.success));

      log('[FoodDiaryCubit] Запись успешно удалена', name: 'FoodDiaryCubit');
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при удалении записи: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [_loadEntries] Загрузка записей дневника питания
  FutureOr<void> _loadEntries(
    FoodDiaryLoadEntries event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log('[FoodDiaryCubit] Загрузка записей дневника', name: 'FoodDiaryCubit');

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет логика загрузки записей
      // - Загрузка из локального хранилища
      // - Синхронизация с бэкендом при необходимости
      // - Фильтрация по дате если указана
      // - Расчет общих показателей

      emit((state as FoodDiaryMainState).copyWith(status: Status.success));

      log('[FoodDiaryCubit] Записи успешно загружены', name: 'FoodDiaryCubit');
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при загрузке записей: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [_clearAll] Очистка всех записей дневника питания
  FutureOr<void> _clearAll(
    FoodDiaryClearAll event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] Очистка всех записей дневника',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      // TODO(FoodDiary): Здесь будет логика очистки всех записей
      // - Очистка локального хранилища
      // - Синхронизация с бэкендом
      // - Сброс всех показателей

      emit(
        (state as FoodDiaryMainState).copyWith(
          status: Status.success,
          entries: [],
          totalCalories: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
        ),
      );

      log(
        '[FoodDiaryCubit] Все записи успешно очищены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при очистке записей: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }

  /// [calculateWellnessScore] Рассчитывает Daily Wellness Score на основе потребленных блюд
  ///
  /// Принимает массив блюд, получает актуальный день, создает/обновляет wellness entity.
  /// Если у пользователя уже есть WelnessEntity за сегодня, то добавляет новые блюда к существующим
  /// и пересчитывает Daily Wellness Score для всех потребленных блюд.
  /// Формула: Daily Wellness Score = 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
  /// (на основе потребленных макросов относительно целевых)
  Future<DayEntity> calculateWellnessScore(List<Meal> consumedMeals) async {
    try {
      log(
        '[FoodDiaryCubit] Расчет Daily Wellness Score для ${consumedMeals.length} блюд',
        name: 'FoodDiaryCubit',
      );

      // Получаем актуальный сегодняшний день
      final currentDay = whoopBloc.state.day;
      log(
        '[FoodDiaryCubit] Текущий день: ${currentDay.dateTime}',
        name: 'FoodDiaryCubit',
      );

      // Получаем существующую WelnessEntity или создаем пустую
      final existingWelness = currentDay.welnessEntity;
      List<DiaryMeal> allConsumedMeals = [];

      if (existingWelness != null) {
        log(
          '[FoodDiaryCubit] Найдена существующая WelnessEntity с ${existingWelness.consumedMeals.length} блюдами',
          name: 'FoodDiaryCubit',
        );
        // Добавляем уже существующие блюда
        allConsumedMeals.addAll(existingWelness.consumedMeals);
      } else {
        log(
          '[FoodDiaryCubit] WelnessEntity не найдена, создаем новую',
          name: 'FoodDiaryCubit',
        );
      }

      // Добавляем новые потребленные блюда
      final newDiaryMeals = consumedMeals.map((e) => e.toDiaryMeal()).toList();
      allConsumedMeals.addAll(newDiaryMeals);

      log(
        '[FoodDiaryCubit] Общее количество потребленных блюд: ${allConsumedMeals.length} (${existingWelness?.consumedMeals.length ?? 0} существующих + ${newDiaryMeals.length} новых)',
        name: 'FoodDiaryCubit',
      );

      // Суммируем макросы из всех потребленных блюд (существующих + новых)
      double totalKcal = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final diaryMeal in allConsumedMeals) {
        totalKcal += diaryMeal.macros.kcal;
        totalProtein += diaryMeal.macros.protein;
        totalCarbs += diaryMeal.macros.carbs;
        totalFat += diaryMeal.macros.fat;
      }

      log(
        '[FoodDiaryCubit] Суммарные потребленные макросы: K=${totalKcal.toStringAsFixed(1)}ккал, P=${totalProtein.toStringAsFixed(1)}г, C=${totalCarbs.toStringAsFixed(1)}г, F=${totalFat.toStringAsFixed(1)}г',
        name: 'FoodDiaryCubit',
      );

      // Создаем MacrosBreakdown для потребленных макросов
      final consumedMacros = MacrosBreakdown(
        kcal: totalKcal.round(),
        protein: totalProtein.round(),
        carbs: totalCarbs.round(),
        fat: totalFat.round(),
      );

      // Получаем целевые макросы из текущего дня
      final targetMacros = currentDay.macros;
      log(
        '[FoodDiaryCubit] Целевые макросы: K=${targetMacros.kcal}ккал, P=${targetMacros.protein}г, C=${targetMacros.carbs}г, F=${targetMacros.fat}г',
        name: 'FoodDiaryCubit',
      );

      // Рассчитываем процентные соотношения потребленных макросов к целевым
      double kcalPercentage =
          targetMacros.kcal > 0 ? (totalKcal / targetMacros.kcal) * 100 : 0;
      double proteinPercentage = targetMacros.protein > 0
          ? (totalProtein / targetMacros.protein) * 100
          : 0;
      double carbsPercentage =
          targetMacros.carbs > 0 ? (totalCarbs / targetMacros.carbs) * 100 : 0;
      double fatPercentage =
          targetMacros.fat > 0 ? (totalFat / targetMacros.fat) * 100 : 0;

      log(
        '[FoodDiaryCubit] Процентные соотношения: K=${kcalPercentage.toStringAsFixed(1)}%, P=${proteinPercentage.toStringAsFixed(1)}%, C=${carbsPercentage.toStringAsFixed(1)}%, F=${fatPercentage.toStringAsFixed(1)}%',
        name: 'FoodDiaryCubit',
      );

      // Применяем формулу Daily Wellness Score
      // 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
      double wellnessScore = (kcalPercentage * 0.40) +
          (proteinPercentage * 0.30) +
          (carbsPercentage * 0.20) +
          (fatPercentage * 0.10);

      // Ограничиваем максимальное значение до 100%
      wellnessScore = wellnessScore > 100 ? 100 : wellnessScore;

      log(
        '[FoodDiaryCubit] Рассчитанный Daily Wellness Score: ${wellnessScore.toStringAsFixed(1)}%',
        name: 'FoodDiaryCubit',
      );

      // Создаем или обновляем WelnessEntity
      final welnessEntity = existingWelness?.copyWith(
            consumedMeals: allConsumedMeals,
            welnessPercentage: wellnessScore,
            consumedMacros: consumedMacros,
          ) ??
          WelnessEntity(
            consumedMeals: allConsumedMeals,
            welnessPercentage: wellnessScore,
            consumedMacros: consumedMacros,
          );

      // Обновляем день с обновленной wellness entity
      final updatedDay = currentDay.copyWith(welnessEntity: welnessEntity);
      whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));

      log(
        '[FoodDiaryCubit] ✅ Daily Wellness Score успешно ${existingWelness != null ? 'обновлен' : 'рассчитан'} и ${existingWelness != null ? 'обновлен' : 'добавлен'} в день',
        name: 'FoodDiaryCubit',
      );

      // Обновляем день в WhoopBloc
      log(
        '[FoodDiaryCubit] 🔄 Отправляем обновленный день в WhoopBloc',
        name: 'FoodDiaryCubit',
      );

      return updatedDay;
    } catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] Ошибка при расчете Daily Wellness Score: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      rethrow;
    }
  }

  /// [_clearTodayEntries] Дебажный метод для очистки всех записей дневника питания за сегодня
  ///
  /// Очищает записи как локально (Hive), так и в Directus.
  /// Также сбрасывает WelnessEntity в текущем дне.
  FutureOr<void> _clearTodayEntries(
    FoodDiaryClearTodayEntries event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit] 🧹 ДЕБАГ: Очистка всех записей дневника питания за сегодня',
        name: 'FoodDiaryCubit',
      );

      emit((state as FoodDiaryMainState).copyWith(status: Status.loading));

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      log(
        '[FoodDiaryCubit] 📅 Очищаем записи за период: ${todayStart.toIso8601String()} - ${todayEnd.toIso8601String()}',
        name: 'FoodDiaryCubit',
      );

      // 1. Очищаем локальные записи в Hive
      try {
        log(
          '[FoodDiaryCubit] 💾 Очищаем локальные записи в Hive...',
          name: 'FoodDiaryCubit',
        );

        // TODO: Здесь будет логика очистки локальных записей в Hive
        // Пока что просто логируем, так как структура хранения еще не определена
        // await hive.clearFoodDiaryEntriesForDate(todayStart);
        log(
          '[FoodDiaryCubit] TODO: Реализовать метод clearFoodDiaryEntriesForDate в HiveRepo',
          name: 'FoodDiaryCubit',
        );

        log(
          '[FoodDiaryCubit] ✅ Локальные записи в Hive очищены',
          name: 'FoodDiaryCubit',
        );
      } catch (e) {
        log(
          '[FoodDiaryCubit] ⚠️ Ошибка при очистке локальных записей: $e',
          name: 'FoodDiaryCubit',
        );
        // Продолжаем выполнение, даже если локальная очистка не удалась
      }

      // 2. Очищаем записи в Directus
      try {
        log(
          '[FoodDiaryCubit] 🌐 Очищаем записи в Directus...',
          name: 'FoodDiaryCubit',
        );

        // Получаем все записи дневника питания за сегодня из Directus
        final todayEntriesResponse = await directus.readMany(
          collection: 'food_diary_entries', // Предполагаемое название коллекции
          filters: Filters({
            'timestamp': {
              '_gte': todayStart.toIso8601String(),
              '_lt': todayEnd.toIso8601String(),
            },
          }),
        );

        if (todayEntriesResponse.isNotEmpty) {
          // Извлекаем ID записей для удаления
          final entryIds = todayEntriesResponse
              .map((entry) => entry['id'].toString())
              .toList();

          log(
            '[FoodDiaryCubit] 🗑️ Найдено ${entryIds.length} записей для удаления: $entryIds',
            name: 'FoodDiaryCubit',
          );

          // Удаляем записи пакетно
          await directus.deleteMany(
            collection: 'food_diary_entries',
            ids: entryIds,
          );

          log(
            '[FoodDiaryCubit] ✅ Записи в Directus удалены',
            name: 'FoodDiaryCubit',
          );
        } else {
          log(
            '[FoodDiaryCubit] ℹ️ Записей за сегодня в Directus не найдено',
            name: 'FoodDiaryCubit',
          );
        }
      } catch (e) {
        log(
          '[FoodDiaryCubit] ⚠️ Ошибка при очистке записей в Directus: $e',
          name: 'FoodDiaryCubit',
        );
        // Продолжаем выполнение, даже если очистка в Directus не удалась
      }

      // 3. Сбрасываем WelnessEntity в текущем дне
      try {
        log(
          '[FoodDiaryCubit] 🔄 Сбрасываем WelnessEntity в текущем дне...',
          name: 'FoodDiaryCubit',
        );

        final currentDay = whoopBloc.state.day;
        final clearedDay = currentDay.copyWith(
          welnessEntity: WelnessEntity(
            consumedMeals: const [],
            welnessPercentage: 0,
            consumedMacros:
                MacrosBreakdown(kcal: 0, protein: 0, carbs: 0, fat: 0),
          ),
        );

        // Обновляем день в WhoopBloc
        whoopBloc.add(WhoopUpdateCurrentDay(day: clearedDay));

        log(
          '[FoodDiaryCubit] ✅ WelnessEntity сброшена',
          name: 'FoodDiaryCubit',
        );
      } catch (e) {
        log(
          '[FoodDiaryCubit] ⚠️ Ошибка при сбросе WelnessEntity: $e',
          name: 'FoodDiaryCubit',
        );
      }

      // 4. Обновляем состояние кубита
      emit(
        (state as FoodDiaryMainState).copyWith(
          status: Status.success,
          entries: [], // Очищаем локальные записи в состоянии
          totalCalories: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
        ),
      );

      log(
        '[FoodDiaryCubit] 🎉 ДЕБАГ: Все записи дневника питания за сегодня успешно очищены',
        name: 'FoodDiaryCubit',
      );
    } catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] ❌ ДЕБАГ: Ошибка при очистке записей за сегодня: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit((state as FoodDiaryMainState).copyWith(status: Status.error));
    }
  }
}
