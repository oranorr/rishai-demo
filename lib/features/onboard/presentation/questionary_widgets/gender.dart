// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../questionary.dart';

class GenderPicker extends StatefulWidget {
  final Function(Gender) setGender;
  final bool? needsLightBack;
  const GenderPicker({
    super.key,
    required this.setGender,
    this.needsLightBack,
  });

  @override
  State<GenderPicker> createState() => _GenderPickerState();
}

class _GenderPickerState extends State<GenderPicker> {
  int? selected;

  void select(int i) {
    setState(() {
      selected = i;
    });
    widget.setGender(i == 0 ? Gender.male : Gender.female);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
