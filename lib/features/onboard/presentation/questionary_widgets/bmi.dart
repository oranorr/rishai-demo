// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../questionary.dart';

class BmiWidget extends StatelessWidget {
  const BmiWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
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
            )
          ],
        );
      },
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double height;
  final double weight;
  const _BmiCard({
    super.key,
    required this.height,
    required this.weight,
  });

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
        crossAxisAlignment: CrossAxisAlignment.center,
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
              )),
          SizedBox(height: 12.h),
          Container(
            width: 117.w,
            height: 30.h,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: getColor(bmi))),
            child: Center(
                child: Text(
              bmi.toString().substring(0, 4),
              // '',
              style: context.styles.boldSmall.copyWith(color: getColor(bmi)),
            )),
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
  final String title;
  final double value;
  const _RulerWidget({
    super.key,
    required this.title,
    required this.value,
  });

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
                  width: 1, color: context.theme.colorScheme.primary)),
          child: RotatedBox(
            quarterTurns: -1,
            child: LinearProgressIndicator(
              value: getValue(value),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                context.theme.colorScheme.primary.withOpacity(0.32),
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
        Text(getName(),
            style: context.styles.regularLarge
                .copyWith(color: const Color(0xffA8A8A8))),
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
        break;
      case 'Weight':
        maxValue = 150;
        break;
      default:
        maxValue = 0;
    }
    return value / maxValue;
  }
}
