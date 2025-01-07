// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../questionary.dart';

class GenderPicker extends StatefulWidget {
  final VoidCallback setGender;

  const GenderPicker({
    required this.setGender,
    super.key,
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
    widget.setGender();
  }

  List<String> assets = [
    'assets/images/male_sign.svg',
    'assets/images/female_sign.svg',
    'assets/images/non-b_sign.svg',
    'assets/images/idk_sign.svg',
  ];

  List<String> titles = [
    'Male',
    'Female',
    'Non-Binary',
    'Prefer not to choose',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: titles.length,
      itemBuilder: (context, i) {
        return GestureDetector(
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
                  color: RishColors.formBackgroun,
                  border: selected == i
                      ? Border.all(color: getColor(selected))
                      : null,
                ),
                child: Center(
                  child: SvgPicture.asset(assets[i]),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                titles[i],
                style: context.styles.boldLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Color getColor(int? selected) {
    if (selected == null) {
      return Colors.transparent;
    } else if (selected == 0) {
      return Colors.blue;
    } else if (selected == 1) {
      return Colors.pink;
    } else if (selected == 2) {
      return const Color(0xffF4C700);
    } else if (selected == 3) {
      return const Color(0xffF5F5DC);
    } else {
      return Colors.white;
    }
  }
}
