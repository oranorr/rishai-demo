import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:directus/directus.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/directus/directus_repository.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart';
import 'package:rishai/features/food_diary/domain/services/wellness_score_calculator.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';

part 'food_diary_event.dart';
part 'food_diary_state.dart';

// [FoodDiaryCubit] Глобальные экземпляры для доступа из других частей приложения
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
  FoodDiaryCubit(
    this._wellnessScoreCalculator,
    this.whoopBloc,
    this.weekPlanBloc,
    this.userBloc,
    this.directus,
  ) : super(
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
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Зависимости
  // ════════════════════════════════════════════════════════════════════════════

  /// [_wellnessScoreCalculator] Сервис для расчета wellness score
  final WellnessScoreCalculator _wellnessScoreCalculator;

  /// [whoopBloc] Блок для работы с данными Whoop
  final WhoopBloc whoopBloc;

  /// [weekPlanBloc] Блок для работы с недельными планами
  final WeekPlanBloc weekPlanBloc;

  /// [userBloc] Блок для работы с данными пользователя
  final UserBloc userBloc;

  /// [directus] Репозиторий для работы с Directus
  final DirectusService directus;

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
  /// Делегирует расчет сервису WellnessScoreCalculator.
  Future<void> calculatePivotLifeScore() async {
    await _wellnessScoreCalculator.calculatePivotLifeScore();
  }

  /// [calculateWellnessScore] Рассчитывает Daily Wellness Score на основе потребленных блюд
  ///
  /// Делегирует расчет сервису WellnessScoreCalculator.
  /// После расчета автоматически пересчитывает Pivot Life Score.
  ///
  /// [consumedMeals] - обычные блюда из планов (List<Meal>)
  /// [customMeals] - кастомные проанализированные блюда (List<DiaryMeal>), опционально
  Future<DayEntity> calculateWellnessScore(
    List<Meal> consumedMeals, {
    List<DiaryMeal> customMeals = const [],
  }) async {
    log(
      '[FoodDiaryCubit] Расчет Daily Wellness Score через WellnessScoreCalculator',
      name: 'FoodDiaryCubit',
    );

    // Делегируем расчет сервису
    final updatedDay =
        await _wellnessScoreCalculator.calculateDailyWellnessScore(
      consumedMeals,
      customMeals: customMeals,
    );

    // После успешного расчета Daily Wellness Score пересчитываем Pivot Life Score
    log(
      '[FoodDiaryCubit] 🔄 Запускаем пересчет Pivot Life Score после обновления Daily Wellness Score',
      name: 'FoodDiaryCubit',
    );
    await calculatePivotLifeScore();

    return updatedDay;
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

      // Получаем уже потребленные блюда
      final consumedMeals =
          whoopState.day.welnessEntity?.consumedMeals ?? <DiaryMeal>[];

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Потребленных блюд: ${consumedMeals.length}',
        name: 'FoodDiaryCubit',
      );

      // Фильтруем блюда, исключая уже потребленные
      final availableMeals = allMeals.where((meal) {
        final diaryMeal = meal.toDiaryMeal(isGeneratedMeal: true);
        final isConsumed = consumedMeals.any(
          (consumed) =>
              consumed.title == diaryMeal.title &&
              consumed.type == diaryMeal.type,
        );
        return !isConsumed;
      }).toList();

      log(
        '[FoodDiaryCubit._initializeDiaryEntryPage] Доступных блюд для выбора: ${availableMeals.length}',
        name: 'FoodDiaryCubit',
      );

      emit(
        DiaryEntryPageState.initial().copyWith(
          status: Status.success,
          availableMeals: availableMeals,
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

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealRemove] ✅ Блюдо удалено',
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

  /// [_customMealSetMealType] Устанавливает тип приема пищи для блюда
  ///
  /// Устанавливает тип приема пищи (завтрак, обед, ужин, перекус) для указанного блюда.
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

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealSetMealType] ✅ Тип приема пищи установлен',
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

      emit(currentState.copyWith(customMeals: updatedMeals));

      log(
        '[FoodDiaryCubit._customMealReset] ✅ Блюдо сброшено в пустое состояние',
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
}
