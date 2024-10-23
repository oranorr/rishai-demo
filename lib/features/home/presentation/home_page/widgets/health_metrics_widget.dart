part of '../home_page.dart';

class _HealthMetricsWidget extends StatelessWidget {
  final HealthMetricsEntity health;
  const _HealthMetricsWidget({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < health.toList().length; i++)
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RishColors.stroke),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      health.toListNames()[i],
                      style: context.styles.regularMedium
                          .copyWith(color: RishColors.textSecondary),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      health.toList()[i].toString(),
                      style: context.styles.numsS,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
