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
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
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
  int currentPage = 2;

  @override
  void initState() {
    pageController = PageController(initialPage: currentPage)
      ..addListener(listener);
    WidgetsBinding.instance.addObserver(this);
    // t = Timer.periodic(const Duration(minutes: 10), (t) {
    //   whoopBloc.add(const WhoopCheckForRefresh(needsErrorSnack: false));
    // });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   whoopBloc.add(const WhoopCheckForRefresh(needsErrorSnack: false));
    // }
  }

  void listener() {
    setState(() {
      currentPage = pageController.page!.toInt();
    });
    // print(pageController);
  }

  void testMealsGroup() {
    final days = userBloc.state.days;
    final meals = DayEntity.getMealHistory(days, daysLimit: 20);
    log(meals.toString());
  }

  @override
  Widget build(BuildContext context) {
    // testMealsGroup();
    return BlocBuilder<WhoopBloc, WhoopState>(
      bloc: whoopBloc,
      builder: (context, state) {
        List<Widget> bodies = [
          ChatPage(controller: pageController),
          const WeekPlanScreen(),
          HomePage(controller: pageController),
          const SettingsPage(),
        ];

        return RishScaffold(
          implyLeading: false,
          needsAppBar: false,
          bottomNavigationBar: RishiBottonNavigationBar(
            currentPage: currentPage,
            jump: (page) async {
              await pageController.rAnimate(page);
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
