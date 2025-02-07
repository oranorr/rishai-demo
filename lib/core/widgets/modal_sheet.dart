import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/onboard/domain/entities.dart';

class ModalSheet {
  static Widget _buildSheet({
    required BuildContext context,
    required double height,
    required String text,
    required Widget child,
    bool? needsButton,
    String? subtitle,
    String? infoText,
  }) {
    // int selected;
    return StatefulBuilder(
      builder: (context, setter) {
        return Container(
          height: height,
          // color: context.colors.white,
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80.w,
                        height: 4.h,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFCDCDCD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              style: context.styles.h2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (infoText != null) ...[
                            GestureDetector(
                              onTap: () async => RishiDialog.infoPopup(
                                context,
                                infoText,
                              ),
                              child: const Icon(
                                Icons.info,
                                size: 25,
                                color: RishColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle,
                          style: context.styles.regularLarge,
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: child),
                if (needsButton ?? true)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: SizedBox(
                      height: 56.h,
                      child: RishButton.primary(
                        title: 'Save changes',
                        action: () {
                          // onSave(selected);
                          context.pop();
                        },
                        isLoading: false,
                        enabled: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showSingleChildSheet({
    required BuildContext context,
    required String title,
    required Widget child,
    required double height,
    bool? needsButton,
    String? subtitle,
    String? infoText,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _buildSheet(
          context: context,
          height: height,
          text: title,
          child: child,
          subtitle: subtitle,
          needsButton: needsButton,
          infoText: infoText,
        );
      },
    );
  }

  static Future<void> showQuestionarySheet({
    required String title,
    required BuildContext context,
    required List<Question> data,
    required Function(List<Question>) onSave,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _buildQuestionarySheet(
          context: context,
          height: 686.h,
          text: title,
          onSave: onSave,
          data: data,
          needsChildrenScroll: true,
        );
      },
    );
  }

  static Widget _buildQuestionarySheet({
    required BuildContext context,
    required double height,
    required String text,
    required List<Question> data,
    required Function(List<Question>) onSave,
    // required List<Widget> children,
    bool? needsChildrenScroll = false,
    bool? needsTitle = true,
  }) {
    List<Question> selected = [];
    FitnessGoal? goalSelected;

    return StatefulBuilder(
      builder: (
        BuildContext context,
        StateSetter setter,
      ) {
        return Container(
          height: height,
          // color: context.colors.white,
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80.w,
                        height: 4.h,
                        decoration: ShapeDecoration(
                          color: RishColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (needsTitle ?? true)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Text(
                      text,
                      style: context.styles.h2,
                    ),
                  ),
                Expanded(
                  child: (data.runtimeType != List<FitnessGoal>)
                      ? ListView(
                          physics: needsChildrenScroll ?? false
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: data.map((q) {
                            bool isSelected = selected.contains(q);
                            return q.buildWidget(
                              context: context,
                              needsLightBack: true,
                              action: (q) {
                                setter(() {
                                  if (q.runtimeType == Dietary) {
                                    if (selected.isNotEmpty) {
                                      selected.remove(selected.first);
                                    }
                                    selected.add(q);
                                  } else {
                                    isSelected
                                        ? selected.remove(q)
                                        : selected.add(q);
                                  }
                                  // if(selected)
                                });
                              },
                              isSelected: isSelected,
                            );
                          }).toList(),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final goal = data[index];
                            bool isSelected = goal == goalSelected;
                            return goal.buildWidget(
                              context: context,
                              needsLightBack: true,
                              preSelectCard: (g) {
                                setter(() {
                                  goalSelected = g as FitnessGoal;
                                });
                              },
                              action: (goal) {
                                setter(() {
                                  goalSelected = goal as FitnessGoal;
                                });
                              },
                              isSelected: isSelected,
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: SizedBox(
                    height: 56.h,
                    child: RishButton.primary(
                      title: 'Save changes',
                      action: () {
                        if (data.runtimeType != List<FitnessGoal>) {
                          onSave(selected);
                        } else {
                          onSave([goalSelected!]);
                        }
                        context.pop();
                      },
                      enabled: selected.isNotEmpty || goalSelected != null,
                      isLoading: false,
                    ),

                    // RishButton(
                    //   action: () {

                    //   },
                    //   isLoading: false,
                    //   ),
                    //   type: selected.isNotEmpty || goalSelected != null
                    //       ? ButtonType.primary
                    //       : ButtonType.disabled,
                    // ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
