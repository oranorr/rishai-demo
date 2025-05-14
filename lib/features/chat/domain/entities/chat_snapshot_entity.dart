import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/message_entity.dart';

part 'chat_snapshot_entity.g.dart';

@HiveType(typeId: 4)
class ChatSnapshotEntity {
  ChatSnapshotEntity({
    required this.messages,
    required this.date,
    required this.requestsLeft,
    this.mealPlan,
    this.threadId,
  });

  factory ChatSnapshotEntity.fromDirectus(Map<String, dynamic> map) {
    return ChatSnapshotEntity(
      messages: [],
      date: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      requestsLeft: map['requestsLeft'] is String
          ? int.parse(map['requestsLeft'])
          : map['requestsLeft'],
      threadId: map['threadId'],
      mealPlan: map['mealPlan'] != null
          ? MealPlanEntity.fromMap(map['mealPlan'])
          : null,
    );
  }
  @HiveField(0)
  final List<MessageEntity> messages;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final int requestsLeft;
  @HiveField(3)
  final MealPlanEntity? mealPlan;
  @HiveField(4)
  final String? threadId;

  Map<String, dynamic> toDirectus() {
    return {
      'dateTime': date.millisecondsSinceEpoch,
      'requestsLeft': requestsLeft,
      'threadId': threadId,
    };
  }

  ChatSnapshotEntity copyWith({
    List<MessageEntity>? messages,
    DateTime? date,
    int? requestsLeft,
    bool? planCreated,
    MealPlanEntity? mealPlan,
    String? threadId,
  }) {
    return ChatSnapshotEntity(
      messages: messages ?? this.messages,
      date: date ?? this.date,
      requestsLeft: requestsLeft ?? this.requestsLeft,
      mealPlan: mealPlan ?? this.mealPlan,
      threadId: threadId ?? this.threadId,
    );
  }

  @override
  String toString() {
    return 'ChatSnapshotEntity(messages: $messages, date: $date, requestsLeft: $requestsLeft, mealPlan: $mealPlan, threadId: $threadId)';
  }

  @override
  bool operator ==(covariant ChatSnapshotEntity other) {
    if (identical(this, other)) {
      return true;
    }

    return listEquals(other.messages, messages) &&
        other.date == date &&
        other.requestsLeft == requestsLeft &&
        other.mealPlan == mealPlan;
  }

  @override
  int get hashCode {
    return messages.hashCode ^
        date.hashCode ^
        requestsLeft.hashCode ^
        mealPlan.hashCode;
  }

  // Map<String, dynamic> toMap() {
  //   return <String, dynamic>{
  //     'messages': messages.map((x) => x.toMap()).toList(),
  //     'date': date.millisecondsSinceEpoch,
  //     'requestsLeft': requestsLeft,
  //     'planCreated': planCreated,
  //     'mealPlan': mealPlan?.toMap(),
  //   };
  // }

  // factory ChatSnapshotEntity.fromMap(Map<String, dynamic> map) {
  //   return ChatSnapshotEntity(
  //     messages: List<MessageEntity>.from((map['messages'] as List<int>).map<MessageEntity>((x) => MessageEntity.fromMap(x as Map<String,dynamic>),),),
  //     date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
  //     requestsLeft: map['requestsLeft'] as int,
  //     planCreated: map['planCreated'] as bool,
  //     mealPlan: map['mealPlan'] != null ? MealPlanEntity.fromMap(map['mealPlan'] as Map<String,dynamic>) : null,
  //   );
  // }

  // String toJson() => json.encode(toMap());

  // factory ChatSnapshotEntity.fromJson(String source) => ChatSnapshotEntity.fromMap(json.decode(source) as Map<String, dynamic>);
}
