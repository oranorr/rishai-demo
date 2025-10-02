part of '../week_plan_screen.dart';

class WeekLandingPage extends StatefulWidget {
  const WeekLandingPage({required this.plans, super.key});
  final List<WeekPlanEntity?> plans;

  @override
  State<WeekLandingPage> createState() => _WeekLandingPageState();
}

class _WeekLandingPageState extends State<WeekLandingPage> {
  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;
    // Убираем дублирующий BlocBuilder, так как он уже есть в WeekPlanScreen
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        // Убираем проверку isLoading, так как она уже обрабатывается в WeekPlanScreen
        return Column(
          crossAxisAlignment: plans.isEmpty
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: plans.isEmpty
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your meal preps',
                  style: context.styles.h1,
                ),
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
            if (plans.isEmpty && state.filter?.hasActiveFilters == true) ...[
              const Spacer(),
              Text(
                'No preps found for your filters.',
                style: context.styles.h3,
              ),
              const Spacer(),
            ] else if (plans.isEmpty) ...[
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
              action: weekPlanBloc.isThereActivePlan
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WeekContentWrap(plan: state.allWeekPlans.last),
                        ),
                      );
                    }
                  : () {
                      // Переходим к экрану выбора порций для создания нового плана
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RishScaffold(
                            implyLeading: true,
                            child: _ServingsSelector(),
                          ),
                        ),
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
