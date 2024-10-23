// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../questionary.dart';

class AgeWidget extends StatefulWidget {
  final Function(int) setAge;
  final bool? needsLightBack;
  const AgeWidget({
    super.key,
    required this.setAge,
    this.needsLightBack,
  });

  @override
  State<AgeWidget> createState() => _AgeWidgetState();
}

class _AgeWidgetState extends State<AgeWidget> {
  int age = 20;
  int selectedIndex = 3;
  List<int> ages = List.generate(100, (age) => age)..removeRange(0, 15);

  @override
  void initState() {
    widget.setAge(age);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // widget.setAge(age);
    return Column(
      children: [
        Stack(
          children: [
            Positioned(
              top: 128.h,
              child: Container(
                height: 100.h,
                width: 343.w,
                decoration: BoxDecoration(
                    color: widget.needsLightBack ?? false
                        ? RishColors.stroke
                        : RishColors.formBackgroun,
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            NumberPicker(
              itemCount: 3,
              minValue: 12,
              maxValue: 90,
              haptics: true,
              value: age,
              onChanged: (ag) {
                setState(() {
                  age = ag;
                  widget.setAge(age);
                });
              },
              itemWidth: double.infinity,
              itemHeight: 120.h,
              textStyle: context.styles.numsL,
              selectedTextStyle: context.styles.h1
                  .copyWith(color: context.theme.colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
