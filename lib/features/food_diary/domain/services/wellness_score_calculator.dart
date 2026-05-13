import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/day_manager/day_manager.dart';
import 'package:rishai/core/services/user_service/user_service_client.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/pivot_life_scrore_entity.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

/// [WellnessScoreCalculator] Сервис для расчета wellness score
///
/// Изолирует всю бизнес-логику расчета wellness score от UI-логики cubit.
/// Отвечает за:
/// - Расчет Daily Wellness Score на основе потребленных блюд
/// - Расчет Pivot Life Score (среднего wellness score)
/// - Логику штрафов за переедание
@injectable
class WellnessScoreCalculator {
  WellnessScoreCalculator(
    this._dayManager,
    this._whoopBloc,
    this._userServiceClient,
  );

  final DayManager _dayManager;
  final WhoopBloc _whoopBloc;
  final UserBloc _userBloc = userBloc;
  final UserServiceClient _userServiceClient;

  /// [calculateDailyWellnessScore] Рассчитывает Daily Wellness Score на основе потребленных блюд
  ///
  /// Принимает массив блюд, получает актуальный день, создает/обновляет wellness entity.
  /// Если у пользователя уже есть WelnessEntity за сегодня, то добавляет новые блюда к существующим
  /// и пересчитывает Daily Wellness Score для всех потребленных блюд.
  /// Формула: Daily Wellness Score = 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
  /// (на основе потребленных макросов относительно целевых)
  ///
  /// [consumedMeals] - обычные блюда из планов (List<Meal>)
  /// [customMeals] - кастомные проанализированные блюда (List<DiaryMeal>), опционально
  ///
  /// Возвращает обновленный DayEntity с рассчитанным wellness score
  Future<DayEntity> calculateDailyWellnessScore(
    List<Meal> consumedMeals, {
    List<DiaryMeal> customMeals = const [],
  }) async {
    try {
      log(
        '[WellnessScoreCalculator] Расчет Daily Wellness Score для ${consumedMeals.length} обычных блюд${customMeals.isNotEmpty ? ' и ${customMeals.length} кастомных блюд' : ''}',
        name: 'WellnessScoreCalculator',
      );

      // Получаем актуальный сегодняшний день
      final currentDay = _whoopBloc.state.day;
      log(
        '[WellnessScoreCalculator] Текущий день: ${currentDay.dateTime}',
        name: 'WellnessScoreCalculator',
      );

      // Получаем существующую WelnessEntity или создаем пустую
      final existingWelness = currentDay.welnessEntity;
      List<DiaryMeal> allConsumedMeals = [];

      if (existingWelness != null) {
        log(
          '[WellnessScoreCalculator] Найдена существующая WelnessEntity с ${existingWelness.consumedMeals.length} блюдами',
          name: 'WellnessScoreCalculator',
        );
        // Добавляем уже существующие блюда
        allConsumedMeals.addAll(existingWelness.consumedMeals);
      } else {
        log(
          '[WellnessScoreCalculator] WelnessEntity не найдена, создаем новую',
          name: 'WellnessScoreCalculator',
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
          '[WellnessScoreCalculator] Добавление ${customMeals.length} кастомных блюд',
          name: 'WellnessScoreCalculator',
        );
        allConsumedMeals.addAll(customMeals);
      }

      log(
        '[WellnessScoreCalculator] Общее количество потребленных блюд: ${allConsumedMeals.length} (${existingWelness?.consumedMeals.length ?? 0} существующих + ${newDiaryMeals.length} обычных + ${customMeals.length} кастомных)',
        name: 'WellnessScoreCalculator',
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
        '[WellnessScoreCalculator] Суммарные потребленные макросы: K=${totalKcal.toStringAsFixed(1)}ккал, P=${totalProtein.toStringAsFixed(1)}г, C=${totalCarbs.toStringAsFixed(1)}г, F=${totalFat.toStringAsFixed(1)}г',
        name: 'WellnessScoreCalculator',
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
        '[WellnessScoreCalculator] Целевые макросы: K=${targetMacros.kcal}ккал, P=${targetMacros.protein}г, C=${targetMacros.carbs}г, F=${targetMacros.fat}г',
        name: 'WellnessScoreCalculator',
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
        '[WellnessScoreCalculator] Процентные соотношения: K=${kcalPercentage.toStringAsFixed(1)}%, P=${proteinPercentage.toStringAsFixed(1)}%, C=${carbsPercentage.toStringAsFixed(1)}%, F=${fatPercentage.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
      );

      // Применяем формулу Daily Wellness Score (DWS_raw)
      // 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
      double dwsRaw = (kcalPercentage * 0.40) +
          (proteinPercentage * 0.30) +
          (carbsPercentage * 0.20) +
          (fatPercentage * 0.10);

      log(
        '[WellnessScoreCalculator] DWS_raw (до применения штрафов): ${dwsRaw.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
      );

      // Применяем систему штрафов за переедание, если DWS_raw > 100%
      double wellnessScore = _applyPenaltyForOvereating(dwsRaw);

      log(
        '[WellnessScoreCalculator] ✅ DWS_final (Daily Wellness Score): ${wellnessScore.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
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
      _whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));

      log(
        '[WellnessScoreCalculator] ✅ Daily Wellness Score успешно ${existingWelness != null ? 'обновлен' : 'рассчитан'} и ${existingWelness != null ? 'обновлен' : 'добавлен'} в день',
        name: 'WellnessScoreCalculator',
      );

      return updatedDay;
    } catch (e, stackTrace) {
      log(
        '[WellnessScoreCalculator] Ошибка при расчете Daily Wellness Score: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'WellnessScoreCalculator',
      );
      rethrow;
    }
  }

  /// [_applyPenaltyForOvereating] Применяет штрафы за переедание
  ///
  /// Если DWS_raw > 100%, применяется система штрафов в зависимости от степени переедания.
  /// Гарантирует минимальное значение wellness score = 10%.
  double _applyPenaltyForOvereating(double dwsRaw) {
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
        '[WellnessScoreCalculator] ⚠️ Переедание обнаружено! DWS_raw=${dwsRaw.toStringAsFixed(1)}%, penalty=${penalty.toStringAsFixed(1)}, multiplier=${penaltyMultiplier}x',
        name: 'WellnessScoreCalculator',
      );
    }

    return wellnessScore;
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
        currentUser = _userBloc.state.user;

        // [DEBUG] Детальное логирование для диагностики
        log(
          '[WellnessScoreCalculator] 🔍 Попытка ${attempt + 1}/$maxAttempts: directusId=${currentUser.directusId}, email=${currentUser.email}, UserBloc instance=${_userBloc.hashCode}',
          name: 'WellnessScoreCalculator',
        );

        if (currentUser.directusId != '-1') {
          // Пользователь авторизован - выходим из цикла
          log(
            '[WellnessScoreCalculator] ✅ Пользователь авторизован на попытке ${attempt + 1}',
            name: 'WellnessScoreCalculator',
          );
          break;
        }

        // Если это не последняя попытка, ждем перед следующей проверкой
        if (attempt < maxAttempts - 1) {
          // Экспоненциальная задержка: 100ms, 200ms, 400ms, 800ms
          final delay = Duration(
            milliseconds: initialDelay.inMilliseconds * (1 << attempt),
          );
          log(
            '[WellnessScoreCalculator] ⏳ Попытка ${attempt + 1}/$maxAttempts: пользователь не авторизован (directusId=${currentUser.directusId}), ждем ${delay.inMilliseconds}ms перед повторной проверкой',
            name: 'WellnessScoreCalculator',
          );
          await Future.delayed(delay);
        }
      }

      // Финальная проверка после всех попыток
      if (currentUser == null || currentUser.directusId == '-1') {
        log(
          '[WellnessScoreCalculator] ❌ Пользователь не авторизован после $maxAttempts попыток, пропускаем расчет Pivot Life Score',
          name: 'WellnessScoreCalculator',
        );
        return;
      }

      // Получаем inceptionDate из app_config в Directus
      DateTime? inceptionDateFromConfig;
      try {
        final appConfig = await _userServiceClient.getAppConfigPublic();
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
            '[WellnessScoreCalculator] 📅 Получена дата начала отсчета из app_config: ${inceptionDateFromConfig.toIso8601String().split('T')[0]}',
            name: 'WellnessScoreCalculator',
          );
        } else {
          // Если inceptionDate не задана в app_config, используем дату первого дня с wellness score
          log(
            '[WellnessScoreCalculator] ⚠️ inceptionDate не найдена в app_config, будет использована дата первого дня с wellness score',
            name: 'WellnessScoreCalculator',
          );
        }
      } catch (e, stackTrace) {
        log(
          '[WellnessScoreCalculator] ❌ Ошибка при получении inceptionDate из app_config: $e',
          error: e,
          stackTrace: stackTrace,
          name: 'WellnessScoreCalculator',
        );
        // В случае ошибки используем дату первого дня с wellness score
      }

      // Получаем все дни пользователя через DayManager
      final userDaysResult =
          await _dayManager.getUserDays(userId: currentUser.directusId);

      final List<DayEntity> userDays = userDaysResult.fold(
        (failure) {
          log(
            '[WellnessScoreCalculator] ❌ Ошибка при получении дней пользователя: ${failure.message}',
            name: 'WellnessScoreCalculator',
          );
          return <DayEntity>[];
        },
        (days) => days,
      );

      if (userDays.isEmpty) {
        log(
          '[WellnessScoreCalculator] ⚠️ У пользователя нет дней для расчета Pivot Life Score',
          name: 'WellnessScoreCalculator',
        );
        return;
      }

      // Фильтруем дни, у которых есть wellness score
      final daysWithWellnessScore = userDays
          .where((day) => day.welnessEntity?.welnessPercentage != null)
          .toList();

      if (daysWithWellnessScore.isEmpty) {
        log(
          '[WellnessScoreCalculator] ⚠️ У пользователя нет дней с Daily Wellness Score для расчета среднего',
          name: 'WellnessScoreCalculator',
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
          '[WellnessScoreCalculator] 🆕 Устанавливаем дату начала отсчета как дату первого дня с wellness score: ${inceptionDate.toIso8601String().split('T')[0]}',
          name: 'WellnessScoreCalculator',
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
          '[WellnessScoreCalculator] ⚠️ Нет дней с Daily Wellness Score после даты начала отсчета (${inceptionDate.toIso8601String().split('T')[0]})',
          name: 'WellnessScoreCalculator',
        );
        return;
      }

      log(
        '[WellnessScoreCalculator] 📈 Найдено ${filteredDays.length} дней с Daily Wellness Score после даты начала отсчета (${inceptionDate.toIso8601String().split('T')[0]}) из ${daysWithWellnessScore.length} общих дней с wellness score',
        name: 'WellnessScoreCalculator',
      );

      // Вычисляем среднее арифметическое
      double totalWellnessScore = 0;
      for (final day in filteredDays) {
        final wellnessScore = day.welnessEntity!.welnessPercentage;
        totalWellnessScore += wellnessScore;
        log(
          '[WellnessScoreCalculator] 📅 День ${day.dateTime.toIso8601String().split('T')[0]}: Wellness Score = ${wellnessScore.toStringAsFixed(1)}%',
          name: 'WellnessScoreCalculator',
        );
      }

      final averageWellnessScore = totalWellnessScore / filteredDays.length;

      log(
        '[WellnessScoreCalculator] 🎯 Рассчитанный средний Daily Wellness Score (Pivot Life Score): ${averageWellnessScore.toStringAsFixed(2)}% (на основе ${filteredDays.length} дней с ${inceptionDate.toIso8601String().split('T')[0]})',
        name: 'WellnessScoreCalculator',
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
        '[WellnessScoreCalculator] 🔄 Отправляем обновленный Pivot Life Score в UserBloc...',
        name: 'WellnessScoreCalculator',
      );
      _userBloc.add(UpdateUserEvent(user: updatedUser));

      // [FIX] Даем время UserBloc обновить состояние
      await Future.delayed(const Duration(milliseconds: 100));

      log(
        '[WellnessScoreCalculator] ✅ Pivot Life Score успешно рассчитан и обновлен: ${averageWellnessScore.toStringAsFixed(2)}%',
        name: 'WellnessScoreCalculator',
      );
    } on Exception catch (e, stackTrace) {
      log(
        '[WellnessScoreCalculator] ❌ Ошибка при расчете Pivot Life Score: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'WellnessScoreCalculator',
      );
      // Не пробрасываем ошибку, чтобы не нарушить основной процесс добавления блюда
    }
  }

  /// [recalculateWellnessScoreForExistingMeals] Пересчитывает Daily Wellness Score для существующих блюд
  ///
  /// Используется когда изменяются целевые макросы (например, при изменении модификатора).
  /// Пересчитывает wellness score на основе существующих потребленных блюд и новых целевых макросов.
  ///
  /// [currentDay] - текущий день с обновленными целевыми макросами
  /// Возвращает обновленный DayEntity с пересчитанным wellness score
  Future<DayEntity> recalculateWellnessScoreForExistingMeals(
    DayEntity currentDay,
  ) async {
    try {
      log(
        '[WellnessScoreCalculator] 🔄 Пересчет Daily Wellness Score для существующих блюд при изменении целевых макросов',
        name: 'WellnessScoreCalculator',
      );
      log(
        '[WellnessScoreCalculator] Текущий день: ${currentDay.dateTime}',
        name: 'WellnessScoreCalculator',
      );

      // Получаем существующую WelnessEntity
      final existingWelness = currentDay.welnessEntity;

      // Если нет существующих блюд, нечего пересчитывать
      if (existingWelness == null || existingWelness.consumedMeals.isEmpty) {
        log(
          '[WellnessScoreCalculator] ⚠️ Нет существующих блюд для пересчета wellness score',
          name: 'WellnessScoreCalculator',
        );
        return currentDay;
      }

      log(
        '[WellnessScoreCalculator] Найдено ${existingWelness.consumedMeals.length} существующих блюд для пересчета',
        name: 'WellnessScoreCalculator',
      );

      // Используем существующие блюда
      final allConsumedMeals = existingWelness.consumedMeals;

      // Суммируем макросы из всех существующих блюд
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
        '[WellnessScoreCalculator] Суммарные потребленные макросы: K=${totalKcal.toStringAsFixed(1)}ккал, P=${totalProtein.toStringAsFixed(1)}г, C=${totalCarbs.toStringAsFixed(1)}г, F=${totalFat.toStringAsFixed(1)}г',
        name: 'WellnessScoreCalculator',
      );

      // Создаем MacrosBreakdown для потребленных макросов
      final consumedMacros = MacrosBreakdown(
        kcal: totalKcal.round(),
        protein: totalProtein.round(),
        carbs: totalCarbs.round(),
        fat: totalFat.round(),
      );

      // Получаем новые целевые макросы из текущего дня
      final targetMacros = currentDay.macros;
      log(
        '[WellnessScoreCalculator] Новые целевые макросы: K=${targetMacros.kcal}ккал, P=${targetMacros.protein}г, C=${targetMacros.carbs}г, F=${targetMacros.fat}г',
        name: 'WellnessScoreCalculator',
      );

      // Рассчитываем процентные соотношения потребленных макросов к новым целевым
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
        '[WellnessScoreCalculator] Процентные соотношения: K=${kcalPercentage.toStringAsFixed(1)}%, P=${proteinPercentage.toStringAsFixed(1)}%, C=${carbsPercentage.toStringAsFixed(1)}%, F=${fatPercentage.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
      );

      // Применяем формулу Daily Wellness Score (DWS_raw)
      // 40% of kcals% + 30% of Protein% + 20% of carbs% + 10% of fats%
      double dwsRaw = (kcalPercentage * 0.40) +
          (proteinPercentage * 0.30) +
          (carbsPercentage * 0.20) +
          (fatPercentage * 0.10);

      log(
        '[WellnessScoreCalculator] DWS_raw (до применения штрафов): ${dwsRaw.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
      );

      // Применяем систему штрафов за переедание, если DWS_raw > 100%
      double wellnessScore = _applyPenaltyForOvereating(dwsRaw);

      log(
        '[WellnessScoreCalculator] ✅ DWS_final (Daily Wellness Score после пересчета): ${wellnessScore.toStringAsFixed(1)}%',
        name: 'WellnessScoreCalculator',
      );

      // Обновляем WelnessEntity с новым wellness score
      final welnessEntity = existingWelness.copyWith(
        consumedMeals: allConsumedMeals,
        welnessPercentage: wellnessScore,
        consumedMacros: consumedMacros,
      );

      // Обновляем день с обновленной wellness entity
      final updatedDay = currentDay.copyWith(welnessEntity: welnessEntity);

      // Сохраняем день в Directus
      log(
        '[WellnessScoreCalculator] 💾 PATCH /days/current после пересчёта wellness',
        name: 'WellnessScoreCalculator',
      );
      await _dayManager.createOrUpdateDay(day: updatedDay);

      // После успешного пересчета Daily Wellness Score пересчитываем Pivot Life Score
      log(
        '[WellnessScoreCalculator] 🔄 Запускаем пересчет Pivot Life Score после пересчета Daily Wellness Score',
        name: 'WellnessScoreCalculator',
      );
      await calculatePivotLifeScore();

      log(
        '[WellnessScoreCalculator] ✅ Daily Wellness Score успешно пересчитан для существующих блюд',
        name: 'WellnessScoreCalculator',
      );

      return updatedDay;
    } catch (e, stackTrace) {
      log(
        '[WellnessScoreCalculator] ❌ Ошибка при пересчете Daily Wellness Score для существующих блюд: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'WellnessScoreCalculator',
      );
      rethrow;
    }
  }
}
