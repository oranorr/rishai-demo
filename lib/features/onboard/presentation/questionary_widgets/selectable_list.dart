part of '../questionary.dart';

class SelectableList extends StatefulWidget {
  const SelectableList({
    required this.data,
    required this.setSomething,
    super.key,
  });
  final List<Question> data;
  final Function(List<Question>) setSomething;

  @override
  State<SelectableList> createState() => _SelectableListState();
}

class _SelectableListState extends State<SelectableList> {
  List<Question> selected = [];
  FitnessGoal? goalSelected;

  void toggleDietSelection(Question diet) {
    setState(() {
      if (diet.runtimeType == Dietary) {
        if (selected.isNotEmpty) {
          selected.remove(selected.first);
        }
        selected.add(diet);
      } else {
        selected.contains(diet) ? selected.remove(diet) : selected.add(diet);
      }
      // if (selected.contains(diet)) {
      //   selected.remove(diet);
      // } else {
      //   if (diet.runtimeType == Dietary) {
      //     if (selected.isEmpty) {
      //       selected.add(diet);
      //     }
      //   } else {
      //     selected.add(diet);
      //   }
      // }
    });
    widget.setSomething(selected);
  }

  void selectGoal(FitnessGoal goal) {
    widget.setSomething([goal]);
  }

  void preselect(FitnessGoal g) {
    setState(() {
      goalSelected = g;
    });
  }

  bool isSelectedGoal(FitnessGoal goal) {
    return goalSelected == goal;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    if (data.runtimeType != List<FitnessGoal>) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final q = data[index];
          final isSelected = selected.contains(q);

          return q.buildWidget(
            context: context,
            action: (q) {
              toggleDietSelection(q);
            },
            isSelected: isSelected,
          );
        },
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final goal = data[index];
          // bool isSelected = goal == goalSelected;
          return goal.buildWidget(
            preSelectCard: (goal) {
              preselect(goal as FitnessGoal);
            },
            context: context,
            action: (goal) {
              selectGoal(goal as FitnessGoal);
            },
            isSelected: isSelectedGoal(goal as FitnessGoal),
          );
        },
      );
    }
  }
}
