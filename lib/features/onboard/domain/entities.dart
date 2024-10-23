// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/settings/presentation/widgets/modificator_selector.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';

class QuestionaryData {
  final String title;
  final String subtitle;
  QuestionaryData({
    required this.title,
    required this.subtitle,
  });
}

abstract class Question {
  final String name;
  final String assetPath;
  final String? subtitle;
  final Diet? diet;
  final GoalType? goal;
  final CuisineEnum? cuisine;
  const Question({
    required this.name,
    required this.assetPath,
    this.subtitle,
    this.diet,
    this.goal,
    this.cuisine,
  });
  @override
  bool operator ==(covariant Question other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.assetPath == assetPath &&
        other.subtitle == subtitle &&
        other.diet == diet &&
        other.goal == goal &&
        other.cuisine == cuisine;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        assetPath.hashCode ^
        subtitle.hashCode ^
        diet.hashCode ^
        goal.hashCode ^
        cuisine.hashCode;
  }

  @override
  String toString() {
    return 'Question(name: $name, assetPath: $assetPath, subtitle: $subtitle, diet: $diet, goal: $goal, cuisine: $cuisine)';
  }

  Widget buildWidget({
    required BuildContext context,
    required Function(Question question) action,
    required bool isSelected,
    Function(Question q)? preSelectCard,
    bool? needsLightBack,
  });
}

class Dietary extends Question {
  Dietary({
    required super.name,
    required super.assetPath,
    required super.diet,
  });

  @override
  Widget buildWidget({
    required BuildContext context,
    required Function(Question question) action,
    required bool isSelected,
    Function(Question q)? preSelectCard,
    bool? needsLightBack,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: needsLightBack ?? false
            ? RishColors.stroke
            : RishColors.formBackgroun,
        // tileColor:  const Color(0xff242239),
        leading: SvgPicture.asset(assetPath),
        title: Text(name, style: context.styles.regularLarge),
        trailing: Checkbox(
          shape: const CircleBorder(),
          value: isSelected,
          onChanged: (value) {
            action(this);
          },
        ),
        onTap: () {
          action(this);
        },
      ),
    );
  }
}

class Cuisine extends Question {
  Cuisine(
      {required super.name, required super.assetPath, required super.cuisine});

  @override
  Widget buildWidget(
      {required BuildContext context,
      required Function(Question question) action,
      required bool isSelected,
      Function(Question q)? preSelectCard,
      bool? needsLightBack}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        tileColor: needsLightBack ?? false
            ? RishColors.stroke
            : RishColors.formBackgroun,
        // tileColor: const Color(0xff242239),
        leading: SvgPicture.asset(assetPath),
        title: Text(name, style: context.styles.regularLarge),
        trailing: Checkbox(
          shape: const CircleBorder(),
          value: isSelected,
          onChanged: (value) {
            action(this);
          },
        ),
        onTap: () {
          action(this);
        },
      ),
    );
  }
}

class FitnessGoal extends Question {
  double modificator;

  FitnessGoal({
    required super.name,
    required super.assetPath,
    required super.subtitle,
    required super.goal,
    required this.modificator,
  });

  set setModificator(double val) => modificator = val;

  @override
  Widget buildWidget(
      {required BuildContext context,
      required Function(Question question) action,
      Function(Question q)? preSelectCard,
      required bool isSelected,
      bool? needsLightBack}) {
    return GestureDetector(
      onTap: () {
        ///for profile settings not to show popup
        if (needsLightBack ?? false) {
          preSelectCard!(this);
          action(this);
          return;
        }
        preSelectCard!(this);
        ModificatorSelectorSheet(
                goal: toUseGoal(),
                setModificator: (value) {
                  action(copyWith(modificator: value));
                },
                context: context)
            .show();
        // ModalSheet.showSingleChildSheet(
        //   needsButton: false,
        //   context: context,
        //   title: 'Select Modificator',
        //   height: goal == GoalType.recomp || goal == GoalType.optimize
        //       ? 270.h
        //       : 400.h,
        //   child: ModificatorSelector(
        //     type: toUseGoal().goal,
        //     setModificator: (value) {
        //       action(copyWith(modificator: value));
        //     },
        //     defaultModificator: toUseGoal().getModificators().first,
        //     modificators: toUseGoal().getModificators(),
        //     subtitle: goal == GoalType.recomp
        //         ? 'Your calorie intake will be changing automatically every two weeks'
        //         : 'You calories will match your TDEE',
        //   ),
        // );
      },
      child: Card(
        color: needsLightBack ?? false
            ? RishColors.stroke
            : RishColors.formBackgroun,
        shape: RoundedRectangleBorder(
            side: BorderSide(
                color: isSelected
                    ? context.theme.colorScheme.primary
                    : Colors.transparent,
                width: 1),
            borderRadius: BorderRadius.circular(16.0)),
        child: SizedBox(
          width: 132.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(height: 20.h),
              SvgPicture.asset(
                assetPath,
                fit: BoxFit.scaleDown,
              ),
              SizedBox(height: 4.h),
              Text(name, style: context.styles.regularLarge),
              SizedBox(height: 4.h),
              SizedBox(
                width: 130.w,
                child: Text(
                  subtitle!,
                  style: context.styles.regularSmall
                      .copyWith(color: const Color(0xffA8A8A8)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  UserGoal toUseGoal() => UserGoal(
      goal: goal!, modificator: modificator, updatedAt: DateTime.now());

  FitnessGoal copyWith({
    double? modificator,
  }) {
    return FitnessGoal(
      modificator: modificator ?? this.modificator,
      name: name,
      assetPath: assetPath,
      subtitle: subtitle,
      goal: goal,
    );
  }
}

enum Diet {
  carnivore,
  keto,
  mediterranean,
  omnivore,
  paleo,
  pescatarian,
  vegan,
  vegetarianLactoOvo
}

enum CuisineEnum {
  mediterranean,
  eastAsia,
  southAsia,
  middleEast,
  western,
  latino,
  africano
}
