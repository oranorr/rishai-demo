import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/page_controller_extension.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/chat/presentation/chat_page.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late PageController pageController;
  final ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    pageController = PageController(initialPage: currentPageNotifier.value)
      ..addListener(() {
        final newPage = pageController.page?.round() ?? 0;
        if (newPage != currentPageNotifier.value) {
          currentPageNotifier.value = newPage;
        }
      });
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

  @override
  Widget build(BuildContext context) {
    // testMealsGroup();
    // print(userBloc.state.user);
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        List<Widget> bodies = [
          HomePage(controller: pageController),
          const WeekPlanScreen(),
          ChatPage(controller: pageController),
          const SettingsPage(),
        ];

        return RishScaffold(
          implyLeading: false,
          needsAppBar: false,
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
          child: Padding(
            padding: EdgeInsets.only(top: 60.h),
            child: PageView.builder(
              controller: pageController,
              itemCount: bodies.length,
              itemBuilder: (context, index) {
                return bodies[index];
              },
            ),
          ),
        );
        // }
      },
    );
  }
}
