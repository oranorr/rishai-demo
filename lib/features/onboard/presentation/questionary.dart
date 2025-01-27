import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/onboard/data/questionary_repository.dart';
import 'package:rishai/features/onboard/domain/entities.dart';
import 'package:rishai/features/user/domain/entities/food_preferences_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part './questionary_widgets/bmi.dart';
part 'questionary_widgets/sex_picker.dart';
part './questionary_widgets/age.dart';
part 'questionary_widgets/selectable_list.dart';
part 'questionary_mixin.dart';
part './questionary_widgets/gender_picker.dart';

class Questionary extends StatefulWidget {
  const Questionary({super.key});

  @override
  State<Questionary> createState() => _QuestionaryState();
}

class _QuestionaryState extends State<Questionary> with QuestionaryMixin {
  @override
  Widget build(BuildContext context) {
    List<Widget> bodies = [
      const BmiWidget(),
      GenderPicker(setGender: setGender),
      SexPicker(setGender: setSex, needsLightBack: false),
      AgeWidget(setAge: setAge),
      SelectableList(
        data: QuestionaryRepository().diets,
        setSomething: setDiets,
      ),
      SelectableList(
        data: QuestionaryRepository().cuisines,
        setSomething: setCuisines,
      ),
      SelectableList(
        data: QuestionaryRepository().restrictions,
        setSomething: setRestrictions,
      ),
      SelectableList(
        data: QuestionaryRepository().goals,
        setSomething: setGoal,
      ),
    ];

    return RishScaffold(
      needsAppBar: false,
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Expanded(
            child: PageView.builder(
              // physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (value) {
                resolveType(value);
              },
              controller: pageController,
              itemCount: data.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  // height: 540.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data[index].title,
                        style: context.styles.h3,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        data[index].subtitle,
                        style: context.styles.regularLarge
                            .copyWith(color: const Color(0xffA8A8A8)),
                      ),
                      // SizedBox(height: 24.h),
                      Expanded(child: bodies[index]),
                      // const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
          BlocBuilder<WhoopBloc, WhoopState>(
            bloc: whoopBloc,
            builder: (context, state) {
              return RishButton.primary(
                title: isLastPage ? 'Save' : 'Continue',
                enabled: buttonEnabled,
                isLoading: state.status == Status.loading,
                action: buttonAction,
              );
            },
          ),
        ],
      ),
    );
  }
}
