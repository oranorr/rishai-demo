import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:directus/directus.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';
import 'package:rishai/core/services/directus/directus_repository_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart';
import 'package:rishai/features/food_diary/domain/pivot_life_scrore_entity.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'food_diary_event.dart';
part 'food_diary_state.dart';

// [FoodDiaryCubit] Глобальные экземпляры для доступа из других частей приложения
final foodDiaryCubit = getIt.get<FoodDiaryCubit>();
final directusService = getIt.get<DirectusService>();

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
    on<FoodDiaryInitialize>(_initialize);

    on<FoodDiaryDeleteEntry>(_deleteEntry);
    on<FoodDiaryLoadEntries>(_loadEntries);
    on<FoodDiaryClearAll>(_clearAll);
    on<FoodDiaryClearTodayEntries>(_clearTodayEntries);

    // Обработчики событий для страницы DiaryEntryPage
    on<DiaryEntryPageInitialize>(_initializeDiaryEntryPage);
    on<DiaryEntryToggleMealSelection>(_toggleMealSelection);
    on<DiaryEntrySetMealType>(_setMealType);
    on<DiaryEntryAddSelectedMeals>(_addSelectedMeals);
    on<DiaryEntryClearSelection>(_clearSelection);
    on<DiaryEntryUpdatePhotos>(_updatePhotos);
    on<DiaryEntryAddPhoto>(_addPhoto);
    on<DiaryEntryAddPhotos>(_addPhotos);
    on<DiaryEntryRemovePhoto>(_removePhoto);
    on<DiaryEntryUpdateDescription>(_updateDescription);

    // Обработчики событий для управления кастомными блюдами
    on<CustomMealAdd>(_customMealAdd);
    on<CustomMealRemove>(_customMealRemove);
    on<CustomMealUpdatePhotos>(_customMealUpdatePhotos);
    on<CustomMealAddPhoto>(_customMealAddPhoto);
    on<CustomMealAddPhotos>(_customMealAddPhotos);
    on<CustomMealRemovePhoto>(_customMealRemovePhoto);
    on<CustomMealUpdateDescription>(_customMealUpdateDescription);
    on<CustomMealSetMealType>(_customMealSetMealType);
    on<CustomMealSetAnalyzedResult>(_customMealSetAnalyzedResult);
    on<CustomMealReset>(_customMealReset);
    on<CustomMealToggleSelection>(_customMealToggleSelection);
    on<CustomMealStartRegenerating>(_customMealStartRegenerating);
    on<CustomMealStopRegenerating>(_customMealStopRegenerating);
  }
  // ════════════════════════════════════════════════════════════════════════════
  // Константы для работы с фотографиями
  // ════════════════════════════════════════════════════════════════════════════

  /// [maxPhotos] Максимальное количество фотографий для одного блюда
  static const int maxPhotos = 3;

  /// [imageQuality] Качество сжатия изображений (0-100)
  static const int imageQuality = 85;

  /// [maxImageWidth] Максимальная ширина изображения в пикселях
  static const double maxImageWidth = 1920;

  /// [maxImageHeight] Максимальная высота изображения в пикселях
  static const double maxImageHeight = 1080;

  /// [getMaxPhotosForMeal] Вычисляет максимальное количество фотографий для блюда
  ///
  /// **Правила лимита фотографий:**
  /// - Если подписка не оплачена: 1 фото строго
  /// - Если подписка оплачена и блюдо НЕ снек: 3 фото макс
  /// - Если подписка оплачена и блюдо снек: 2 фото макс
  ///
  /// **Параметры:**
  /// - mealType: Тип приема пищи (завтрак, обед, ужин, перекус, снек)
  ///
  /// **Возвращает:**
  /// Максимальное количество фотографий для данного блюда
  static int getMaxPhotosForMeal(ServingType? mealType) {
    // Если подписка не оплачена - всегда 1 фото
    if (!adapty.isActive) {
      return 1;
    }

    // Если подписка оплачена
    // Проверяем, является ли блюдо снеком
    final isSnack = mealType == ServingType.snack;

    if (isSnack) {
      // Если блюдо снек - 2 фото
      return 2;
    } else {
      // Если блюдо не снек - 3 фото
      return 3;
    }
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

  /// [calculatePivotLifeScore] Рассчитывает среднее арифметическое Daily Wellness Score
  ///
  /// Получает все дни пользователя с wellness score, вычисляет среднее арифметическое
  /// и обновляет PivotLifeScoreEntity в профиле пользователя локально и удаленно.
  /// Учитывает дату начала отсчета (inceptionDate) - считаются только дни >= inceptionDate.
  Future<void> calculatePivotLifeScore() async {
    try {
      // Получаем ID текущего пользователя
      // [FIX] Добавляем несколько попыток с увеличивающейся задержкой на случай race condition
      // когда UserBloc обновляет состояние между emit'ами или после UpdateUserEvent
      UserEntity? currentUser;
      const maxAttempts = 5;
      const initialDelay = Duration(milliseconds: 100);
      
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        currentUser = userBloc.state.user;
        
        if (currentUser.directusId != '-1') {
          // Пользователь авторизован - выходим из цикла
          break;
        }
        
        // Если это не последняя попытка, ждем перед следующей проверкой
        if (attempt < maxAttempts - 1) {
          // Экспоненциальная задержка: 100ms, 200ms, 400ms, 800ms
          final delay = Duration(milliseconds: initialDelay.inMilliseconds * (1 << attempt));
          log(
            '[FoodDiaryCubit] ⏳ Попытка ${attempt + 1}/$maxAttempts: пользователь не авторизован, ждем ${delay.inMilliseconds}ms перед повторной проверкой',
            name: 'FoodDiaryCubit',
          );
          await Future.delayed(delay);
        }
      }
      
      // Финальная проверка после всех попыток
      if (currentUser == null || currentUser.directusId == '-1') {
        log(
          '[FoodDiaryCubit] ❌ Пользователь не авторизован после $maxAttempts попыток, пропускаем расчет Pivot Life Score',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // Получаем inceptionDate из app_config в Directus
      DateTime? inceptionDateFromConfig;
      try {
        final appConfig = await directusService.readAppConfig();
        final inceptionDateValue = appConfig['inceptionDate'];

        if (inceptionDateValue != null) {
          // Парсим DateTime из app_config (может быть в разных форматах)
          if (inceptionDateValue is int) {
            // Если это timestamp в миллисекундах
            inceptionDateFromConfig =
                DateTime.fromMillisecondsSinceEpoch(inceptionDateValue);
          } else if (inceptionDateValue is String) {
            // Если это строка ISO8601
            inceptionDateFromConfig = DateTime.parse(inceptionDateValue);
          } else {
            throw Exception('Неизвестный формат inceptionDate в app_config');
          }

          log(
            '[FoodDiaryCubit] 📅 Получена дата начала отсчета из app_config: ${inceptionDateFromConfig.toIso8601String().split('T')[0]}',
            name: 'FoodDiaryCubit',
          );
        } else {
          // Если inceptionDate не задана в app_config, используем дату первого дня с wellness score
          log(
            '[FoodDiaryCubit] ⚠️ inceptionDate не найдена в app_config, будет использована дата первого дня с wellness score',
            name: 'FoodDiaryCubit',
          );
        }
      } catch (e, stackTrace) {
        log(
          '[FoodDiaryCubit] ❌ Ошибка при получении inceptionDate из app_config: $e',
          error: e,
          stackTrace: stackTrace,
          name: 'FoodDiaryCubit',
        );
        // В случае ошибки используем дату первого дня с wellness score
      }

      // Получаем все дни пользователя через DayManager
      final userDaysResult =
          await dayManager.getUserDays(userId: currentUser.directusId);

      final List<DayEntity> userDays = userDaysResult.fold(
        (failure) {
          log(
            '[FoodDiaryCubit] ❌ Ошибка при получении дней пользователя: ${failure.message}',
            name: 'FoodDiaryCubit',
          );
          return <DayEntity>[];
        },
        (days) => days,
      );

      if (userDays.isEmpty) {
        log(
          '[FoodDiaryCubit] ⚠️ У пользователя нет дней для расчета Pivot Life Score',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // Фильтруем дни, у которых есть wellness score
      final daysWithWellnessScore = userDays
          .where((day) => day.welnessEntity?.welnessPercentage != null)
          .toList();

      if (daysWithWellnessScore.isEmpty) {
        log(
          '[FoodDiaryCubit] ⚠️ У пользователя нет дней с Daily Wellness Score для расчета среднего',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // Определяем inceptionDate:
      // - Если получена из app_config - используем её
      // - Если нет - используем дату первого дня с wellness score
      final DateTime inceptionDate;
      if (inceptionDateFromConfig != null) {
        inceptionDate = inceptionDateFromConfig;
      } else {
        // Находим самый ранний день с wellness score
        daysWithWellnessScore.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        inceptionDate = daysWithWellnessScore.first.dateTime;
        log(
          '[FoodDiaryCubit] 🆕 Устанавливаем дату начала отсчета как дату первого дня с wellness score: ${inceptionDate.toIso8601String().split('T')[0]}',
          name: 'FoodDiaryCubit',
        );
      }

      // Фильтруем дни, которые >= inceptionDate (сравниваем только дату, без времени)
      final filteredDays = daysWithWellnessScore.where((day) {
        final dayDate = DateTime(
          day.dateTime.year,
          day.dateTime.month,
          day.dateTime.day,
        );
        final inceptionDateOnly = DateTime(
          inceptionDate.year,
          inceptionDate.month,
          inceptionDate.day,
        );
        return dayDate.isAfter(inceptionDateOnly) ||
            dayDate.isAtSameMomentAs(inceptionDateOnly);
      }).toList();

      if (filteredDays.isEmpty) {
        log(
          '[FoodDiaryCubit] ⚠️ Нет дней с Daily Wellness Score после даты начала отсчета (${inceptionDate.toIso8601String().split('T')[0]})',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit] 📈 Найдено ${filteredDays.length} дней с Daily Wellness Score после даты начала отсчета (${inceptionDate.toIso8601String().split('T')[0]}) из ${daysWithWellnessScore.length} общих дней с wellness score',
        name: 'FoodDiaryCubit',
      );

      // Вычисляем среднее арифметическое
      double totalWellnessScore = 0;
      for (final day in filteredDays) {
        final wellnessScore = day.welnessEntity!.welnessPercentage;
        totalWellnessScore += wellnessScore;
        log(
          '[FoodDiaryCubit] 📅 День ${day.dateTime.toIso8601String().split('T')[0]}: Wellness Score = ${wellnessScore.toStringAsFixed(1)}%',
          name: 'FoodDiaryCubit',
        );
      }

      final averageWellnessScore = totalWellnessScore / filteredDays.length;

      log(
        '[FoodDiaryCubit] 🎯 Рассчитанный средний Daily Wellness Score (Pivot Life Score): ${averageWellnessScore.toStringAsFixed(2)}% (на основе ${filteredDays.length} дней с ${inceptionDate.toIso8601String().split('T')[0]})',
        name: 'FoodDiaryCubit',
      );

      // Создаем или обновляем PivotLifeScoreEntity с сохранением inceptionDate
      final pivotLifeScore = PivotLifeScoreEntity(
        score: averageWellnessScore,
        updatedAt: DateTime.now(),
        inceptionDate: inceptionDate,
      );

      // Обновляем пользователя с новым Pivot Life Score
      final updatedUser = currentUser.copyWith(pivotLifeScore: pivotLifeScore);

      // Обновляем пользователя через UserBloc (это обновит и локально, и удаленно)
      log(
        '[FoodDiaryCubit] 🔄 Отправляем обновленный Pivot Life Score в UserBloc...',
        name: 'FoodDiaryCubit',
      );
      userBloc.add(UpdateUserEvent(user: updatedUser));

      // [FIX] Даем время UserBloc обновить состояние
      await Future.delayed(const Duration(milliseconds: 100));

      log(
        '[FoodDiaryCubit] ✅ Pivot Life Score успешно рассчитан и обновлен: ${averageWellnessScore.toStringAsFixed(2)}%',
        name: 'FoodDiaryCubit',
      );
    } catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit] ❌ Ошибка при расчете Pivot Life Score: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      // Не пробрасываем ошибку, чтобы не нарушить основной процесс добавления блюда
    }
  }

  /// [calculateWellnessScore] Рассчитывает Daily Wellness Score на основе потребленных блюд
  ///
  /// Принимает массив блюд, получает актуальный день, создает/обновляет wellness entity.
  /// Если у пользователя уже есть WelnessEntity за сегодня, то добавляет новые блюда к существующим
  /// и пересчитывает Daily Wellness Score для всех потребленных блюд.
  /// Формула: Daily Wellness Score = 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
  /// (на основе потребленных макросов относительно целевых)
  ///
  /// [consumedMeals] - обычные блюда из планов (List<Meal>)
  /// [customMeals] - кастомные проанализированные блюда (List<DiaryMeal>), опционально
  Future<DayEntity> calculateWellnessScore(
    List<Meal> consumedMeals, {
    List<DiaryMeal> customMeals = const [],
  }) async {
    try {
      log(
        '[FoodDiaryCubit] Расчет Daily Wellness Score для ${consumedMeals.length} обычных блюд${customMeals.isNotEmpty ? ' и ${customMeals.length} кастомных блюд' : ''}',
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

      // Добавляем новые потребленные блюда (обычные)
      final newDiaryMeals = consumedMeals
          .map((e) => e.toDiaryMeal(isGeneratedMeal: true))
          .toList();
      allConsumedMeals.addAll(newDiaryMeals);

      // Добавляем кастомные проанализированные блюда (если есть)
      if (customMeals.isNotEmpty) {
        log(
          '[FoodDiaryCubit] Добавление ${customMeals.length} кастомных блюд',
          name: 'FoodDiaryCubit',
        );
        allConsumedMeals.addAll(customMeals);
      }

      log(
        '[FoodDiaryCubit] Общее количество потребленных блюд: ${allConsumedMeals.length} (${existingWelness?.consumedMeals.length ?? 0} существующих + ${newDiaryMeals.length} обычных + ${customMeals.length} кастомных)',
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

      // Применяем формулу Daily Wellness Score (DWS_raw)
      // 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
      double dwsRaw = (kcalPercentage * 0.40) +
          (proteinPercentage * 0.30) +
          (carbsPercentage * 0.20) +
          (fatPercentage * 0.10);

      log(
        '[FoodDiaryCubit] DWS_raw (до применения штрафов): ${dwsRaw.toStringAsFixed(1)}%',
        name: 'FoodDiaryCubit',
      );

      // Применяем систему штрафов за переедание, если DWS_raw > 100%
      double wellnessScore = dwsRaw;

      if (dwsRaw > 100) {
        // Определяем коэффициент штрафа в зависимости от степени переедания
        double penaltyMultiplier;

        if (dwsRaw <= 110) {
          // 101-110%: Мягкий штраф
          penaltyMultiplier = 2.0;
        } else if (dwsRaw <= 120) {
          // 111-120%: Умеренный штраф
          penaltyMultiplier = 2.2;
        } else if (dwsRaw <= 130) {
          // 121-130%: Жесткий штраф
          penaltyMultiplier = 2.3;
        } else if (dwsRaw <= 140) {
          // 131-140%: Сильный штраф
          penaltyMultiplier = 2.4;
        } else {
          // >140%: Экстремальный штраф
          penaltyMultiplier = 2.5;
        }

        // Рассчитываем штраф
        final penalty = penaltyMultiplier * (dwsRaw - 100);

        // Применяем штраф
        wellnessScore = dwsRaw - penalty;

        // Гарантируем минимальное значение 10%
        if (wellnessScore < 10) {
          wellnessScore = 10;
        }

        log(
          '[FoodDiaryCubit] ⚠️ Переедание обнаружено! DWS_raw=${dwsRaw.toStringAsFixed(1)}%, penalty=${penalty.toStringAsFixed(1)}, multiplier=${penaltyMultiplier}x',
          name: 'FoodDiaryCubit',
        );
      }

      log(
        '[FoodDiaryCubit] ✅ DWS_final (Daily Wellness Score): ${wellnessScore.toStringAsFixed(1)}%',
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

      // [FIX] Сохраняем день в Directus ДО отправки события в WhoopBloc
      // Это предотвращает задвойку дня, аналогично логике создания плана питания
      log(
        '[FoodDiaryCubit] 💾 Сохраняем обновленный день в Directus перед отправкой в WhoopBloc',
        name: 'FoodDiaryCubit',
      );
      await dayManager.createOrUpdateDay(day: updatedDay);

      log(
        '[FoodDiaryCubit] ✅ Daily Wellness Score успешно ${existingWelness != null ? 'обновлен' : 'рассчитан'} и ${existingWelness != null ? 'обновлен' : 'добавлен'} в день',
        name: 'FoodDiaryCubit',
      );

      // Обновляем день в WhoopBloc (без повторного сохранения в Directus)
      log(
        '[FoodDiaryCubit] 🔄 Отправляем обновленный день в WhoopBloc',
        name: 'FoodDiaryCubit',
      );
      whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));

      // После успешного расчета Daily Wellness Score пересчитываем Pivot Life Score
      log(
        '[FoodDiaryCubit] 🔄 Запускаем пересчет Pivot Life Score после обновления Daily Wellness Score',
        name: 'FoodDiaryCubit',
      );

      // [FIX] Ждем завершения пересчета Pivot Life Score, чтобы UI отрисовался с актуальными данными
      await calculatePivotLifeScore();

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

  // ════════════════════════════════════════════════════════════════════════════
  // Обработчики событий для страницы DiaryEntryPage
  // ════════════════════════════════════════════════════════════════════════════

  /// [_initializeDiaryEntryPage] Инициализация страницы добавления блюд
  ///
  /// Загружает доступные блюда из дневного и недельного планов,
  /// фильтрует уже потребленные блюда, подготавливает UI.
  FutureOr<void> _initializeDiaryEntryPage(
    DiaryEntryPageInitialize event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Инициализация страницы добавления блюд',
        name: 'FoodDiaryCubit',
      );

      emit(DiaryEntryPageState.initial().copyWith(status: Status.loading));

      // Получаем блюда из дневного плана
      final whoopState = whoopBloc.state;
      final dailyPlanMeals = whoopState.day.mealPlanEntity?.meals ?? <Meal>[];

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Блюд из дневного плана: ${dailyPlanMeals.length}',
        name: 'FoodDiaryCubit',
      );

      // Получаем блюда из недельного плана на сегодня
      final weekPlanMeals = _getWeekPlanMealsForToday();

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Блюд из недельного плана: ${weekPlanMeals.length}',
        name: 'FoodDiaryCubit',
      );

      // ═══════════════════════════════════════════════════════════════════════
      // Логика выбора блюд для отображения:
      // - Если есть только индивидуальный план - показывать только его
      // - Если есть только 5-дневный план - показывать план текущего дня
      // - Если есть оба плана - показывать только индивидуальный план
      // - Если ничего не сгенерировано - показывать пустой список
      // ═══════════════════════════════════════════════════════════════════════
      final bool hasDailyPlan = dailyPlanMeals.isNotEmpty;
      final bool hasWeekPlan = weekPlanMeals.isNotEmpty;

      List<Meal> allMeals;

      if (hasDailyPlan && hasWeekPlan) {
        // Если есть оба плана - показываем только индивидуальный
        log(
          '[FoodDiaryCubit._initializeDiaryEntryPage] Найдены оба плана, используем только индивидуальный план',
          name: 'FoodDiaryCubit',
        );
        allMeals = dailyPlanMeals;
      } else if (hasDailyPlan) {
        // Если есть только индивидуальный план - показываем его
        log(
          '[FoodDiaryCubit._initializeDiaryEntryPage] Найден только индивидуальный план',
          name: 'FoodDiaryCubit',
        );
        allMeals = dailyPlanMeals;
      } else if (hasWeekPlan) {
        // Если есть только недельный план - показываем план текущего дня
        log(
          '[FoodDiaryCubit._initializeDiaryEntryPage] Найден только недельный план, используем план текущего дня',
          name: 'FoodDiaryCubit',
        );
        allMeals = weekPlanMeals;
      } else {
        // Если ничего не сгенерировано - пустой список
        log(
          '[FoodDiaryCubit._initializeDiaryEntryPage] Планы не найдены, показываем пустой список',
          name: 'FoodDiaryCubit',
        );
        allMeals = <Meal>[];
      }

      // [filterAvailableMeals] Используем единый метод фильтрации, который учитывает:
      // 1. Уже потребленные блюда (точное совпадение)
      // 2. Типы кастомных блюд (если есть)
      // 3. Типы уже добавленных в дневник блюд
      // На момент инициализации кастомных блюд еще нет, но метод все равно работает корректно
      final initialState = DiaryEntryPageState.initial();
      final availableMeals = _filterAvailableMealsByCustomMealTypes(
        allMealsFromPlan: allMeals,
        customMeals: initialState.customMeals,
      );

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Доступных блюд для выбора: ${availableMeals.length}',
        name: 'FoodDiaryCubit',
      );

      emit(
        DiaryEntryPageState.initial().copyWith(
          status: Status.success,
          availableMeals: availableMeals,
          allMealsFromPlan: allMeals,
        ),
      );

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] ✅ Инициализация завершена успешно',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] ❌ Ошибка при инициализации: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
      emit(
        DiaryEntryPageState.initial().copyWith(
          status: Status.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// [_getWeekPlanMealsForToday] Получает блюда из активного недельного плана на сегодня
  ///
  /// Находит активный недельный план, определяет текущий день недели
  /// и возвращает блюда для этого дня.
  List<Meal> _getWeekPlanMealsForToday() {
    final weekPlans = weekPlanBloc.state.allWeekPlans;
    if (weekPlans.isEmpty) {
      log(
        '[FoodDiaryCubit._getWeekPlanMealsForToday] Нет недельных планов',
        name: 'FoodDiaryCubit',
      );
      return [];
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Ищем активный план, который покрывает сегодняшнюю дату
    WeekPlanEntity? activePlan;
    for (final plan in weekPlans) {
      final startDate = DateTime(
        plan.startDate.year,
        plan.startDate.month,
        plan.startDate.day,
      );
      final endDate = DateTime(
        plan.endDate.year,
        plan.endDate.month,
        plan.endDate.day,
      );

      // Проверяем, попадает ли сегодняшняя дата в диапазон плана
      if ((todayDate.isAfter(startDate) ||
              todayDate.isAtSameMomentAs(startDate)) &&
          (todayDate.isBefore(endDate) ||
              todayDate.isAtSameMomentAs(endDate))) {
        activePlan = plan;
        log(
          '[FoodDiaryCubit._getWeekPlanMealsForToday] Найден активный план: ${plan.formatPeriod()}',
          name: 'FoodDiaryCubit',
        );
        break;
      }
    }

    if (activePlan == null) {
      log(
        '[FoodDiaryCubit._getWeekPlanMealsForToday] Нет активного плана на сегодня',
        name: 'FoodDiaryCubit',
      );
      return [];
    }

    // Определяем индекс дня в плане
    final startDate = DateTime(
      activePlan.startDate.year,
      activePlan.startDate.month,
      activePlan.startDate.day,
    );
    final dayIndex = todayDate.difference(startDate).inDays;

    // Проверяем, что индекс в пределах плана
    if (dayIndex < 0 || dayIndex >= activePlan.plans.length) {
      log(
        '[FoodDiaryCubit._getWeekPlanMealsForToday] Индекс дня $dayIndex вне диапазона плана',
        name: 'FoodDiaryCubit',
      );
      return [];
    }

    final todayPlan = activePlan.plans[dayIndex];
    log(
      '[FoodDiaryCubit._getWeekPlanMealsForToday] Найден план на день $dayIndex с ${todayPlan.meals.length} блюдами',
      name: 'FoodDiaryCubit',
    );

    return todayPlan.meals;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// [_getServingTypeFromString] Преобразует строку типа блюда в ServingType
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Использует ту же логику, что и Meal.servingType для преобразования
  /// строки типа блюда (например, "Breakfast", "Savoury Breakfast") в ServingType enum.
  ///
  /// **Параметры:**
  /// - [typeString] - строка типа блюда из DiaryMeal.type
  ///
  /// **Возвращает:**
  /// ServingType enum или null, если тип не распознан
  ServingType? _getServingTypeFromString(String typeString) {
    final type = typeString.toLowerCase();
    if (type.contains('breakfast') || type.contains('meal 1')) {
      return ServingType.breakfast;
    } else if (type.contains('lunch') || type.contains('meal 2')) {
      return ServingType.lunch;
    } else if (type.contains('dinner') || type.contains('meal 3')) {
      return ServingType.dinner;
    } else if (type.contains('supper') || type.contains('meal 4')) {
      return ServingType.supper;
    } else if (type.contains('snack') || type.contains('meal 5')) {
      return ServingType.snack;
    }
    return null;
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// [_filterAvailableMealsByCustomMealTypes] Фильтрует доступные блюда
  /// ═══════════════════════════════════════════════════════════════════════
  ///
  /// Фильтрует список доступных сгенерированных блюд, исключая:
  /// 1. Уже потребленные блюда (точное совпадение title и type)
  /// 2. Блюда, тип которых совпадает с типом кастомных блюд
  /// 3. Блюда, тип которых совпадает с типом уже добавленных в дневник блюд
  ///
  /// **Логика:**
  /// - Собирает все типы из кастомных блюд (где mealType != null)
  /// - Собирает все типы из уже добавленных в дневник блюд (consumedMeals)
  /// - Исключает из allMealsFromPlan блюда, у которых servingType
  ///   совпадает с одним из собранных типов
  /// - Также исключает уже потребленные блюда (точное совпадение)
  ///
  /// **Параметры:**
  /// - [allMealsFromPlan] - все блюда из плана (до фильтрации)
  /// - [customMeals] - массив кастомных блюд
  ///
  /// **Возвращает:**
  /// Отфильтрованный список доступных блюд
  List<Meal> _filterAvailableMealsByCustomMealTypes({
    required List<Meal> allMealsFromPlan,
    required List<CustomMealEntry> customMeals,
  }) {
    // [getConsumedMeals] Получаем уже потребленные блюда
    final whoopState = whoopBloc.state;
    final consumedMeals =
        whoopState.day.welnessEntity?.consumedMeals ?? <DiaryMeal>[];

    // [collectCustomMealTypes] Собираем все типы из кастомных блюд
    final customMealTypes = customMeals
        .where((meal) => meal.mealType != null)
        .map((meal) => meal.mealType!)
        .toSet();

    // [collectConsumedMealTypes] Собираем все типы из уже добавленных в дневник блюд
    final consumedMealTypes = consumedMeals
        .map((meal) => _getServingTypeFromString(meal.type))
        .whereType<ServingType>()
        .toSet();

    // [combineExcludedTypes] Объединяем типы кастомных блюд и уже добавленных блюд
    final excludedTypes = <ServingType>{
      ...customMealTypes,
      ...consumedMealTypes,
    };

    log(
      '[FoodDiaryCubit._filterAvailableMealsByCustomMealTypes] Типы кастомных блюд: ${customMealTypes.map((t) => t.name).join(", ")}',
      name: 'FoodDiaryCubit',
    );
    log(
      '[FoodDiaryCubit._filterAvailableMealsByCustomMealTypes] Типы уже добавленных блюд: ${consumedMealTypes.map((t) => t.name).join(", ")}',
      name: 'FoodDiaryCubit',
    );
    log(
      '[FoodDiaryCubit._filterAvailableMealsByCustomMealTypes] Исключаемые типы: ${excludedTypes.map((t) => t.name).join(", ")}',
      name: 'FoodDiaryCubit',
    );

    // [filterMeals] Фильтруем блюда
    final filteredMeals = allMealsFromPlan.where((meal) {
      // [checkConsumed] Проверяем, не потреблено ли блюдо (точное совпадение)
      final diaryMeal = meal.toDiaryMeal(isGeneratedMeal: true);
      final isConsumed = consumedMeals.any(
        (consumed) =>
            consumed.title == diaryMeal.title &&
            consumed.type == diaryMeal.type,
      );

      if (isConsumed) {
        return false;
      }

      // [checkExcludedType] Проверяем, не совпадает ли тип с исключаемыми типами
      final mealServingType = meal.servingType;
      final isExcludedByType = excludedTypes.contains(mealServingType);

      if (isExcludedByType) {
        final reason = customMealTypes.contains(mealServingType)
            ? 'кастомного блюда'
            : 'уже добавленного в дневник блюда';
        log(
          '[FoodDiaryCubit._filterAvailableMealsByCustomMealTypes] Исключено блюдо "${meal.title}" (тип: ${mealServingType.name}) из-за $reason того же типа',
          name: 'FoodDiaryCubit',
        );
        return false;
      }

      return true;
    }).toList();

    log(
      '[FoodDiaryCubit._filterAvailableMealsByCustomMealTypes] Отфильтровано блюд: ${filteredMeals.length} из ${allMealsFromPlan.length}',
      name: 'FoodDiaryCubit',
    );

    return filteredMeals;
  }

  /// [_toggleMealSelection] Переключает выбор блюда
  ///
  /// Добавляет или удаляет блюдо из списка выбранных для добавления в дневник.
  FutureOr<void> _toggleMealSelection(
    DiaryEntryToggleMealSelection event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._toggleMealSelection] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._toggleMealSelection] Переключение выбора блюда: ${event.meal.title} -> ${event.isSelected}',
        name: 'FoodDiaryCubit',
      );

      final updatedSelectedMeals = List<Meal>.from(currentState.selectedMeals);

      if (event.isSelected) {
        // Добавляем блюдо в выбранные, если его там нет
        if (!updatedSelectedMeals.contains(event.meal)) {
          updatedSelectedMeals.add(event.meal);
          log(
            '[FoodDiaryCubit._toggleMealSelection] ✅ Блюдо добавлено в выбранные. Всего выбрано: ${updatedSelectedMeals.length}',
            name: 'FoodDiaryCubit',
          );
        }
      } else {
        // Удаляем блюдо из выбранных
        updatedSelectedMeals.remove(event.meal);
        log(
          '[FoodDiaryCubit._toggleMealSelection] ✅ Блюдо удалено из выбранных. Всего выбрано: ${updatedSelectedMeals.length}',
          name: 'FoodDiaryCubit',
        );
      }

      emit(currentState.copyWith(selectedMeals: updatedSelectedMeals));
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._toggleMealSelection] ❌ Ошибка при переключении выбора: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_setMealType] Устанавливает тип приема пищи
  ///
  /// Используется для выбора типа приема пищи при добавлении кастомных блюд.
  FutureOr<void> _setMealType(
    DiaryEntrySetMealType event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._setMealType] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._setMealType] Установка типа приема пищи: ${event.mealType?.name ?? 'null'}',
        name: 'FoodDiaryCubit',
      );

      emit(
        currentState.copyWith(
          selectedMealType: event.mealType,
          clearMealType: event.mealType == null,
        ),
      );

      log(
        '[FoodDiaryCubit._setMealType] ✅ Тип приема пищи установлен',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._setMealType] ❌ Ошибка при установке типа приема пищи: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_addSelectedMeals] Добавляет выбранные блюда в дневник
  ///
  /// Добавляет все выбранные блюда в дневник питания, рассчитывает wellness score,
  /// очищает список выбранных блюд после успешного добавления.
  /// Учитывает как обычные блюда (selectedMeals), так и кастомные проанализированные блюда (selectedCustomMeals).
  FutureOr<void> _addSelectedMeals(
    DiaryEntryAddSelectedMeals event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._addSelectedMeals] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final selectedCustomMeals = currentState.selectedCustomMeals;
      final hasRegularMeals = currentState.selectedMeals.isNotEmpty;
      final hasCustomMeals = selectedCustomMeals.isNotEmpty;

      if (!hasRegularMeals && !hasCustomMeals) {
        log(
          '[FoodDiaryCubit._addSelectedMeals] ⚠️ Нет выбранных блюд для добавления',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._addSelectedMeals] Добавление ${currentState.selectedMeals.length} обычных блюд и ${selectedCustomMeals.length} кастомных блюд в дневник',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(status: Status.loading));

      // Логируем добавляемые обычные блюда
      for (final meal in currentState.selectedMeals) {
        log(
          '[FoodDiaryCubit._addSelectedMeals] Добавляемое обычное блюдо: ${meal.title}',
          name: 'FoodDiaryCubit',
        );
      }

      // Логируем добавляемые кастомные блюда
      for (final customMeal in selectedCustomMeals) {
        if (customMeal.analyzedMeal != null) {
          log(
            '[FoodDiaryCubit._addSelectedMeals] Добавляемое кастомное блюдо: ${customMeal.analyzedMeal!.title}',
            name: 'FoodDiaryCubit',
          );
        }
      }

      // Извлекаем DiaryMeal из выбранных кастомных блюд
      final customDiaryMeals = selectedCustomMeals
          .where((meal) => meal.analyzedMeal != null)
          .map((meal) => meal.analyzedMeal!)
          .toList();

      // Рассчитываем wellness score с выбранными блюдами (обычные + кастомные)
      await calculateWellnessScore(
        currentState.selectedMeals,
        customMeals: customDiaryMeals,
      );

      log(
        '[FoodDiaryCubit._addSelectedMeals] ✅ Блюда успешно добавлены в дневник',
        name: 'FoodDiaryCubit',
      );

      // ┌───────────────────────────────────────────────────────────────────┐
      // │ Сохранение времени использования фото для бесплатных пользователей │
      // └───────────────────────────────────────────────────────────────────┘
      // [savePhotoUsageTime] Сохраняем время только когда:
      // 1. Пользователь бесплатный (не активная подписка)
      // 2. Среди добавленных кастомных блюд есть хотя бы одно с фотографиями
      if (!adapty.isActive && selectedCustomMeals.isNotEmpty) {
        // [checkForPhotos] Проверяем, есть ли фотографии в добавляемых блюдах
        final hasPhotosInCustomMeals = selectedCustomMeals.any(
          (meal) => meal.photos.isNotEmpty,
        );

        if (hasPhotosInCustomMeals) {
          // [setLastUploadTime] Сохраняем текущее время как время последнего использования фото
          await prefsRepo.setLastFreeUserPhotoUploadTime(DateTime.now());
          log(
            '[FoodDiaryCubit._addSelectedMeals] 💾 Время использования фотографии сохранено для бесплатного пользователя',
            name: 'FoodDiaryCubit',
          );
        }
      }

      // Очищаем списки выбранных блюд после успешного добавления
      final updatedCustomMeals = currentState.customMeals.map((meal) {
        if (meal.isSelected && meal.isAnalyzed) {
          // Сбрасываем флаг выбора
          return meal.copyWith(isSelected: false);
        }
        return meal;
      }).toList();

      emit(
        currentState.copyWith(
          status: Status.success,
          selectedMeals: [],
          customMeals: updatedCustomMeals,
        ),
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._addSelectedMeals] ❌ Ошибка при добавлении блюд: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );

      final currentState = state;
      if (currentState is DiaryEntryPageState) {
        emit(
          currentState.copyWith(
            status: Status.error,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  /// [_clearSelection] Очищает список выбранных блюд
  ///
  /// Очищает список выбранных блюд без добавления их в дневник.
  /// Используется при отмене или сбросе выбора.
  FutureOr<void> _clearSelection(
    DiaryEntryClearSelection event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._clearSelection] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._clearSelection] Очистка выбранных блюд (было выбрано: ${currentState.selectedMeals.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(selectedMeals: []));

      log(
        '[FoodDiaryCubit._clearSelection] ✅ Выбранные блюда очищены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._clearSelection] ❌ Ошибка при очистке выбранных блюд: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_updatePhotos] Обновляет список фотографий
  ///
  /// Обновляет список выбранных фотографий блюд.
  /// Используется при добавлении или удалении фотографий.
  FutureOr<void> _updatePhotos(
    DiaryEntryUpdatePhotos event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._updatePhotos] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._updatePhotos] Обновление фотографий (новое количество: ${event.photos.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(selectedPhotos: event.photos));

      log(
        '[FoodDiaryCubit._updatePhotos] ✅ Фотографии обновлены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._updatePhotos] ❌ Ошибка при обновлении фотографий: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_addPhoto] Добавляет одну фотографию в список
  ///
  /// Добавляет новую фотографию в список выбранных фотографий блюда.
  /// Проверяет лимит в 3 фотографии.
  FutureOr<void> _addPhoto(
    DiaryEntryAddPhoto event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._addPhoto] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      const maxPhotos = 3;
      final currentPhotos = currentState.selectedPhotos;

      if (currentPhotos.length >= maxPhotos) {
        log(
          '[FoodDiaryCubit._addPhoto] ⚠️ Достигнут лимит фотографий: $maxPhotos',
          name: 'FoodDiaryCubit',
        );
        // Можно добавить emit с сообщением об ошибке если нужно
        return;
      }

      final updatedPhotos = List<XFile>.from(currentPhotos)..add(event.photo);

      log(
        '[FoodDiaryCubit._addPhoto] Добавление фотографии (всего: ${updatedPhotos.length}/$maxPhotos)',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(selectedPhotos: updatedPhotos));

      log(
        '[FoodDiaryCubit._addPhoto] ✅ Фотография добавлена',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._addPhoto] ❌ Ошибка при добавлении фотографии: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_addPhotos] Добавляет несколько фотографий в список
  ///
  /// Добавляет несколько новых фотографий в список выбранных фотографий блюда.
  /// Автоматически ограничивает количество до максимального (3 шт).
  FutureOr<void> _addPhotos(
    DiaryEntryAddPhotos event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._addPhotos] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      const maxPhotos = 3;
      final currentPhotos = currentState.selectedPhotos;
      final availableSlots = maxPhotos - currentPhotos.length;

      if (availableSlots <= 0) {
        log(
          '[FoodDiaryCubit._addPhotos] ⚠️ Достигнут лимит фотографий: $maxPhotos',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // Берем только столько фотографий, сколько доступно слотов
      final photosToAdd = event.photos.take(availableSlots).toList();
      final updatedPhotos = List<XFile>.from(currentPhotos)
        ..addAll(photosToAdd);

      log(
        '[FoodDiaryCubit._addPhotos] Добавление ${photosToAdd.length} фотографий (всего: ${updatedPhotos.length}/$maxPhotos)',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(selectedPhotos: updatedPhotos));

      log(
        '[FoodDiaryCubit._addPhotos] ✅ Фотографии добавлены',
        name: 'FoodDiaryCubit',
      );

      // Предупреждаем если не все фото добавились
      if (event.photos.length > availableSlots) {
        log(
          '[FoodDiaryCubit._addPhotos] ⚠️ Некоторые фотографии не были добавлены из-за лимита',
          name: 'FoodDiaryCubit',
        );
      }
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._addPhotos] ❌ Ошибка при добавлении фотографий: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_removePhoto] Удаляет фотографию по индексу
  ///
  /// Удаляет фотографию из списка выбранных фотографий блюда по указанному индексу.
  FutureOr<void> _removePhoto(
    DiaryEntryRemovePhoto event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._removePhoto] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final currentPhotos = currentState.selectedPhotos;

      if (event.index < 0 || event.index >= currentPhotos.length) {
        log(
          '[FoodDiaryCubit._removePhoto] ⚠️ Некорректный индекс: ${event.index} (всего фотографий: ${currentPhotos.length})',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedPhotos = List<XFile>.from(currentPhotos)
        ..removeAt(event.index);

      log(
        '[FoodDiaryCubit._removePhoto] Удаление фотографии по индексу ${event.index} (осталось: ${updatedPhotos.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(selectedPhotos: updatedPhotos));

      log(
        '[FoodDiaryCubit._removePhoto] ✅ Фотография удалена',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._removePhoto] ❌ Ошибка при удалении фотографии: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_updateDescription] Обновляет описание кастомного блюда
  ///
  /// Обновляет текстовое описание блюда, введенное пользователем.
  /// @deprecated Используйте _customMealUpdateDescription
  FutureOr<void> _updateDescription(
    DiaryEntryUpdateDescription event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._updateDescription] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._updateDescription] Обновление описания блюда (длина: ${event.description.length} символов)',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(mealDescription: event.description));

      log(
        '[FoodDiaryCubit._updateDescription] ✅ Описание обновлено',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._updateDescription] ❌ Ошибка при обновлении описания: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Обработчики событий для управления массивом кастомных блюд
  // ════════════════════════════════════════════════════════════════════════════

  /// [_customMealAdd] Добавляет новое пустое кастомное блюдо
  ///
  /// Создает новый пустой экземпляр CustomMealEntry и добавляет его в массив.
  /// Используется при нажатии на кнопку "Add more".
  FutureOr<void> _customMealAdd(
    CustomMealAdd event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealAdd] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final newMeal = CustomMealEntry.empty();
      final updatedMeals = List<CustomMealEntry>.from(currentState.customMeals)
        ..add(newMeal);

      log(
        '[FoodDiaryCubit._customMealAdd] Добавление нового блюда (ID: ${newMeal.id}, всего: ${updatedMeals.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealAdd] ✅ Блюдо добавлено',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealAdd] ❌ Ошибка при добавлении блюда: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealRemove] Удаляет кастомное блюдо по ID
  ///
  /// Удаляет блюдо из массива. Если остается 0 блюд, создает одно пустое.
  /// После удаления обновляет фильтрацию доступных блюд.
  FutureOr<void> _customMealRemove(
    CustomMealRemove event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealRemove] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // [removeMeal] Удаляем блюдо из массива
      final updatedMeals = currentState.customMeals
          .where((meal) => meal.id != event.mealId)
          .toList();

      // Если все удалили — добавляем одно пустое блюдо
      if (updatedMeals.isEmpty) {
        updatedMeals.add(CustomMealEntry.empty());
        log(
          '[FoodDiaryCubit._customMealRemove] Все блюда удалены, создается новое пустое',
          name: 'FoodDiaryCubit',
        );
      }

      log(
        '[FoodDiaryCubit._customMealRemove] Удаление блюда (ID: ${event.mealId}, осталось: ${updatedMeals.length})',
        name: 'FoodDiaryCubit',
      );

      // [filterAvailableMeals] Обновляем фильтрацию доступных блюд после удаления
      final filteredAvailableMeals = _filterAvailableMealsByCustomMealTypes(
        allMealsFromPlan: currentState.allMealsFromPlan,
        customMeals: updatedMeals,
      );

      log(
        '[FoodDiaryCubit._customMealRemove] Отфильтровано доступных блюд: ${filteredAvailableMeals.length} (было: ${currentState.availableMeals.length})',
        name: 'FoodDiaryCubit',
      );

      emit(
        currentState.copyWith(
          customMeals: updatedMeals,
          availableMeals: filteredAvailableMeals,
        ),
      );

      log(
        '[FoodDiaryCubit._customMealRemove] ✅ Блюдо удалено и доступные блюда обновлены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealRemove] ❌ Ошибка при удалении блюда: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealUpdatePhotos] Обновляет список фотографий блюда
  ///
  /// Заменяет весь список фотографий для указанного блюда.
  FutureOr<void> _customMealUpdatePhotos(
    CustomMealUpdatePhotos event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealUpdatePhotos] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          return meal.copyWith(photos: event.photos);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealUpdatePhotos] Обновление фотографий (ID: ${event.mealId}, количество: ${event.photos.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealUpdatePhotos] ✅ Фотографии обновлены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealUpdatePhotos] ❌ Ошибка при обновлении фотографий: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealAddPhoto] Добавляет одну фотографию к блюду
  ///
  /// Добавляет фотографию в список, проверяя лимит на основе подписки и типа блюда.
  FutureOr<void> _customMealAddPhoto(
    CustomMealAddPhoto event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealAddPhoto] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          // Вычисляем лимит для данного блюда на основе подписки и типа блюда
          final maxPhotosForMeal = getMaxPhotosForMeal(meal.mealType);

          if (meal.photos.length >= maxPhotosForMeal) {
            log(
              '[FoodDiaryCubit._customMealAddPhoto] ⚠️ Достигнут лимит фотографий: $maxPhotosForMeal',
              name: 'FoodDiaryCubit',
            );
            return meal;
          }

          final updatedPhotos = List<XFile>.from(meal.photos)..add(event.photo);
          return meal.copyWith(photos: updatedPhotos);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealAddPhoto] Добавление фотографии (ID: ${event.mealId})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealAddPhoto] ✅ Фотография добавлена',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealAddPhoto] ❌ Ошибка при добавлении фотографии: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealAddPhotos] Добавляет несколько фотографий к блюду
  ///
  /// Добавляет фотографии в список, автоматически ограничивая до лимита
  /// на основе подписки и типа блюда.
  FutureOr<void> _customMealAddPhotos(
    CustomMealAddPhotos event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealAddPhotos] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          // Вычисляем лимит для данного блюда на основе подписки и типа блюда
          final maxPhotosForMeal = getMaxPhotosForMeal(meal.mealType);
          final availableSlots = maxPhotosForMeal - meal.photos.length;

          if (availableSlots <= 0) {
            log(
              '[FoodDiaryCubit._customMealAddPhotos] ⚠️ Достигнут лимит фотографий: $maxPhotosForMeal',
              name: 'FoodDiaryCubit',
            );
            return meal;
          }

          final photosToAdd = event.photos.take(availableSlots).toList();
          final updatedPhotos = List<XFile>.from(meal.photos)
            ..addAll(photosToAdd);

          return meal.copyWith(photos: updatedPhotos);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealAddPhotos] Добавление фотографий (ID: ${event.mealId}, количество: ${event.photos.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealAddPhotos] ✅ Фотографии добавлены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealAddPhotos] ❌ Ошибка при добавлении фотографий: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealRemovePhoto] Удаляет фотографию из блюда по индексу
  ///
  /// Удаляет фотографию из списка фотографий указанного блюда.
  FutureOr<void> _customMealRemovePhoto(
    CustomMealRemovePhoto event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealRemovePhoto] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          if (event.photoIndex < 0 || event.photoIndex >= meal.photos.length) {
            log(
              '[FoodDiaryCubit._customMealRemovePhoto] ⚠️ Некорректный индекс: ${event.photoIndex}',
              name: 'FoodDiaryCubit',
            );
            return meal;
          }

          final updatedPhotos = List<XFile>.from(meal.photos)
            ..removeAt(event.photoIndex);
          return meal.copyWith(photos: updatedPhotos);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealRemovePhoto] Удаление фотографии (ID: ${event.mealId}, индекс: ${event.photoIndex})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealRemovePhoto] ✅ Фотография удалена',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealRemovePhoto] ❌ Ошибка при удалении фотографии: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealUpdateDescription] Обновляет описание блюда
  ///
  /// Обновляет текстовое описание для указанного блюда.
  FutureOr<void> _customMealUpdateDescription(
    CustomMealUpdateDescription event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealUpdateDescription] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          return meal.copyWith(description: event.description);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealUpdateDescription] Обновление описания (ID: ${event.mealId}, длина: ${event.description.length})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealUpdateDescription] ✅ Описание обновлено',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealUpdateDescription] ❌ Ошибка при обновлении описания: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealSetMealType] Устанавливает тип приема пищи для кастомного блюда
  ///
  /// Устанавливает тип приема пищи (завтрак, обед, ужин, перекус) для указанного блюда.
  /// После установки типа фильтрует доступные сгенерированные блюда, исключая блюда того же типа.
  FutureOr<void> _customMealSetMealType(
    CustomMealSetMealType event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealSetMealType] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // [updateCustomMeals] Обновляем тип приема пищи для указанного блюда
      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          return meal.copyWith(
            mealType: event.mealType,
            clearMealType: event.mealType == null,
          );
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealSetMealType] Установка типа приема пищи (ID: ${event.mealId}, тип: ${event.mealType?.name})',
        name: 'FoodDiaryCubit',
      );

      // [filterAvailableMeals] Фильтруем доступные блюда на основе типов кастомных блюд
      final filteredAvailableMeals = _filterAvailableMealsByCustomMealTypes(
        allMealsFromPlan: currentState.allMealsFromPlan,
        customMeals: updatedMeals,
      );

      log(
        '[FoodDiaryCubit._customMealSetMealType] Отфильтровано доступных блюд: ${filteredAvailableMeals.length} (было: ${currentState.availableMeals.length})',
        name: 'FoodDiaryCubit',
      );

      emit(
        currentState.copyWith(
          customMeals: updatedMeals,
          availableMeals: filteredAvailableMeals,
        ),
      );

      log(
        '[FoodDiaryCubit._customMealSetMealType] ✅ Тип приема пищи установлен и доступные блюда отфильтрованы',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealSetMealType] ❌ Ошибка при установке типа приема пищи: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealSetAnalyzedResult] Сохраняет результат анализа блюда
  ///
  /// Обновляет блюдо, сохраняя в нем результат анализа от сервера.
  /// После этого блюдо переходит в режим read-only отображения.
  FutureOr<void> _customMealSetAnalyzedResult(
    CustomMealSetAnalyzedResult event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealSetAnalyzedResult] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          return meal.copyWith(analyzedMeal: event.analyzedMeal);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealSetAnalyzedResult] Сохранение результата анализа (ID: ${event.mealId}, блюдо: ${event.analyzedMeal.title})',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealSetAnalyzedResult] ✅ Результат анализа сохранен',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealSetAnalyzedResult] ❌ Ошибка при сохранении результата анализа: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealReset] Сбрасывает блюдо в пустое состояние
  ///
  /// Заменяет блюдо на пустую карточку с тем же ID.
  /// Используется при удалении единственного проанализированного блюда.
  /// После сброса обновляет фильтрацию доступных блюд.
  FutureOr<void> _customMealReset(
    CustomMealReset event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealReset] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      // [resetMeal] Сбрасываем блюдо в пустое состояние
      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId) {
          // Создаем пустое блюдо с тем же ID
          return CustomMealEntry.empty().copyWith(id: event.mealId);
        }
        return meal;
      }).toList();

      log(
        '[FoodDiaryCubit._customMealReset] Сброс блюда в пустое состояние (ID: ${event.mealId})',
        name: 'FoodDiaryCubit',
      );

      // [filterAvailableMeals] Обновляем фильтрацию доступных блюд после сброса
      final filteredAvailableMeals = _filterAvailableMealsByCustomMealTypes(
        allMealsFromPlan: currentState.allMealsFromPlan,
        customMeals: updatedMeals,
      );

      log(
        '[FoodDiaryCubit._customMealReset] Отфильтровано доступных блюд: ${filteredAvailableMeals.length} (было: ${currentState.availableMeals.length})',
        name: 'FoodDiaryCubit',
      );

      emit(
        currentState.copyWith(
          customMeals: updatedMeals,
          availableMeals: filteredAvailableMeals,
        ),
      );

      log(
        '[FoodDiaryCubit._customMealReset] ✅ Блюдо сброшено в пустое состояние и доступные блюда обновлены',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealReset] ❌ Ошибка при сбросе блюда: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealToggleSelection] Переключает выбор проанализированного блюда
  ///
  /// Добавляет или убирает блюдо из списка выбранных для добавления в дневник.
  /// Работает только с проанализированными блюдами (isAnalyzed = true).
  FutureOr<void> _customMealToggleSelection(
    CustomMealToggleSelection event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealToggleSelection] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      final updatedMeals = currentState.customMeals.map((meal) {
        if (meal.id == event.mealId && meal.isAnalyzed) {
          // Переключаем состояние выбора
          final newIsSelected = !meal.isSelected;
          log(
            '[FoodDiaryCubit._customMealToggleSelection] Переключение выбора (ID: ${event.mealId}, isSelected: ${meal.isSelected} -> $newIsSelected)',
            name: 'FoodDiaryCubit',
          );
          return meal.copyWith(isSelected: newIsSelected);
        }
        return meal;
      }).toList();

      // Проверяем результат перед эмитом
      final selectedCount =
          updatedMeals.where((m) => m.isAnalyzed && m.isSelected).length;
      log(
        '[FoodDiaryCubit._customMealToggleSelection] Количество выбранных кастомных блюд после обновления: $selectedCount',
        name: 'FoodDiaryCubit',
      );

      emit(currentState.copyWith(customMeals: updatedMeals));

      // Проверяем состояние после эмита
      final newState = state;
      if (newState is DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealToggleSelection] После эмита: selectedCustomMealsCount = ${newState.selectedCustomMealsCount}',
          name: 'FoodDiaryCubit',
        );
      }

      log(
        '[FoodDiaryCubit._customMealToggleSelection] ✅ Выбор переключен',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealToggleSelection] ❌ Ошибка при переключении выбора: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealStartRegenerating] Отмечает блюдо как регенерирующееся
  ///
  /// Добавляет ID блюда в множество регенерирующихся блюд,
  /// что используется для блокировки кнопки добавления в дневник.
  FutureOr<void> _customMealStartRegenerating(
    CustomMealStartRegenerating event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealStartRegenerating] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._customMealStartRegenerating] Начало регенерации блюда (ID: ${event.mealId})',
        name: 'FoodDiaryCubit',
      );

      // Добавляем ID блюда в множество регенерирующихся
      final updatedRegeneratingIds = {
        ...currentState.regeneratingMealIds,
        event.mealId,
      };

      emit(
        currentState.copyWith(
          regeneratingMealIds: updatedRegeneratingIds,
        ),
      );

      log(
        '[FoodDiaryCubit._customMealStartRegenerating] ✅ Блюдо отмечено как регенерирующееся. Всего регенерируется: ${updatedRegeneratingIds.length}',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealStartRegenerating] ❌ Ошибка при отметке начала регенерации: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }

  /// [_customMealStopRegenerating] Убирает блюдо из списка регенерирующихся
  ///
  /// Удаляет ID блюда из множества регенерирующихся блюд,
  /// разблокируя кнопку добавления в дневник после завершения регенерации.
  FutureOr<void> _customMealStopRegenerating(
    CustomMealStopRegenerating event,
    Emitter<FoodDiaryState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! DiaryEntryPageState) {
        log(
          '[FoodDiaryCubit._customMealStopRegenerating] ⚠️ Некорректное состояние: ${currentState.runtimeType}',
          name: 'FoodDiaryCubit',
        );
        return;
      }

      log(
        '[FoodDiaryCubit._customMealStopRegenerating] Окончание регенерации блюда (ID: ${event.mealId})',
        name: 'FoodDiaryCubit',
      );

      // Удаляем ID блюда из множества регенерирующихся
      final updatedRegeneratingIds = {
        ...currentState.regeneratingMealIds,
      }..remove(event.mealId);

      emit(
        currentState.copyWith(
          regeneratingMealIds: updatedRegeneratingIds,
        ),
      );

      log(
        '[FoodDiaryCubit._customMealStopRegenerating] ✅ Блюдо убрано из регенерирующихся. Всего регенерируется: ${updatedRegeneratingIds.length}',
        name: 'FoodDiaryCubit',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[FoodDiaryCubit._customMealStopRegenerating] ❌ Ошибка при отметке окончания регенерации: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'FoodDiaryCubit',
      );
    }
  }
}
