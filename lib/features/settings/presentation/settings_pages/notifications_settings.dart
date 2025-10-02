import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/services/notifications/notifications_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';

class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({super.key});

  @override
  State<NotificationsSettings> createState() => _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettings> {
  TimeOfDay selectedTime = TimeOfDay.now();
  String? savedTime;
  bool buttonEnabled = false;
  bool notesAreOn = false;

  @override
  void initState() {
    super.initState();
    _initializeNotificationsState();
  }

  /// Инициализация состояния уведомлений с проверкой разрешений
  Future<void> _initializeNotificationsState() async {
    savedTime = prefsRepo.getNoteTime(); // Получаем сохранённое время

    // Проверяем разрешения на уведомления
    bool notificationsEnabled = await notes.areNotificationsEnabled();

    if (savedTime != null && notificationsEnabled) {
      // Если есть сохранённое время И разрешения предоставлены
      List<String> timeParts = savedTime!.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      selectedTime = TimeOfDay(hour: hour, minute: minute);

      setState(() {
        notesAreOn = true;
        buttonEnabled = false; // Время уже установлено
      });
    } else {
      // Если нет сохранённого времени ИЛИ нет разрешений
      setState(() {
        notesAreOn = false;
        buttonEnabled = false; // Кнопка неактивна без разрешений
      });

      // Если есть сохранённое время, но нет разрешений - очищаем его
      if (savedTime != null && !notificationsEnabled) {
        await prefsRepo.setNotifcationTime(null);
        savedTime = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // notes.showImmediateNotification();
    return RishScaffold(
      centerTitle: true,
      implyLeading: true,
      needsAppBar: true,
      appBarLabel: Text(
        'Notification',
        style: context.styles.h2,
      ),
      child: Column(
        children: [
          Text(
            'Receive a daily push notification to create your meal plan',
            style: context.styles.regularLarge
                .copyWith(color: RishColors.textSecondary),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily meal plan reminder',
                style: context.styles.regularMedium,
              ),
              Switch(
                value: notesAreOn,
                onChanged: (v) async {
                  if (v) {
                    // 🔐 ПРОВЕРКА РАЗРЕШЕНИЙ: Проверяем, разрешены ли уведомления
                    bool notificationsEnabled =
                        await notes.areNotificationsEnabled();

                    if (!notificationsEnabled) {
                      // 📱 ЗАПРОС РАЗРЕШЕНИЙ: Если разрешения не предоставлены, запрашиваем их
                      await notes.requestPermissions();

                      // 🔍 ПОВТОРНАЯ ПРОВЕРКА: Проверяем снова после запроса разрешений
                      notificationsEnabled =
                          await notes.areNotificationsEnabled();

                      if (!notificationsEnabled) {
                        // ⚠️ ДИАЛОГ РАЗРЕШЕНИЙ: Если пользователь всё ещё не разрешил уведомления,
                        // показываем диалог с объяснением и кнопкой перехода в настройки
                        if (mounted) {
                          _showPermissionDialog(context);
                        }
                        return; // 🚫 Не включаем свитчер, так как разрешения не предоставлены
                      }
                    }

                    // ✅ РАЗРЕШЕНИЯ ПРЕДОСТАВЛЕНЫ: Если разрешения предоставлены, включаем уведомления
                    setState(() {
                      notesAreOn = v;
                      buttonEnabled = v && _isTimeChanged();
                    });
                  } else {
                    // 🔇 ОТКЛЮЧЕНИЕ УВЕДОМЛЕНИЙ: Отключаем уведомления
                    setState(() {
                      notesAreOn = v;
                      buttonEnabled = false; // Кнопка неактивна при отключении
                    });

                    await notes.cancelNotifications();
                    prefsRepo.setNotifcationTime(null);

                    setState(() {
                      savedTime = null;
                    });
                  }
                },
                activeTrackColor: RishColors.stroke,
                inactiveTrackColor: RishColors.stroke,
                inactiveThumbColor: RishColors.textSecondary,
                activeColor: context.theme.colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          if (notesAreOn)
            AnimatedContainer(
              duration: Durations.long1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notification time',
                    style: context.styles.regularMedium,
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _selectTime(context);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: RishColors.stroke),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              savedTime != null
                                  ? _formatTime(savedTime!)
                                  : _formatTimeOfDay(selectedTime),
                              style: context.styles.regularMedium,
                            ),
                            SizedBox(width: 24.w),
                            const Icon(
                              Icons.more_time_rounded,
                              color: RishColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Кнопка "Set"
          RishButton.primary(
            title: 'Set',
            enabled: buttonEnabled &&
                notesAreOn, // Кнопка активна только если есть разрешения И время изменено
            isLoading: false,
            action: () async {
              // 🔐 ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Проверяем разрешения перед установкой уведомлений
              bool notificationsEnabled = await notes.areNotificationsEnabled();
              if (!notificationsEnabled) {
                // Если разрешения не предоставлены, показываем диалог
                if (mounted) {
                  _showPermissionDialog(context);
                }
                return;
              }

              // ✅ УСТАНОВКА УВЕДОМЛЕНИЙ: Если разрешения есть, устанавливаем уведомления
              await notes.scheduleNotification(selectedTime);
              String formattedTime =
                  "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
              await prefsRepo.setNotifcationTime(formattedTime);
              setState(() {
                savedTime = formattedTime;
                buttonEnabled = false;
              });
            },
          ),
          if (kDebugMode) ...[
            SizedBox(height: 16.h),
            // Кнопка для тестирования уведомлений
            RishButton.secondary(
              title: '🧪 Test Notification',
              action: () async {
                log('🧪 Тестирование уведомлений...');
                await notes.testNotification();
              },
            ),
          ],
        ],
      ),
    );
  }

  // Проверка, изменилось ли время
  bool _isTimeChanged() {
    if (savedTime == null) {
      return true; // Если нет сохранённого времени, считаем что время изменилось
    }
    List<String> timeParts = savedTime!.split(':');
    int savedHour = int.parse(timeParts[0]);
    int savedMinute = int.parse(timeParts[1]);
    return selectedTime.hour != savedHour || selectedTime.minute != savedMinute;
  }

  // Выбор времени
  Future<void> _selectTime(BuildContext context) async {
    // 🔐 ПРОВЕРКА РАЗРЕШЕНИЙ: Проверяем разрешения перед выбором времени
    bool notificationsEnabled = await notes.areNotificationsEnabled();
    if (!notificationsEnabled) {
      // Если разрешения не предоставлены, показываем диалог
      if (mounted) {
        _showPermissionDialog(context);
      }
      return;
    }

    // ✅ ВЫБОР ВРЕМЕНИ: Если разрешения есть, позволяем выбрать время
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        buttonEnabled = _isTimeChanged(); // Проверяем, изменилось ли время
      });
    }
  }

  // Форматирование сохранённого времени
  String _formatTime(String time) {
    List<String> timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return _formatTimeOfDay(timeOfDay);
  }

  // Форматирование TimeOfDay
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: true,
    );
  }

  /// 🚨 ПОКАЗ ДИАЛОГА РАЗРЕШЕНИЙ: Показывает диалог с объяснением необходимости разрешений на уведомления
  ///
  /// Диалог содержит:
  /// - Объяснение зачем нужны уведомления
  /// - Инструкцию по включению в настройках
  /// - Кнопку "Settings" для перехода в настройки приложения
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Notification Permissions',
            style: context.styles.h3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To receive daily reminders for creating your meal plan, you need to allow notifications.',
                style: context.styles.regularMedium.copyWith(
                  color: RishColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Please enable notifications in your device settings.',
                style: context.styles.regularMedium.copyWith(
                  color: RishColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            RishButton.primary(
              title: 'Settings',
              enabled: true,
              isLoading: false,
              action: () async {
                Navigator.of(context).pop();
                // Открываем настройки приложения
                await _openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// ⚙️ ОТКРЫТИЕ НАСТРОЕК: Открывает настройки приложения для изменения разрешений
  ///
  /// Использует permission_handler.openAppSettings() для:
  /// - Android: открытия настроек приложения
  /// - iOS: открытия настроек приложения
  ///
  /// Это позволяет пользователю легко изменить разрешения на уведомления
  /// без необходимости искать настройки вручную
  Future<void> _openAppSettings() async {
    try {
      // Используем permission_handler для открытия настроек
      await openAppSettings();
    } catch (e) {
      log('Error opening app settings: $e');
    }
  }
}
