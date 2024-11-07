import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/dropdown_menu.dart';
import 'package:rishai/core/widgets/modal_sheet.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/onboard/data/questionary_repository.dart';
import 'package:rishai/features/onboard/domain/entities.dart';
import 'package:rishai/features/onboard/presentation/questionary.dart';
import 'package:rishai/features/settings/presentation/widgets/modificator_selector.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part '../profile_mixin.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> with ProfileMixin {
  bool planCreated = chatBloc.state.mealPlan != null;
  @override
  Widget build(BuildContext context) {
    return RishScaffold(
        implyLeading: !buttonIsActive,
        needsAppBar: true,
        centerTitle: true,
        needsBottomPadding: false,
        appBarLabel: Text(
          'Profile',
          style: context.styles.h2,
        ),
        child: ListView(
          children: [
            RishDropdownMenu(
              title: 'Dietary preference',
              preSelectedData: updUser.foodPreferences!.diets.join(', '),
              action: planCreated
                  ? _showDialog
                  : () {
                      ModalSheet.showQuestionarySheet(
                        title: 'Dietary prefrence',
                        context: context,
                        data: QuestionaryRepository().diets,
                        onSave: (List<Question> selectedDiets) {
                          updateDietary(selectedDiets.cast<Dietary>());
                        },
                      );
                    },
            ),
            SizedBox(height: 16.h),
            RishDropdownMenu(
              title: 'Cuisine preferences',
              preSelectedData: updUser.foodPreferences!.cuisines.join(', '),
              action: planCreated
                  ? _showDialog
                  : () {
                      ModalSheet.showQuestionarySheet(
                        title: 'Cuisine prefrences',
                        context: context,
                        data: QuestionaryRepository().cuisines,
                        onSave: (List<Question> selectedCuisines) {
                          updateCuisines(selectedCuisines.cast<Cuisine>());
                        },
                      );
                    },
            ),
            SizedBox(height: 16.h),
            RishDropdownMenu(
              title: 'Fitness goal',
              preSelectedData: updUser.userGoal!.getGoalTypeName(),
              action:
                  // !kDebugMode
                  planCreated
                      ? _showDialog
                      : () {
                          ModalSheet.showQuestionarySheet(
                            title: 'Fitness goal',
                            context: context,
                            data: QuestionaryRepository().goals,
                            onSave: (List<Question> selectedGoal) {
                              // print(selectedGoal);
                              updateGoal(selectedGoal.first as FitnessGoal);
                            },
                          );
                        },
            ),
            SizedBox(height: 16.h),
            RishDropdownMenu(
                title: 'Calorie deficit/surplus %',
                preSelectedData:
                    '${(updUser.userGoal!.modificator * 100).round()} %',
                action: !modificatorChangable
                    ? () {}
                    : modificatorChangable && chatBloc.state.mealPlan == null
                        ? () {
                            ModificatorSelectorSheet(
                                    goal: updUser.userGoal!,
                                    setModificator: (value) {
                                      changeModificator(value);
                                    },
                                    context: context)
                                .show();
                            // ModalSheet.showSingleChildSheet(
                            //   needsButton: false,
                            //   context: context,
                            //   title: 'Select Modificator',
                            //   height: 400.h,
                            //   child: ModificatorSelector(
                            //     type: updUser.userGoal!.goal,
                            //     setModificator: (value) {
                            //       changeModificator(value);
                            //     },
                            //     defaultModificator:
                            //         updUser.userGoal!.modificator,
                            //     modificators:
                            //         updUser.userGoal!.getModificators(),
                            //     subtitle: updUser.userGoal!.goal ==
                            //             GoalType.recomp
                            //         ? 'Your calorie intake will be changing automatically every two weeks'
                            //         : 'You calories will match your TDEE',
                            //   ),
                            // );
                          }
                        : _showDialog,
                needsTrailing: modificatorChangable),
            SizedBox(height: 8.h),
            Text(
              updUser.userGoal!.getSettingsDescription(),
              style: context.styles.regularSmall
                  .copyWith(color: RishColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: RishDropdownMenu(
                    title: 'Age',
                    preSelectedData: '${updUser.age} yo',
                    action: () {
                      ModalSheet.showSingleChildSheet(
                        context: context,
                        title: 'Your Age',
                        height: 551.h,
                        child: AgeWidget(
                          setAge: (age) {
                            updateAge(age);
                          },
                          needsLightBack: true,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: RishDropdownMenu(
                    title: 'Biological Sex',
                    preSelectedData: updUser.gender!.name.capitalize(),
                    action: () {
                      ModalSheet.showSingleChildSheet(
                        context: context,
                        title: 'Your biological sex',
                        height: 383.h,
                        child: SexPicker(
                          setGender: (gender) {
                            updateGender(gender);
                          },
                          needsLightBack: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),
            Text(
              'The following parameters can be changed in WHOOP',
              style: context.styles.regularLarge
                  .copyWith(color: RishColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: RishDropdownMenu(
                    title: 'Height',
                    preSelectedData:
                        '${((updUser.bodyMeasurements!.height) * 100).round()} cm',
                    action: () {},
                    needsTrailing: false,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: RishDropdownMenu(
                    title: 'Weight',
                    preSelectedData:
                        '${(updUser.bodyMeasurements?.weight ?? 10).round()} kg',
                    action: () {},
                    needsTrailing: false,
                  ),
                ),
              ],
            ),
            // const Spacer(),
            SizedBox(height: 36.h),
            RishButton.primary(
                title: 'Save changes',
                enabled: buttonIsActive,
                isLoading: false,
                action: () {
                  userBloc.add(UpdateUserEvent(user: updUser));
                  whoopBloc.add(WhoopChangeModificatorOrSex(
                      modificator: updUser.userGoal!.modificator,
                      gender: updUser.gender!,
                      context: context));
                  setState(() {
                    buttonIsActive = false;
                  });
                  // context.pop();
                }),
            SizedBox(height: 16.h),
          ],
        ));
  }

  void _showDialog() {
    RishiDialog.showCustomDialog(context,
        type: DialogType.info,
        actionDialogType: ActionDialogType.warning,
        text:
            'This setting can only be changed tomorrow, BEFORE creating a new meal plan',
        action: () {
      context.pop();
    });
  }
}
