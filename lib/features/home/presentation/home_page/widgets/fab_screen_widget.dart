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
                                // [subscriptionCheck] Проверяем статус подписки перед созданием плана
                                if (!adapty.isActive) {
                                  // [showDialog] Если подписка не активна, показываем диалог и ведем на paywall
                                  // [note] Не закрываем overlay перед показом диалога, чтобы избежать ошибок размонтирования
                                  if (context.mounted) {
                                    await RishiDialog
                                        .showSubscriptionRequiredDialog(
                                      context,
                                      body:
                                          'Creating an individual meal plan is available only for subscribers.',
                                      onUpgrade: () {
                                        // [navigateToPaywall] Переходим на экран paywall для обновления подписки
                                        appNavigationService.go(
                                          path: AppRoutes.paywall.path,
                                        );
                                      },
                                    );
                                    // [hideOverlay] Закрываем overlay после закрытия диалога
                                    onHideOverlay();
                                  }
                                  return;
                                }

                                if (!hasMealPlan) {
                                  onHideOverlay();
                                  // [action] Переход на страницу чата (страница 2) для создания нового плана
                                  await homePageControllerService
                                      .navigateToPage(
                                    page: 2,
                                  );
                                } else {
                                  onHideOverlay();
                                  // [action] Проверяем текущую страницу перед скроллом
                                  final currentPage =
                                      homePageControllerService.currentPage;

                                  // [action] Если мы не на домашней странице (0), сначала переходим на неё
                                  if (currentPage != null && currentPage != 0) {
                                    await homePageControllerService
                                        .navigateToPage(page: 0);
                                    // [action] Небольшая задержка для завершения анимации перехода
                                    await Future.delayed(
                                      const Duration(milliseconds: 200),
                                    );
                                  }

                                  // [action] Выполняем скролл к meal plan на домашней странице
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
                            // [subscriptionCheck] Проверяем статус подписки перед созданием meal prep
                            if (!adapty.isActive) {
                              // [showDialog] Если подписка не активна, показываем диалог и ведем на paywall
                              // [note] Не закрываем overlay перед показом диалога, чтобы избежать ошибок размонтирования
                              if (context.mounted) {
                                await RishiDialog
                                    .showSubscriptionRequiredDialog(
                                  context,
                                  body:
                                      'Creating a new meal prep is available only for subscribers.',
                                  onUpgrade: () {
                                    // [navigateToPaywall] Переходим на экран paywall для обновления подписки
                                    appNavigationService.go(
                                      path: AppRoutes.paywall.path,
                                    );
                                  },
                                );
                                // [hideOverlay] Закрываем overlay после закрытия диалога
                                onHideOverlay();
                              }
                              return;
                            }

                            // [navigateToMealPrep] Переход на страницу meal prep (страница 1)
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
