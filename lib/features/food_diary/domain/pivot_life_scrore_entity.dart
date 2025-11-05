import 'package:hive/hive.dart';

part 'pivot_life_scrore_entity.g.dart';

@HiveType(typeId: 21)
class PivotLifeScoreEntity {
  PivotLifeScoreEntity({
    required this.score,
    required this.updatedAt,
  });

  factory PivotLifeScoreEntity.fromMap(Map<String, dynamic> map) {
    return PivotLifeScoreEntity(
      score: map['score'].toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
  @HiveField(0)
  final double score;
  @HiveField(1)
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  PivotLifeScoreEntity copyWith({
    double? score,
    DateTime? updatedAt,
  }) {
    return PivotLifeScoreEntity(
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PivotLifeScoreEntity(score: $score, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant PivotLifeScoreEntity other) {
    if (identical(this, other)) return true;

    return other.score == score && other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => score.hashCode ^ updatedAt.hashCode;
}
