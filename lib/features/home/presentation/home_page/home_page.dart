import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:rishai/features/home/presentation/meal_screen.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/user/presentation/bloc/user_state.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'widgets/calendar_widget.dart';

part 'widgets/health_metrics_widget.dart';
part 'widgets/macros_breakdown_widget.dart';
part 'widgets/meal_plan_widget.dart';
part 'widgets/pivot_life_widget.dart';
part 'widgets/daily_wellness_widget.dart';

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
    _trackMealPlanView();
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

  void _trackMealPlanView() {
    // Проверяем, есть ли у пользователя план питания на сегодня
    final hasMealPlan = whoopBloc.state.day.mealPlanEntity != null;

    // Трекинг просмотра страницы с 1-дневным планом питания
    analytics.logScreenView(
      screenName: 'home_screen_meal_plan',
      screenClass: 'HomePage',
    );

    if (hasMealPlan) {
      analytics.logCustomEvent(
        name: 'view_1day_meal_plan',
        parameters: {
          'meal_count': whoopBloc.state.day.mealPlanEntity?.meals.length ?? 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // test(userBloc.state.days.last);
    return BlocConsumer<UserBloc, UserState>(
      bloc: userBloc,
      listener: (context, state) {
        if (state.status == Status.success) {
          _resetPageController();
        }
      },
      builder: (context, userState) {
        // print(userState.days.last.dateTime);
        return BlocBuilder<WhoopBloc, WhoopState>(
          bloc: whoopBloc,
          builder: (context, whoopState) {
            // [FIX] Синхронизируем состояние загрузки между блоками
            // Считаем, что данные загружаются, если любой из блоков в состоянии загрузки
            final isLoading = userState.status == Status.loading ||
                whoopState.status == Status.loading;

            // [FIX] Обрабатываем случай, когда дни еще не загружены
            if (userState.days.isEmpty) {
              if (isLoading) {
                // Показываем индикатор загрузки, если дни еще загружаются
                return const Center(
                  child: CircularProgressIndicator(
                    color: RishColors.primary,
                  ),
                );
              } else {
                // Показываем сообщение об ошибке, если дни не загружены и загрузка не идет
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: RishColors.textSecondary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Data failed to load',
                        style: context.styles.h3,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Please, try to restart the app',
                        style: context.styles.regularMedium.copyWith(
                          color: RishColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
            }

            return PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              reverse: true,
              itemCount: userState.days.length,
              itemBuilder: (context, index) {
                final days = userState.days.reversed.toList();
                return _HomePageBody(
                  homePageController: pageController,
                  controller: widget.controller,
                  isLoading: isLoading,
                  day: days[index],
                  isLastPage: index == userState.days.length - 1,
                  isFirstPage: index == 0,
                );
              },
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

  Future<void> test() async {
    print('=== ТЕСТ НОВОЙ АРХИТЕКТУРЫ ===');

    final userId = userBloc.state.user.directusId;
    print('Тестирую для пользователя: $userId');

    try {
      // Тест 1: Получение всех дней пользователя
      final userDaysResult = await dayManager.getUserDays(userId: userId);
      userDaysResult.fold(
        (failure) => print('❌ Ошибка получения дней: ${failure.message}'),
        (days) => print('✅ Получено ${days.length} дней пользователя'),
      );

      // Тест 2: Получение последнего дня
      final lastDay = await dayManager.getLastUserDay(userId: userId);
      if (lastDay != null) {
        print('✅ Последний день: ${lastDay.dateTime}');
      } else {
        print('❌ Последний день не найден');
      }

      // Тест 3: Получение активного дня (текущий незавершенный цикл)
      final activeDay = await dayManager.getActiveDay(userId: userId);
      if (activeDay != null) {
        print(
          '✅ Найден активный день: cycleId=${activeDay.cycleId}, дата=${activeDay.dateTime}',
        );
      } else {
        print('❌ Активный день не найден');
      }

      print('=== ТЕСТ ЗАВЕРШЕН ===');
    } catch (e) {
      print('❌ Ошибка во время теста: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhoopBloc, WhoopState>(
      bloc:
          whoopBloc, // [FIX] Используем тот же экземпляр, что и в других местах
      listener: (context, state) {
        if ((state.status != Status.loading) &&
            _refreshCompleter != null &&
            !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete();
        }
      },
      // buildWhen: (previous, current) {
      // [buildWhen] Принудительно перестраиваем при изменении wellness entity
      // final wellnessChanged =
      //     previous.day.welnessEntity != current.day.welnessEntity;
      // final mealPlanChanged =
      //     previous.day.mealPlanEntity != current.day.mealPlanEntity;
      // final statusChanged = previous.status != current.status;

      // final shouldRebuild =
      //     wellnessChanged || mealPlanChanged || statusChanged;

      // dev.log(
      //   '[HomePage] buildWhen: wellness=$wellnessChanged, mealPlan=$mealPlanChanged, status=$statusChanged -> rebuild=$shouldRebuild',
      //   name: 'HomePage',
      // );

      // if (wellnessChanged) {
      //   dev.log(
      //     '[HomePage] Wellness изменилась: ${previous.day.welnessEntity?.welnessPercentage}% -> ${current.day.welnessEntity?.welnessPercentage}%',
      //     name: 'HomePage',
      //   );
      // }

      // return shouldRebuild;
      // },
      builder: (BuildContext context, state) {
        print(state.day.welnessEntity);
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
              const PivotLifeWidget(progress: 0.87),
              SizedBox(height: 20.h),
              DailyWellnessWidget(
                day: widget.day.isToday ? state.day : widget.day,
              ),
              // BlocBuilder<WhoopBloc, WhoopState>(
              //   builder: (context, whoopState) {
              //     return
              //   },
              // ),
              // Row(
              //   children: [
              //     Text(
              //       'Calories',
              //       style: context.styles.h3,
              //     ),
              //     const Spacer(),
              //     GestureDetector(
              //       onTap: () async => RishiDialog.infoPopup(
              //         context,
              //         LegalTextsRepo().infoPopup,
              //       ),
              //       child: const Icon(
              //         Icons.info_outline,
              //         size: 30,
              //         color: RishColors.primary,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 12.h),SizedBox(height: 20.h),
              SizedBox(height: 12.h),
              _HealthMetricsWidget(
                day: widget.day.isToday ? state.day : widget.day,
              ),
              SizedBox(height: 12.h),
              _MacrosBreakdownWidget(
                isToday: widget.day.isToday,
                day: widget.day.isToday ? state.day : widget.day,
              ),
              // SizedBox(height: 20.h),
              // Text(
              //   'Health metrics',
              //   style: context.styles.h3,
              // ),

              // SizedBox(height: 20.h),
              // Row(
              //   children: [
              //     Text(
              //       'Meal plan',
              //       style: context.styles.h3,
              //     ),
              //     const Spacer(),
              //     GestureDetector(
              //       onTap: () async => RishiDialog.infoPopup(
              //         context,
              //         'Cooking instructions & ingredients for each meal are provided in the meal landing card and you can ask for more detail in the AI chat. You may also replace any ONE meal for an alternative, ONCE per day, if you wish to.',
              //       ),
              //       child: const Icon(
              //         Icons.info_outline,
              //         size: 30,
              //         color: RishColors.primary,
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(height: 12.h),
              BlocBuilder<WhoopBloc, WhoopState>(
                bloc: whoopBloc,
                builder: (context, state) {
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
              // SizedBox(height: 20.h),
              // Row(
              //   children: [
              //     Text(
              //       '5-day Meal Plan Prep',
              //       style: context.styles.h3,
              //     ),
              //     const Spacer(),
              //     GestureDetector(
              //       onTap: () async => RishiDialog.infoPopup(
              //         context,
              //         'When you choose to do a 5-day meal prep, the combination of meals you pick will apply to all 5 days. If you choose to skip breakfast, then you will not see a breakfast option across all 5 days.',
              //       ),
              //       child: const Icon(
              //         Icons.info_outline,
              //         size: 30,
              //         color: RishColors.primary,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 12.h),
              // BlocBuilder<WeekPlanBloc, WeekPlanState>(
              //   bloc: weekPlanBloc,
              //   builder: (context, state) {
              //     return RishButton.primary(
              //       title: '5-day meal prep',
              //       enabled: true,
              //       isLoading: false,
              //       action: () async {
              //         await widget.controller.rAnimate(1);
              //       },
              //     );
              //   },
              // ),
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
