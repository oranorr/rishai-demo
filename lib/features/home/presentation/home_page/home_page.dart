import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/date_time_extension.dart';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/analytics/analytics_repository_impl.dart';
import 'package:rishai/core/services/day_manager/day_manager_impl.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
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

  /// Один раз пробуем [UserGetDays], если попали на home без прохода redirect/init (например старый back).
  bool _requestedDaysBootstrap = false;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
    _trackMealPlanView();
  }

  /// Синхронизируем [PageController] после обновления дней в [UserBloc].
  ///
  /// [BlocConsumer.listener] вызывается **до** перестроения [builder]: при первом
  /// появлении дней (bootstrap с пустого списка) [PageView] ещё не смонтирован —
  /// чтение [PageController.page] падает с assert. Поэтому либо делаем [jumpToPage]
  /// сразу при [PageController.hasClients], либо один раз на следующий кадр после
  /// того, как [PageView.builder] уже привязал контроллер.
  void _resetPageController() {
    void jumpToCurrent() {
      if (!mounted || !pageController.hasClients) return;
      final currentPage = pageController.page?.round() ?? 0;
      pageController.jumpToPage(currentPage);
    }

    if (pageController.hasClients) {
      jumpToCurrent();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToCurrent());
    }
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
        if (state.days.isNotEmpty) {
          _requestedDaysBootstrap = false;
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
              final syncBannerActive =
                  whoopState.syncBannerPhase == WhoopSyncBannerPhase.catchingUp;
              if (isLoading && !syncBannerActive) {
                // Показываем индикатор загрузки, если дни еще загружаются
                return const Center(
                  child: CircularProgressIndicator(
                    color: RishColors.primary,
                  ),
                );
              } else if (isLoading && syncBannerActive) {
                // [SyncBanner] Плашка на HomeScreen — не блокируем весь экран.
                return const SizedBox.shrink();
              } else if (userState.user.directusId != '-1' &&
                  !_requestedDaysBootstrap &&
                  userState.status != Status.loading &&
                  whoopState.status != Status.loading) {
                // [HomeDaysBootstrap] Только если init не запустил загрузку уже.
                _requestedDaysBootstrap = true;
                log(
                  '[HomePage] Пустой список дней при открытии home — запускаем UserGetDays '
                  '(whoop day cycleId=${whoopBloc.state.day.cycleId})',
                  name: 'HomePage',
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  userBloc.add(UserGetDays(newDay: whoopBloc.state.day));
                });
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

  /// Минимальный overscroll вниз (логические px) для pull-to-sync.
  /// Обычный скролл и лёгкий bounce на верхушке не должны дергать WHOOP refresh.
  static const double _strongPullSyncThreshold = 100;

  /// Пиковое «усиленное» потягивание в текущем жесте (только drag пальцем).
  ///
  /// КРИТИЧНО: это именно ПИК (только растёт), а не текущее смещение. На iOS
  /// после отпускания идёт ballistic spring-back, и если бы мы тут вычитали
  /// обратный ход — пик «съедался» бы до того, как [ScrollEndNotification]
  /// его прочитает (та самая регрессия «надо тянуть как бешеный»).
  double _dragPullExtent = 0;

  /// Накопленный overscroll текущего drag для Android ([ClampingScrollPhysics]),
  /// где [ScrollMetrics.pixels] держится на 0 и тянуть надо считать по дельтам.
  double _androidPullAccum = 0;

  /// ScrollController для управления прокруткой списка
  /// Регистрируется в сервисе для доступа извне
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Инициализируем ScrollController
    _scrollController = ScrollController();
    // Регистрируем контроллер в сервисе для доступа извне
    homePageControllerService.registerScrollController(_scrollController);
  }

  @override
  void didUpdateWidget(_HomePageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // Отменяем регистрацию контроллера в сервисе
    homePageControllerService.unregisterScrollController();
    // Освобождаем ресурсы ScrollController
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() {
    _refreshCompleter = Completer<void>();
    context
        .read<WhoopBloc>()
        .add(const WhoopCheckForRefresh(needsErrorSnack: true));
    return _refreshCompleter!.future;
  }

  /// [StrongPullSync] Sync только после явного длинного pull-down на верхушке списка.
  /// Игнорируем ballistic overscroll и обычную прокрутку контента.
  ///
  /// iOS: overscroll виден через отрицательные [ScrollMetrics.pixels] (bounce).
  /// Android: [ClampingScrollPhysics] держит pixels на 0 — overscroll приходит
  /// через [OverscrollNotification] (как в Material [RefreshIndicator]).
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      // Новый жест — сбрасываем пик и аккумулятор.
      _dragPullExtent = 0;
      _androidPullAccum = 0;
      return false;
    }

    final isAtTop = notification.metrics.extentBefore == 0;
    final isVerticalListDown =
        notification.metrics.axisDirection == AxisDirection.down;

    // iOS ([BouncingScrollPhysics]): overscroll виден как отрицательные pixels.
    // Учитываем ТОЛЬКО кадры реального drag пальцем (dragDetails != null),
    // чтобы ballistic spring-back после отпускания не трогал пик.
    if (notification is ScrollUpdateNotification &&
        isAtTop &&
        isVerticalListDown) {
      final isFingerDrag = notification.dragDetails != null;
      if (isFingerDrag && notification.metrics.pixels < 0) {
        _dragPullExtent = max(
          _dragPullExtent,
          -notification.metrics.pixels,
        );
      }
      return false;
    }

    // Android ([ClampingScrollPhysics]): pixels держится на 0 — overscroll
    // приходит только сюда. Копим дельты текущего drag и фиксируем пик.
    if (notification is OverscrollNotification &&
        isAtTop &&
        isVerticalListDown) {
      final isFingerDrag = notification.dragDetails != null;
      if (isFingerDrag) {
        // overscroll < 0 при тяге за верхнюю границу (вниз).
        _androidPullAccum = max(0, _androidPullAccum - notification.overscroll);
        _dragPullExtent = max(_dragPullExtent, _androidPullAccum);
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      final pullExtent = _dragPullExtent;
      _dragPullExtent = 0;
      _androidPullAccum = 0;
      if (pullExtent >= _strongPullSyncThreshold &&
          whoopBloc.state.status != Status.loading) {
        unawaited(_onRefresh());
      }
    }

    return false;
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

      // Тест 3: Получение текущего дня (backend current day)
      final currentDayResult = await dayManager.getLastDayWithCycleStatus(
        userId: userId,
        checkCycleStatus: false,
      );
      final activeDay = currentDayResult?.day;
      if (activeDay != null) {
        print(
          '✅ Найден текущий день: cycleId=${activeDay.cycleId}, дата=${activeDay.dateTime}',
        );
      } else {
        print('❌ Текущий день не найден');
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
      builder: (BuildContext context, state) {
        return NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: ListView(
            controller: _scrollController,
            // [StrongPullSync] Как у RefreshIndicator — overscroll возможен даже при коротком контенте.
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              _CalendarWidget(widget: widget),
              SizedBox(height: 20.h),
              BlocBuilder<UserBloc, UserState>(
                bloc: userBloc,
                builder: (context, state) {
                  return PivotLifeWidget(
                    progress: state.user.pivotLifeScore?.score ?? 0,
                  );
                },
              ),
              SizedBox(height: 20.h),
              // [FIX] Используем whoopState.day для сегодняшнего дня, так как он содержит
              // актуальные данные из Directus (включая welnessEntity), которые мы обновили
              // при входе. Для других дней используем widget.day из UserBloc
              // Добавляем key для принудительного обновления виджета при изменении day
              DailyWellnessWidget(
                key: ValueKey(
                    'wellness_${widget.day.isToday ? state.day.directusId : widget.day.directusId}_${widget.day.welnessEntity?.consumedMeals.length ?? 0}'),
                day: widget.day.isToday ? state.day : widget.day,
              ),
              SizedBox(height: 12.h),
              _HealthMetricsWidget(
                day: widget.day.isToday ? state.day : widget.day,
              ),
              SizedBox(height: 12.h),
              _MacrosBreakdownWidget(
                isToday: widget.day.isToday,
                day: widget.day.isToday ? state.day : widget.day,
              ),
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
