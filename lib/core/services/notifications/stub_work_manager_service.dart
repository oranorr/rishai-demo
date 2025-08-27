import 'dart:developer';

/// Заглушка для iOS - имитирует интерфейс Android WorkManager сервиса
/// На iOS этот сервис не используется, так как flutter_local_notifications работает отлично
class AndroidWorkManagerService {
  /// Инициализация WorkManager для iOS (заглушка)
  static Future<void> initialize() async {
    log('[iOS] WorkManager не используется на iOS - flutter_local_notifications работает отлично');
    // Ничего не делаем на iOS
  }

  /// Планирование ежедневного уведомления в указанное время (заглушка)
  static Future<void> scheduleDailyNotification(int hour, int minute) async {
    log('[iOS] WorkManager не используется на iOS - уведомления планируются через flutter_local_notifications');
    log('[iOS] Запрошенное время: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    // Ничего не делаем на iOS
  }

  /// Отмена всех запланированных уведомлений (заглушка)
  static Future<void> cancelAllNotifications() async {
    log('[iOS] WorkManager не используется на iOS - отмена через flutter_local_notifications');
    // Ничего не делаем на iOS
  }
}
