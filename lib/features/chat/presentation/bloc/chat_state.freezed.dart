// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatState {
  Status get status => throw _privateConstructorUsedError;
  List<MessageEntity> get messages => throw _privateConstructorUsedError;
  int get requestsLeft => throw _privateConstructorUsedError;
  MealPlanEntity? get mealPlan => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)?
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)?
        mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatMainState value) mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatMainState value)? mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatMainState value)? mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatStateCopyWith<ChatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
  @useResult
  $Res call(
      {Status status,
      List<MessageEntity> messages,
      int requestsLeft,
      MealPlanEntity? mealPlan});
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? messages = null,
    Object? requestsLeft = null,
    Object? mealPlan = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageEntity>,
      requestsLeft: null == requestsLeft
          ? _value.requestsLeft
          : requestsLeft // ignore: cast_nullable_to_non_nullable
              as int,
      mealPlan: freezed == mealPlan
          ? _value.mealPlan
          : mealPlan // ignore: cast_nullable_to_non_nullable
              as MealPlanEntity?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMainStateImplCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$$ChatMainStateImplCopyWith(
          _$ChatMainStateImpl value, $Res Function(_$ChatMainStateImpl) then) =
      __$$ChatMainStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      List<MessageEntity> messages,
      int requestsLeft,
      MealPlanEntity? mealPlan});
}

/// @nodoc
class __$$ChatMainStateImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatMainStateImpl>
    implements _$$ChatMainStateImplCopyWith<$Res> {
  __$$ChatMainStateImplCopyWithImpl(
      _$ChatMainStateImpl _value, $Res Function(_$ChatMainStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? messages = null,
    Object? requestsLeft = null,
    Object? mealPlan = freezed,
  }) {
    return _then(_$ChatMainStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageEntity>,
      requestsLeft: null == requestsLeft
          ? _value.requestsLeft
          : requestsLeft // ignore: cast_nullable_to_non_nullable
              as int,
      mealPlan: freezed == mealPlan
          ? _value.mealPlan
          : mealPlan // ignore: cast_nullable_to_non_nullable
              as MealPlanEntity?,
    ));
  }
}

/// @nodoc

class _$ChatMainStateImpl implements ChatMainState {
  const _$ChatMainStateImpl(
      {required this.status,
      required final List<MessageEntity> messages,
      required this.requestsLeft,
      required this.mealPlan})
      : _messages = messages;

  @override
  final Status status;
  final List<MessageEntity> _messages;
  @override
  List<MessageEntity> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  final int requestsLeft;
  @override
  final MealPlanEntity? mealPlan;

  @override
  String toString() {
    return 'ChatState.mainState(status: $status, messages: $messages, requestsLeft: $requestsLeft, mealPlan: $mealPlan)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMainStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.requestsLeft, requestsLeft) ||
                other.requestsLeft == requestsLeft) &&
            (identical(other.mealPlan, mealPlan) ||
                other.mealPlan == mealPlan));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status,
      const DeepCollectionEquality().hash(_messages), requestsLeft, mealPlan);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMainStateImplCopyWith<_$ChatMainStateImpl> get copyWith =>
      __$$ChatMainStateImplCopyWithImpl<_$ChatMainStateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)
        mainState,
  }) {
    return mainState(status, messages, requestsLeft, mealPlan);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)?
        mainState,
  }) {
    return mainState?.call(status, messages, requestsLeft, mealPlan);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, List<MessageEntity> messages,
            int requestsLeft, MealPlanEntity? mealPlan)?
        mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(status, messages, requestsLeft, mealPlan);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatMainState value) mainState,
  }) {
    return mainState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatMainState value)? mainState,
  }) {
    return mainState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatMainState value)? mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(this);
    }
    return orElse();
  }
}

abstract class ChatMainState implements ChatState {
  const factory ChatMainState(
      {required final Status status,
      required final List<MessageEntity> messages,
      required final int requestsLeft,
      required final MealPlanEntity? mealPlan}) = _$ChatMainStateImpl;

  @override
  Status get status;
  @override
  List<MessageEntity> get messages;
  @override
  int get requestsLeft;
  @override
  MealPlanEntity? get mealPlan;
  @override
  @JsonKey(ignore: true)
  _$$ChatMainStateImplCopyWith<_$ChatMainStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
