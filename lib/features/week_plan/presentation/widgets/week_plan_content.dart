// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../week_plan_screen.dart';

class WeekContentWrap extends StatelessWidget {
  final WeekPlanEntity plan;
  const WeekContentWrap({
    required this.plan,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      appBar: AppBar(
        title: Text(
          plan.formatPeriod(),
          style: context.styles.h2,
        ),
      ),
      child: WeekPlanContent(plan: plan),
    );
  }
}

class WeekPlanContent extends StatefulWidget {
  const WeekPlanContent({
    required this.plan,
    super.key,
  });

  final WeekPlanEntity plan;

  @override
  State<WeekPlanContent> createState() => _WeekPlanContentState();
}

class _WeekPlanContentState extends State<WeekPlanContent> with WeekPlanMixin {
  // Добавляем PageController для дней плана
  late PageController dayPageController;

  // Флаг для отслеживания, выполняется ли в данный момент программное изменение страницы
  bool _isPageChangeFromTap = false;

  // [isExportingGroceryList] Флаг состояния загрузки при экспорте списка покупок
  bool _isExportingGroceryList = false;

  // [exportButtonKey] GlobalKey для получения позиции кнопки экспорта
  // Необходимо для передачи sharePositionOrigin на iOS
  final GlobalKey _exportButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    dayPageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    dayPageController.dispose();
    super.dispose();
  }

  // Обновляем выбранный день и синхронизируем PageController
  void updateSelectedDay(int index) {
    if (index < 0 || index >= widget.plan.plans.length) return;

    setState(() {
      selectedIndex = index;
    });

    // Устанавливаем флаг, чтобы избежать циклических обновлений
    _isPageChangeFromTap = true;

    // Прокручиваем основное содержимое, если страницы не совпадают
    if (dayPageController.hasClients &&
        (dayPageController.page?.round() != index)) {
      dayPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    // Прокручиваем горизонтальный список дней до нужной позиции
    if (daysController.hasClients) {
      final maxScroll = daysController.position.maxScrollExtent;
      double targetScroll;

      if (index <= 1) {
        // Для первых двух дней показываем начало списка
        targetScroll = 0.0;
      } else if (index >= widget.plan.plans.length - 2) {
        // Для последних двух дней показываем конец списка
        targetScroll = maxScroll;
      } else {
        // Для средних дней центрируем выбранный день
        targetScroll = (index * 86.w - 100.w).clamp(0.0, maxScroll);
      }

      // Используем плавную анимацию
      daysController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    // Сбрасываем флаг после небольшой задержки
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _isPageChangeFromTap = false;
      }
    });
  }

  // Метод для обработки изменения страницы через свайп
  void onPageChanged(int index) {
    // Если изменение страницы произошло программно, пропускаем обработку
    if (_isPageChangeFromTap) return;

    setState(() {
      selectedIndex = index;
    });

    // Обновляем положение горизонтального списка дней
    if (daysController.hasClients) {
      final maxScroll = daysController.position.maxScrollExtent;
      double targetScroll;

      if (index <= 1) {
        targetScroll = 0.0;
      } else if (index >= widget.plan.plans.length - 2) {
        targetScroll = maxScroll;
      } else {
        targetScroll = (index * 86.w - 100.w).clamp(0.0, maxScroll);
      }

      daysController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Column(
      children: [
        // Row(
        //   children: [
        //     Text(
        //       'Meal prep',
        //       style: context.styles.h3,
        //     ),
        //     if (kDebugMode)
        //       IconButton(
        //         onPressed: onClearPressed,
        //         icon: const Icon(
        //           Icons.delete_forever,
        //           color: Colors.red,
        //           size: 20,
        //         ),
        //       ),
        //     const Spacer(),
        //     Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         _PlanArrow(
        //           callback: () => pageController.previousPage(
        //             duration: const Duration(milliseconds: 300),
        //             curve: Curves.easeInOut,
        //           ),
        //           isForward: false,
        //           isEnabled: !(currentPage > 0),
        //         ),
        //         const SizedBox(width: 8),
        //         Text(
        //           '${plans[currentPage].startDate.formatAsWeekString()} - ${plans[currentPage].endDate.formatAsWeekString()}',
        //           style: context.styles.regularMedium,
        //         ),
        //         const SizedBox(width: 8),
        //         _PlanArrow(
        //           callback: () => pageController.nextPage(
        //             duration: const Duration(milliseconds: 300),
        //             curve: Curves.easeInOut,
        //           ),
        //           isForward: true,
        //           isEnabled: !(currentPage < plans.length - 1),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
        // SizedBox(height: 16.h),
        Expanded(
          child: PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            onPageChanged: (page) {
              // final today = DateTime.now();
              // final (currentPlanIndex, todayIndex) =
              //     findTargetPlan(widget.plans, today);

              // onCurrentPageChanged(page);
              // // Если это текущий план (где есть сегодняшний день) - показываем сегодняшний день
              // // Иначе показываем первый день плана
              // onSelectedIndexChanged(page == currentPlanIndex ? todayIndex : 0);
            },
            itemCount: plan.plans.length,
            itemBuilder: (context, pageIndex) {
              final plan = widget.plan;
              return Column(
                children: [
                  SizedBox(
                    height: 36.h,
                    child: ListView.builder(
                      key: const PageStorageKey<String>('days_list'),
                      shrinkWrap: true,
                      itemCount: plan.plans.length,
                      scrollDirection: Axis.horizontal,
                      controller: daysController,
                      // physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => updateSelectedDay(index),
                            child: Container(
                              width: 80.w,
                              decoration: BoxDecoration(
                                color: isSelected ? RishColors.primary : null,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: RishColors.primary,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Day ${index + 1}',
                                  style: context.styles.regularSmall.copyWith(
                                    color: isSelected
                                        ? Colors.black
                                        : RishColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Заменяем Expanded на Flexible, чтобы избежать конфликта в иерархии
                  Flexible(
                    child: PageView.builder(
                      controller: dayPageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged:
                          onPageChanged, // Используем отдельный метод для обработки свайпа
                      itemCount: plan.plans.length,
                      itemBuilder: (context, dayIndex) {
                        return _MealPlanWidget(
                          plan: plan.plans[dayIndex],
                          isToday: false,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Container(
                      key: _exportButtonKey,
                      child: RishButton.primary(
                        title: 'Export grocery list',
                        enabled: !_isExportingGroceryList,
                        isLoading: _isExportingGroceryList,
                        action: () async {
                            // [exportGroceryList] Экспорт списка покупок с обработкой ошибок
                            // Предотвращаем множественные нажатия
                            if (_isExportingGroceryList) return;

                            setState(() {
                              _isExportingGroceryList = true;
                            });

                            try {
                              // [trackExport] Трекинг экспорта списка покупок из недельного плана
                              await analytics.logCustomEvent(
                                name: 'export_grocery_list_from_week_plan',
                                parameters: {
                                  'day_index': selectedIndex,
                                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                                },
                              );

                              // [collectIngredients] Собираем все ингредиенты из недельного плана
                              final allIngredients = collectAllIngredients(plan);

                              // [validateIngredients] Проверяем, что есть ингредиенты для экспорта
                              if (allIngredients.isEmpty) {
                                throw PdfServiceException(
                                  'No ingredients found in the meal plan',
                                );
                              }

                              // [getButtonPosition] Получаем позицию кнопки для sharePositionOrigin на iOS
                              // Это необходимо для корректной работы share sheet, особенно на iPad
                              // iOS требует валидную позицию с ненулевым размером
                              Rect? sharePositionOrigin;
                              if (Platform.isIOS) {
                                try {
                                  final BuildContext? buttonContext = _exportButtonKey.currentContext;
                                  if (buttonContext != null) {
                                    final RenderBox? renderBox = buttonContext
                                        .findRenderObject() as RenderBox?;
                                    if (renderBox != null && renderBox.hasSize) {
                                      // [getGlobalPosition] Получаем позицию кнопки в глобальных координатах
                                      final position = renderBox.localToGlobal(Offset.zero);
                                      final size = renderBox.size;
                                      
                                      // [validatePosition] Проверяем, что размер не нулевой
                                      // iOS требует ненулевой размер для sharePositionOrigin
                                      if (size.width > 0 && size.height > 0) {
                                        sharePositionOrigin = Rect.fromLTWH(
                                          position.dx,
                                          position.dy,
                                          size.width,
                                          size.height,
                                        );
                                        print('[WeekPlanContent.exportGroceryList] Button position: $sharePositionOrigin');
                                      } else {
                                        print('[WeekPlanContent.exportGroceryList] Warning: Button has zero size, using fallback');
                                      }
                                    } else {
                                      print('[WeekPlanContent.exportGroceryList] Warning: RenderBox is null or has no size, using fallback');
                                    }
                                  } else {
                                    print('[WeekPlanContent.exportGroceryList] Warning: Button context is null, using fallback');
                                  }
                                } catch (e) {
                                  // [handlePositionError] Если не удалось получить позицию, используем fallback
                                  print('[WeekPlanContent.exportGroceryList] Error getting button position: $e, using fallback');
                                }
                              }

                              // [generatePdf] Генерируем PDF со списком покупок
                              final pdfService = PdfService();
                              await pdfService.generateShoppingList(
                                allIngredients,
                                sharePositionOrigin: sharePositionOrigin,
                              );
                            } on PdfServiceException catch (e) {
                              // [handlePdfError] Обработка специфичных ошибок PDF сервиса
                              print('[WeekPlanContent.exportGroceryList] PDF error: ${e.message}');
                              RishSnackbar().showSnackBar(e.message);
                            } catch (e, stackTrace) {
                              // [handleGenericError] Обработка неожиданных ошибок
                              print('[WeekPlanContent.exportGroceryList] Unexpected error: $e');
                              print('[WeekPlanContent.exportGroceryList] Stack trace: $stackTrace');
                              RishSnackbar().showSnackBar(
                                'Failed to export grocery list. Please try again.',
                              );
                            } finally {
                              // [resetLoadingState] Сбрасываем состояние загрузки в любом случае
                              if (mounted) {
                                setState(() {
                                  _isExportingGroceryList = false;
                                });
                              }
                            }
                          },
                        ),
                      ),
                  ),
                  if (Platform.isAndroid) SizedBox(height: 30.h),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// class _PlanArrow extends StatelessWidget {
//   const _PlanArrow({
//     required this.callback,
//     required this.isForward,
//     required this.isEnabled,
//   });
//   final VoidCallback callback;
//   final bool isForward;
//   final bool isEnabled;
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isEnabled ? null : callback,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: 30.h,
//         width: 30.w,
//         decoration: BoxDecoration(
//           color: isEnabled ? Colors.transparent : RishColors.primary,
//           shape: BoxShape.circle,
//           boxShadow: isEnabled
//               ? null
//               : [
//                   BoxShadow(
//                     color: RishColors.primary.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Icon(
//           isForward ? Icons.chevron_right : Icons.chevron_left,
//           color: isEnabled ? Colors.transparent : RishColors.stroke,
//           size: 25.w,
//         ),
//       ),
//     );
//   }
// }
