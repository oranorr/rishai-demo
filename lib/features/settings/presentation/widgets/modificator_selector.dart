// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/modal_sheet.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';

class ModificatorSelectorSheet {
  final UserGoal goal;
  final Function(double) setModificator;
  final BuildContext context;
  ModificatorSelectorSheet({
    required this.goal,
    required this.setModificator,
    required this.context,
  });

  Future<void> show() async {
    await ModalSheet.showSingleChildSheet(
      context: context,
      title: _getStrings().$1,
      height: _getHeight(),
      needsButton: false,
      infoText: _getInfoText(),
      child: ModificatorSelector(
        subtitle: _getStrings().$2,
        setModificator: setModificator,
        defaultModificator: goal.modificator,
        modificators: goal.getModificators(),
        type: goal.goal,
      ),
    );
  }

  String? _getInfoText() {
    switch (goal.goal) {
      case GoalType.aesthetics:
        return 'The deficit % represents the percentage of calories you will be asked to consume UNDER your average weekly calorie burn. If your deficit is 10%, and your average weekly calories burnt is 2,000 kcals, then your meals will total to 1,800 kcals to be consumed. This is ideally for weight loss.';
      case GoalType.performance:
        return 'The surplus % represents the percentage of calories you will be asked to consume OVER your average weekly calorie burn. If your surplus is 10%, and your average weekly calories burnt is 2,000 kcals, then your meals will total to 2,200 kcals to be consumed. This is ideally for muscle gain.';
      case GoalType.recomp || GoalType.optimize:
        return null;

      // case GoalType.aesthetics || GoalType.performance:
      //   return '410.h';
      // case GoalType.recomp:
      //   return '300.h';
      // case GoalType.optimize:
      //   return '250.h';
    }
  }

  double _getHeight() {
    switch (goal.goal) {
      case GoalType.aesthetics || GoalType.performance:
        return 410.h;
      case GoalType.recomp:
        return 300.h;
      case GoalType.optimize:
        return 250.h;
    }
  }

  (String title, String subtitle) _getStrings() {
    switch (goal.goal) {
      case GoalType.aesthetics:
        return ('Select calorie deficit %', '(-20% to -1%)');
      case GoalType.performance:
        return ('Select calorie surplus %', '(+1% to +15%)');
      case GoalType.recomp:
        return (
          '',
          'The calorie deficit % and surplus % will rotate between -5% and +5% every two weeks, automatically'
        );
      case GoalType.optimize:
        return (
          '',
          'Your target calories will match your average calorie burn'
        );
    }
  }
}

class ModificatorSelector extends StatefulWidget {
  final Function(double) setModificator;
  final double defaultModificator;
  final List<double> modificators;
  final GoalType type;
  final String? subtitle;

  const ModificatorSelector({
    required this.setModificator,
    required this.defaultModificator,
    required this.modificators,
    required this.type,
    super.key,
    this.subtitle,
  });

  @override
  State<ModificatorSelector> createState() => _ModificatorSelectorState();
}

class _ModificatorSelectorState extends State<ModificatorSelector> {
  late int selected;
  late List<int> modificators;

  @override
  void initState() {
    // isAethtetics = widget.
    modificators = List<int>.from(
      widget.modificators.map((mod) => (mod * 100).round()).toList(),
    );
    // if (widget.needsPreselected ?? false) {
    setState(() {
      selected = widget.type == GoalType.aesthetics
          ? modificators.last
          : modificators.first;
    });
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print(widget.defaultModificator);
    // print(selected)
    bool isAethtetics = widget.type == GoalType.aesthetics;
    bool needsText =
        widget.type == GoalType.recomp || widget.type == GoalType.optimize;
    return Column(
      children: [
        if (!needsText)
          Text(
            widget.subtitle!,
            style: context.styles.regularLarge,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (!needsText) ...[
              Column(
                children: [
                  Stack(
                    children: [
                      Positioned(
                        top: 55.h,
                        child: Container(
                          height: 70.h,
                          width: 343.w,
                          decoration: BoxDecoration(
                            color: RishColors.stroke,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      NumberPicker(
                        minValue: isAethtetics
                            ? modificators.last
                            : modificators.first,
                        maxValue: isAethtetics
                            ? modificators.first
                            : modificators.last,
                        value: selected,
                        onChanged: (i) {
                          setState(() {
                            selected = i;
                          });
                        },
                        itemWidth: double.infinity,
                        itemHeight: 60.h,
                        textStyle: context.styles.numsM,
                        selectedTextStyle: context.styles.h1
                            .copyWith(color: context.theme.colorScheme.primary),
                        textMapper: (numberText) {
                          return '$numberText %';
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (needsText) ...[
              Align(
                child: Text(
                  widget.subtitle!,
                  style: context.styles.regularLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 32),
          child: SizedBox(
            height: 56.h,
            child: RishButton.primary(
              title: 'Save changes',
              action: () {
                widget.setModificator(selected / 100);
                context.pop();
              },
              isLoading: false,
              enabled: true,
            ),
          ),
        ),
      ],
    );
  }
}
