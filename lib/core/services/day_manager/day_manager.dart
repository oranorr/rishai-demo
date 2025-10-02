import 'package:dartz/dartz.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

/// Результат проверки последнего дня пользователя
class LastDayResult {
  const LastDayResult({
    required this.day,
    required this.isCycleActive,
    this.cycleId,
  });

  /// Создает результат для активного дня
  factory LastDayResult.active(DayEntity day) {
    return LastDayResult(
      day: day,
      isCycleActive: true,
      cycleId: day.cycleId,
    );
  }

  /// Создает результат для завершенного цикла
  factory LastDayResult.ended(DayEntity day) {
    return LastDayResult(
      day: day,
      isCycleActive: false,
      cycleId: day.cycleId,
    );
  }

  final DayEntity day;
  final bool isCycleActive; // true = цикл активен, false = завершен
  final int? cycleId;
}

abstract class DayManager {
  // Старые методы fetchDays, getDaysIds удалены

  /// Получить все дни пользователя (новая упрощенная архитектура)
  Future<Either<Failure, List<DayEntity>>> getUserDays({
    required String userId,
  });

  Future<DayEntity?> getLastUserDay({
    required String userId,
  });

  Future<DayEntity> createOrUpdateDay({
    required DayEntity day,
  });

  /// Поиск дня по ID биологического цикла WHOOP
  Future<DayEntity?> getDayByCycleId({
    required String userId,
    required int cycleId,
  });

  /// Получение активного дня (текущий незавершенный цикл)
  Future<DayEntity?> getActiveDay({
    required String userId,
  });

  /// УНИФИЦИРОВАННЫЙ МЕТОД: Получение последнего дня с проверкой статуса цикла
  /// Заменяет логику из getLastCycleId, fetchLastChatSnap и getActiveDay
  Future<LastDayResult?> getLastDayWithCycleStatus({
    required String userId,
    bool checkCycleStatus = true,
  });

  /// Инициализация загрузки дней пользователя при входе в приложение
  /// с отслеживанием прогресса и адаптивными таймаутами
  Future<InitializationResult> initializeUserDaysOnLogin({
    required String userId,
    required DayEntity newDay,
  });

  /// Очистка локального хранилища дней (используется при логауте)
  Future<void> clearUserDays();
}

/// Результат инициализации дней
class InitializationResult {
  const InitializationResult({
    required this.success,
    this.partialSuccess = false,
    this.daysLoaded = 0,
    this.errorMessage,
  });

  factory InitializationResult.success(int daysLoaded) =>
      InitializationResult(success: true, daysLoaded: daysLoaded);

  factory InitializationResult.partialSuccess(int daysLoaded) =>
      InitializationResult(
        success: true,
        partialSuccess: true,
        daysLoaded: daysLoaded,
      );

  factory InitializationResult.failure(String message) => InitializationResult(
        success: false,
        errorMessage: message,
      );
  final bool success;
  final bool partialSuccess;
  final int daysLoaded;
  final String? errorMessage;
}
