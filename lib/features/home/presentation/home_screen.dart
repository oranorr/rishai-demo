import 'dart:developer';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/page_controller_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart'
    show ChatDeleteMealPlan, chatBloc;
import 'package:rishai/features/chat/presentation/chat_page.dart';
import 'package:rishai/features/food_diary/presentation/diary_entry_page.dart';
import 'package:rishai/features/food_diary/presentation/food_diary_page.dart';
import 'package:rishai/features/home/presentation/bottom_navigation.dart';
import 'package:rishai/features/home/presentation/home_page/home_page.dart';
import 'package:rishai/features/settings/presentation/settings_page.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/week_plan_screen.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late PageController pageController;
  final ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(0);

  // Состояние для управления overlay с блюром
  bool _isOverlayVisible = false;
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    pageController = PageController(initialPage: currentPageNotifier.value)
      ..addListener(() {
        final newPage = pageController.page?.round() ?? 0;
        if (newPage != currentPageNotifier.value) {
          currentPageNotifier.value = newPage;
        }
      });

    // Инициализация анимации для overlay
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addObserver(this);
    // t = Timer.periodic(const Duration(minutes: 10), (t) {
    //   whoopBloc.add(const WhoopCheckForRefresh(needsErrorSnack: false));
    // });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPageNotifier.dispose();
    _overlayAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   whoopBloc.add(const WhoopCheckForRefresh(needsErrorSnack: false));
    // }
  }

  void testMealsGroup() {
    final days = userBloc.state.days;
    for (final day in days) {
      log('ID: ${day.cycleId}, date: ${day.dateTime}');
    }
    final meals = DayEntity.getMealHistory(days, daysLimit: 20);
    log(meals.toString());
  }

  /// Показать overlay с блюром и кнопками
  void _showOverlay() {
    setState(() {
      _isOverlayVisible = true;
    });
    _overlayAnimationController.forward();
  }

  /// Скрыть overlay с блюром и кнопками
  void _hideOverlay() {
    _overlayAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isOverlayVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        List<Widget> bodies = [
          HomePage(controller: pageController),
          const WeekPlanScreen(),
          ChatPage(controller: pageController),
          const FoodDiaryPage(),
          const SettingsPage(),
        ];

        return ValueListenableBuilder<int>(
          valueListenable: currentPageNotifier,
          builder: (context, currentPage, _) {
            return RishScaffold(
              implyLeading: false,
              needsAppBar: false,
              floatingActionButton: currentPage == 1 || currentPage == 2
                  ? null
                  : FloatingActionButton(
                      shape: const CircleBorder(),
                      onPressed: _showOverlay,
                      backgroundColor: RishColors.primary,
                      child: Icon(
                        Icons.add,
                        size: 24.sp,
                        color: Colors.black,
                      ),
                    ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: ValueListenableBuilder<int>(
                valueListenable: currentPageNotifier,
                builder: (context, currentPage, _) {
                  return RishiBottonNavigationBar(
                    currentPage: currentPage,
                    jump: (page) async {
                      await pageController.rAnimate(page);
                    },
                  );
                },
              ),
              child: Stack(
                children: [
                  // Основной контент
                  Padding(
                    padding: EdgeInsets.only(top: 60.h),
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: bodies.length,
                      itemBuilder: (context, index) {
                        return bodies[index];
                      },
                    ),
                  ),
                  // Overlay с блюром и кнопками
                  if (_isOverlayVisible) _buildBlurOverlay(context),
                ],
              ),
            );
          },
        );
        // }
      },
    );
  }

  Widget _buildBlurOverlay(BuildContext context) {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayAnimation.value,
          child: GestureDetector(
            onTap: _hideOverlay, // Закрытие при тапе на фон
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10.0 * _overlayAnimation.value,
                sigmaY: 10.0 * _overlayAnimation.value,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3 * _overlayAnimation.value),
                child: Center(
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * _overlayAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Spacer(),
                        RishButton.primary(
                          title: 'Add meal to your diary',
                          enabled: true,
                          isLoading: false,
                          action: () {
                            appNavigationService.push(
                              path: AppRoutes.diaryEntryPage.path,
                            );
                            _hideOverlay();
                            // TODO: Добавить логику для добавления еды
                            log('[_buildBlurOverlay] Добавить еду нажата');
                          },
                        ),
                        SizedBox(height: 8.h),
                        if (kDebugMode) ...[
                          RishButton.primary(
                            title: '[DEBUG]: REMOVE MEAL PLAN FOR TODAY.',
                            enabled: true,
                            isLoading: false,
                            action: () {
                              chatBloc.add(ChatDeleteMealPlan());
                              _hideOverlay();
                            },
                          ),
                          SizedBox(height: 8.h),
                        ],
                        RishButton.primary(
                          title: 'Create new meal plan  ',
                          enabled: true,
                          isLoading: false,
                          action: () async {
                            await pageController.rAnimate(2);
                            _hideOverlay();
                          },
                        ),
                        SizedBox(height: 8.h),
                        RishButton.primary(
                          title: '5-day meal prep',
                          enabled: true,
                          isLoading: false,
                          action: () async {
                            await pageController.rAnimate(1);
                            _hideOverlay();
                          },
                        ),
                        SizedBox(height: 150.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
