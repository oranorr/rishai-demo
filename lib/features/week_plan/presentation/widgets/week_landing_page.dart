part of '../week_plan_screen.dart';

class WeekLandingPage extends StatefulWidget {
  const WeekLandingPage({required this.plans, super.key});
  final List<WeekPlanEntity?> plans;

  @override
  State<WeekLandingPage> createState() => _WeekLandingPageState();
}

class _WeekLandingPageState extends State<WeekLandingPage> {
  /// Обработчик нажатия на кнопку создания/открытия плана питания
  /// 
  /// Проверяет статус подписки и наличие активного плана,
  /// затем выполняет навигацию к соответствующему экрану.
  /// 
  /// [plan] - опциональный план питания (не используется, но оставлен для совместимости)
  Future<void> handleButton(WeekPlanEntity? plan) async {
    // Проверяем, что виджет все еще смонтирован
    if (!mounted) return;

    try {
      // Логируем статус подписки для отладки
      print('[handleButton] adapty.isActive: ${adapty.isActive}');
      
      // Проверяем статус подписки
      if (!adapty.isActive) {
        // Проверяем mounted перед показом диалога
        if (!mounted) return;
        
        await RishiDialog.showSubscriptionRequiredDialog(
          context,
          body: 'Creating a new meal prep is available only for subscribers.',
          onUpgrade: () {
            // Проверяем mounted перед навигацией
            if (!mounted) return;
            appNavigationService.go(path: AppRoutes.paywall.path);
          },
        );
        return;
      }

      // Проверяем mounted перед проверкой состояния блока
      if (!mounted) return;

      // Получаем текущее состояние блока
      final currentState = weekPlanBloc.state;
      
      // Проверяем наличие активного плана
      if (weekPlanBloc.isThereActivePlan) {
        // Дополнительная проверка на пустоту списка для безопасности
        if (currentState.allWeekPlans.isEmpty) {
          print('[handleButton] Ошибка: isThereActivePlan вернул true, но список планов пуст');
          // Если нет планов, переходим к созданию нового
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RishScaffold(
                implyLeading: true,
                child: _ServingsSelector(),
              ),
            ),
          );
          return;
        }

        // Проверяем mounted перед навигацией
        if (!mounted) return;
        
        final activePlan = currentState.allWeekPlans.last;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeekContentWrap(plan: activePlan),
          ),
        );
      } else {
        // Нет активного плана - переходим к созданию нового
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RishScaffold(
              implyLeading: true,
              child: _ServingsSelector(),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Логируем ошибку для отладки
      print('[handleButton] Ошибка при обработке нажатия кнопки: $e');
      print('[handleButton] Stack trace: $stackTrace');
      
      // Проверяем mounted перед показом ошибки пользователю
      if (!mounted) return;
      
      // Можно показать пользователю сообщение об ошибке, если нужно
      // Но пока просто логируем, чтобы не прерывать пользовательский опыт
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;
    // Убираем дублирующий BlocBuilder, так как он уже есть в WeekPlanScreen
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        // Убираем проверку isLoading, так как она уже обрабатывается в WeekPlanScreen
        // Первый вход без кэша: список пуст, но загрузка ещё не завершалась.
        // Показываем skeleton, чтобы не мигало «There are no preps yet».
        final bool isFirstLoad = plans.isEmpty && !state.hasLoaded;

        // «Пусто по-настоящему» — только после завершённой загрузки.
        final bool isTrulyEmpty = plans.isEmpty && state.hasLoaded;

        return Column(
          crossAxisAlignment: isTrulyEmpty
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: isTrulyEmpty
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your meal preps',
                  style: context.styles.h1,
                ),
                // Деликатный индикатор фоновой синхронизации (Apple HIG:
                // не перекрываем контент, лишь намекаем, что данные обновляются).
                if (state.isSyncing && plans.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  const CupertinoActivityIndicator(radius: 8),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await FiltersPopup().show(context);
                  },
                  child: Stack(
                    children: [
                      const Icon(Icons.tune),
                      if (state.filter != null)
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: RishColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: RishColors.textPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isFirstLoad)
              const Expanded(child: _WeekPlansSkeleton())
            // ignore: use_if_null_to_convert_nulls_to_bools
            else if (isTrulyEmpty && state.filter?.hasActiveFilters == true) ...[
              const Spacer(),
              Text(
                'No preps found for your filters.',
                style: context.styles.h3,
              ),
              const Spacer(),
            ] else if (isTrulyEmpty) ...[
              const Spacer(),
              Text(
                'There are no preps yet.\nGo create one!',
                style: context.styles.h3,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ] else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _WeekCard(week: plan!);
                  },
                ),
              ),
            SizedBox(
              height: 10.h,
            ),
            RishButton.primary(
              title: weekPlanBloc.isThereActivePlan
                  ? 'Open current prep'
                  : 'Create new prep',
              action: () async {
                await handleButton(
                  state.allWeekPlans.isNotEmpty
                      ? state.allWeekPlans.last
                      : null,
                );
              },
              enabled: true,
              isLoading: false,
            ),
          ],
        );
      },
    );
  }
}

