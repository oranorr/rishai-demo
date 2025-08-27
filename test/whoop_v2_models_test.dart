import 'package:flutter_test/flutter_test.dart';
import 'package:rishai/features/whoop/data/models/v2/sleep_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/workout_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/cycle_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/recovery_model_v2.dart';

void main() {
  group('WHOOP API v2 Models Tests', () {
    test('SleepModelV2 should work with UUID and int IDs', () {
      // Тест с UUID
      final sleepV2Uuid = SleepModelV2(
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 12345,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        start: DateTime(2024, 1, 1, 22),
        end: DateTime(2024, 1, 2, 6),
        nap: false,
        scoreState: 'SCORED',
        activityV1Id: 67890,
      );

      expect(sleepV2Uuid.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(sleepV2Uuid.idAsUuid, '550e8400-e29b-41d4-a716-446655440000');
      expect(sleepV2Uuid.idAsInt, 67890); // Использует activityV1Id
      expect(sleepV2Uuid.userId, 12345);
      expect(sleepV2Uuid.activityV1Id, 67890);

      // Тест с int ID
      final sleepV2Int = SleepModelV2(
        id: 12345,
        userId: 12345,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        start: DateTime(2024, 1, 1, 22),
        end: DateTime(2024, 1, 2, 6),
        nap: false,
        scoreState: 'SCORED',
      );

      expect(sleepV2Int.id, 12345);
      expect(sleepV2Int.idAsInt, 12345);
      expect(sleepV2Int.idAsUuid, null);
      expect(sleepV2Int.userId, 12345);
    });

    test('WorkoutModelV2 should work with UUID and int IDs', () {
      final workoutV2 = WorkoutModelV2(
        id: '7bfc6a15-5521-612f-b9a4-e274dd7afae9',
        userId: 12345,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        start: DateTime(2024, 1, 1, 8),
        end: DateTime(2024, 1, 1, 9),
        timezoneOffset: '+04:00',
        sportId: 44,
        scoreState: 'SCORED',
        score: null,
        activityV1Id: 11111,
      );

      expect(workoutV2.id, '7bfc6a15-5521-612f-b9a4-e274dd7afae9');
      expect(workoutV2.idAsUuid, '7bfc6a15-5521-612f-b9a4-e274dd7afae9');
      expect(workoutV2.idAsInt, 11111);
      expect(workoutV2.userId, 12345);
      expect(workoutV2.sportId, 44);
    });

    test('CycleModelV2 should work with UUID and int IDs', () {
      final cycleV2 = CycleModelV2(
        id: '9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d',
        userId: 12345,
        createdAt: DateTime(2024),
        start: DateTime(2024),
        scoreState: 'SCORED',
        activityV1Id: 22222,
      );

      expect(cycleV2.id, '9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d');
      expect(cycleV2.idAsUuid, '9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d');
      expect(cycleV2.idAsInt, 22222);
      expect(cycleV2.userId, 12345);
    });

    test('RecoveryModelV2 should work with UUID and int IDs', () {
      final recoveryV2 = RecoveryModelV2(
        cycleId: '9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d',
        sleepId: '550e8400-e29b-41d4-a716-446655440000',
        userId: 12345,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        scoreState: 'SCORED',
        activityV1Id: 33333,
      );

      expect(recoveryV2.cycleId, '9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d');
      expect(recoveryV2.sleepId, '550e8400-e29b-41d4-a716-446655440000');
      expect(recoveryV2.userId, 12345);
      expect(recoveryV2.activityV1Id, 33333);
    });
  });
}
