// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LoginState {
  Status get status => throw _privateConstructorUsedError;
  LoginInfoEntity? get loginEntity => throw _privateConstructorUsedError;
  String? get otp => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Status status, LoginInfoEntity? loginEntity,
            String? otp, String? errorMessage)
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, LoginInfoEntity? loginEntity, String? otp,
            String? errorMessage)?
        mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, LoginInfoEntity? loginEntity, String? otp,
            String? errorMessage)?
        mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginMainState value) mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginMainState value)? mainState,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginMainState value)? mainState,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LoginStateCopyWith<LoginState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginStateCopyWith<$Res> {
  factory $LoginStateCopyWith(
          LoginState value, $Res Function(LoginState) then) =
      _$LoginStateCopyWithImpl<$Res, LoginState>;
  @useResult
  $Res call(
      {Status status,
      LoginInfoEntity? loginEntity,
      String? otp,
      String? errorMessage});
}

/// @nodoc
class _$LoginStateCopyWithImpl<$Res, $Val extends LoginState>
    implements $LoginStateCopyWith<$Res> {
  _$LoginStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? loginEntity = freezed,
    Object? otp = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      loginEntity: freezed == loginEntity
          ? _value.loginEntity
          : loginEntity // ignore: cast_nullable_to_non_nullable
              as LoginInfoEntity?,
      otp: freezed == otp
          ? _value.otp
          : otp // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoginMainStateImplCopyWith<$Res>
    implements $LoginStateCopyWith<$Res> {
  factory _$$LoginMainStateImplCopyWith(_$LoginMainStateImpl value,
          $Res Function(_$LoginMainStateImpl) then) =
      __$$LoginMainStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      LoginInfoEntity? loginEntity,
      String? otp,
      String? errorMessage});
}

/// @nodoc
class __$$LoginMainStateImplCopyWithImpl<$Res>
    extends _$LoginStateCopyWithImpl<$Res, _$LoginMainStateImpl>
    implements _$$LoginMainStateImplCopyWith<$Res> {
  __$$LoginMainStateImplCopyWithImpl(
      _$LoginMainStateImpl _value, $Res Function(_$LoginMainStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? loginEntity = freezed,
    Object? otp = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$LoginMainStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      loginEntity: freezed == loginEntity
          ? _value.loginEntity
          : loginEntity // ignore: cast_nullable_to_non_nullable
              as LoginInfoEntity?,
      otp: freezed == otp
          ? _value.otp
          : otp // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$LoginMainStateImpl implements LoginMainState {
  const _$LoginMainStateImpl(
      {required this.status, this.loginEntity, this.otp, this.errorMessage});

  @override
  final Status status;
  @override
  final LoginInfoEntity? loginEntity;
  @override
  final String? otp;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'LoginState.mainState(status: $status, loginEntity: $loginEntity, otp: $otp, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginMainStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.loginEntity, loginEntity) ||
                other.loginEntity == loginEntity) &&
            (identical(other.otp, otp) || other.otp == otp) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, status, loginEntity, otp, errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginMainStateImplCopyWith<_$LoginMainStateImpl> get copyWith =>
      __$$LoginMainStateImplCopyWithImpl<_$LoginMainStateImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Status status, LoginInfoEntity? loginEntity,
            String? otp, String? errorMessage)
        mainState,
  }) {
    return mainState(status, loginEntity, otp, errorMessage);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Status status, LoginInfoEntity? loginEntity, String? otp,
            String? errorMessage)?
        mainState,
  }) {
    return mainState?.call(status, loginEntity, otp, errorMessage);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Status status, LoginInfoEntity? loginEntity, String? otp,
            String? errorMessage)?
        mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(status, loginEntity, otp, errorMessage);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoginMainState value) mainState,
  }) {
    return mainState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoginMainState value)? mainState,
  }) {
    return mainState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoginMainState value)? mainState,
    required TResult orElse(),
  }) {
    if (mainState != null) {
      return mainState(this);
    }
    return orElse();
  }
}

abstract class LoginMainState implements LoginState {
  const factory LoginMainState(
      {required final Status status,
      final LoginInfoEntity? loginEntity,
      final String? otp,
      final String? errorMessage}) = _$LoginMainStateImpl;

  @override
  Status get status;
  @override
  LoginInfoEntity? get loginEntity;
  @override
  String? get otp;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$LoginMainStateImplCopyWith<_$LoginMainStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
