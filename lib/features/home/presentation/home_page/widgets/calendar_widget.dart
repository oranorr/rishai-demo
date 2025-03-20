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
          SizedBox(width: 2.w),
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onTap: () async {
              await widget.homePageController
                  .nextPage(duration: Durations.medium1, curve: Curves.ease);
            },
            isLoading: widget.isLoading,
            isDisabled: widget.isLastPage,
          ),
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
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onTap: () async {
              await widget.homePageController.previousPage(
                duration: Durations.medium1,
                curve: Curves.ease,
              );
            },
            isLoading: false,
            isDisabled: widget.isFirstPage,
          ),
          SizedBox(width: 2.w),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isLoading,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40.h,
        width: 40.w,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : RishColors.primary,
          shape: BoxShape.circle,
          boxShadow: isDisabled || isLoading
              ? null
              : [
                  BoxShadow(
                    color: RishColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: RishColors.stroke,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                icon,
                color: isDisabled ? Colors.transparent : RishColors.stroke,
                size: 32.w,
              ),
      ),
    );
  }
}
