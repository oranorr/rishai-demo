import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    savedTime = prefsRepo.getNoteTime(); // Получаем сохранённое время
    notesAreOn = savedTime != null; // Инициализируем состояние переключателя
    if (savedTime != null) {
      // Парсим сохранённое время и устанавливаем selectedTime
      List<String> timeParts = savedTime!.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      selectedTime = TimeOfDay(hour: hour, minute: minute);
      buttonEnabled = false;
    } else {
      buttonEnabled = true;
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
                  setState(() {
                    if (v) {
                      notes.requestPermissions();
                    } else {
                      prefsRepo.setNotifcationTime(null);
                    }
                    notesAreOn = v;
                    buttonEnabled = v && _isTimeChanged();
                  });
                  if (!v) {
                    await notes.cancelNotifications();
                    // prefsRepo.setNoteTime(null); // Удаляем сохранённое время
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
            enabled: buttonEnabled,
            isLoading: false,
            action: () async {
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
      ),
    );
  }

  // Проверка, изменилось ли время
  bool _isTimeChanged() {
    if (savedTime == null) {
      return true;
    }
    List<String> timeParts = savedTime!.split(':');
    int savedHour = int.parse(timeParts[0]);
    int savedMinute = int.parse(timeParts[1]);
    return selectedTime.hour != savedHour || selectedTime.minute != savedMinute;
  }

  // Выбор времени
  Future<void> _selectTime(BuildContext context) async {
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
}
