import 'package:hive/hive.dart';

part 'pivot_life_scrore_entity.g.dart';

@HiveType(typeId: 21)
class PivotLifeScoreEntity {
  PivotLifeScoreEntity({
    required this.score,
    required this.updatedAt,
    required this.inceptionDate,
  });

  factory PivotLifeScoreEntity.fromMap(Map<String, dynamic> map) {
    return PivotLifeScoreEntity(
      score: map['score'].toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      inceptionDate: map['inceptionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['inceptionDate'])
          : DateTime.now(), // Fallback для старых данных
    );
  }
  @HiveField(0)
  final double score;
  @HiveField(1)
  final DateTime updatedAt;
  @HiveField(2)
  final DateTime inceptionDate;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'inceptionDate': inceptionDate.millisecondsSinceEpoch,
    };
  }

  PivotLifeScoreEntity copyWith({
    double? score,
    DateTime? updatedAt,
    DateTime? inceptionDate,
  }) {
    return PivotLifeScoreEntity(
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
      inceptionDate: inceptionDate ?? this.inceptionDate,
    );
  }

  @override
  String toString() {
    return 'PivotLifeScoreEntity(score: $score, updatedAt: $updatedAt, inceptionDate: $inceptionDate)';
  }

  @override
  bool operator ==(covariant PivotLifeScoreEntity other) {
    if (identical(this, other)) return true;

    return other.score == score &&
        other.updatedAt == updatedAt &&
        other.inceptionDate == inceptionDate;
  }

  @override
  int get hashCode => score.hashCode ^ updatedAt.hashCode ^ inceptionDate.hashCode;
}
