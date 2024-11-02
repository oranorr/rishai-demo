import 'package:rishai/features/onboard/domain/entities.dart';
import 'package:rishai/features/user/domain/entities/user_goal_entity.dart';

class QuestionaryRepository {
  List<QuestionaryData> data = [
    QuestionaryData(
        title: 'A few more details..', subtitle: 'We\'ve got this from WHOOP'),
    QuestionaryData(title: 'Your gender', subtitle: 'Please, select'),
    QuestionaryData(title: 'Age', subtitle: 'How old are you?'),
    QuestionaryData(
        title: 'Dietary Preferences', subtitle: 'Please select one:'),
    QuestionaryData(
        title: 'Cuisine Preferences',
        subtitle: 'You can select multiple cuisines:'),
    QuestionaryData(
        title: 'Fitness Goal',
        subtitle:
            'Please select one:\nEach goal works on a specific surplus or deficit percentage of one\'s total energy expenditure'),
  ];

  final List<Dietary> diets = [
    Dietary(
        name: 'Carnivore',
        assetPath: 'assets/diet/carnivore.svg',
        diet: Diet.carnivore),
    // Dietary(name: 'Keto', assetPath: 'assets/diet/keto.svg', diet: Diet.keto),
    Dietary(
        name: 'Omnivore',
        assetPath: 'assets/diet/omnivore.svg',
        diet: Diet.omnivore),
    // Dietary(
    //     name: 'Paleo', assetPath: 'assets/diet/paleo.svg', diet: Diet.paleo),
    Dietary(
        name: 'Pescatarian',
        assetPath: 'assets/diet/pescatarian.svg',
        diet: Diet.pescatarian),
    Dietary(
        name: 'Vegan', assetPath: 'assets/diet/vegan.svg', diet: Diet.vegan),
    Dietary(
        name: 'Vegetarian (lacto-ovo)',
        assetPath: 'assets/diet/vegetarian.svg',
        diet: Diet.vegetarianLactoOvo),
  ];

  final List<Cuisine> cuisines = [
    Cuisine(
        name: 'Mediterranean',
        assetPath: 'assets/diet/mediterranean.svg',
        cuisine: CuisineEnum.mediterranean),
    Cuisine(
        name: 'East Asian',
        assetPath: 'assets/cuisines/east_asian.svg',
        cuisine: CuisineEnum.eastAsia),
    Cuisine(
        name: 'South Asian',
        assetPath: 'assets/cuisines/south_asian.svg',
        cuisine: CuisineEnum.southAsia),
    Cuisine(
        name: 'Middle Eastern',
        assetPath: 'assets/cuisines/middle_eastern.svg',
        cuisine: CuisineEnum.middleEast),
    Cuisine(
        name: 'Western',
        assetPath: 'assets/cuisines/western.svg',
        cuisine: CuisineEnum.western),
    Cuisine(
        name: 'Mexican',
        assetPath: 'assets/cuisines/latino.svg',
        cuisine: CuisineEnum.latino),
    // Cuisine(
    //     name: 'Africano',
    //     assetPath: 'assets/cuisines/africano.svg',
    //     cuisine: CuisineEnum.africano),
  ];

  final List<FitnessGoal> goals = [
    FitnessGoal(
      name: 'Aesthetics',
      assetPath: 'assets/fitness/loose_weight.svg',
      subtitle: 'Fat and Weight loss',
      goal: GoalType.aesthetics,
      modificator: -0.05,
    ),
    FitnessGoal(
      name: 'Performance',
      assetPath: 'assets/fitness/performance.svg',
      subtitle: 'Strength and Muscle mass gain',
      goal: GoalType.performance,
      modificator: 0.05,
    ),
    FitnessGoal(
      name: 'Recomp',
      assetPath: 'assets/fitness/recomp.svg',
      subtitle: 'Muscle gain and Fat loss',
      goal: GoalType.recomp,
      modificator: -0.05,
    ),
    FitnessGoal(
      name: 'Optimize Me',
      assetPath: 'assets/fitness/optimize.svg',
      subtitle: 'Healthspan x Longevity',
      goal: GoalType.optimize,
      modificator: 0,
    ),
  ];
}
