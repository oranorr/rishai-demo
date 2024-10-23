part of 'user_entity.dart';

@HiveType(typeId: 3)
class BodyMeasurementsEntity extends Equatable {
  @HiveField(0)
  final double height;
  @HiveField(1)
  final int weight;
  @HiveField(2)
  final int maxHeartRate;
  const BodyMeasurementsEntity({
    required this.height,
    required this.weight,
    required this.maxHeartRate,
  });

  @override
  List<Object> get props => [height, weight, maxHeartRate];

  BodyMeasurementsEntity copyWith({
    double? height,
    int? weight,
    int? maxHeartRate,
  }) {
    return BodyMeasurementsEntity(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'height': height,
      'weight': weight,
      'maxHeartRate': maxHeartRate
    };
  }

  factory BodyMeasurementsEntity.fromMap(Map<String, dynamic> map) {
    return BodyMeasurementsEntity(
      height: map['height']!.runtimeType == int
          ? (map['height']! as int).toDouble()
          : map['height']!,
      weight: map['weight']!,
      maxHeartRate: map['maxHeartRate']!,
    );
  }
}
