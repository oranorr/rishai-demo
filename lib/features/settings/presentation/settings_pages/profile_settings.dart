import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:rishai/features/onboard/data/questionary_repository.dart';
import 'package:rishai/features/onboard/domain/entities.dart';
import 'package:rishai/features/onboard/presentation/questionary.dart';
import 'package:rishai/features/settings/presentation/widgets/modificator_selector.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/core/services/hive/hive_impl.dart';
import 'package:rishai/features/whoop/domain/entities/user_data_entity.dart';

part '../profile_mixin.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> with ProfileMixin {
  bool planCreated =
      kDebugMode ? false : whoopBloc.state.day.mealPlanEntity != null;

  // Добавляем проверку, является ли день "вчерашним"
  bool get isYesterday {
    final day = whoopBloc.state.day;
    final today = DateTime.now();

    // dateTime уже является DateTime объектом
    final dayDate = day.dateTime;

    // Приводим к одному формату даты без времени для сравнения
    final todayDate = DateTime(today.year, today.month, today.day);
    final normalizedDayDate =
        DateTime(dayDate.year, dayDate.month, dayDate.day);

    // Проверяем, является ли день "вчерашним"
    final difference = todayDate.difference(normalizedDayDate).inDays;
    return difference == 1;
  }

  // Проверка доступности изменения цели
  bool get canChangeGoal {
    return !planCreated && !isYesterday;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, userState) {
        // [FIX] Всегда используем актуальные данные из UserBloc
        // Если пользователь не редактирует (кнопка неактивна), показываем данные из блока
        final displayUser = buttonIsActive ? updUser : userState.user;

        return RishScaffold(
          implyLeading: !buttonIsActive,
          needsAppBar: true,
          centerTitle: true,
          needsBottomPadding: false,
          appBarLabel: Text(
            'Profile',
            style: context.styles.h2,
          ),
          child: _buildContent(context, displayUser),
        );
      },
    );
  }

  Widget _buildWhoopDataWidget(BuildContext context) {
    return FutureBuilder<UserDataEntity?>(
      future: hive.fetchUserDataEntity(userId: userBloc.state.user.directusId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: RishColors.formBackgroun,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: RishColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Loading WHOOP data...',
                      style: context.styles.regularLarge,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: RishColors.formBackgroun,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_outlined,
                    color: RishColors.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'No WHOOP data available',
                      style: context.styles.regularLarge.copyWith(
                        color: RishColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final whoopData = snapshot.data!;
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: RishColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'WHOOP Data',
                      style: context.styles.boldMedium,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildWhoopDataRow(
                  context,
                  'Calorie Goal:',
                  '${whoopData.calorieGoal} kcal',
                ),
                _buildWhoopDataRow(
                  context,
                  'Weight:',
                  '${(whoopData.userWeightLbs / 2.205).toStringAsFixed(1)} kg',
                ),
                _buildWhoopDataRow(
                  context,
                  'Recovery Score:',
                  '${whoopData.recoveryScore}%',
                ),
                _buildWhoopDataRow(
                  context,
                  'Sleep Performance:',
                  '${whoopData.sleepPerformance}%',
                ),
                _buildWhoopDataRow(
                  context,
                  'Strain Value:',
                  whoopData.strainValue.toStringAsFixed(1),
                ),
                _buildWhoopDataRow(
                  context,
                  'Last Updated:',
                  '${whoopData.askTime.day}/${whoopData.askTime.month}/${whoopData.askTime.year}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhoopDataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.styles.regularMedium.copyWith(
              color: RishColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: context.styles.regularMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserEntity user) {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: RishColors.formBackgroun,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: RishColors.primary,
                  size: 20,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    userBloc.state.user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.styles.regularLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode) _buildWhoopDataWidget(context),
        RishDropdownMenu(
          title: 'Dietary preference',
          preSelectedData: user.foodPreferences!.diets.join(', '),
          action: () async {
            await ModalSheet.showQuestionarySheet(
              title: 'Dietary prefrence',
              context: context,
              data: QuestionaryRepository().diets,
              onSave: (List<Question> selectedDiets) {
                updateDietary(selectedDiets.cast<Dietary>());
              },
            );
          },
        ),
        SizedBox(height: 8.h),
        _dietaryDescription(
          user.foodPreferences?.diets.first ?? '',
          context,
        ),
        SizedBox(height: 8.h),
        RishDropdownMenu(
          title: 'Cuisine preferences',
          preSelectedData: user.foodPreferences!.cuisines.join(', '),
          action: () async {
            await ModalSheet.showQuestionarySheet(
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
          title: 'Food restrictions',
          preSelectedData: user.foodPreferences!.restrictions.isEmpty
              ? 'No restrictions'
              : user.foodPreferences!.restrictions.join(', '),
          action: () async {
            await ModalSheet.showQuestionarySheet(
              title: 'Food restrictions',
              context: context,
              data: QuestionaryRepository().restrictions,
              allowEmptySelection: true,
              onSave: (List<Question> selectedRestrictions) {
                updateRestrinctions(
                  selectedRestrictions.cast<Restriction>(),
                );
              },
            );
          },
        ),
        SizedBox(height: 16.h),
        RishDropdownMenu(
          title: 'Fitness goal',
          preSelectedData: user.userGoal!.getGoalTypeName(),
          action: canChangeGoal
              ? () async {
                  await ModalSheet.showQuestionarySheet(
                    title: 'Fitness goal',
                    context: context,
                    data: QuestionaryRepository().goals,
                    onSave: (List<Question> selectedGoal) {
                      updateGoal(selectedGoal.first as FitnessGoal);
                    },
                  );
                }
              : _showDialog,
        ),
        SizedBox(height: 16.h),
        RishDropdownMenu(
          title: 'Calorie deficit/surplus %',
          preSelectedData: '${(user.userGoal!.modificator * 100).round()} %',
          action: !modificatorChangable
              ? () {}
              : modificatorChangable && canChangeGoal
                  ? () async {
                      await ModificatorSelectorSheet(
                        goal: user.userGoal!,
                        setModificator: (value) {
                          changeModificator(value);
                        },
                        context: context,
                      ).show();
                    }
                  : _showDialog,
          needsTrailing: modificatorChangable,
        ),
        SizedBox(height: 8.h),
        Text(
          user.userGoal!.getSettingsDescription(),
          style: context.styles.regularMedium
              .copyWith(color: RishColors.textSecondary),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: RishDropdownMenu(
                title: 'Age',
                preSelectedData: '${user.age} yo',
                action: () async {
                  await ModalSheet.showSingleChildSheet(
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
                preSelectedData: user.gender!.name.capitalize(),
                action: () async {
                  await ModalSheet.showSingleChildSheet(
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
                    '${((user.bodyMeasurements!.height) * 100).round()} cm',
                action: () {},
                needsTrailing: false,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: RishDropdownMenu(
                title: 'Weight',
                preSelectedData: '${user.bodyMeasurements?.weight ?? 10} kg',
                action: () {},
                needsTrailing: false,
              ),
            ),
          ],
        ),
        SizedBox(height: 36.h),
        RishButton.primary(
          title: 'Save changes',
          enabled: buttonIsActive,
          isLoading: false,
          action: () async {
            // [FIX] Сначала сохраняем изменения, которые нужно проверить
            final currentUser = userBloc.state.user;
            final modificatorChanged = currentUser.userGoal?.modificator !=
                updUser.userGoal?.modificator;
            final genderChanged = currentUser.gender != updUser.gender;

            // [DIET_CHECK] Проверяем изменение диет для кето/карнивор
            final previousDiets = currentUser.foodPreferences?.diets ?? [];
            final newDiets = updUser.foodPreferences?.diets ?? [];
            final dietChanged = !listEquals(previousDiets, newDiets);

            // Обновляем пользователя
            userBloc.add(UpdateUserEvent(user: updUser));

            // [FIX] Деактивируем кнопку сразу, BlocBuilder автоматически покажет актуальные данные
            setState(() {
              buttonIsActive = false;
            });

            // [FIX] Небольшая задержка перед проверкой изменений
            await Future.delayed(const Duration(milliseconds: 100));

            // [DIET_CHECK] Проверяем изменение диеты на кето/карнивор при сохранении
            if (dietChanged) {
              log(
                '[ProfileSettings] Обнаружено изменение диет при сохранении',
                name: 'ProfileSettings',
              );
              whoopBloc.add(
                WhoopCheckDietChange(
                  newDiets: newDiets,
                  previousDiets: previousDiets,
                  context: context,
                ),
              );
            }

            // Проверяем, нужно ли обновить макросы
            if (modificatorChanged || genderChanged) {
              whoopBloc.add(
                WhoopChangeModificatorOrSex(
                  modificator: updUser.userGoal!.modificator,
                  gender: updUser.gender!,
                  context: context,
                  currentDiets: updUser
                      .foodPreferences?.diets, // Передаем актуальные диеты
                ),
              );
            }
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Future<void> _showDialog() async {
    String message = isYesterday
        ? 'This setting can only be changed tomorrow, AFTER the new day starts'
        : 'This setting can only be changed tomorrow, BEFORE creating a new meal plan';

    await RishiDialog.showCustomDialog(
      context,
      type: DialogType.info,
      actionDialogType: ActionDialogType.warning,
      text: message,
      action: () {
        context.pop();
      },
    );
  }

  Widget _dietaryDescription(String dietName, BuildContext context) {
    String text = '';
    final normalizedDietName = dietName.toLowerCase();

    if (normalizedDietName == 'carnivore') {
      text = '''
Picking Carnivore changes your daily macros for a carnivore diet based on your WHOOP data. Carbs will not exceed 1% of your total calorie consumption goal.''';
    } else if (normalizedDietName == 'keto') {
      text = '''
Picking Keto changes your daily macros for a ketogenic diet based on your WHOOP data. Carbs will range between 5-10% of your total calorie consumption goal.''';
    } else {
      text = '''
Macro goals are based on dietary preference and WHOOP data. They are the same for omnivore, pescatarian, vegan, vegetarian.''';
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.grey,
      ),
    );
  }
}
