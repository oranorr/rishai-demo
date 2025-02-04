part of '../home_page.dart';

class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget({
    required this.widget,
  });

  final _HomePageBody widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: [
          SizedBox(width: 1.w),
          GestureDetector(
            onTap: () async {
              // print(widget.homePageController.page);
              await widget.homePageController
                  .nextPage(duration: Durations.medium1, curve: Curves.ease);
            },
            child: widget.isLoading
                ? const SizedBox.square(
                    dimension: 25,
                    child: CircularProgressIndicator(
                      color: RishColors.primary,
                      strokeWidth: 1,
                    ),
                  )
                : widget.isLastPage
                    ? const SizedBox.square(dimension: 25)
                    : const Icon(
                        Icons.arrow_back_ios,
                        color: RishColors.stroke,
                      ),
          ),
          // const Spacer(),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await userBloc.showDataPicker(
                  context: context,
                  initalDate: widget.day.dateTime,
                  controller: widget.homePageController,
                );
              },
              child: Text(
                widget.day.dateTime.formatAsDayString(),
                style: context.styles.h2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // const Spacer(),
          GestureDetector(
            onTap: () async {
              await widget.homePageController.previousPage(
                duration: Durations.medium1,
                curve: Curves.ease,
              );
            },
            child: widget.isFirstPage
                ? const SizedBox.square(dimension: 25)
                : const Icon(
                    Icons.arrow_forward_ios,
                    color: RishColors.stroke,
                  ),
          ),
        ],
      ),
    );
  }
}
