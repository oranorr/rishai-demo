import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:rishai/core/services/notifications/notifications_service.dart';
import 'package:rishai/core/services/notifications/work_manager_import.dart';

/// Верхнеуровневый сервис для планирования уведомлений
/// Разделяет логику между Android (WorkManager) и iOS (flutter_local_notifications)
class PlatformNotificationsService {
  PlatformNotificationsService(this._flutterLocalNotificationsPlugin);
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  /// Планирование ежедневного уведомления в указанное время
  /// Автоматически выбирает лучший способ для каждой платформы
  Future<void> scheduleDailyNotification(TimeOfDay time) async {
    try {
      log('[PlatformNotificationsService] Планируем уведомление на ${time.hour}:${time.minute.toString().padLeft(2, '0')}');

      if (Platform.isAndroid) {
        // Android: используем WorkManager для надежности
        await _scheduleNotificationAndroid(time);
      } else if (Platform.isIOS) {
        // iOS: используем текущее решение (работает отлично)
        await _scheduleNotificationIOS(time);
      } else {
        log('[PlatformNotificationsService] Неподдерживаемая платформа, используем fallback');
        await _scheduleNotificationFallback(time);
      }

      log('[PlatformNotificationsService] Уведомление успешно запланировано');
    } catch (e) {
      log('[PlatformNotificationsService] Ошибка при планировании уведомления: $e');
      rethrow;
    }
  }

  /// Планирование уведомлений для Android через WorkManager
  Future<void> _scheduleNotificationAndroid(TimeOfDay time) async {
    try {
      log('[PlatformNotificationsService] Android: используем WorkManager');

      // Используем условный импорт для WorkManager
      await AndroidWorkManagerService.scheduleDailyNotification(
        time.hour,
        time.minute,
      );
      log('[PlatformNotificationsService] Android: уведомление запланировано через WorkManager');
    } catch (e) {
      log('[PlatformNotificationsService] Ошибка Android WorkManager, используем fallback: $e');
      // Fallback на обычное планирование
      await _scheduleNotificationFallback(time);
    }
  }

  /// Планирование уведомлений для iOS (текущее решение)
  Future<void> _scheduleNotificationIOS(TimeOfDay time) async {
    try {
      log('[PlatformNotificationsService] iOS: используем текущее решение (zonedSchedule)');

      // Создаем iOS-специфичные настройки
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // iOS-специфичные настройки для надежности
        interruptionLevel: InterruptionLevel.timeSensitive, // iOS 15+
      );

      NotificationDetails platformChannelSpecifics = const NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
      );

      // Используем текущую логику планирования для iOS
      final now = tz.TZDateTime.now(tz.local);

      // Дополнительная диагностика для iOS
      log('[PlatformNotificationsService] iOS: Диагностика таймзоны');
      log('[PlatformNotificationsService] iOS: tz.local.name = ${tz.local.name}');
      log('[PlatformNotificationsService] iOS: Текущее время (tz): $now');
      log('[PlatformNotificationsService] iOS: Текущее время (DateTime): ${DateTime.now()}');
      log('[PlatformNotificationsService] iOS: Системное смещение: ${DateTime.now().timeZoneOffset.inHours} часов');

