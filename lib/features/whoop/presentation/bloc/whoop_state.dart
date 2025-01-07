import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rishai/core/status.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

part 'whoop_state.freezed.dart';

@freezed
sealed class WhoopState with _$WhoopState {
  const factory WhoopState.main({
    required Status status,
    required DayEntity day,
    required bool whoopConnected,
    DateTime? calibratingCompleteDate,
  }) = WhoopMainState;
}
