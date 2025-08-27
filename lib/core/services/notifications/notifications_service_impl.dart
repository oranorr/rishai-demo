import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/services/notifications/notifications_service.dart';
import 'package:rishai/core/services/notifications/platform_notifications_service.dart';
import 'package:rishai/core/services/notifications/work_manager_import.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ВАЖНО: Настройки уведомлений изменены для соответствия политике Google Store
// USE_FULL_SCREEN_INTENT разрешен только для приложений звонков и будильников
// Для обеспечения своевременности уведомлений используем:
// 1. Importance.high (вместо max) - обеспечивает видимость без full-screen intent
// 2. Priority.high - высокий приоритет для Android версий < 8.0
// 3. AndroidScheduleMode.exactAllowWhileIdle - точное время даже в Doze режиме
// 4. Разрешение USE_EXACT_ALARM - для точных уведомлений

final notes = getIt.get<NotificationsService>();

@Singleton(as: NotificationsService)
class NotificationsServiceImpl implements NotificationsService {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late PlatformNotificationsService _platformService;

  // Канал с важностью High вместо Max для соответствия политике Google Store
  // High importance всё ещё обеспечивает хорошую видимость уведомлений без USE_FULL_SCREEN_INTENT
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    '9', // Измени ID канала, чтобы пересоздать его
    'Scheduled Notifications',
    description: 'Channel for scheduled notifications',
    importance: Importance
        .high, // Изменено с max на high для соответствия политике Google Store
    enableLights: true,
  );
  @override
  Future<void> initNotificationsService() async {
    try {
      // Запрос разрешений
      await _initializeTimeZone(); // Инициализация таймзон
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Создание канала для Android
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel)
          .then((_) {
        log('channel created: ${channel.id}');
      });

      // Инициализация уведомлений
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS-специфичные настройки
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      // Запрашиваем разрешения для iOS
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      InitializationSettings initializationSettings =
          const InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      // Инициализируем платформенный сервис для разделения логики по платформам
      _platformService =
          PlatformNotificationsService(flutterLocalNotificationsPlugin);

      // Инициализируем WorkManager для Android (если это Android)
      if (Platform.isAndroid) {
        try {
          // Импортируем и инициализируем WorkManager для Android
          await _initializeWorkManagerForAndroid();
          log('[NotificationsServiceImpl] WorkManager инициализирован для Android');
        } catch (e) {
          log('[NotificationsServiceImpl] Ошибка инициализации WorkManager: $e');
          // Продолжаем работу без WorkManager
        }
      }

      log('Notifications initialized successfully');

      // Проверяем разрешения после инициализации
      await _checkAndLogPermissions();
    } on Exception catch (e) {
      log('Error initializing notifications: $e');
    }
  }

  /// Инициализирует WorkManager для Android
  Future<void> _initializeWorkManagerForAndroid() async {
    try {
      // Используем условный импорт для WorkManager
      await AndroidWorkManagerService.initialize();
      log('[NotificationsServiceImpl] WorkManager успешно инициализирован для Android');
    } catch (e) {
      log('[NotificationsServiceImpl] Ошибка инициализации WorkManager: $e');
      rethrow;
    }
  }

  /// Проверяет и логирует текущие разрешения для уведомлений
  Future<void> _checkAndLogPermissions() async {
    try {
      if (Platform.isIOS) {
        final iOSPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iOSPlugin != null) {
          log('=== ПРОВЕРКА РАЗРЕШЕНИЙ iOS ===');
          log('iOS плагин найден, разрешения запрошены');
          log('===============================');
        } else {
          log('❌ iOS плагин не найден');
        }
      }
    } catch (e) {
      log('Error checking permissions: $e');
    }
  }

  Future<void> _initializeTimeZone() async {
    try {
      tz.initializeTimeZones();

      // Получаем системную таймзону
      final String currentTimeZone = tz.local.name;
      log('=== ИНИЦИАЛИЗАЦИЯ ТАЙМЗОНЫ ===');
      log('Системная таймзона: $currentTimeZone');

      // Проверяем, что таймзона работает правильно
      final now = tz.TZDateTime.now(tz.local);
      final utcNow = DateTime.now().toUtc();
      final localNow = DateTime.now();

      log('Время в системной таймзоне: $now');
      log('Время UTC: $utcNow');
      log('Время локальное: $localNow');
      log('Разница с UTC: ${now.difference(utcNow).inHours} часов');

      // Проверяем, не является ли tz.local UTC
      if (currentTimeZone == 'UTC') {
        log('⚠️ ВНИМАНИЕ: tz.local возвращает UTC!');
        log('🔧 Попробуем определить локальную таймзону через DateTime.now()');

        // Пытаемся определить локальную таймзону через системное время
        final systemOffset = DateTime.now().timeZoneOffset;
        log('Системное смещение таймзоны: ${systemOffset.inHours} часов');
      }

      log('================================');
    } on Exception catch (e) {
      log('❌ Ошибка инициализации таймзоны: $e');
      // Fallback на UTC если что-то пошло не так
      log('⚠️ Используем UTC как fallback');
    }
  }

  Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    log('Notification received while app in foreground: $title');
  }

  void _onSelectNotification(NotificationResponse details) {
    log('Notification selected: ${details.payload}');
  }

  /// Проверяет, что уведомление действительно запланировано
  Future<void> _verifyScheduledNotification(int notificationId) async {
    try {
      // Получаем все запланированные уведомления
      final pendingNotifications = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

      log('=== ПРОВЕРКА ЗАПЛАНИРОВАННЫХ УВЕДОМЛЕНИЙ ===');
      log('ID запланированного уведомления: $notificationId');
      log('Активные уведомления Android: ${pendingNotifications?.length ?? 0}');

      // Для iOS проверяем через другой способ
      if (Platform.isIOS) {
        log('📱 iOS: Уведомление запланировано через zonedSchedule');
        log('📱 iOS: Проверьте настройки уведомлений в системных настройках');
      }

      log('==============================================');
    } catch (e) {
      log('❌ Ошибка при проверке уведомлений: $e');
    }
  }

  @override
  Future<void> scheduleNotification(TimeOfDay time) async {
    try {
      await cancelNotifications();

      log('[NotificationsServiceImpl] Планируем уведомление на ${time.hour}:${time.minute.toString().padLeft(2, '0')}');

      // Используем платформенный сервис для разделения логики по платформам
      await _platformService.scheduleDailyNotification(time);

      log('[NotificationsServiceImpl] Уведомление успешно запланировано через платформенный сервис');
    } catch (e) {
      log('[NotificationsServiceImpl] Ошибка при планировании уведомления: $e');
      rethrow;
    }
  }

  @override
  Future<void> showImmediateNotification() async {
    try {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance
            .high, // Изменено с max на high для соответствия политике Google Store
        priority: Priority
            .high, // Остается high, что является оптимальным для своевременности
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final now = tz.TZDateTime.now(tz.local);
      final scheduleTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute + 1,
      );
      final notificationTime = scheduleTime.isBefore(now)
          ? scheduleTime.add(const Duration(days: 1))
          : scheduleTime;

      log('Текущее время: $now');
      log('Время уведомления: $notificationTime');
      final int rndId = math.Random().nextInt(100);
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        rndId,
        'Pivot daily reminder',
        "It's time to create your new meal plan for today",
        notificationTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      )
          .then((_) {
        log('Уведомление успешно запланировано на $notificationTime');
      }).catchError((error) {
        log('Ошибка при планировании уведомления: $error');
      });

      // await flutterLocalNotificationsPlugin.show(
      //   0,
      //   'Тестовое уведомление',
      //   'Это тестовое уведомление.',
      //   platformChannelSpecifics,
      // );

      log('Немедленное уведомление отправлено');
    } on Exception catch (e) {
      log('Ошибка при отправке немедленного уведомления: $e');
    }
  }

  /// Тестирует уведомления, планируя их через короткий промежуток времени
  @override
  Future<void> testNotification() async {
    try {
      log('🧪 ТЕСТИРОВАНИЕ УВЕДОМЛЕНИЙ');

      if (Platform.isIOS) {
        // iOS: используем специальный метод тестирования
        await _platformService.testNotificationIOS();
        return;
      }

      // Android: используем существующую логику
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Планируем уведомление через 10 секунд
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 10));

      log('⏰ Тестовое уведомление через 10 секунд');
      log('🕐 Время срабатывания (локальное): $testTime');
      log('🌍 Время срабатывания (UTC): ${testTime.toUtc()}');

      const int testId = 999; // Используем специальный ID для теста

      await flutterLocalNotificationsPlugin.zonedSchedule(
        testId,
        '🧪 Тестовое уведомление',
        'Если вы видите это, уведомления работают!',
        testTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      log('✅ Тестовое уведомление запланировано на $testTime');
      log('📱 Проверьте, придет ли уведомление через 10 секунд');
    } catch (e) {
      log('❌ Ошибка при тестировании уведомлений: $e');
    }
  }

  @override
  Future<void> cancelNotifications() async {
    try {
      log('[NotificationsServiceImpl] Отменяем все уведомления');

      // Используем платформенный сервис для отмены уведомлений
      await _platformService.cancelAllNotifications();

      log('[NotificationsServiceImpl] Все уведомления отменены');
    } on Exception catch (e) {
      log('[NotificationsServiceImpl] Ошибка при отмене уведомлений: $e');
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        PermissionStatus notificationPermission =
            await Permission.notification.status;
        if (notificationPermission.isDenied ||
            notificationPermission.isPermanentlyDenied) {
          await Permission.notification.request();
        }

        if (await Permission.scheduleExactAlarm.isDenied) {
          log('scheduleExactAlarm permission denied. Requesting permission...');
          await Permission.scheduleExactAlarm.request();
        }
        log(
          'Permissions granted, note: ${await Permission.notification.status}, alarm: ${await Permission.scheduleExactAlarm.status}',
        );
      } on Exception catch (e) {
        log('Error requesting permissions: $e');
      }
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }
}
