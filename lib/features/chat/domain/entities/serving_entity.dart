// ignore_for_file: public_member_api_docs, sort_constructors_first
class ServingEntity {
  final ServingType type;
  final String? comment;
  final String prompt;
  final int weight;

  ServingEntity({
    required this.type,
    required this.prompt,
    required this.weight,
    this.comment,
  });

  @override
  String toString() =>
      'ServingEntity(type: $type, comment: $comment, weight: $weight)';

  ServingEntity copyWith({
    ServingType? type,
    String? comment,
    String? prompt,
    int? weight,
  }) {
    return ServingEntity(
      type: type ?? this.type,
      comment: comment ?? this.comment,
      prompt: prompt ?? this.prompt,
      weight: weight ?? this.weight,
    );
  }
}

enum ServingType {
  breakfast,
  lunch,
  dinner,
  supper,
  snack,
}

extension ServingName on ServingType {
  String get name {
    switch (this) {
      case ServingType.breakfast:
        return 'Breakfast';
      case ServingType.lunch:
        return 'Lunch';
      case ServingType.dinner:
        return 'Dinner';
      case ServingType.supper:
        return 'Supper';
      case ServingType.snack:
        return 'Snack';
    }
  }
}
