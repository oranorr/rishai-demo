// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../home_page.dart';

class _CaloriesWidget extends StatelessWidget {
  final DayEntity day;

  const _CaloriesWidget({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
        child: Row(
      children: [
        SizedBox.square(
          dimension: 140.w,
          child: BlocBuilder<UserBloc, UserState>(
            bloc: userBloc,
            builder: (context, userState) {
              final mod = day.isToday
                  ? userState.user.userGoal!.modificator
                  : ((day.macros.kcal / day.weekTdeeAverage) - 1);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: mod < 0 ? 1 + mod : 1,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: RishColors.stroke,
                    ),
                  ),
                  Positioned.fill(
                    right: 12.w,
                    left: 12.w,
                    top: 12.w,
                    bottom: 12.w,
                    child: CircularProgressIndicator(
                      value: mod > 0 ? 1 - mod : 1,
                      strokeWidth: 9,
                      color: RishColors.protein,
                      backgroundColor: RishColors.stroke,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                ],
              );
            },
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<WhoopBloc, WhoopState>(
                bloc: whoopBloc,
                builder: (context, state) {
                  int kcal =
                      day.isToday ? state.day.macros.kcal : day.macros.kcal;
                  return Text(
                    '$kcal kcal',
                    style: context.styles.numsM
                        .copyWith(color: RishColors.primary),
                  );
                },
              ),
              Text(
                'Daily Calorie Goal',
                style: context.styles.regularMedium
                    .copyWith(color: RishColors.primary),
              ),
              SizedBox(height: 12.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.weekTdeeAverage.round()} kcal',
                  style:
                      context.styles.numsM.copyWith(color: RishColors.protein),
                ),
              ),
              Text(
                'Calories Burned (TDEE) - 7 Days Average',
                style: context.styles.regularMedium
                    .copyWith(color: RishColors.protein),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
