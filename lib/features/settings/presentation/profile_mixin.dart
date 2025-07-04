part of './settings_pages/profile_settings.dart';

// final updUser = userBloc.state.user;

mixin ProfileMixin on State<ProfileSettings> {
  late UserEntity updUser;
  bool buttonIsActive = false;
  bool modificatorChangable = false;
  // late UserBloc bloc;
  @override
  void initState() {
    updUser = userBloc.state.user;
    modificatorChangable = updUser.userGoal!.goal == GoalType.aesthetics ||
        updUser.userGoal!.goal == GoalType.performance;

    super.initState();
  }

  @override
  void dispose() {
    updUser = UserEntity.unauthorized();
    print('haha');
    buttonIsActive = false;
    super.dispose();
  }

  void updateDietary(List<Dietary> diets) {
    final upd = updUser.copyWith(
      foodPreferences: updUser.foodPreferences!.copyWith(
        diets: diets.map((diet) => diet.name).toList(),
      ),
    );
    setUser(upd);
  }

  void updateCuisines(List<Cuisine> cuisines) {
    final upd = updUser.copyWith(
      foodPreferences: updUser.foodPreferences!.copyWith(
        cuisines: cuisines.map((cuisine) => cuisine.name).toList(),
      ),
    );

    setUser(upd);
  }

  void updateRestrinctions(List<Restriction> restrictions) {
    final upd = updUser.copyWith(
      foodPreferences: updUser.foodPreferences!.copyWith(
        restrictions: restrictions.isEmpty
            ? []
            : restrictions.map((restriction) => restriction.name).toList(),
      ),
    );

    setUser(upd);
  }

  void updateGoal(FitnessGoal incGoal) {
    final upd = updUser.copyWith(userGoal: incGoal.toUseGoal());
    setUser(upd);
  }

  void updateAge(int incAge) {
    final upd = updUser.copyWith(age: incAge);
    setUser(upd);
  }

  void updateGender(Gender incGender) {
    final upd = updUser.copyWith(gender: incGender);
    setUser(upd);
  }

  void changeModificator(double incMod) {
    final upd = updUser.copyWith(
      userGoal: UserGoal(
        goal: updUser.userGoal!.goal,
        modificator: incMod,
        updatedAt: DateTime.now(),
      ),
    );
    setUser(upd);
  }

  void setUser(UserEntity upd) {
    // Сохраняем текущий план питания
    final currentDay = whoopBloc.state.day;
    final currentMealPlan = currentDay.mealPlanEntity;

    setState(() {
      updUser = upd;
      buttonIsActive = true;
      modificatorChangable = updUser.userGoal!.goal == GoalType.aesthetics ||
          updUser.userGoal!.goal == GoalType.performance;
    });

    // Восстанавливаем план питания
    if (currentMealPlan != null) {
      final updatedDay = currentDay.copyWith(
        mealPlanEntity: currentMealPlan,
      );
      whoopBloc.add(WhoopUpdateCurrentDay(day: updatedDay));
    }
  }

  // [FIX] Метод для сброса изменений к актуальному состоянию UserBloc
  void resetToUserState() {
    setState(() {
      updUser = userBloc.state.user;
      buttonIsActive = false;
      modificatorChangable = updUser.userGoal!.goal == GoalType.aesthetics ||
          updUser.userGoal!.goal == GoalType.performance;
    });
  }

  // [FIX] Добавляем метод для синхронизации данных пользователя с UserBloc
  void syncUserData() {
    final currentUser = userBloc.state.user;
    if (currentUser != updUser && !buttonIsActive) {
      setState(() {
        updUser = currentUser;
        modificatorChangable = updUser.userGoal!.goal == GoalType.aesthetics ||
            updUser.userGoal!.goal == GoalType.performance;
      });
    }
  }
}
