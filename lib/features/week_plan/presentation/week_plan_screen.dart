import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/core/services/pdf/pdf_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/domain/entities/week_plan_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:rishai/features/week_plan/presentation/widgets/filters_popup.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

part 'widgets/loading_widget.dart';
part 'widgets/servings_selector.dart';
part 'week_plan_mixin.dart';
part 'widgets/week_plan_widget.dart';
part 'widgets/week_plan_content.dart';
part 'widgets/week_landing_page.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  // @override
  // int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Трекинг просмотра 5-дневного плана питания
    analytics.logScreenView(
      screenName: 'week_plan_screen',
      screenClass: 'WeekPlanScreen',
    );
    analytics.logCustomEvent(
      name: 'view_5days_meal_plan',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        // Обрабатываем состояние загрузки
        if (state.isLoading) {
          return const _LoadingState();
        }

        // Возвращаем WeekLandingPage с правильными планами
        return WeekLandingPage(
          plans: state.filter != null
              ? state.displayWeekPlans.reversed.toList()
              : state.allWeekPlans.reversed.toList(),
        );
        // if (decide(state)) {
        //   final plans = state.weekPlans
        //       .where((plan) => plan != null)
        //       .map((plan) => plan!)
        //       .toList();
        //   return _WeekPlanContent(
        //     plans: plans,
        //     selectedIndex: selectedIndex,
        //     currentPage: currentPage,
        //     pageController: pageController,
        //     daysController: daysController,
        //     onSelectedIndexChanged: (index) {
        //       setState(() {
        //         selectedIndex = index;
        //       });
        //     },
        //     onCurrentPageChanged: (page) {
        //       setState(() {
        //         currentPage = page;
        //       });
        //     },
        //     onClearPressed: () {
        //       weekPlanBloc.add(const WeekPlanClear());
        //     },
        //     findTargetPlan: _findTargetPlan,
        //     collectAllIngredients: _collectAllIngredients,
        //   );
        // } else {
        //   return const _ServingsSelector();
        // }
      },
    );
  }
}
