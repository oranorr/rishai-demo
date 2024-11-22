// ignore_for_file: public_member_api_docs, sort_constructors_first
class OnboardRepository {
  static List<OnboardEntity> data = [
    OnboardEntity(
      title: 'Unlock your WHOOP\'s full potential',
      subtitle:
          'Pivot seamlessly integrates with WHOOP to provide bespoke nutrition advice based on your lifestyle.\nOptimize your healthspan, Pivot to longevity',
      assetPath: 'assets/images/onboard_1.png',
    ),
    OnboardEntity(
      title: 'Your personalized Nutritionist',
      subtitle:
          'Pivot analyzes your WHOOP metrics to create adaptive meal plans tailored to your fitness goals and dietary preferences',
      assetPath: 'assets/images/onboard_2.png',
    ),
    OnboardEntity(
      title: 'Ask Pivot anything\n(nutrition related)',
      subtitle:
          'Get personalised answers to your nutritional and meal plan related questions in our AI chat mode',
      assetPath: 'assets/images/onboard_3.png',
    ),
  ];
}

class OnboardEntity {
  final String title;
  final String subtitle;
  final String assetPath;
  OnboardEntity({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}
