// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserState {
  Status get status => throw _privateConstructorUsedError;
  UserEntity get user => throw _privateConstructorUsedError;
  List<DayEntity> get days => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            Status status, UserEntity user, List<DayEntity> days)
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, UserEntity user, List<DayEntity> days)?
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, UserEntity user, List<DayEntity> days)?
        mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(UserMainState value) mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(UserMainState value)? mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(UserMainState value)? mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $UserStateCopyWith<UserState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserStateCopyWith<$Res> {
  factory $UserStateCopyWith(UserState value, $Res Function(UserState) then) =
      _$UserStateCopyWithImpl<$Res, UserState>;
  @useResult
  $Res call({Status status, UserEntity user, List<DayEntity> days});
}

/// @nodoc
class _$UserStateCopyWithImpl<$Res, $Val extends UserState>
    implements $UserStateCopyWith<$Res> {
  _$UserStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? user = null,
    Object? days = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserEntity,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayEntity>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserMainStateImplCopyWith<$Res>
    implements $UserStateCopyWith<$Res> {
  factory _$$UserMainStateImplCopyWith(
          _$UserMainStateImpl value, $Res Function(_$UserMainStateImpl) then) =
      __$$UserMainStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Status status, UserEntity user, List<DayEntity> days});
}

/// @nodoc
class __$$UserMainStateImplCopyWithImpl<$Res>
    extends _$UserStateCopyWithImpl<$Res, _$UserMainStateImpl>
    implements _$$UserMainStateImplCopyWith<$Res> {
  __$$UserMainStateImplCopyWithImpl(
      _$UserMainStateImpl _value, $Res Function(_$UserMainStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? user = null,
    Object? days = null,
  }) {
    return _then(_$UserMainStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserEntity,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayEntity>,
    ));
  }
}

/// @nodoc

class _$UserMainStateImpl implements UserMainState {
  const _$UserMainStateImpl(
      {required this.status,
      required this.user,
      required final List<DayEntity> days})
      : _days = days;

  @override
  final Status status;
  @override
  final UserEntity user;
  final List<DayEntity> _days;
  @override
  List<DayEntity> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'UserState.mainState(status: $status, user: $user, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserMainStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.user, user) || other.user == user) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, status, user, const DeepCollectionEquality().hash(_days));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserMainStateImplCopyWith<_$UserMainStateImpl> get copyWith =>
      __$$UserMainStateImplCopyWithImpl<_$UserMainStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            Status status, UserEntity user, List<DayEntity> days)
        mainState,
  }) {
    return mainState(status, user, days);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, UserEntity user, List<DayEntity> days)?
        mainState,
  }) {
    return mainState?.call(status, user, days);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, UserEntity user, List<DayEntity> days)?
        mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(status, user, days);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(UserMainState value) mainState,
  }) {
    return mainState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(UserMainState value)? mainState,
  }) {
    return mainState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(UserMainState value)? mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(this);
    }
    return orElse();
  }
}

abstract class UserMainState implements UserState {
  const factory UserMainState(
      {required final Status status,
      required final UserEntity user,
      required final List<DayEntity> days}) = _$UserMainStateImpl;

  @override
  Status get status;
  @override
  UserEntity get user;
  @override
  List<DayEntity> get days;
  @override
  @JsonKey(ignore: true)
  _$$UserMainStateImplCopyWith<_$UserMainStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
