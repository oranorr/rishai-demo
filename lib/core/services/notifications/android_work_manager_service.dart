import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android-специфичный сервис для планирования уведомлений через WorkManager
/// Решает проблемы с Doze Mode и оптимизацией батареи в Android 12+
class AndroidWorkManagerService {
  static const String _notificationTaskName = 'scheduleDailyNotification';
  static const String _notificationChannelId = 'daily_reminders';

  /// Инициализация WorkManager для Android
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      log('[AndroidWorkManager] WorkManager initialized successfully');
    } catch (e) {
      log('[AndroidWorkManager] Error initializing WorkManager: $e');
      rethrow;
    }
  }

  /// Планирование ежедневного уведомления в указанное время
  static Future<void> scheduleDailyNotification(int hour, int minute) async {
    try {
      // Отменяем существующие задачи
      await Workmanager().cancelAll();

      // Вычисляем время для следующего уведомления
      final now = DateTime.now();
      final nextNotification = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Если время уже прошло сегодня, планируем на завтра
      final targetTime = nextNotification.isBefore(now)
          ? nextNotification.add(const Duration(days: 1))
          : nextNotification;

      final delay = targetTime.difference(now).inSeconds;

      log('[AndroidWorkManager] Планируем уведомление на ${targetTime.hour}:${targetTime.minute.toString().padLeft(2, '0')}');
      log('[AndroidWorkManager] Задержка: $delay секунд');

      // Планируем первое уведомление с точной задержкой
      await Workmanager().registerOneOffTask(
        _notificationTaskName,
        _notificationTaskName,
        initialDelay: Duration(seconds: delay),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false, // Ключевое - работает даже в Doze Mode
          requiresStorageNotLow: false,
        ),
        inputData: {
          'hour': hour,
          'minute': minute,
          'title': 'Pivot daily reminder',
          'body': "It's time to create your new meal plan for today",
        },
      );

      log('[AndroidWorkManager] Первое уведомление запланировано через WorkManager');
    } catch (e) {
      log('[AndroidWorkManager] Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Отмена всех запланированных уведомлений
  static Future<void> cancelAllNotifications() async {
    try {
      await Workmanager().cancelAll();
      log('[AndroidWorkManager] All WorkManager notifications cancelled');
    } catch (e) {
      log('[AndroidWorkManager] Error cancelling notifications: $e');
    }
  }
}

/// Callback функция для WorkManager - выполняется в указанное время
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('[AndroidWorkManager] Executing task: $task');

      // Получаем время из данных задачи
      final hour = inputData?['hour'] ?? 9;
      final minute = inputData?['minute'] ?? 0;

      log('[AndroidWorkManager] Показываем уведомление для времени $hour:${minute.toString().padLeft(2, '0')}');

      // Показываем уведомление
      await _showNotification(inputData);

      // Планируем следующее уведомление на завтра
      await _scheduleNextDayNotification(hour, minute);

      log('[AndroidWorkManager] Notification shown and next day scheduled');
      return true;
    } catch (e) {
      log('[AndroidWorkManager] Error executing task: $e');
      return false;
    }
  });
}

/// Показ уведомления через flutter_local_notifications
Future<void> _showNotification(Map<String, dynamic>? inputData) async {
  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Создаем канал для Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_reminders',
      'Daily Reminders',
      description: 'Channel for daily meal plan reminders',
      importance: Importance.high,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Показываем уведомление
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      inputData?['title'] ?? 'Daily Reminder',
      inputData?['body'] ?? 'Time to create your meal plan',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Channel for daily meal plan reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
    );

    log('[AndroidWorkManager] Notification shown successfully');
  } catch (e) {
    log('[AndroidWorkManager] Error showing notification: $e');
  }
}

/// Планирование уведомления на следующий день
Future<void> _scheduleNextDayNotification(int hour, int minute) async {
  try {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextNotification = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour,
      minute,
    );

    final delay = nextNotification.difference(now).inSeconds;

    await Workmanager().registerOneOffTask(
      'scheduleDailyNotification',
      'scheduleDailyNotification',
      initialDelay: Duration(seconds: delay),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'hour': hour,
        'minute': minute,
        'title': 'Pivot daily reminder',
        'body': "It's time to create your new meal plan for today",
      },
    );

    log('[AndroidWorkManager] Next notification scheduled for tomorrow at $hour:${minute.toString().padLeft(2, '0')}');
  } catch (e) {
    log('[AndroidWorkManager] Error scheduling next day notification: $e');
  }
}
