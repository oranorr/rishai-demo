part of '../chat_page.dart';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: [
          const Icon(
            Icons.assessment,
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your personal Pivot AI coach',
                style: context.styles.h3,
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: RishColors.success,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Online',
                    style: context.styles.boldMedium
                        .copyWith(color: RishColors.success),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
