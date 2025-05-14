import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/onboard/data/questionary_repository.dart';
import 'package:rishai/features/week_plan/domain/entities/week_filter_entity.dart';
import 'package:rishai/features/week_plan/presentation/bloc/week_plan_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

class FiltersPopup {
  Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RishColors.formBackgroun,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95, // Занимает 95% экрана
        minChildSize: 0.8, // Минимум 90% экрана
        expand: false,
        builder: (context, scrollController) => const _FiltersWidget(),
      ),
    );
  }
}

class _FiltersWidget extends StatefulWidget {
  const _FiltersWidget();

  @override
  State<_FiltersWidget> createState() => __FiltersWidgetState();
}

class __FiltersWidgetState extends State<_FiltersWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  late WeekFilterEntity filter;

  @override
  void initState() {
    if (weekPlanBloc.state.filter != null &&
        weekPlanBloc.state.filter!.hasActiveFilters) {
      filter = weekPlanBloc.state.filter!;
      _selectedDay = filter.startDate;
      _rangeStart = filter.startDate;
      _rangeEnd = filter.endDate;
    } else {
      filter = WeekFilterEntity(
        startDate: null,
        endDate: null,
        dietaryPreferences: [],
        fitnessGoal: [],
        cuisines: [],
        mealsTypes: [],
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeekPlanBloc, WeekPlanState>(
      bloc: weekPlanBloc,
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: context.styles.regularMedium,
                    ),
                  ),
                  Text('Filters', style: context.styles.boldLarge),
                  GestureDetector(
                    onTap: filter.hasActiveFilters ||
                            (state.filter?.hasActiveFilters ?? false)
                        ? () {
                            weekPlanBloc.add(const WeekPlanEvent.clearFilter());
                            clearFilter();
                          }
                        : () {},
                    child: Text(
                      'Clear all',
                      style: filter.hasActiveFilters ||
                              (state.filter?.hasActiveFilters ?? false)
                          ? context.styles.regularMedium
                          : context.styles.regularMedium
                              .copyWith(color: RishColors.textSecondary),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    SizedBox(height: 20.h),
                    TableCalendar(
                      availableGestures: AvailableGestures.horizontalSwipe,
                      locale: 'en_US',
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      rangeStartDay: _rangeStart,
                      rangeEndDay: _rangeEnd,
                      rangeSelectionMode: _rangeSelectionMode,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _rangeStart = null;
                            _rangeEnd = null;
                            _rangeSelectionMode = RangeSelectionMode.toggledOff;
                          });
                        }
                      },
                      onRangeSelected: (start, end, focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                          _rangeStart = start;
                          _rangeEnd = end;
                          _selectedDay = null;
                          if (start != null || end != null) {
                            _rangeSelectionMode = RangeSelectionMode.toggledOn;
                          }
                        });
                        updateFilterDates(start, end);
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: context.styles.regularMedium
                            .copyWith(color: Colors.white),
                        weekendTextStyle: context.styles.regularMedium
                            .copyWith(color: Colors.white),
                        outsideTextStyle: context.styles.regularMedium
                            .copyWith(color: Colors.white.withOpacity(0.12)),
                        selectedTextStyle: context.styles.regularMedium
                            .copyWith(color: Colors.black),
                        // selectedDecoration: const BoxDecoration(
                        //   color: RishColors.carbs,
                        //   shape: BoxShape.circle,
                        // ),
                        todayTextStyle: context.styles.regularMedium
                            .copyWith(color: RishColors.primary),
                        todayDecoration: BoxDecoration(
                          color: RishColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        rangeStartDecoration: const BoxDecoration(
                          color: Color(0xff543964),
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Color(0xff543964),
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor:
                            RishColors.primary.withOpacity(0.12),
                        withinRangeTextStyle: const TextStyle(
                          color: RishColors.primary,
                        ),
                        rangeStartTextStyle:
                            const TextStyle(color: RishColors.primary),
                        rangeEndTextStyle:
                            const TextStyle(color: RishColors.primary),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: context.styles.boldSmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          height: 1,
                        ),
                        weekendStyle: context.styles.boldSmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Dietary preferences',
                      style: context.styles.h3,
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: QuestionaryRepository()
                          .diets
                          .map(
                            (m) => _FilterChip(
                              isSelected:
                                  filter.dietaryPreferences.contains(m.name),
                              title: m.name,
                              onSelected: () {
                                updateFilterPrefs(m.name);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Fitness goals',
                      style: context.styles.h3,
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: QuestionaryRepository()
                          .goals
                          .map(
                            (m) => _FilterChip(
                              isSelected: filter.fitnessGoal.contains(m.name),
                              title: m.name,
                              onSelected: () {
                                updateFilterGoal(m.name);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Cuisines preferences',
                      style: context.styles.h3,
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: QuestionaryRepository()
                          .cuisines
                          .map(
                            (m) => _FilterChip(
                              isSelected: filter.cuisines.contains(m.name),
                              title: m.name,
                              onSelected: () {
                                updateFilterCuisines(m.name);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              RishButton.primary(
                title: 'Update',
                enabled: filter.hasActiveFilters,
                isLoading: false,
                action: () {
                  weekPlanBloc.add(WeekPlanFilter(filter: filter));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void updateFilterDates(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    setState(() {
      filter = filter.copyWith(
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  void updateFilterPrefs(String incPref) {
    final List<String> prefs = filter.dietaryPreferences;
    prefs.contains(incPref) ? prefs.remove(incPref) : prefs.add(incPref);

    setState(() {
      filter = filter.copyWith(
        dietaryPreferences: prefs,
      );
    });
    // setState(() {
    //   filter = filter.copyWith(
    //     dietaryPreferences: incPrefs,
    //   );
    // });
  }

  void updateFilterGoal(String incGoal) {
    final List<String> goals = filter.fitnessGoal;
    goals.contains(incGoal) ? goals.remove(incGoal) : goals.add(incGoal);

    setState(() {
      filter = filter.copyWith(
        fitnessGoal: goals,
      );
    });
  }

  void clearFilter() {
    setState(() {
      filter = WeekFilterEntity(
        startDate: null,
        endDate: null,
        dietaryPreferences: [],
        fitnessGoal: [],
        cuisines: [],
        mealsTypes: [],
      );
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void updateFilterCuisines(String incCuisine) {
    final List<String> cuisines = filter.cuisines;
    cuisines.contains(incCuisine)
        ? cuisines.remove(incCuisine)
        : cuisines.add(incCuisine);

    setState(() {
      filter = filter.copyWith(
        cuisines: cuisines,
      );
    });
  }

  void updateFilterMealsTypes(String incMealType) {
    final List<String> mealsTypes = filter.mealsTypes;
    mealsTypes.contains(incMealType)
        ? mealsTypes.remove(incMealType)
        : mealsTypes.add(incMealType);

    setState(() {
      filter = filter.copyWith(
        mealsTypes: mealsTypes,
      );
    });
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.isSelected,
    required this.title,
    required this.onSelected,
  });
  final bool isSelected;
  final String title;
  final VoidCallback onSelected;

  @override
  State<_FilterChip> createState() => __FilterChipState();
}

class __FilterChipState extends State<_FilterChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? RishColors.primary.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border:
              widget.isSelected ? null : Border.all(color: RishColors.stroke),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            widget.title,
            style: context.styles.regularMedium.copyWith(
              color: widget.isSelected
                  ? RishColors.primary
                  : RishColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
