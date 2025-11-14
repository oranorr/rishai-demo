part of './questionary.dart';

mixin QuestionaryMixin on State<Questionary> {
  late PageController pageController;
  bool buttonEnabled = true;
  List<QuestionaryData> data = QuestionaryRepository().data;
  bool isLastPage = false;
  Gender? gender;
  int? age;
  List<Dietary> diets = [];
  List<Cuisine> cuisines = [];
  List<Restriction> restrictions = [];
  FitnessGoal? fitnessGoal;
  UserEntity user = userBloc.state.user;

  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void resolveType(int page) {
    if (page == 7) {
      setState(() {
        isLastPage = true;
      });
    } else {
      setState(() {
        isLastPage = false;
      });
    }

    bool enabled;
    if (page == 0 || page == 3) {
      enabled = true;
    } else if (page == 2) {
      enabled = gender != null;
    } else if (page == 3) {
      enabled = diets.isNotEmpty;
    } else if (page == 6) {
      enabled = true;
    } else {
      enabled = false;
    }

    setState(() {
      buttonEnabled = enabled;
    });
  }

  void setSex(Gender gnd) {
    setState(() {
      gender = gnd;
      buttonEnabled = true;
    });
  }

  void setGender() {
    setState(() {
      buttonEnabled = true;
    });
  }

  // ignore: use_setters_to_change_properties
  void setAge(int incAge) {
    age = incAge;
    // setState(() {
    //   buttonEnabled = true;
    // });
  }

  void setDiets(List<Question> incDiets) {
    setState(() {
      diets = incDiets.cast<Dietary>();
      buttonEnabled = diets.isNotEmpty;
    });
  }

  void setCuisines(List<Question> incCuisines) {
    setState(() {
      cuisines = incCuisines.cast<Cuisine>();
      buttonEnabled = cuisines.isNotEmpty;
    });
  }

  void setRestrictions(List<Question> incRestrictions) {
    restrictions = incRestrictions.cast<Restriction>();
    // Кнопка всегда активна для опционального списка restrictions
    setState(() {
      buttonEnabled = true;
    });
  }

  void setGoal(List<Question> incGoal) {
    setState(() {
      fitnessGoal = incGoal.first as FitnessGoal;
      buttonEnabled = true;
    });
  }

  Future<void> buttonAction() async {
    if (!isLastPage) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    } else {
      // [SaveUserData] Сохраняем данные пользователя из опросника
      UserEntity updUser = user.copyWith(
        gender: gender,
        age: age,
        foodPreferences: FoodPreferences(
          diets: diets.map((diet) => diet.name).toList(),
          cuisines: cuisines.map((cuisine) => cuisine.name).toList(),
          restrictions:
              restrictions.map((restriction) => restriction.name).toList(),
        ),
        userGoal: fitnessGoal!.toUseGoal(),
        // bodyMeasurements: whoopBloc.state.day.bodyMeasurements,
      );

      // [UpdateUser] Обновляем пользователя и ждем завершения
      userBloc.add(UpdateUserEvent(user: updUser));

      // [WaitForUpdate] Ждем обновления состояния UserBloc перед инициализацией WHOOP
      // Это критически важно для правильной работы проверки needsQuestionary
      await Future.delayed(const Duration(milliseconds: 200));

      // [VerifyUpdate] Дополнительно проверяем, что состояние действительно обновилось
      int attempts = 0;
      const maxAttempts = 10;
      while (userBloc.state.user.needsQuestionary && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      // [ShowPaywall] Устанавливаем флаг, что после paywall нужно перейти на redirect
      // и переходим на paywall для нового пользователя
      // [NOTE] InitWhoopOnLogin НЕ вызываем здесь, так как он автоматически переходит на /redirect
      // Вместо этого вызываем его на странице Redirect после paywall
      await prefsRepo.setShouldRedirectAfterPaywall(true);
      context.go(AppRoutes.paywall.path);
    }
  }
}
