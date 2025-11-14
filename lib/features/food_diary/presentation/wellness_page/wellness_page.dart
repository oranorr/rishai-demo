// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
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
                  onTap: () async => RishiDialog.infoPopup(
                    context,
                    '''
The Daily Nutritional Wellness Score is your personal performance tracker and gives you a clear snapshot of how well you're fueling your body, measuring your nutritional consistency.

Our proprietary algorithm calculates a % score based on how closely your calorie and macro intake matches your daily targets.

Your Daily Nutritional Wellness score provides nutritional insights and personalized recommendations for dietary choices by Pivot's nutritional intelligence.

Your DNWS drops faster once you exceed 110% of your target intake, encouraging balance over excess.''',
                    title: 'Daily Nutritional Wellness',
                  ),
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
                    if (adapty.isActive) ...[
                      const _RecommendationsWidget(),
                      SizedBox(height: 20.h),
                      const _ComparisonWidget(),
                    ] else ...[
                      const _NoSubscriptionWidget(),
                    ],
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
        // color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Image.asset('assets/images/wellness.png'),
            ),
            Align(
              child: Text(
                '${welnessPercentage.toStringAsFixed(0)}%',
                style: context.styles.h2,
              ),
            ),
          ],
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

class _NoSubscriptionWidget extends StatelessWidget {
  const _NoSubscriptionWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'You can get detailed insights and nutritional coaching if you subscribe.',
          style: context.styles.h2,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
        RishButton.primary(
          title: 'Subscribe',
          enabled: true,
          isLoading: false,
          action: () {
            appNavigationService.go(path: AppRoutes.paywall.path);
          },
        ),
      ],
    );
  }
}
