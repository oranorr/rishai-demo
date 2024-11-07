// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../questionary.dart';

class SexPicker extends StatefulWidget {
  final Function(Gender) setGender;
  final bool? needsLightBack;
  const SexPicker({
    super.key,
    required this.setGender,
    this.needsLightBack,
  });

  @override
  State<SexPicker> createState() => _SexPickerState();
}

class _SexPickerState extends State<SexPicker> {
  int? selected;

  void select(int i) {
    setState(() {
      selected = i;
    });
    widget.setGender(i == 0 ? Gender.male : Gender.female);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < 2; i++)
              GestureDetector(
                onTap: () {
                  select(i);
                },
                child: Column(
                  children: [
                    Container(
                      height: 126.h,
                      width: 126.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.needsLightBack ?? false
                            ? RishColors.stroke
                            : RishColors.formBackgroun,
                        border: selected == i
                            ? Border.all(color: getColor(selected))
                            : null,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                            'assets/images/${i == 0 ? 'male_sign' : 'female_sign'}.svg'),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      i == 0 ? 'Male' : 'Female',
                      style: context.styles.boldLarge,
                    )
                  ],
                ),
              ),
          ],
        ),
        if (!widget.needsLightBack!) ...[
          SizedBox(height: 25.h),
          Text(
            'DISCLAIMER',
            style: context.styles.h2,
          ),
          SizedBox(height: 20.h),
          Text(
            '''
We ask for your sex assigned at birth because some of Pivot’s calculations, such as those related to metabolism, muscle mass, and energy expenditure, are based on biological factors tied to birth sex. This helps us provide the most accurate nutritional guidance for your body.

We understand that gender identity is personal, and we aim to be respectful and inclusive. Your information will only be used for accurate recommendations and will be kept confidential.
''',
            style: context.styles.regularMedium,
          )
        ],
      ],
    );
  }

  Color getColor(int? selected) {
    if (selected == null) {
      return Colors.transparent;
    } else if (selected == 0) {
      return Colors.blue;
    } else if (selected == 1) {
      return Colors.pink;
    } else {
      return Colors.yellow;
    }
  }
}
