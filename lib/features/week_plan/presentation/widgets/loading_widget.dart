part of '../week_plan_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "I'm creating your personalized\n5-day meal prep.\n\nPlease wait a few minutes and avoid switching apps or locking your screen until the generation has completed",
          style: context.styles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }
}
