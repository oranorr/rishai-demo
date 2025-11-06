part of '../../home_screen.dart';

class _FabOverlayWidget extends StatelessWidget {
  const _FabOverlayWidget({
    required this.overlayAnimation,
    required this.onHideOverlay,
  });

  /// Анимация для появления/скрытия overlay
  final Animation<double> overlayAnimation;

  /// Callback для скрытия overlay
  final VoidCallback onHideOverlay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: overlayAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: overlayAnimation.value,
          child: GestureDetector(
            onTap: onHideOverlay, // Закрытие при тапе на фон
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10.0 * overlayAnimation.value,
                sigmaY: 10.0 * overlayAnimation.value,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3 * overlayAnimation.value),
                child: Center(
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * overlayAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Spacer(),

                        // Кнопка для добавления еды в дневник
                        RishButton.primary(
                          title: 'Add meal to your diary',
                          enabled: true,
                          isLoading: false,
                          action: () {
                            appNavigationService.push(
                              path: AppRoutes.diaryEntryPage.path,
                            );
                            onHideOverlay();
                          },
                        ),
                        SizedBox(height: 8.h),

                        // Debug кнопка для удаления meal plan (только в debug режиме)
                        if (kDebugMode) ...[
                          RishButton.primary(
                            title: '[DEBUG]: REMOVE MEAL PLAN FOR TODAY.',
                            enabled: true,
                            isLoading: false,
                            action: () {
                              chatBloc.add(ChatDeleteMealPlan());
                              onHideOverlay();
                            },
                          ),
                          SizedBox(height: 8.h),
                        ],

                        // Кнопка для создания нового meal plan
                        BlocBuilder<WhoopBloc, WhoopState>(
                          bloc: whoopBloc,
                          builder: (context, state) {
                            final hasMealPlan =
                                state.day.mealPlanEntity != null;
                            return RishButton.primary(
                              title: !hasMealPlan
                                  ? 'Create new meal plan'
                                  : 'View meal plan',
                              enabled: true,
                              isLoading: false,
                              action: () async {
                                if (!hasMealPlan) {
                                  onHideOverlay();
                                  // Переход на страницу чата (страница 2)
                                  await homePageControllerService.navigateToPage(
                                    page: 2,
                                  );
                                } else {
                                  onHideOverlay();
                                  await homePageControllerService
                                      .scrollToBottom();
                                }
                              },
                            );
                          },
                        ),
                        SizedBox(height: 8.h),

                        // Кнопка для 5-дневного meal prep
                        RishButton.primary(
                          title: '5-day meal prep',
                          enabled: true,
                          isLoading: false,
                          action: () async {
                            // Переход на страницу meal prep (страница 1)
                            await homePageControllerService.navigateToPage(
                              page: 1,
                            );
                            onHideOverlay();
                          },
                        ),

                        // Отступ снизу для удобства использования
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
