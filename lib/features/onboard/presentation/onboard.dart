// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/features/onboard/data/onboard_repository.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  late PageController textController;
  late PageController imageController;
  int currentPage = 0;
  @override
  void initState() {
    textController = PageController();
    imageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> buttonAction(BuildContext context) async {
    if (currentPage != 2) {
      await textController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.linear,
      );
      await imageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.linear,
      );
      setState(() {
        currentPage = currentPage + 1;
      });
    } else {
      await prefsRepo.watchedOnboard();
      appNavigationService.go(path: AppRoutes.login.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = OnboardRepository.data;
    return RishScaffold(
      child: LayoutBuilder(
        builder: (context, constrains) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constrains.maxWidth,
              maxHeight: constrains.maxHeight,
              minHeight: constrains.minHeight,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 374.h,
                  child: PageView.builder(
                    controller: imageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return Image.asset(data[index].assetPath);
                    },
                  ),
                ),
                SizedBox(
                  height: 24.h,
                ),
                SmoothPageIndicator(
                  controller: textController,
                  count: data.length,
                  effect: ExpandingDotsEffect(
                    expansionFactor: 5,
                    dotColor: const Color(0xff403D64),
                    radius: 40,
                    dotWidth: 8.w,
                    dotHeight: 8.h,
                    activeDotColor: context.theme.colorScheme.primary,
                  ),
                ),
                SizedBox(
                  height: 24.h,
                ),
                Expanded(
                  child: PageView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: textController,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Text(
                            data[index].title,
                            textAlign: TextAlign.center,
                            style: context.styles.h2,
                          ),
                          SizedBox(
                            height: 8.h,
                          ),
                          SizedBox(
                            height: 80.h,
                            child: AutoSizeText(
                              data[index].subtitle,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: context.styles.regularLarge
                                  .copyWith(color: const Color(0xffA8A8A8)),
                              minFontSize: 13,
                              maxLines: 4,
                              // overflow: TextOverflow.ellipsis,
                              // overflow: TextOverflow.,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // const Spacer(),
                RishButton.primary(
                  title: currentPage == 2 ? "Let's start!" : 'Continue',
                  enabled: true,
                  isLoading: false,
                  action: () async {
                    await buttonAction(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