      // Проверяем, не является ли tz.local UTC
      tz.Location targetTimeZone = tz.local;
      if (tz.local.name == 'UTC') {
        log('[PlatformNotificationsService] iOS: ⚠️ tz.local возвращает UTC!');
        log('[PlatformNotificationsService] iOS: 🔧 Используем системную таймзону');
        // Используем системное время для создания уведомления
        final systemNow = DateTime.now();
        final systemScheduleTime = DateTime(
          systemNow.year,
          systemNow.month,
          systemNow.day,
          time.hour,
          time.minute,
        );

        final notificationTime = systemScheduleTime.isBefore(systemNow)
            ? systemScheduleTime.add(const Duration(days: 1))
            : systemScheduleTime;

        log('[PlatformNotificationsService] iOS: Время уведомления (системное): $notificationTime');

        final int rndId =
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

        // Планируем через zonedSchedule с системным временем для iOS
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          rndId,
          'Pivot daily reminder',
          "It's time to create your new meal plan for today",
          tz.TZDateTime.from(notificationTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        log('[PlatformNotificationsService] iOS: Уведомление запланировано через schedule на $notificationTime');
        return;
      }

      final scheduleTime = tz.TZDateTime(
        targetTimeZone,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final notificationTime = scheduleTime.isBefore(now)
          ? scheduleTime.add(const Duration(days: 1))
          : scheduleTime;

      final int rndId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        rndId,
        'Pivot daily reminder',
        "It's time to create your new meal plan for today",
        notificationTime,
        platformChannelSpecifics,
        // iOS-специфичные настройки
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log('[PlatformNotificationsService] iOS: уведомление запланировано на $notificationTime');
    } catch (e) {
      log('[PlatformNotificationsService] Ошибка iOS планирования: $e');
      rethrow;
    }
  }

  /// Fallback планирование для неподдерживаемых платформ или ошибок
  Future<void> _scheduleNotificationFallback(TimeOfDay time) async {
    try {
      log('[PlatformNotificationsService] Fallback: используем базовое планирование');

      // Базовые настройки для всех платформ
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'daily_reminders',
        'Daily Reminders',
        channelDescription: 'Channel for daily meal plan reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformChannelSpecifics = const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Планируем через zonedSchedule с базовыми настройками
      final now = tz.TZDateTime.now(tz.local);
      final scheduleTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final notificationTime = scheduleTime.isBefore(now)
          ? scheduleTime.add(const Duration(days: 1))
          : scheduleTime;

      final int rndId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        rndId,
        'Pivot daily reminder',
        "It's time to create your new meal plan for today",
        notificationTime,
        platformChannelSpecifics,
        // Платформо-специфичные настройки
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log('[PlatformNotificationsService] Fallback: уведомление запланировано на $notificationTime');
    } catch (e) {
      log('[PlatformNotificationsService] Ошибка fallback планирования: $e');
      rethrow;
    }
  }

  /// Тестирует уведомления на iOS
  Future<void> testNotificationIOS() async {
    try {
      log('[PlatformNotificationsService] iOS: Тестируем уведомления');

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      NotificationDetails platformChannelSpecifics = const NotificationDetails(
        iOS: iOSPlatformChannelSpecifics,
      );

      // Показываем тестовое уведомление немедленно
      final int testId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        testId,
        '🧪 Тестовое уведомление iOS',
        'Если вы видите это, уведомления работают!',
        platformChannelSpecifics,
      );

      log('[PlatformNotificationsService] iOS: Тестовое уведомление показано немедленно');

      // Планируем тестовое уведомление через 10 секунд
      final now = DateTime.now();
      final testTime = now.add(const Duration(seconds: 10));

      log('[PlatformNotificationsService] iOS: Планируем тестовое уведомление через 10 секунд на $testTime');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        testId + 1,
        '🧪 Тестовое уведомление iOS (через 10с)',
        'Это тестовое уведомление через 10 секунд!',
        tz.TZDateTime.from(testTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      log('[PlatformNotificationsService] iOS: Тестовое уведомление запланировано на $testTime');
    } catch (e) {
      log('[PlatformNotificationsService] iOS: Ошибка тестирования: $e');
    }
  }

  /// Отмена всех запланированных уведомлений
  Future<void> cancelAllNotifications() async {
    try {
      log('[PlatformNotificationsService] Отменяем все уведомления');

      if (Platform.isAndroid) {
        // Android: отменяем через WorkManager
        await AndroidWorkManagerService.cancelAllNotifications();
      }

      // Всегда отменяем через flutter_local_notifications
      await _flutterLocalNotificationsPlugin.cancelAll();

      log('[PlatformNotificationsService] Все уведомления отменены');
    } catch (e) {
      log('[PlatformNotificationsService] Ошибка при отмене уведомлений: $e');
    }
  }
}
