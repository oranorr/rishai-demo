part of '../week_plan_screen.dart';

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Creating your 5-day meal plan...',
          style: context.styles.h2,
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }
}
