import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/core/extensions/page_controller_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/settings/domain/other_legal_texts_repo.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'widgets/calories_widget.dart';
part 'widgets/health_metrics_widget.dart';
part 'widgets/macros_breakdown_widget.dart';
part 'widgets/meal_plan_widget.dart';
part 'widgets/calendar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    super.key,
  });
  final PageController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController pageController;
  bool isLoading = false;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }

  void _resetPageController() {
    final currentPage = pageController.page?.round() ?? 0;
    pageController.jumpToPage(currentPage);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем состояние WhoopBloc при изменении страницы
    if (oldWidget.controller.page != widget.controller.page) {
      final currentDay = userBloc.state.days.reversed
          .toList()[widget.controller.page?.round() ?? 0];
      whoopBloc.add(WhoopUpdateCurrentDay(day: currentDay));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      bloc: userBloc,
      listener: (context, state) {
        if (state.status == Status.success) {
          _resetPageController();
        }
      },
      builder: (context, state) {
        // print(state.user.daysIds);
        return PageView.builder(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          reverse: true,
          itemCount: state.days.length,
          itemBuilder: (context, index) {
            final days = state.days.reversed.toList();
            return _HomePageBody(
              homePageController: pageController,
              controller: widget.controller,
              isLoading: state.status == Status.loading,
              day: days[index],
              isLastPage: index == state.days.length - 1,
              isFirstPage: index == 0,
            );
          },
        );
      },
    );
  }
}

class _HomePageBody extends StatefulWidget {
  const _HomePageBody({
    required this.day,
    required this.controller,
    required this.homePageController,
    required this.isLoading,
    required this.isLastPage,
    required this.isFirstPage,
  });
  final DayEntity day;
  final PageController controller;
  final PageController homePageController;
  final bool isLoading;
  final bool isLastPage;
  final bool isFirstPage;

  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  Completer<void>? _refreshCompleter;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_HomePageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _onRefresh() {
    _refreshCompleter = Completer<void>();
    context
        .read<WhoopBloc>()
        .add(const WhoopCheckForRefresh(needsErrorSnack: true));
    return _refreshCompleter!.future;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhoopBloc, WhoopState>(
      listener: (context, state) {
        if ((state.status != Status.loading) &&
            _refreshCompleter != null &&
            !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete();
        }
      },
      builder: (BuildContext context, state) {
        return RefreshIndicator(
          color: RishColors.primary,
          backgroundColor: RishColors.stroke,
          displacement: 50,
          onRefresh: () async {
            if (state.status == Status.loading) return;
            await _onRefresh();
          },
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              _CalendarWidget(widget: widget),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Calories',
                    style: context.styles.h3,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async => RishiDialog.infoPopup(
                      context,
                      LegalTextsRepo().infoPopup,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 30,
                      color: RishColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _CaloriesWidget(
                day: widget.day,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    "Today's macros goal",
                    style: context.styles.h3,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async => RishiDialog.infoPopup(
                      context,
                      'Your daily consumption goal of calories is broken up into its macronutrient constituents of proteins, carbs, and fats. This gives you individualised targets for each macronutrient, and they sum up to your daily calorie consumption goal.',
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 30,
                      color: RishColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _MacrosBreakdownWidget(
                isToday: widget.day.isToday,
                day: widget.day,
              ),
              SizedBox(height: 20.h),
              Text(
                'Health metrics',
                style: context.styles.h3,
              ),
              SizedBox(height: 12.h),
              _HealthMetricsWidget(
                health: widget.day.healthMetrics,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Meal plan',
                    style: context.styles.h3,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async => RishiDialog.infoPopup(
                      context,
                      'Cooking instructions & ingredients for each meal are provided in the meal landing card and you can ask for more detail in the AI chat. You may also replace any ONE meal for an alternative, ONCE per day, if you wish to.',
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 30,
                      color: RishColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              BlocBuilder<WhoopBloc, WhoopState>(
                bloc: whoopBloc,
                builder: (context, state) {
                  // print(state.day.mealPlanEntity);
                  return _MealPlanWidget(
                    enoughRequests: chatBloc.state.requestsLeft != 0,
                    controller: widget.controller,
                    isToday: widget.day.isToday,
                    plan: widget.day.isToday
                        ? state.day.mealPlanEntity
                        : widget.day.mealPlanEntity,
                    ifNotTodayNeedsCreatePlan:
                        widget.day.cycleId == state.day.cycleId,
                  );
                },
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    '5-day Meal Plan Prep',
                    style: context.styles.h3,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async => RishiDialog.infoPopup(
                      context,
                      'When you choose to do a 5-day meal prep, the combination of meals you pick will apply to all 5 days. If you choose to skip breakfast, then you will not see a breakfast option across all 5 days.',
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 30,
                      color: RishColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              BlocBuilder<WeekPlanBloc, WeekPlanState>(
                bloc: weekPlanBloc,
                builder: (context, state) {
                  return RishButton.primary(
                    title: '5-day meal prep',
                    enabled: true,
                    isLoading: false,
                    action: () async {
                      await widget.controller.rAnimate(1);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RishColors.formBackgroun,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: child,
      ),
    );
  }
}
