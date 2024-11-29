import 'dart:developer';
import 'dart:io';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/services/notifications/notifications_service.dart';
import 'dart:math' as math;

final notes = getIt.get<NotificationsService>();

@Singleton(as: NotificationsService)
class NotificationsServiceImpl implements NotificationsService {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    '9', // Измени ID канала, чтобы пересоздать его
    'Scheduled Notifications',
    description: 'Channel for scheduled notifications',
    importance: Importance.max,
    enableLights: true,
    enableVibration: true,
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

      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: onDidReceiveLocalNotification,
        ),
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      print("Notifications initialized successfully");
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> _initializeTimeZone() async {
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      print("Time zone initialized to $currentTimeZone");
    } catch (e) {
      print("Error initializing time zone: $e");
    }
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    print("Notification received while app in foreground: $title");
  }

  void _onSelectNotification(NotificationResponse details) {
    print('Notification selected: ${details.payload}');
  }

  @override
  Future<void> scheduleNotification(TimeOfDay time) async {
    try {
      await cancelNotifications();
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
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
          tz.local, now.year, now.month, now.day, time.hour, time.minute);

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
        androidAllowWhileIdle: true,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      )
          .then((_) {
        log('Уведомление успешно запланировано на $notificationTime');
      }).catchError((error) {
        log('Ошибка при планировании уведомления: $error');
      });
    } catch (e) {
      log("Ошибка при планировании уведомления: $e");
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
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
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
          tz.local, now.year, now.month, now.day, now.hour, now.minute + 1);
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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

      print('Немедленное уведомление отправлено');
    } catch (e) {
      print("Ошибка при отправке немедленного уведомления: $e");
    }
  }

  @override
  Future<void> cancelNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('Notification cancelled');
    } catch (e) {
      print("Error cancelling notification: $e");
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
          log("scheduleExactAlarm permission denied. Requesting permission...");
          await Permission.scheduleExactAlarm.request();
        }
        print(
            "Permissions granted, note: ${await Permission.notification.status}, alarm: ${await Permission.scheduleExactAlarm.status}");
      } catch (e) {
        print("Error requesting permissions: $e");
      }
    } else if (Platform.isIOS) {
      flutterLocalNotificationsPlugin
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
