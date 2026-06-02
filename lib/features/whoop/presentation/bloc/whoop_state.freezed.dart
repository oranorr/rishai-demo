// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whoop_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WhoopState {
  Status get status => throw _privateConstructorUsedError;
  DayEntity get day => throw _privateConstructorUsedError;
  bool get whoopConnected => throw _privateConstructorUsedError;
  DateTime? get calibratingCompleteDate => throw _privateConstructorUsedError;
  WhoopSyncBannerPhase get syncBannerPhase =>
      throw _privateConstructorUsedError;
  DateTime? get lastSyncedAt => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)
        main,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)?
        main,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)?
        main,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WhoopMainState value) main,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WhoopMainState value)? main,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WhoopMainState value)? main,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WhoopStateCopyWith<WhoopState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WhoopStateCopyWith<$Res> {
  factory $WhoopStateCopyWith(
          WhoopState value, $Res Function(WhoopState) then) =
      _$WhoopStateCopyWithImpl<$Res, WhoopState>;
  @useResult
  $Res call(
      {Status status,
      DayEntity day,
      bool whoopConnected,
      DateTime? calibratingCompleteDate,
      WhoopSyncBannerPhase syncBannerPhase,
      DateTime? lastSyncedAt});
}

/// @nodoc
class _$WhoopStateCopyWithImpl<$Res, $Val extends WhoopState>
    implements $WhoopStateCopyWith<$Res> {
  _$WhoopStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? day = null,
    Object? whoopConnected = null,
    Object? calibratingCompleteDate = freezed,
    Object? syncBannerPhase = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DayEntity,
      whoopConnected: null == whoopConnected
          ? _value.whoopConnected
          : whoopConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      calibratingCompleteDate: freezed == calibratingCompleteDate
          ? _value.calibratingCompleteDate
          : calibratingCompleteDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncBannerPhase: null == syncBannerPhase
          ? _value.syncBannerPhase
          : syncBannerPhase // ignore: cast_nullable_to_non_nullable
              as WhoopSyncBannerPhase,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WhoopMainStateImplCopyWith<$Res>
    implements $WhoopStateCopyWith<$Res> {
  factory _$$WhoopMainStateImplCopyWith(_$WhoopMainStateImpl value,
          $Res Function(_$WhoopMainStateImpl) then) =
      __$$WhoopMainStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      DayEntity day,
      bool whoopConnected,
      DateTime? calibratingCompleteDate,
      WhoopSyncBannerPhase syncBannerPhase,
      DateTime? lastSyncedAt});
}

/// @nodoc
class __$$WhoopMainStateImplCopyWithImpl<$Res>
    extends _$WhoopStateCopyWithImpl<$Res, _$WhoopMainStateImpl>
    implements _$$WhoopMainStateImplCopyWith<$Res> {
  __$$WhoopMainStateImplCopyWithImpl(
      _$WhoopMainStateImpl _value, $Res Function(_$WhoopMainStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? day = null,
    Object? whoopConnected = null,
    Object? calibratingCompleteDate = freezed,
    Object? syncBannerPhase = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_$WhoopMainStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DayEntity,
      whoopConnected: null == whoopConnected
          ? _value.whoopConnected
          : whoopConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      calibratingCompleteDate: freezed == calibratingCompleteDate
          ? _value.calibratingCompleteDate
          : calibratingCompleteDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncBannerPhase: null == syncBannerPhase
          ? _value.syncBannerPhase
          : syncBannerPhase // ignore: cast_nullable_to_non_nullable
              as WhoopSyncBannerPhase,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$WhoopMainStateImpl implements WhoopMainState {
  const _$WhoopMainStateImpl(
      {required this.status,
      required this.day,
      required this.whoopConnected,
      this.calibratingCompleteDate,
      this.syncBannerPhase = WhoopSyncBannerPhase.hidden,
      this.lastSyncedAt});

  @override
  final Status status;
  @override
  final DayEntity day;
  @override
  final bool whoopConnected;
  @override
  final DateTime? calibratingCompleteDate;
  @override
  @JsonKey()
  final WhoopSyncBannerPhase syncBannerPhase;
  @override
  final DateTime? lastSyncedAt;

  @override
  String toString() {
    return 'WhoopState.main(status: $status, day: $day, whoopConnected: $whoopConnected, calibratingCompleteDate: $calibratingCompleteDate, syncBannerPhase: $syncBannerPhase, lastSyncedAt: $lastSyncedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WhoopMainStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.whoopConnected, whoopConnected) ||
                other.whoopConnected == whoopConnected) &&
            (identical(
                    other.calibratingCompleteDate, calibratingCompleteDate) ||
                other.calibratingCompleteDate == calibratingCompleteDate) &&
            (identical(other.syncBannerPhase, syncBannerPhase) ||
                other.syncBannerPhase == syncBannerPhase) &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, day, whoopConnected,
      calibratingCompleteDate, syncBannerPhase, lastSyncedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WhoopMainStateImplCopyWith<_$WhoopMainStateImpl> get copyWith =>
      __$$WhoopMainStateImplCopyWithImpl<_$WhoopMainStateImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)
        main,
  }) {
    return main(status, day, whoopConnected, calibratingCompleteDate,
        syncBannerPhase, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)?
        main,
  }) {
    return main?.call(status, day, whoopConnected, calibratingCompleteDate,
        syncBannerPhase, lastSyncedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            Status status,
            DayEntity day,
            bool whoopConnected,
            DateTime? calibratingCompleteDate,
            WhoopSyncBannerPhase syncBannerPhase,
            DateTime? lastSyncedAt)?
        main,
    required TResult orElse(),
  }) {
    if (main != null) {
      return main(status, day, whoopConnected, calibratingCompleteDate,
          syncBannerPhase, lastSyncedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(WhoopMainState value) main,
  }) {
    return main(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(WhoopMainState value)? main,
  }) {
    return main?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(WhoopMainState value)? main,
    required TResult orElse(),
  }) {
    if (main != null) {
      return main(this);
    }
    return orElse();
  }
}

abstract class WhoopMainState implements WhoopState {
  const factory WhoopMainState(
      {required final Status status,
      required final DayEntity day,
      required final bool whoopConnected,
      final DateTime? calibratingCompleteDate,
      final WhoopSyncBannerPhase syncBannerPhase,
      final DateTime? lastSyncedAt}) = _$WhoopMainStateImpl;

  @override
  Status get status;
  @override
  DayEntity get day;
  @override
  bool get whoopConnected;
  @override
  DateTime? get calibratingCompleteDate;
  @override
  WhoopSyncBannerPhase get syncBannerPhase;
  @override
  DateTime? get lastSyncedAt;
  @override
  @JsonKey(ignore: true)
  _$$WhoopMainStateImplCopyWith<_$WhoopMainStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
