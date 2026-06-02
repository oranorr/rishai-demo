part of '../week_plan_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "I'm creating your personalized\n5-day meal prep.",
          style: context.styles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }
}
