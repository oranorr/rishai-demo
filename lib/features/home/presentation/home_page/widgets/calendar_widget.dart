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
          Stack(
            children: [
              Image.asset(
                'assets/icons/logo.png',
                width: 32.w,
                height: 32.h,
              ),
              if (!adapty.isActive) _buildUpgradeButton(context, fake: true),
            ],
          ),
          //
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavigationButton(
                  icon: Icons.chevron_left,
                  onTap: () async {
                    await widget.homePageController.nextPage(
                      duration: Durations.medium1,
                      curve: Curves.ease,
                    );
                  },
                  isLoading: widget.isLoading,
                  isDisabled: widget.isLastPage,
                ),
                SizedBox(width: 2.w),
                Text(
                  widget.day.dateTime.formatAsDayString(),
                  style: context.styles.h2.copyWith(
                    color: widget.isLoading
                        ? context.styles.h2.color?.withOpacity(0.6)
                        : context.styles.h2.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 2.w),
                _buildNavigationButton(
                  icon: Icons.chevron_right,
                  onTap: () async {
                    await widget.homePageController.previousPage(
                      duration: Durations.medium1,
                      curve: Curves.ease,
                    );
                  },
                  isLoading: widget.isLoading,
                  isDisabled: widget.isFirstPage,
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () async {
              await userBloc.showDataPicker(
                context: context,
                initalDate: widget.day.dateTime,
                controller: widget.homePageController,
              );
            },
            child: adapty.isActive
                ? SvgPicture.asset('assets/icons/calendar.svg')
                : _buildUpgradeButton(context, fake: false),
          ),
          // SizedBox(width: 2.w),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context, {required bool fake}) {
    return Text(
      'Upgrade',
      style: context.styles.boldLarge.copyWith(
        color: fake ? Colors.transparent : RishColors.primary,
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
        child: Icon(
          icon,
          color: isDisabled ? Colors.transparent : RishColors.primary,
          size: 24.w,
        ),
      ),
    );
  }
}
