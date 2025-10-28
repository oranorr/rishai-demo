// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'comparison_widget.dart';
part 'recommendations_widget.dart';

class WellnessPage extends StatelessWidget {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        return RishScaffold(
          needsAppBar: true,
          implyLeading: true,
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  'Daily Nutritional Wellness',
                  style: context.styles.h2,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async => RishiDialog.infoPopup(context, '''
Recommendations change dynamically over the day as you capture meals.

Staying within ±10% of your daily goal gives the highest score.

Going beyond 10% reduces your score progressively, as overeating affects energy balance and recovery.

Pivot's nutritional intelligence instantly analyzes your day and recommends foods to fill your remaining targets.

Scores above target are penalized to encourage balanced nutrition, not overeating.'''),
                  child: SvgPicture.asset('assets/icons/info_round.svg'),
                ),
              ],
            ),
          ),
          child: state.day.welnessEntity != null
              ? ListView(
                  children: [
                    _AnimationWidget(
                      welnessPercentage:
                          state.day.welnessEntity?.welnessPercentage ?? 0,
                    ),
                    SizedBox(height: 40.h),
                    const _RecommendationsWidget(),
                    SizedBox(height: 20.h),
                    const _ComparisonWidget(),
                  ],
                )
              : Column(
                  children: [
                    _AnimationWidget(
                      welnessPercentage:
                          state.day.welnessEntity?.welnessPercentage ?? 0,
                    ),
                    const Spacer(),
                    const _CaptureMeal(),
                  ],
                ),
        );
      },
    );
  }
}

class _AnimationWidget extends StatelessWidget {
  final double welnessPercentage;
  const _AnimationWidget({
    required this.welnessPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 311.h,
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'animation goes brrrr\n $welnessPercentage',
        ),
      ),
    );
  }
}

class _CaptureMeal extends StatelessWidget {
  const _CaptureMeal({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 130.h,
      child: Column(
        children: [
          Text(
            "You haven't recorded anything yet. Please add a meal to your Food Diary.",
            style: context.styles.regularMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          RishButton.primary(
            title: 'Capture a meal',
            enabled: true,
            isLoading: false,
            action: () {
              appNavigationService.push(path: AppRoutes.diaryEntryPage.path);
            },
          ),
        ],
      ),
    );
  }
}
