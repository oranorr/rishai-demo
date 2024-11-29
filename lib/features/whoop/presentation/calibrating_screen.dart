import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

class CalibratingScreen extends StatefulWidget {
  const CalibratingScreen({super.key});

  @override
  State<CalibratingScreen> createState() => _CalibratingScreenState();
}

class _CalibratingScreenState extends State<CalibratingScreen> {
  late Timer _timer;
  double _progress = 1.0;
  late DateTime target;
  Duration _remainingTime = const Duration();
  @override
  void initState() {
    target = whoopBloc.state.calibratingCompleteDate!;
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() async {
    DateTime now = DateTime.now();
    Duration totalDuration = target.difference(now); // Время до конца

    if (totalDuration.isNegative) {
      // Если время окончания уже прошло
      _remainingTime = Duration.zero;
      _progress = 0.0;
      await prefsRepo.calibratingDate();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (kDebugMode) {
          target = target.subtract(const Duration(hours: 20));
        }
        DateTime currentTime = DateTime.now();
        _remainingTime = target.difference(currentTime);

        if (_remainingTime.isNegative) {
          _timer.cancel();
          _progress = 0.0;
          _remainingTime = Duration.zero;
        } else {
          _progress = _remainingTime.inSeconds / totalDuration.inSeconds;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        return RishScaffold(
          child: Center(
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                Text(
                  'Your coach will be ready in',
                  style: context.styles.h3,
                ),
                SizedBox(height: 50.h),
                SizedBox.square(
                  dimension: 291.w,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          strokeWidth: 35,
                          value: _progress,
                          strokeCap: StrokeCap.round,
                          backgroundColor: RishColors.formBackgroun,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          _formatRemainingTime(_remainingTime),
                          style: context.styles.h1,
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 50.h),
                Text(
                  'Your WHOOP does not have sufficient data.\nPlease, come back later.',
                  style: context.styles.regularMedium
                      .copyWith(color: RishColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      // Показываем дни и оставшиеся часы
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String hours = twoDigits(
          duration.inHours.remainder(24)); // Часы без учёта целых дней
      return '${duration.inDays} ${_pluralizeDays(duration.inDays)} and $hours h';
    } else {
      // Если меньше одного дня, показываем только часы и минуты
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String hours = twoDigits(duration.inHours);
      String minutes = twoDigits(duration.inMinutes.remainder(60));
      return "$hours:$minutes";
    }
  }

  String _pluralizeDays(int days) {
    if (days == 1) {
      return 'day';
    } else if (days >= 2 && days <= 4) {
      return 'days';
    } else {
      return 'days';
    }
  }
}
