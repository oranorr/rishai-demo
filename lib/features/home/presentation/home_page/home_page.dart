import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/page_controller_extension.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_state.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

import '../../../chat/domain/entities/meal_plan_entity.dart';

part 'widgets/calories_widget.dart';
part 'widgets/health_metrics_widget.dart';
part 'widgets/macros_breakdown_widget.dart';
part 'widgets/meal_plan_widget.dart';
part 'widgets/calendar_widget.dart';

class HomePage extends StatefulWidget {
  final PageController controller;
  const HomePage({
    super.key,
    required this.controller,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController pageController;

  @override
  void initState() {
    pageController = PageController();

    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        // userBloc.createMockData(state.days.first);
        return PageView.builder(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          reverse: true,
          itemCount: state.days.length,
          itemBuilder: (context, index) {
            return _HomePageBody(
              homePageController: pageController,
              controller: widget.controller,
              isLoading: state.status == Status.loading,
              day: state.days.reversed.toList()[index],
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
  final DayEntity day;
  final PageController controller;
  final PageController homePageController;
  final bool isLoading;
  final bool isLastPage;
  final bool isFirstPage;
  const _HomePageBody({
    super.key,
    required this.day,
    required this.controller,
    required this.homePageController,
    required this.isLoading,
    required this.isLastPage,
    required this.isFirstPage,
  });

  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  @override
  Widget build(BuildContext context) {
    // whoopBloc.testAlgo();
    // userBloc.createMockData(widget.day);
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        _CalendarWidget(widget: widget),
        SizedBox(height: 20.h),
        Text(
          'Calories',
          style: context.styles.h3,
        ),
        SizedBox(height: 12.h),
        _CaloriesWidget(
          day: widget.day,
        ),
        SizedBox(height: 20.h),
        Text(
          'Today\'s macros goal',
          style: context.styles.h3,
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
        Text(
          'Meal plan',
          style: context.styles.h3,
        ),
        SizedBox(height: 12.h),
        BlocBuilder<ChatBloc, ChatState>(
          bloc: chatBloc,
          builder: (context, state) {
            // print(widget.day.mealPlanEntity);
            return _MealPlanWidget(
              enoughRequests: state.requestsLeft != 0,
              controller: widget.controller,
              isToday: widget.day.isToday,
              plan: widget.day.isToday
                  ? state.mealPlan
                  : widget.day.mealPlanEntity,
            );
          },
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({
    super.key,
    required this.child,
  });

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
