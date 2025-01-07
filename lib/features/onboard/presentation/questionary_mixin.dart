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
    // print(gender);
    if (page == 6) {
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
      // _type = ButtonType.primary;
      enabled = true;
    } else if (page == 2) {
      enabled = gender != null;
      // _type = gender == null ? ButtonType.disabled : ButtonType.primary;
    } else if (page == 3) {
      enabled = diets.isNotEmpty;
      // _type = diets.isEmpty ? ButtonType.disabled : ButtonType.primary;
    } else {
      enabled = false;
      // _type = ButtonType.disabled;
    }
    setState(() {
      // type = _type;
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
      UserEntity updUser = user.copyWith(
        gender: gender,
        age: age,
        foodPreferences: FoodPreferences(
          diets: diets.map((diet) => diet.name).toList(),
          cuisines: cuisines.map((cuisine) => cuisine.name).toList(),
        ),
        userGoal: fitnessGoal!.toUseGoal(),
        // bodyMeasurements: whoopBloc.state.day.bodyMeasurements,
      );
      userBloc.add(UpdateUserEvent(user: updUser));
      // await Future.delayed(Durations.short1);
      whoopBloc.add(InitWhoopOnLogin());
      context.go(AppRoutes.redirect.path);
    }
  }
}
