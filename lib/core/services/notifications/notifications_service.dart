import 'package:flutter/material.dart';

abstract class NotificationsService {
  Future<void> initNotificationsService();
  Future<void> scheduleNotification(TimeOfDay time);
  Future<void> cancelNotifications();
  Future<void> requestPermissions();
  Future<void> showImmediateNotification();
}
