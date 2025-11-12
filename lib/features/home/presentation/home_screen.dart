import 'dart:developer';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart'
    show ChatDeleteMealPlan, chatBloc;
import 'package:rishai/features/chat/presentation/chat_page.dart';
import 'package:rishai/features/food_diary/presentation/food_diary_presentation/food_diary_page.dart';
import 'package:rishai/features/home/presentation/bottom_navigation.dart';
import 'package:rishai/features/home/presentation/home_page/home_page.dart';
import 'package:rishai/features/settings/presentation/settings_page.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/week_plan_screen.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_state.dart';

part 'home_page/widgets/fab_screen_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  /// PageController для управления переключением страниц
  /// Регистрируется в сервисе для доступа извне
  late PageController pageController;

  // Состояние для управления overlay с блюром
  bool _isOverlayVisible = false;
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();

    // Инициализируем PageController (начинаем с первой страницы)
    pageController = PageController();

    // Регистрируем PageController в сервисе для доступа извне
    // Сервис обновит currentPageNotifier через listener при изменениях страницы
    homePageControllerService.registerPageController(pageController);

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
  }

  @override
  void dispose() {
    // Отменяем регистрацию PageController в сервисе
    homePageControllerService.unregisterPageController();
    // Освобождаем ресурсы PageController
    pageController.dispose();
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
          valueListenable: homePageControllerService.currentPageNotifier,
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
                valueListenable: homePageControllerService.currentPageNotifier,
                builder: (context, currentPage, _) {
                  return RishiBottonNavigationBar(
                    currentPage: currentPage,
                    jump: (page) async {
                      // ┌─────────────────────────────────────────────────────────┐
                      // │ Закрываем overlay от FAB при нажатии на кнопки         │
                      // │ bottom navigation bar                                  │
                      // └─────────────────────────────────────────────────────────┘
                      if (_isOverlayVisible) {
                        _hideOverlay();
                      }
                      // Используем метод сервиса для навигации
                      await homePageControllerService.navigateToPage(
                        page: page,
                      );
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
                  if (_isOverlayVisible)
                    _FabOverlayWidget(
                      overlayAnimation: _overlayAnimation,
                      onHideOverlay: _hideOverlay,
                    ),
                ],
              ),
            );
          },
        );
        // }
      },
    );
  }
}
