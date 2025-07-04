part of '../questionary.dart';

class BmiWidget extends StatefulWidget {
  const BmiWidget({
    super.key,
  });

  @override
  State<BmiWidget> createState() => _BmiWidgetState();
}

class _BmiWidgetState extends State<BmiWidget> {
  Timer? _retryTimer;
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 5;
  final Duration _retryInterval = const Duration(seconds: 3);
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startRetryMechanism();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startRetryMechanism() {
    log('[BmiWidget] Starting retry mechanism', name: 'BmiWidget');
    _retryTimer = Timer.periodic(_retryInterval, (timer) {
      if (_retryAttempts >= _maxRetryAttempts) {
        log('[BmiWidget] Max retry attempts reached', name: 'BmiWidget');
        timer.cancel();
        return;
      }

      // Проверяем, есть ли данные
      final hasData = userBloc.state.user.bodyMeasurements != null;
      if (hasData) {
        log(
          '[BmiWidget] Data found, stopping retry mechanism',
          name: 'BmiWidget',
        );
        timer.cancel();
        return;
      }

      // Увеличиваем счетчик попыток
      _retryAttempts++;
      log(
        '[BmiWidget] Retry attempt $_retryAttempts/$_maxRetryAttempts',
        name: 'BmiWidget',
      );

      // Делаем попытку загрузить данные
      _retryLoadData();
    });
  }

  void _retryLoadData() {
    setState(() {
      _isRetrying = true;
    });

    // Запускаем повторную загрузку данных из WhoopBloc
    whoopBloc.add(WhoopRetrieveBodyData());

    // Через короткое время убираем флаг retry
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
  }

  void _manualRetry() {
    log('[BmiWidget] Manual retry triggered', name: 'BmiWidget');
    _retryAttempts = 0;
    _retryLoadData();
    _startRetryMechanism();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        log(
          '[BmiWidget] bodyMeasurements: ${state.user.bodyMeasurements}',
          name: 'BmiWidget',
        );

        // [FIX] Проверяем на null чтобы избежать крашей
        if (state.user.bodyMeasurements == null) {
          // Если превышено количество попыток, показываем fallback UI
          if (_retryAttempts >= _maxRetryAttempts) {
            return _buildFallbackUI();
          }

          // Показываем загрузку с информацией о попытках
          return _buildLoadingUI();
        }

        // Останавливаем retry механизм если данные получены
        _retryTimer?.cancel();

        final double height = state.user.bodyMeasurements!.height * 100;
        final double weight = state.user.bodyMeasurements!.weight.toDouble();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Линейка роста
                _RulerWidget(title: 'Height', value: height),

                //Человечек
                SvgPicture.asset('assets/images/body.svg'),

                //Линейка веса
                _RulerWidget(title: 'Weight', value: weight),
              ],
            ),
            //Карточка с бми
            SizedBox(height: 25.h),
            _BmiCard(
              weight: weight,
              height: height,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Загружаем данные из WHOOP...',
            style: context.styles.regularMedium,
          ),
          if (_retryAttempts > 0) ...[
            SizedBox(height: 8.h),
            Text(
              'Попытка $_retryAttempts из $_maxRetryAttempts',
              style: context.styles.regularSmall.copyWith(
                color: const Color(0xffA8A8A8),
              ),
            ),
          ],
          if (_isRetrying) ...[
            SizedBox(height: 8.h),
            Text(
              'Повторная загрузка...',
              style: context.styles.regularSmall.copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.h,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          Text(
            'Не удалось загрузить данные',
            style: context.styles.regularMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'Проверьте подключение к WHOOP',
            style: context.styles.regularSmall.copyWith(
              color: const Color(0xffA8A8A8),
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _manualRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.height,
    required this.weight,
  });
  final double height;
  final double weight;

  @override
  Widget build(BuildContext context) {
    double heightInMeters = height / 100;
    double bmi = weight / (heightInMeters * heightInMeters);
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xff242239),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(getColor(bmi)),
            backgroundColor: const Color(0xff403D64),
            value: getValue(bmi),
            strokeWidth: 5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: 285.w,
            child: Text(
              'According to your height and weight your BMI is ${bmi.toString().substring(0, 4)}',
              style: context.styles.regularMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: 117.w,
            height: 30.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: getColor(bmi)),
            ),
            child: Center(
              child: Text(
                bmi.toString().substring(0, 4),
                // '',
                style: context.styles.boldSmall.copyWith(color: getColor(bmi)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double getValue(double bmi) {
    return bmi / 40;
  }

  Color getColor(double bmi) {
    if (bmi > 30) {
      return Colors.red;
    } else if (bmi < 18.5 || (bmi > 25 && bmi < 30)) {
      return Colors.orange;
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return Colors.green;
    } else {
      return Colors.pink;
    }
  }

  String getName(double bmi) {
    if (bmi < 18.5) {
      return 'you are underweight.';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'you have normal BMi.';
    } else if (bmi >= 25) {
      return 'you have excessive weight.';
    } else {
      return 'idk some error';
    }
  }
}

// Недостаточный вес: BMI < 18.5
// Нормальный вес: BMI от 18.5 до 24.9
// Избыточный вес: BMI от 25.0 до 29.9
// Ожирение I степени: BMI от 30.0 до 34.9
// Ожирение II степени: BMI от 35.0 до 39.9
// Ожирение III степени (морбидное ожирение): BMI ≥ 40.0

class _RulerWidget extends StatelessWidget {
  const _RulerWidget({
    required this.title,
    required this.value,
  });
  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: context.styles.boldMedium,
        ),
        SizedBox(height: 12.h),
        Container(
          height: 185,
          width: 25.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            border: Border.all(
              color: context.theme.colorScheme.primary,
            ),
          ),
          child: RotatedBox(
            quarterTurns: -1,
            child: LinearProgressIndicator(
              value: getValue(value),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                context.theme.colorScheme.primary.withValues(alpha: 0.32),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(value.round().toString(), style: context.styles.numsL),
        SizedBox(height: 4.h),
        Text(
          getName(),
          style: context.styles.regularLarge
              .copyWith(color: const Color(0xffA8A8A8)),
        ),
      ],
    );
  }

  String getName() {
    switch (title) {
      case 'Height':
        return 'cms';

      case 'Weight':
        return 'kgs';
      default:
        return '';
    }
  }

  double getValue(value) {
    final double maxValue;
    switch (title) {
      case 'Height':
        maxValue = 215;
      case 'Weight':
        maxValue = 150;
      default:
        maxValue = 0;
    }
    return value / maxValue;
  }
}