/// Apple HIG-style placeholder: пока грузим preps впервые (кэша нет), вместо
/// пустого «нет планов» показываем мягко пульсирующие карточки-скелетоны.
/// Это даёт ощущение скорости и не «обманывает» пользователя пустым экраном.
class _WeekPlansSkeleton extends StatefulWidget {
  const _WeekPlansSkeleton();

  @override
  State<_WeekPlansSkeleton> createState() => _WeekPlansSkeletonState();
}

class _WeekPlansSkeletonState extends State<_WeekPlansSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Плавная «дышащая» пульсация ~1.1с в каждую сторону (нежно, не мигает).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Освобождаем контроллер анимации, чтобы не текла память.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView.builder(
        // Скелетон не интерактивен — отключаем скролл.
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => const _SkeletonCard(),
      ),
    );
  }
}

/// Одна карточка-заглушка, повторяющая геометрию [_WeekCard].
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок-период (имитация week.formatPeriod()).
        Container(
          width: 140.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: RishColors.stroke,
            borderRadius: BorderRadius.all(Radius.circular(6.r)),
          ),
        ),
        SizedBox(height: 10.h),
        // Тело карточки с 4 «строками» свойств (diet/goal/cuisine/meals).
        Container(
          height: 150.h,
          decoration: const BoxDecoration(
            color: RishColors.stroke,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
  });
  final WeekPlanEntity week;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              week.formatPeriod(),
              style: context.styles.h3,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeekContentWrap(plan: week),
                  ),
                );
              },
              child: Text(
                'View',
                style: context.styles.regularLarge
                    .copyWith(color: RishColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeekContentWrap(plan: week),
              ),
            );
          },
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: RishColors.stroke,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(
                        'Dietary preference:',
                        style: context.styles.boldMedium,
                      ),
                      const Spacer(),
                      Text(
                        // 'Vegan, Carnivore, Lacto, Something else',
                        week.dietaryPreferences.isEmpty
                            ? 'Not Stated'
                            : week.dietaryPreferences,
                        style: context.styles.regularMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: RishColors.formBackgroun,
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(
                        'Fitness goal:',
                        style: context.styles.boldMedium,
                      ),
                      const Spacer(),
                      Text(
                        week.fitnessGoal.isEmpty
                            ? 'Not Stated'
                            : week.fitnessGoal.capitalizeWords(),
                        style: context.styles.regularMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: RishColors.formBackgroun,
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuisine preferences:',
                        style: context.styles.boldMedium,
                      ),
                      // const Spacer(),
                      if (week.cuisines.isEmpty)
                        const Spacer()
                      else
                        SizedBox(
                          width: 10.w,
                        ),
                      Expanded(
                        child: Text(
                          // 'Vegan, Carnivore, Lacto, Something else',
                          week.cuisines.isEmpty
                              ? 'Not Stated'
                              : week.cuisines.join(', '),
                          style: context.styles.regularMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: RishColors.formBackgroun,
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal selection:',
                        style: context.styles.boldMedium,
                      ),
                      if (week.mealsTypes.isEmpty)
                        const Spacer()
                      else
                        SizedBox(
                          width: 10.w,
                        ),
                      Expanded(
                        child: Text(
                          week.mealsTypes.isEmpty
                              ? 'Not Stated'
                              : week.mealsTypes.join('\n'),
                          style: context.styles.regularMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 10.h,
        ),
      ],
    );
  }
}
