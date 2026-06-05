import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/home_page_controller/home_page_controller_service_impl.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/banner_ad_widget.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/presentation/bloc/chat_bloc.dart'
    show ChatDeleteMealPlan, chatBloc;
import 'package:rishai/features/chat/presentation/chat_page.dart';
import 'package:rishai/features/food_diary/presentation/food_diary_presentation/food_diary_page.dart';
import 'package:rishai/features/home/presentation/bottom_navigation.dart';
import 'package:rishai/features/home/presentation/home_page/home_page.dart';
import 'package:rishai/features/home/presentation/widgets/data_sync_status_banner.dart';
import 'package:rishai/features/settings/presentation/settings_page.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
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

  // ┌─────────────────────────────────────────────────────────┐
  // │ Отслеживание последней показанной страницы для         │
  // │ предотвращения повторного показа диалога подписки       │
  // └─────────────────────────────────────────────────────────┘
  int? _lastShownSubscriptionDialogPage;

  // ┌─────────────────────────────────────────────────────────┐
  // │ Timer для задержки показа диалога подписки              │
  // │ Позволяет отменить показ, если пользователь быстро     │
  // │ переключился на другую страницу                         │
  // └─────────────────────────────────────────────────────────┘
  Timer? _subscriptionDialogTimer;

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

    // ┌─────────────────────────────────────────────────────────┐
    // │ Подписываемся на изменения текущей страницы для        │
    // │ показа диалога подписки при открытии страниц 1 или 2    │
    // │ для бесплатных пользователей                            │
    // └─────────────────────────────────────────────────────────┘
    homePageControllerService.currentPageNotifier.addListener(_onPageChanged);

    WidgetsBinding.instance.addObserver(this);
    // t = Timer.periodic(const Duration(minutes: 10), (t) {
    //   whoopBloc.add(const WhoopCheckForRefresh(needsErrorSnack: false));
    // });
  }

  @override
  void dispose() {
    // ┌─────────────────────────────────────────────────────────┐
    // │ Отменяем таймер показа диалога, если он активен        │
    // └─────────────────────────────────────────────────────────┘
    _subscriptionDialogTimer?.cancel();
    _subscriptionDialogTimer = null;
    // ┌─────────────────────────────────────────────────────────┐
    // │ Отписываемся от изменений текущей страницы               │
    // └─────────────────────────────────────────────────────────┘
    homePageControllerService.currentPageNotifier
        .removeListener(_onPageChanged);
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

  /// ┌─────────────────────────────────────────────────────────┐
  /// │ Обработчик изменения страницы                          │
  /// │                                                         │
  /// │ Показывает диалог подписки при открытии страниц 1 или 2│
  /// │ для бесплатных пользователей.                          │
  /// │                                                         │
  /// │ Для страницы 1 (5 day meal prep):                      │
  /// │ - Если у пользователя НЕТ планов питания - попап        │
  /// │   показывается сразу при открытии экрана                │
  /// │ - Если у пользователя ЕСТЬ планы питания - попап       │
  /// │   НЕ показывается при открытии, только при нажатии     │
  /// │   на кнопку "Create new prep"                           │
  /// │                                                         │
  /// │ Для страницы 2 (чат): попап показывается всегда         │
  /// │                                                         │
  /// │ Диалог показывается только один раз при открытии        │
  /// │ каждой страницы.                                       │
  /// │                                                         │
  /// │ Использует задержку и проверку текущей страницы перед  │
  /// │ показом, чтобы избежать показа диалога на неправильной  │
  /// │ странице при быстром переключении между вкладками.      │
  /// └─────────────────────────────────────────────────────────┘
  void _onPageChanged() {
    if (!mounted) return;

    final currentPage = homePageControllerService.currentPageNotifier.value;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Отменяем предыдущий таймер, если он активен,           │
    // │ чтобы избежать показа диалога на неправильной странице  │
    // │ при быстром переключении между вкладками                │
    // └─────────────────────────────────────────────────────────┘
    _subscriptionDialogTimer?.cancel();
    _subscriptionDialogTimer = null;

    // ┌─────────────────────────────────────────────────────────┐
    // │ Проверяем, что это страница 1 (5 day meal prep) или 2    │
    // │ (чат), и что диалог еще не показывался для этой страницы│
    // └─────────────────────────────────────────────────────────┘
    if ((currentPage == 1 || currentPage == 2) &&
        _lastShownSubscriptionDialogPage != currentPage) {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Проверяем статус подписки пользователя                  │
      // └─────────────────────────────────────────────────────────┘
      if (!adapty.isActive) {
        // ┌─────────────────────────────────────────────────────────┐
        // │ Для страницы 1 (5 day meal prep) проверяем наличие      │
        // │ планов питания. Если планы есть - не показываем попап   │
        // │ при открытии экрана (попап будет показан только при     │
        // │ нажатии на кнопку "Create new prep")                    │
        // └─────────────────────────────────────────────────────────┘
        if (currentPage == 1) {
          // Получаем текущее состояние WeekPlanBloc
          final weekPlanState = weekPlanBloc.state;

          // Проверяем, есть ли у пользователя планы питания
          final hasMealPlans = weekPlanState.allWeekPlans.isNotEmpty;

          // Если планы есть - не показываем попап при открытии экрана
          if (hasMealPlans) {
            // Пользователь может просматривать существующие планы,
            // попап будет показан только при попытке создать новый
            return;
          }
        }

        // ┌─────────────────────────────────────────────────────────┐
        // │ Сохраняем номер страницы, для которой планируем показать│
        // │ диалог, чтобы использовать его для проверки позже       │
        // └─────────────────────────────────────────────────────────┘
        final targetPage = currentPage;

        // ┌─────────────────────────────────────────────────────────┐
        // │ Формируем текст диалога в зависимости от страницы      │
        // └─────────────────────────────────────────────────────────┘
        final String dialogBody;
        if (targetPage == 1) {
          dialogBody =
              'Access to 5-day meal prep is available only for subscribers.';
        } else {
          dialogBody =
              'Access to AI-Coach chat is available only for subscribers.';
        }

        // ┌─────────────────────────────────────────────────────────┐
        // │ Устанавливаем таймер с задержкой перед показом диалога│
        // │ Задержка позволяет странице полностью отобразиться и   │
        // │ предотвращает показ диалога при быстром переключении    │
        // └─────────────────────────────────────────────────────────┘
        _subscriptionDialogTimer = Timer(const Duration(milliseconds: 500), () {
          // ┌─────────────────────────────────────────────────────────┐
          // │ Проверяем, что виджет все еще смонтирован               │
          // └─────────────────────────────────────────────────────────┘
          if (!mounted) return;

          // ┌─────────────────────────────────────────────────────────┐
          // │ КРИТИЧЕСКАЯ ПРОВЕРКА: Убеждаемся, что мы все еще      │
          // │ находимся на той же странице, для которой планировали  │
          // │ показать диалог. Это предотвращает показ диалога на    │
          // │ неправильной странице при быстром переключении         │
          // └─────────────────────────────────────────────────────────┘
          final currentPageAfterDelay =
              homePageControllerService.currentPageNotifier.value;

          if (currentPageAfterDelay != targetPage) {
            // ┌─────────────────────────────────────────────────────────┐
            // │ Пользователь переключился на другую страницу,          │
            // │ не показываем диалог                                    │
            // └─────────────────────────────────────────────────────────┘
            return;
          }

          // ┌─────────────────────────────────────────────────────────┐
          // │ Дополнительная проверка статуса подписки перед показом │
          // │ (на случай, если подписка была активирована за это время)│
          // └─────────────────────────────────────────────────────────┘
          if (adapty.isActive) {
            return;
          }

          // ┌─────────────────────────────────────────────────────────┐
          // │ Для страницы 1 дополнительно проверяем наличие планов  │
          // │ после задержки (на случай, если планы загрузились)      │
          // └─────────────────────────────────────────────────────────┘
          if (targetPage == 1) {
            final weekPlanStateAfterDelay = weekPlanBloc.state;
            final hasMealPlansAfterDelay =
                weekPlanStateAfterDelay.allWeekPlans.isNotEmpty;

            // Если планы появились за время задержки - не показываем попап
            if (hasMealPlansAfterDelay) {
              return;
            }
          }

          // ┌─────────────────────────────────────────────────────────┐
          // │ Все проверки пройдены, показываем диалог подписки      │
          // └─────────────────────────────────────────────────────────┘
          _lastShownSubscriptionDialogPage = targetPage;

          RishiDialog.showSubscriptionRequiredDialog(
            context,
            body: dialogBody,
            onUpgrade: () {
              // ┌─────────────────────────────────────────────────────────┐
              // │ Переходим на экран paywall для обновления подписки      │
              // └─────────────────────────────────────────────────────────┘
              appNavigationService.go(path: AppRoutes.paywall.path);
            },
          );
        });
      }
    } else if (currentPage != 1 && currentPage != 2) {
      // ┌─────────────────────────────────────────────────────────┐
      // │ Сбрасываем отслеживание при переходе на другие страницы │
      // │ чтобы диалог снова показывался при возврате               │
      // └─────────────────────────────────────────────────────────┘
      _lastShownSubscriptionDialogPage = null;
    }
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
                  // [SyncBanner] Плашка WHOOP sync только на домашнем табе.
                  if (currentPage == 0)
                    BlocBuilder<WhoopBloc, WhoopState>(
                      bloc: whoopBloc,
                      buildWhen: (previous, current) {
                        if (previous is WhoopMainState &&
                            current is WhoopMainState) {
                          return previous.syncBannerPhase !=
                                  current.syncBannerPhase ||
                              previous.lastSyncedAt != current.lastSyncedAt;
                        }
                        return true;
                      },
                      builder: (context, whoopState) {
                        if (whoopState is! WhoopMainState) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          top: 60.h + 8.h,
                          left: 16.w,
                          right: 16.w,
                          child: DataSyncStatusBanner(
                            phase: whoopState.syncBannerPhase,
                            lastSyncedAt: whoopState.lastSyncedAt,
                          ),
                        );
                      },
                    ),
                  // Overlay с блюром и кнопками
                  if (_isOverlayVisible)
                    _FabOverlayWidget(
                      overlayAnimation: _overlayAnimation,
                      onHideOverlay: _hideOverlay,
                    ),
                  // ┌─────────────────────────────────────────────────────────┐
                  // │ Баннерная реклама слева от FAB                        │
                  // │ Отображается только на страницах, где есть FAB        │
                  // │ (не на страницах 1 и 2)                               │
                  // │ Размещается над bottomNavigationBar, слева от FAB      │
                  // └─────────────────────────────────────────────────────────┘
                  if ((currentPage != 4) && !adapty.isActive)
                    Positioned(
                      left: 0.w,
                      bottom: 0,
                      right:
                          (currentPage == 1 || currentPage == 2) ? 0.w : 60.w,
                      // bottom: kBottomNavigationBarHeight + 8.h, // Высота bottomNavigationBar + небольшой отступ
                      child: BannerAdWidget(
                        androidAdUnitId: 'ca-app-pub-3940256099942544/6300978111',
                        iosAdUnitId: 'ca-app-pub-3940256099942544/2934735716',
                      ),
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
